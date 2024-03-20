//
//  ChartsView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import SwiftUI
import GADUtil
import ComposableArchitecture

enum ChartsItem: String, CaseIterable{
    case day, week, month, year
    var title: String {
        self.rawValue.capitalized
    }
}

@Reducer
struct Charts {
    @ObservableState
    struct State: Equatable {
        var ad: GADNativeViewModel = .none
        var drinks: [DrinkModel] = CacheUtil.getDrinks()
        var item: ChartsItem = .day
        @Presents var historyState: History.State?
        var leftUnit: [Int] = Array(0..<6)
        var leftDatasource: [String] {
            switch item {
            case .day:
                 return leftUnit.map({
                    "\($0 * 200)"
                 }).reversed()
            case .week, .month:
                return leftUnit.map({
                   "\($0 * 500)"
                }).reversed()
            case .year:
                return leftUnit.map({
                   "\($0 * 500 * 30)"
                }).reversed()
            }
        }
        
        var datasource: [ChartsModel] {
            var max = 1
            // 数据源
            // 用于计算进度
            max = leftDatasource.map({Int($0) ?? 0}).max { l1, l2 in
                l1 < l2
            } ?? 1
            switch item {
            case .day:
                return unitDatasource.map({ time in
                    let total = drinks.filter { model in
                        if model.date.isToday {
                            let hour = Int(time.components(separatedBy: ":").first ?? "") ?? 0
                            if model.date.hour >= hour - 6, model.date.hour <= hour {
                                return true
                            }
                            return false
                        }
                        return false
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return ChartsModel(progress: Double(total)  / Double(max) , ml: total, unit: time)
                })
            case .week:
                return unitDatasource.map { weeks in
                    // 当前搜索目的周几 需要从周日开始作为下标0开始的 所以 unit数组必须是7123456
                    let week = unitDatasource.firstIndex(of: weeks) ?? 0
                    
                    // 当前日期 用于确定当前周
                    let weekDay = Calendar.current.component(.weekday, from: Date())
                    let firstCalendar = Calendar.current.date(byAdding: .day, value: 1-weekDay, to: Date()) ?? Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    // 目标日期
                    let target = Calendar.current.date(byAdding: .day, value: week, to: firstCalendar) ?? Date()
                    let targetString = dateFormatter.string(from: target)
                    
                    let total = drinks.filter { model in
                        model.date.date == targetString
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return ChartsModel(progress: Double(total)  / Double(max), ml: total, unit: weeks)
                }
            case .month:
                return unitDatasource.reversed().map { date in
                    let year = Calendar.current.component(.year, from: Date())
                    
                    let month = date.components(separatedBy: "/").first ?? "01"
                    let day = date.components(separatedBy: "/").last ?? "01"
                    
                    let total = drinks.filter { model in
                        return model.date.date == "\(year)-\(month)-\(day)"
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    
                    return ChartsModel(progress: Double(total)  / Double(max), ml: total, unit: date)
                    
                }
            case .year:
                return  unitDatasource.reversed().map { month in
                    let total = drinks.filter { model in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let date = formatter.date(from: model.date.date)
                        formatter.dateFormat = "MMM"
                        let m = formatter.string(from: date!)
                        return m == month
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return ChartsModel(progress: Double(total)  / Double(max), ml: total, unit: month)
                }
            }
        }
        
        var unitDatasource: [String] {
            switch item {
            case .day:
                return["06:00", "12:00", "18:00", "24:00"]
            case .week:
                return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            case .month:
                var days: [String] = []
                for index in 0..<30 {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd"
                    let date = Date(timeIntervalSinceNow: TimeInterval(index * 24 * 60 * 60 * -1))
                    let day = formatter.string(from: date)
                    days.insert(day, at: 0)
                }
                return days
            case .year:
                var months: [String] = []
                for index in 0..<12 {
                    let d = Calendar.current.date(byAdding: .month, value: -index, to: Date()) ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM"
                    let day = formatter.string(from: d)
                    months.insert(day, at: 0)
                }
                return months
            }
        }
        mutating func presentHistoryView() {
            historyState = .init()
        }
        mutating func updateItem(_ item: ChartsItem) {
            self.item = item
        }
    }
    enum Action: Equatable {
        case historyButtonTapped
        case historyAction(PresentationAction<History.Action>)
        case updateItem(ChartsItem)
    }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .historyButtonTapped = action {
                state.presentHistoryView()
            }
            if case let .updateItem(item) = action {
                state.updateItem(item)
            }
            return .none
        }.ifLet(\.$historyState, action: \.historyAction) {
            History()
        }
    }
}

struct ChartsView: View {
    @ComposableArchitecture.Bindable var  store: StoreOf<Charts>
    var body: some View {
        WithPerceptionTracking {
            VStack{
                WithPerceptionTracking {
                    _NavigationBar(store: store)
                    _ChartsItemView(store: store)
                }
                HStack(spacing: 0){
                    WithPerceptionTracking {
                        _ChartLeftView(store: store)
                        _ChartRightView(store: store)
                    }
                    Spacer()
                }.padding(.all, 20)
                Spacer()
                HStack{
                    WithPerceptionTracking {
                        GADNativeView(model: store.ad)
                    }
                }.padding(.horizontal, 20).frame(height: 116)
            }.onAppear(perform: {
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
            }).fullScreenCover(item: $store.scope(state: \.historyState, action: \.historyAction)) { store in
                HistoryView(store: store)
            }
        }
    }
    
    struct _NavigationBar: View {
        @ComposableArchitecture.Bindable var  store: StoreOf<Charts>
        var body: some View {
            HStack{
                Image("charts_title")
                Spacer()
                Button(action: {
                    store.send(.historyButtonTapped)
                }, label: {
                    Image("charts_history")
                }).padding(.vertical, 10)
            }.padding(.horizontal, 16)
        }
    }
    
    struct _ChartsItemView: View {
        @ComposableArchitecture.Bindable var  store: StoreOf<Charts>
        var body: some View {
            HStack{
                HStack{
                    ForEach(ChartsItem.allCases, id: \.self) { item in
                        WithPerceptionTracking {
                            Button(action: {
                                store.send(.updateItem(item))
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(item.title)
                                    Spacer()
                                }
                            }).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 30).stroke(item == store.item ? Color.black : Color.clear).background(item == store.item ? Color(uiColor: UIColor.init(hex: 0x007CFD)) : Color.clear).cornerRadius(30)).foregroundStyle(item == store.item ? Color.white : Color.black)
                        }
                    }
                }.background(RoundedRectangle(cornerRadius: 30).stroke( Color.black, lineWidth: 1).background(Color(uiColor: UIColor.init(hex: 0xCDF4FE))).cornerRadius(30))
            }.padding(.all, 20)
        }
    }
    
    struct _ChartLeftView: View {
        let store: StoreOf<Charts>
        var body: some View {
            HStack(alignment: .top, spacing: 3){
                VStack(alignment: .trailing, spacing: 0){
                    WithPerceptionTracking {
                        ForEach(store.leftDatasource, id: \.self) { ml in
                            HStack{
                                Spacer()
                                Text(ml)
                            }.font(.system(size: 12)).frame(width: 40, height: 40).foregroundStyle(Color.black.opacity(0.6))
                        }
                    }
                }.frame(width: 40)
                WithPerceptionTracking {
                    Color.black.frame(width: 1).frame(height: 40 * CGFloat(store.leftUnit.count))
                }
            }.frame(height: 240)
        }
    }
    
    struct _ChartRightView: View {
        let store: StoreOf<Charts>
        var body: some View {
            VStack(spacing: 0) {
                ScrollView(.horizontal){
                    HStack{
                        LazyHGrid(rows: [GridItem(.flexible())], spacing: 24) {
                            WithPerceptionTracking {
                                ForEach(store.datasource, id: \.self) { model in
                                    VStack(spacing: 0){
                                        VStack(spacing: 0){
                                            let progress = model.progress > 1.0 ? 1.0 : model.progress
                                            let height = (1 - progress) * 200
                                            Color.clear.frame(height: height)
                                            Color(uiColor: UIColor.init(hex: 0x007CFD)).cornerRadius(15).opacity(0.45)
                                        }.background(
                                            RoundedRectangle(cornerRadius: 15).stroke(Color.black).background(
                                                Color(uiColor: UIColor(hex: 0xE6FAFF)).cornerRadius(15)
                                            )
                                        ).padding(.top, 20)
                                        Text(model.unit).font(.system(size: 10)).frame(height: 20)
                                    }.frame(width: 30)
                                }
                            }
                        }
                    }
                }.frame(height: 239).padding(.leading, 10)
                Color.black.frame(height: 1)
            }
        }
    }
}

#Preview {
    ChartsView(store: Store.init(initialState: Charts.State(), reducer: {
        Charts()
    }))
}
