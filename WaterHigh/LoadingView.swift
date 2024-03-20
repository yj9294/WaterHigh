//
//  LoadingView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import GADUtil
import Combine

@Reducer
struct Loading {
    @ObservableState
    struct State: Equatable {
        var progress = 0.5
        var duration = 12.4
    }
    enum Action: Equatable {
        case launched
        case startLoading
        case updateProgress
        case stopLoading
        case showLoadingAD
        case none
    }
    
    @Dependency(\.continuousClock) var clock
    enum CancelID{ case timer }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .startLoading = action {
                state.progress = 0.0
                state.duration = 12.4
                GADUtil.share.load(.open)
                GADUtil.share.load(.interstitial)
                GADUtil.share.load(.native)
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(20)) {
                        await send(.updateProgress)
                    }
                }.cancellable(id: CancelID.timer)
            }
            if case .updateProgress = action {
                state.progress += (0.02 / state.duration)
                if state.progress > 1.0 {
                    state.progress = 1.0
                    let stop = Future<Action, Never> { promise in
                        promise(.success(.stopLoading))
                    }
                    let publisher = Future<Action, Never> { promise in
                        GADUtil.share.show(.open) { _ in
                            promise(.success(.launched))
                        }
                    }
                    return .publisher {
                        publisher.merge(with: stop)
                    }
                }

                if state.progress > 0.3, GADUtil.share.isLoaded(.open) {
                    state.progress = 1.0
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
