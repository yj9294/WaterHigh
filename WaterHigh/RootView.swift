//
//  ContentView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import SwiftUI
import ComposableArchitecture

enum RootItem {
    case loading, home
}

@Reducer
struct Root {
    @ObservableState
    struct State: Equatable {
        var state: RootItem = .loading
        var homeState: Home.State = .init()
        var loadingState: Loading.State = .init()
        
        mutating func updateState(_ state: RootItem) {
            self.state = state
        }
    }
    enum Action: Equatable {
        case updateState(RootItem)
        case homeAction(Home.Action)
        case loadingAction(Loading.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .updateState(item) = action {
                state.updateState(item)
            }
            if case .loadingAction(.launched) = action {
                state.updateState(.home)
            }
            return .none
        }
        
        Scope(state: \.homeState, action: \.homeAction) {
            Home()
        }
        
        Scope(state: \.loadingState, action: \.loadingAction) {
            Loading()
        }
    }
}

struct RootView: View {
    let store: StoreOf<Root>
    var body: some View {
        VStack {
            WithPerceptionTracking {
                store.state.state == .loading ? AnyView(LoadingView(store: store.scope(state: \.loadingState, action: \.loadingAction))) : AnyView(HomeView(store: store.scope(state: \.homeState, action: \.homeAction)))
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            store.send(.updateState(.loading))
            store.send(.loadingAction(.startLoading))
        })
    }
}

#Preview {
    RootView(store: Store.init(initialState: Root.State(), reducer: {
        Root()
    }))
}
