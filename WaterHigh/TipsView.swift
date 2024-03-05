//
//  TipsView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/28.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct Tips {
    @ObservableState
    struct State: Equatable {
        var item: TipItem = .tip1
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

struct TipsView: View {
    let store: StoreOf<Tips>
    var body: some View {
        VStack{
            NavigationBar(title: "Details") {
                store.send(.dismiss)
            }
            ScrollView{
                WithPerceptionTracking {
                    VStack(alignment: .leading) {
                        Text(store.item.title).font(.system(size: 24, weight: .medium))
                        Divider()
                        Text(store.item.description).font(.system(size: 16, weight: .regular))
                    }
                }
            }.padding(.all, 20)
            
        }
    }
}
