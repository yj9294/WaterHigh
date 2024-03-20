//
//  DrinkView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import SwiftUI
import GADUtil
import Combine
import ComposableArchitecture
import AppTrackingTransparency

@Reducer
struct Drink {
    @ObservableState
    struct State: Equatable {
        var ad: GADNativeViewModel = .none
        var goal: Int = CacheUtil.getGoal()
        var drinks: [DrinkModel] = CacheUtil.getDrinks()
        @Presents var recordState: Record.State?
        @Presents var goalState: Goal.State?
        var today: Int {
            drinks.filter({$0.date.isToday}).compactMap({$0.ml}).reduce(0, +)
        }
        var progress: Double {
           Double(today) / Double(goal)
        }
        mutating func presentRecordView() {
            recordState = .init()
        }
        mutating func refreshDrinks() {
            drinks = CacheUtil.getDrinks()
        }
        
        mutating func refreshGoal() {
            goal = CacheUtil.getGoal()
        }
        mutating func presentGoalView() {
            goalState = .init()
        }
    }
    enum Action: Equatable {
        case recordAction(PresentationAction<Record.Action>)
        case goalAction(PresentationAction<Goal.Action>)
        case presentRecordView
        case presentGoalView
        
        case updateDrinks
        case updateGoal
        
        case showInterAD
    }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .presentRecordView = action {
                state.presentRecordView()
            }
            if case .recordAction(.presented(.saveButtonTapped)) = action {
                state.refreshDrinks()
                return .run { send in
                    await send(.updateDrinks)
                }
            }
            if case .presentGoalView = action {
                state.presentGoalView()
            }
            if case .goalAction(.presented(.saveButtonTapped)) = action {
                state.refreshGoal()
                return .run { send in
                    await send(.updateGoal)
                }
            }
            if case .showInterAD = action {
                let publisher = Future<Action, Never> { promise in
                    GADUtil.share.load(.interstitial)
                    GADUtil.share.show(.interstitial) { _ in
                        promise(.success(.presentGoalView))
                    }
                }
                return .publisher {
                    publisher
                }
            }
            return .none
        }.ifLet(\.$recordState, action: \.recordAction) {
            Record()
        }.ifLet(\.$goalState, action: \.goalAction) {
            Goal()
        }
    }
}

struct DrinkView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<Drink>
    var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading){
                VStack(alignment: .leading){
                    Image("drink_title").padding(.leading,20).padding(.top, 40)
                    Text("Drinking water on time is a good habit").padding(.leading, 20)
                    HStack{
                        Image("drink_icon")
                        VStack(alignment: .leading, spacing: 20){
                            HStack(alignment: .bottom, spacing:0){
                                WithPerceptionTracking {
                                    Text("\(Int(store.progress * 100))").font(.system(size: 44, weight: .bold)).foregroundStyle(Color(uiColor: UIColor(hex: 0x007CFD)))

                                }
                                Text("%").padding(.bottom, 10)
                            }.padding(.horizontal, 16).padding(.vertical, 2).background(Image("drink_button_1").resizable())
                            Button(action: {
                                store.send(.showInterAD)
                            }, label: {
                                HStack{
                                    WithPerceptionTracking {
                                        Text("Daily Goal \(store.goal)ml")
                                    }
                                    Image("drink_edit")
                                }
                            }).padding(.vertical, 20).padding(.horizontal, 16).background(Image("drink_button_2").resizable())
                            Button(action: {
                                store.send(.presentRecordView)
                            }, label: {
                                HStack{
                                    Text("Add to")
                                    Image("drink_add")
                                }
                            }).padding(.vertical, 20).padding(.horizontal, 16).background(Image("drink_button_3").resizable())
                        }.foregroundColor(.black)
                        Spacer()
                    }.padding(.bottom, 40).padding(.leading, 20).padding(.top, 20)
                }.background(Color(uiColor: UIColor(hex: 0xE6FAFF)))
                Spacer()
                HStack{
                    WithPerceptionTracking {
                        GADNativeView(model: store.ad)
                    }
                }.padding(.horizontal, 20).frame(height: 116)
            }.onAppear(perform: {
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
            }).fullScreenCover(item: $store.scope(state: \.recordState, action: \.recordAction)) { store in
                RecordView(store: store)
            }.fullScreenCover(item: $store.scope(state: \.goalState, action: \.goalAction)) { store in
                GoalView(store: store)
            }.onAppear{
                Task { @MainActor in
                    try await Task.sleep(nanoseconds: 4_000_000_000)
                    ATTrackingManager.requestTrackingAuthorization { _ in
                    }
                }
            }
        }
    }
}

#Preview {
    DrinkView(store: Store.init(initialState: Drink.State(), reducer: {
        Drink()
    }))
}
