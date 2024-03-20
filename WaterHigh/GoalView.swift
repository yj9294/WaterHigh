//
//  GoalView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import SwiftUI
import GADUtil
import ComposableArchitecture

@Reducer
struct Goal {
    @ObservableState
    struct State: Equatable {
        var goal: Int = CacheUtil.getGoal()
        mutating func updateGoal() {
            CacheUtil.setGoal(goal)
        }
        mutating func jia() {
            goal += 100
            if goal > 4000 {
                goal = 4000
            }
        }
        mutating func jian() {
            goal -= 100
            if goal <= 100 {
                goal = 100
            }
        }
    }
    enum Action: Equatable {
        case dismiss
        case saveButtonTapped
        case jianButtonTapped
        case jiaButtonTapped
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .dismiss = action {
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
                return .run { _ in
                    await dismiss()
                }
            }
            if case .saveButtonTapped = action {
                state.updateGoal()
                return .run { _ in
                    await dismiss()
                }
            }
            if case .jianButtonTapped = action {
                state.jian()
            }
            if case .jiaButtonTapped = action {
                state.jia()
            }
            return .none
        }
    }
}

struct GoalView: View {
    let store: StoreOf<Goal>
    var body: some View {
        VStack{
            NavigationBar(title: "Record") {
                store.send(.dismiss)
            }
            HStack{
                Image("goal_icon")
                Spacer()
                VStack{
                    Button(action: {
                        store.send(.jiaButtonTapped)
                    }, label: {
                        Image("goal_jia")
                    })
                    VStack{
                        WithPerceptionTracking {
                            Text("\(store.goal)").font(.system(size: 44, weight: .bold)).foregroundStyle(Color(uiColor: UIColor(hex: 0x007CFD)))
                        }
                        Text("ml").font(.system(size: 20))
                    }
                    Button(action: {
                        store.send(.jianButtonTapped)
                    }, label: {
                        Image("goal_jian")
                    })
                }
            }.padding(.horizontal, 60).padding(.top, 80)
            Spacer()
            Button {
                store.send(.saveButtonTapped)
            } label: {
                Image("record_button_bg")
            }.padding(.bottom, 40)
        }
    }
}

#Preview {
    GoalView(store: Store.init(initialState: Goal.State(), reducer: {
        Goal()
    }))
}
