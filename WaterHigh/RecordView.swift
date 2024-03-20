//
//  RecordView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import GADUtil
import Combine

enum RecordItem: String, Codable, CaseIterable {
    case water, drinks, milk, coffee, tea, custom
    var title: String {
        self.rawValue.capitalized
    }
    var icon: String {
        "record_\(self.rawValue)"
    }
}

@Reducer
struct Record {
    @ObservableState
    struct State: Equatable {
        var drinks: [DrinkModel] = CacheUtil.getDrinks()
        var goal: Int = CacheUtil.getGoal()
        var item: RecordItem = .water
        var ml: String = "200"
        var name: String = "Water"
        mutating func updateItem(_ item: RecordItem) {
            self.item = item
            name = item.title
            ml = "200"
        }
        mutating func updateDrinks() {
            guard let ml = Int(ml), ml > 0 else {
                return
            }
            let drinkModel = DrinkModel(date: Date(), item: item, name: name, ml: ml, goal: goal)
            drinks.append(drinkModel)
            CacheUtil.setDrinks(drinks)
        }
    }
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case dismiss
        case updateItem(RecordItem)
        case saveButtonTapped
        case showInterAD
    }
    
    @Dependency(\.dismiss) var dismiss
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            if case .dismiss = action {
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
                return .run { _ in
                    await dismiss()
                }
            }
            if case let .updateItem(item) = action {
                state.updateItem(item)
            }
            if case .saveButtonTapped = action {
                state.updateDrinks()
                return .run { send in
                    await send(.showInterAD)
                }
            }
            if case .showInterAD = action {
                let publisher = Future<Action, Never> { promise in
                    GADUtil.share.load(.interstitial)
                    GADUtil.share.show(.interstitial) { _ in
                        promise(.success(.dismiss))
                    }
                }
                return .publisher {
                    publisher
                }
            }
            return .none
        }
    }
}

struct RecordView: View {
    let store: StoreOf<Record>
    var body: some View {
        VStack{
            NavigationBar(title: "Record") {
                store.send(.dismiss)
            }
            InputView(store: store).padding(.top, 30)
            ItemsView(store: store)
            Button(action: {
                store.send(.saveButtonTapped)
            }, label: {
                Image("record_button_bg")
            })
            Spacer()
        }
    }
    
    struct InputView: View {
        @ComposableArchitecture.Bindable var store: StoreOf<Record>
        var body: some View {
            ZStack(alignment: .leading){
                VStack(alignment: .leading, spacing: 8){
                    WithPerceptionTracking {
                        HStack{
                            if store.item == .custom {
                                TextField("", text: $store.name).font(.system(size: 16,weight: .medium))
                            } else {
                                Text(store.item.title).font(.system(size: 16,weight: .medium))
                            }
                            Spacer()
                        }
                    }
                    WithPerceptionTracking {
                        HStack{
                            TextField("", text: $store.ml).keyboardType(.numbersAndPunctuation)
                            Text("ml").padding(.trailing, 20)
                        }
                    }.font(.system(size: 24, weight: .bold)).foregroundStyle(Color(uiColor: UIColor.init(hex: 0x007CFD)))
                }.padding(.leading, 50).padding(.vertical, 12).background(Image("record_bg").resizable()).padding(.trailing, 50).padding(.leading, 102)
                WithPerceptionTracking {
                    Image(store.item.icon).resizable().frame(width: 100, height: 100).padding(.leading, 52)
                }
            }
        }
    }
    
    struct ItemsView: View {
        let store: StoreOf<Record>
        var body: some View {
            ScrollView{
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12, content: {
                    ForEach(RecordItem.allCases, id: \.self) { item in
                        Button(action: {
                            store.send(.updateItem(item))
                        }, label: {
                            HStack{
                                Spacer()
                                VStack{
                                    Text(item.title).font(.system(size: 16, weight: .medium))
                                    Image(item.icon)
                                    Text("200 ml").font(.system(size: 16))
                                }
                                Spacer()
                            }
                        }).padding(.vertical, 12).background(Image("record_button").resizable()).foregroundColor(.black)
                    }
                }).padding(.all, 20)
            }
        }
    }
}

struct NavigationBar: View {
    let title: String
    let action: ()->Void
    var body: some View {
        ZStack{
            HStack{
                Button(action: action, label: {
                    Image("back")
                }).padding(.leading, 16)
                Spacer()
            }
            Text(title).padding(.vertical, 10)
        }
    }
}


#Preview {
    RecordView(store: Store.init(initialState: Record.State(), reducer: {
        Record()
    }))
}
