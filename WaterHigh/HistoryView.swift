//
//  HistoryView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/27.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct History {
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

struct HistoryView: View {
    let store: StoreOf<History>
    var body: some View {
        VStack{
            NavigationBar(title: "History") {
                store.send(.dismiss)
            }
            ScrollView{
                LazyVGrid(columns: [GridItem(.flexible())], content: {
                    VStack(content: {
                        ForEach(store.drinks, id: \.self) { item in
                            HStack{
                                HStack{
                                    Image(item.item.icon)
                                    VStack(alignment: .leading){
                                        Text(item.item.title).font(.system(size: 14.0))
                                        Text("\(item.ml)ml").foregroundStyle(Color(uiColor: UIColor(hex: 0x007CFD))).font(.system(size: 16, weight: .medium))
                                    }
                                    Spacer()
                                    Text(item.date.date).font(.system(size: 12)).foregroundStyle(Color.black.opacity(0.45))
                                }.padding(.horizontal, 16).padding(.vertical, 8).background(Color(uiColor: UIColor(hex: 0xE6FAFF)))
                            }.padding(.vertical, 8)
                        }
                    })
                }).padding(.all, 20)
            }
            Spacer()
        }
    }
}

#Preview {
    HistoryView(store: Store.init(initialState: History.State(), reducer: {
        History()
    }))
}
