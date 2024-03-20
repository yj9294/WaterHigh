//
//  ProfileView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import ComposableArchitecture
import GADUtil
import SwiftUI

protocol ProfileItem {
    var title: String { get }
    var bg: String { get }
}

extension ProfileItem {
    var title: String {
        return ""
    }
    
    var bg: String {
        return ""
    }
}

enum SettingItem: ProfileItem, CaseIterable {
    case reminder, privacy, rate
    
    var title: String {
        switch self {
        case .reminder:
            return "Reminder Time"
        case .privacy:
            return "Privacy Policy"
        case .rate:
            return "Rate us"
        }
    }
}

enum TipItem: ProfileItem, CaseIterable {
    case tip1, tip2, tip3
    var title: String {
        switch self {
        case .tip1:
            return "1. Keep your body hydrated"
        case .tip2:
            return "2. Develop good drinking habits"
        case .tip3:
            return "3. Drink water scientifically and stay away from health problems"
        }
    }
    
    var bg: String {
        return "setting_tip_\(Self.allCases.firstIndex(of: self) ?? 0)"
    }
    
    var description: String {
        switch self {
        case .tip1:
            return """
Drink water regularly: Drinking water regularly is the key to keeping your body hydrated. It is recommended to drink at least 8 glasses of water a day, and during hot weather or after exercise, you should increase the amount of water to replace the lost water.
Drink plenty of water: Choose water as your main drink, rather than sugary or caffeinated drinks. Water can help boost metabolism, keep skin hydrated, and promote body detoxification.
Body weight hydration: Determine the amount of water you need each day based on your weight and activity level. It is generally recommended to consume about 1/30 of your body weight per day, for example, a person weighing 60 kg would need to drink about 2 liters of water per day.
Don't wait until you're thirsty: Don't wait until you're thirsty to drink, because thirst is a sign that your body isn't hydrated enough. Staying well hydrated helps maintain the proper functioning of the body and prevents dehydration and other health problems.
Eat more fruits and vegetables: Fruits and vegetables are rich in water and nutrients, and are a good choice to replenish water. Eating more fruits and vegetables not only increases water intake, but also provides vitamins, minerals and antioxidants.
Keeping your body well hydrated is essential to maintaining good health. By drinking water regularly, choosing water, and hydrating according to your weight, you can easily maintain your water balance and improve your health.
"""
        case .tip2:
            return """
Daily ration: Develop a daily ration of water, such as after waking up, before and after lunch, tea time and dinner before and after drinking a glass of water. Drinking water regularly helps to maintain the body's water balance and improve metabolism.
Avoid overdoing it: While it's important to stay hydrated, don't overdo it. Drinking too much water can lead to health problems such as dilutive hyponatremia, so drink in moderation and don't drink too much.
Variety of choices: In addition to pure water, you can also choose foods with high water content, such as watermelon, cucumber, tomato and other fruits and vegetables as a source of supplementary water. At the same time, you can drink tea, coffee and clear soup, but to control the intake of added sugar and caffeine.
Be aware of the environment: In dry, hot or high altitude environments, the body is more likely to lose water, so increase the amount of water you drink to cope with these conditions. When outdoor activities or sports, it is more important to pay attention to timely replenishment of water to avoid dehydration.
Drinking water reminder: You can use mobile phone applications or set timers to remind yourself to drink water and maintain good drinking habits. When working or studying, you can also prepare a glass of water by your side to remind yourself to replenish water at any time.
Keeping a good drinking habit helps to improve health, enhance immunity, improve skin and prevent health problems. Through quantification, variety of choices, attention to the environment and drinking reminders, you can easily develop good drinking habits and enjoy a healthy life.
"""
        case .tip3:
            return """
Follow your body's needs: Your body is losing water every day, so determine your daily water intake according to your weight, lifestyle habits and environmental conditions. It is generally recommended to consume about 30 to 35 ml/kg of water per day, but it is necessary to increase the amount of water in hot weather, exercise or special circumstances.
Balanced drinking time: Spread the drinking time and avoid concentrating on drinking water. Drinking a small glass of water every once in a while helps to maintain the body's water balance, reduce excessive urination times, and improve water utilization.
Observe urine color: Urine color is an important indicator of body water status. Dark yellow urine may indicate dehydration, while clear, clear urine indicates that the body is well hydrated. Therefore, keeping urine light yellow is an indicator of good water intake
Drink warm water in moderation: Warm water is more easily absorbed by the body, so you can drink warm water in moderation in your daily water. Especially when you wake up in the morning, drinking a glass of warm water helps to promote gastrointestinal motility and clean the intestines.
Drink more electrolyte-rich water: After intense exercise or heavy sweating, drink some electrolyte-rich water or sports drinks in addition to regular water to help replace lost water and electrolytes.
Drinking water is an important factor in maintaining good health. By following your body's needs, timing your water intake, monitoring the color of your urine, drinking warm water in moderation, and drinking more electrolyte-rich water, you can effectively maintain your body's water balance and avoid various health problems.
"""
        }
    }
}

@Reducer
struct Profile {
    @ObservableState
    struct State: Equatable {
        @Presents var reminderState: Reminder.State?
        @Presents var privacyState: Privacy.State?
        @Presents var tipsState: Tips.State?
        
        mutating func presentReminderView() {
            reminderState = .init()
            GADUtil.share.disappear(.native)
            GADUtil.share.load(.native)
        }
        
        mutating func presentPrivacyView() {
            privacyState = .init()
        }
        
        mutating func presentTipsView(_ item: TipItem) {
            tipsState = .init(item: item)
        }
        
        func rateAction() {
            if let url = URL(string: "https://apps.apple.com/app/6478917767") {
                UIApplication.shared.open(url)
            }
        }
    }
    enum Action: Equatable {
        case selectedSettingItem(SettingItem)
        case selectedTipItem(TipItem)
        case reminderAction(PresentationAction<Reminder.Action>)
        case privacyAction(PresentationAction<Privacy.Action>)
        case tipsAction(PresentationAction<Tips.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .selectedSettingItem(item) = action {
                switch item {
                case .reminder:
                    state.presentReminderView()
                case .privacy:
                    state.presentPrivacyView()
                default:
                    state.rateAction()
                }
            }
            if case let .selectedTipItem(item) = action {
                state.presentTipsView(item)
            }
            return .none
        }.ifLet(\.$privacyState, action: \.privacyAction) {
            Privacy()
        }.ifLet(\.$reminderState, action: \.reminderAction) {
            Reminder()
        }.ifLet(\.$tipsState, action: \.tipsAction) {
            Tips()
        }
    }
}

struct ProfileView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<Profile>
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack{
                    _NavigationBarView()
                    _SettingView { item in
                        store.send(.selectedSettingItem(item))
                    }
                    _TipView { item in
                        store.send(.selectedTipItem(item))
                    }
                    Spacer()
                }
            }.background(Color(uiColor: UIColor.init(hex: 0xE6FAFF))).fullScreenCover(item: $store.scope(state: \.tipsState, action: \.tipsAction)) { store in
                TipsView(store: store)
            }.fullScreenCover(item: $store.scope(state: \.privacyState, action: \.privacyAction)) { store in
                PrivacyView(store: store)
            }.fullScreenCover(item: $store.scope(state: \.reminderState, action: \.reminderAction)) { store in
                ReminderView(store: store)
            }
        }
    }
    
    struct _NavigationBarView: View {
        var body: some View {
            HStack{
                Image("setting_title")
                Spacer()
            }.padding(.horizontal, 16)
        }
    }
    
    struct _SettingView: View {
        let action: (SettingItem)->Void
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                VStack(spacing: 0){
                    ForEach(SettingItem.allCases, id: \.self) { item in
                        Button {
                            action(item)
                        } label: {
                            HStack{
                                Text(item.title).padding(.vertical, 20)
                                Spacer()
                                Image("setting_arrow")
                            }
                        }.padding(.horizontal, 16)
                    }.foregroundColor(.black)
                }
            }.background(.white).cornerRadius(20).padding(.all, 20)
        }
    }
    struct _TipView: View {
        let action: (TipItem)->Void
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                VStack(spacing: 20){
                    ForEach(TipItem.allCases, id: \.self) { item in
                        Button(action: {
                            action(item)
                        }, label: {
                            HStack{
                                Text(item.title).padding(.vertical, 20).lineLimit(nil).multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }).padding(.leading, 16).padding(.trailing, 120).background(Image(item.bg).resizable())
                    }.foregroundColor(.black)
                }
            }.padding(.horizontal, 20)
        }
    }
}

#Preview {
    ProfileView(store: Store.init(initialState: Profile.State(), reducer: {
        Profile()
    }))
}

