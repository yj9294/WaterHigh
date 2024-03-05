//
//  RewardView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct Reward {
    @ObservableState
    struct State: Equatable {
        var drinks: [DrinkModel] = CacheUtil.getDrinks()
    }
    enum Action: Equatable {
        case dismiss
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .dismiss = action {
                return .run { send in
                    await dismiss()
                }
            }
            return .none
        }
    }
}

struct RewardView: View {
    let store: StoreOf<Reward>
    var body: some View {
        VStack{
            _NavigationBar(store: store)
            _KeepItemView()
            _AchievementView()
            Spacer()
        }.background(Color(uiColor: UIColor(hex: 0xE6FAFF)))
    }
    
    struct _NavigationBar: View {
        @ComposableArchitecture.Bindable var  store: StoreOf<Reward>
        var body: some View {
            HStack{
                Image("reward_title")
                Spacer()
            }.padding(.horizontal, 16).frame(height: 44)
        }
    }
    
    
    struct _KeepItemView: View {
        var body: some View {
            VStack{
                HStack{
                    Text("Keep drinking water").font(.system(size: 16))
                    Spacer()
                }.padding(.leading, 14)
                WithPerceptionTracking {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 18),GridItem(.flexible(), spacing: 8),GridItem(.flexible(), spacing: 18)], spacing: 16, content: {
                        ForEach(KeepItem.allCases, id: \.self) { item in
                            Image(item.icon)
                        }
                    }).padding(.all, 12)
                }
            }.padding(.all, 12).background(.white).padding(.all, 20)
        }
    }
    
    struct _AchievementView: View {
        var body: some View {
            VStack{
                HStack{
                    Text("Drinking Water Achievement").font(.system(size: 16))
                    Spacer()
                }.padding(.leading, 14)
                WithPerceptionTracking {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 18),GridItem(.flexible(), spacing: 8),GridItem(.flexible(), spacing: 18)], spacing: 16, content: {
                        ForEach(ArchiveItem.allCases, id: \.self) { item in
                            Image(item.icon)
                        }
                    })
                }.padding(.all, 12)
            }.padding(.all, 12).background(.white).cornerRadius(20).padding(.all, 20)
        }
    }
}

#Preview {
    RewardView(store: Store.init(initialState: Reward.State(), reducer: {
        Reward()
    }))
}
