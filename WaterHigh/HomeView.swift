//
//  HomeView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import GADUtil

enum HomeItem: String, CaseIterable, Hashable {
    case drink, charts, reward, profile
    var title: String {
        self.rawValue.capitalized
    }
    var icon: String {
        "home_\(self.rawValue)"
    }
    var selectedIcon: String {
        "home_\(self.rawValue)_1"
    }
    
    func isSelected(_ item: HomeItem) -> Bool {
        item == self
    }
}

@Reducer
struct Home {
    
    @ObservableState
    struct State: Equatable {
        
        var item: HomeItem = .drink
        var drinkState: Drink.State = .init()
        var chartsState: Charts.State = .init()
        var rewardSate: Reward.State = .init()
        var profileState: Profile.State = .init()
        
        mutating func updateItem(item: HomeItem) {
            self.item = item
        }
        
        mutating func updateDrinks() {
            drinkState.drinks = CacheUtil.getDrinks()
            chartsState.drinks = CacheUtil.getDrinks()
        }
        
        mutating func updateGoal() {
            drinkState.goal = CacheUtil.getGoal()
        }
        
        var drinkImpressionDate: Date = CacheUtil.getImpressionDate(.drink)
        var chartsImpressionDate: Date = CacheUtil.getImpressionDate(.charts)
        var reminderImpressionDate: Date = CacheUtil.getImpressionDate(.profile)
        mutating func updateADModel(_ ad: GADNativeViewModel) {
            if item == .drink, ad != .none {
                if Date().timeIntervalSince1970 - drinkImpressionDate .timeIntervalSince1970 > 10 {
                    drinkState.ad = ad
                    drinkImpressionDate = Date()
                } else {
                    debugPrint("[AD] drink 原生广告10s间隔限制")
                }
            } else if item == .charts, ad != .none {
                if Date().timeIntervalSince1970 - chartsImpressionDate.timeIntervalSince1970 > 10 {
                    chartsState.ad = ad
                    chartsImpressionDate = Date()
                } else {
                    debugPrint("[AD] charts 原生广告10s间隔限制")
                }
            } else if item == .profile, ad != .none {
                if Date().timeIntervalSince1970 - reminderImpressionDate.timeIntervalSince1970 > 10 {
                    profileState.reminderState?.ad = ad
                    reminderImpressionDate = Date()
                } else {
                    debugPrint("[AD] reminder 原生广告10s间隔限制")
                }
            } else {
                drinkState.ad = .none
                chartsState.ad = .none
                profileState.reminderState?.ad = .none
            }
        }
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case updateItem(HomeItem)
        case drinkAction(Drink.Action)
        case chartsAction(Charts.Action)
        case rewardAction(Reward.Action)
        case profileAction(Profile.Action)
        case updateAD(GADNativeViewModel)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            if case let .updateItem(item) = action {
                state.updateItem(item: item)
            }
            if case .drinkAction(.updateDrinks) = action {
                state.updateDrinks()
            }
            
            if case .drinkAction(.updateGoal) = action {
                state.updateGoal()
            }
            
            if case let .updateAD(ad) = action {
                state.updateADModel(ad)
            }
            return .none
        }
        Scope(state: \.drinkState, action: \.drinkAction) {
            Drink()
        }
        Scope(state: \.chartsState, action: \.chartsAction) {
            Charts()
        }
        Scope(state: \.rewardSate, action: \.rewardAction) {
            Reward()
        }
        Scope(state: \.profileState, action: \.profileAction) {
            Profile()
        }
    }
}

struct HomeView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<Home>
    var body: some View {
        WithPerceptionTracking{
            TabView(selection: $store.item,
                    content:  {
                DrinkView(store: store.scope(state: \.drinkState, action: \.drinkAction)).tabItem {
                    getTabbarItem(.drink, in: store.item)
                }.tag(HomeItem.drink)
                ChartsView(store: store.scope(state: \.chartsState, action: \.chartsAction)).tabItem {
                    getTabbarItem(.charts, in: store.item)
                }.tag(HomeItem.charts)
                RewardView(store: store.scope(state: \.rewardSate, action: \.rewardAction)).tabItem {
                    getTabbarItem(.reward, in: store.item)
                }.tag(HomeItem.reward)
                ProfileView(store: store.scope(state: \.profileState, action: \.profileAction)).tabItem {
                    getTabbarItem(.profile, in: store.item)
                }.tag(HomeItem.profile)
            }).onReceive(NotificationCenter.default.publisher(for: .nativeUpdate), perform: { noti in
                if let ad = noti.object as? GADNativeModel {
                    store.send(.updateAD(GADNativeViewModel(model: ad)))
                } else {
                    store.send(.updateAD(.none))
                }
            })
        }
    }
    
    func getTabbarItem(_ item: HomeItem, in it: HomeItem) ->  some View {
        return VStack{
            Image(item.isSelected(it) ? item.selectedIcon : item.icon)
            Text(item.title).foregroundStyle(Color(uiColor: UIColor(hex: item.isSelected(it) ? 0x00A5FD : 0xA6EDFF)))
        }
    }
}

#Preview {
    HomeView(store: Store.init(initialState: Home.State(), reducer: {
        Home()
    }))
}
