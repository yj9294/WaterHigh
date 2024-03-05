//
//  LoadingView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct Loading {
    @ObservableState
    struct State: Equatable {
        var progress = 0.5
        var duration = 2.4
    }
    enum Action: Equatable {
        case launched
        case startLoading
        case updateProgress
        case stopLoading
    }
    
    @Dependency(\.continuousClock) var clock
    enum CancelID{ case timer }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .startLoading = action {
                state.progress = 0.0
                state.duration = 2.4
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(20)) {
                        await send(.updateProgress)
                    }
                }.cancellable(id: CancelID.timer)
            }
            if case .updateProgress = action {
                state.progress += (0.02 / state.duration)
                if state.progress >= 1.0 {
                    state.progress = 1.0
                    return .run { send in
                        await send(.stopLoading)
                        await send(.launched)
                    }
                }
            }
            if case .stopLoading = action {
                return .cancel(id: CancelID.timer)
            }
            return .none
        }
    }
}

struct LoadingView: View {
    let store: StoreOf<Loading>
    var body: some View {
        VStack{
            Image("loading_title").padding(.top, 100)
            Spacer()
            Image("loading_icon")
            WithPerceptionTracking {
                ProgressView(value: store.progress).tint(Color(uiColor: UIColor(hex: 0x007CFD))).background(Color(uiColor: UIColor(hex: 0xE6FAFF)))
            }.padding(.all, 40).onAppear(perform: {
                store.send(.startLoading)
            })
        }
    }
}

#Preview {
    LoadingView(store: Store.init(initialState: Loading.State(), reducer: {
        Loading()
    }))
}
