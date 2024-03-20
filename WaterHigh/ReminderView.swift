//
//  ReminderView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/28.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct Reminder {
    @ObservableState
    struct State: Equatable {
        var ad: GADNativeViewModel = .none
        var showAddView = false
        var reminders: [ReminderModel] = CacheUtil.getReminders()
        var week: Bool = CacheUtil.getWeekMode()
        mutating func updateWeek(_ week: Bool) {
            self.week = week
            CacheUtil.setWeekMode(week)
            reminders.forEach({NotificationHelper.shared.appendReminder($0.title)})
        }
        mutating func deleteReminder(_ reminder: ReminderModel) {
            self.reminders = self.reminders.filter({$0 != reminder})
            CacheUtil.setReminders(self.reminders)
            NotificationHelper.shared.deleteNotifications(reminder.title)
        }
        mutating func addReminder(_ reminder: ReminderModel) {
            if self.reminders.contains(reminder) {
                return
            }
            self.reminders.append(reminder)
            self.reminders = self.reminders.sorted(by: { l1, l2 in
                l1.title < l2.title
            })
            CacheUtil.setReminders(self.reminders)
            NotificationHelper.shared.appendReminder(reminder.title)
        }
    }
    enum Action: Equatable {
        case dismiss
        case updateWeek(Bool)
        case deleteReminder(ReminderModel)
        case updateShowAddView(Bool)
        case addReminder(ReminderModel)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .dismiss = action {
                return .run { send in
                    await dismiss()
                }
            }
            if case let .updateWeek(week) = action {
                state.updateWeek(!week)
            }
            if case let .deleteReminder(reminder) = action {
                state.deleteReminder(reminder)
            }
            if case let .updateShowAddView(isShow) = action {
                state.showAddView = isShow
            }
            if case let .addReminder(reminder) = action {
                state.addReminder(reminder)
            }
            return .none
        }
    }
}

struct ReminderView: View {
    let store: StoreOf<Reminder>
    var body: some View {
        ZStack{
            VStack{
                NavigationBar(title: "Reminder Time") {
                    store.send(.dismiss)
                }
                ScrollView{
                    WithPerceptionTracking {
                        _WeekView(isWeek: store.week){
                            store.send(.updateWeek(store.week))
                        }
                    }
                    WithPerceptionTracking {
                        _ReminderView(datasource: store.reminders) { item in
                            store.send(.deleteReminder(item))
                        } addAction: {
                            store.send(.updateShowAddView(true))
                        }
                    }
                }
                Spacer()
                HStack{
                    WithPerceptionTracking {
                        GADNativeView(model: store.ad)
                    }
                }.padding(.horizontal, 20).frame(height: 116)
            }
            WithPerceptionTracking {
                if store.showAddView {
                    _PickerView{
                        store.send(.updateShowAddView(false))
                    } add: { hour, min in
                        store.send(.updateShowAddView(false))
                        store.send(.addReminder(ReminderModel(hour: hour, minute: min)))
                    }
                }
            }
        }
        .background(Color(uiColor: UIColor.init(hex: 0xE6FAFF)))
    }
    
    struct _WeekView: View {
        let isWeek: Bool
        let action: ()->Void
        var body: some View {
            VStack(alignment: .leading, spacing: 14){
                HStack{
                    Text("Week Model").font(.system(size: 16, weight: .medium)).foregroundStyle(Color(uiColor: UIColor.init(hex: 0x030002)))
                    Spacer()
                    Button(action: action) {
                        Image(isWeek ? "reminder_on" : "reminder_off")
                    }
                }
                Text("IAfter opening, you won't receive any messages on weekends").font(.system(size: 14)).foregroundStyle(Color.black.opacity(0.6))
            }.padding(.all, 20)
        }
    }
    
    struct _ReminderView: View {
        let datasource: [ReminderModel]
        let deleteAction: (ReminderModel)->Void
        let addAction: ()->Void
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                VStack(spacing: 0){
                    ForEach(datasource, id: \.self) { item in
                        HStack{
                            Text(item.title)
                            Spacer()
                            Button(action: {
                                deleteAction(item)
                            }, label: {
                                Image("reminder_delete")
                            })
                        }.padding(.all, 20).background(Color.init(uiColor: UIColor.init(hex: 0xE6FAFF))).padding(.horizontal, 20).padding(.vertical, 8)
                    }
                    Button(action: {
                        addAction()
                    }, label: {
                        Image("reminder_add")
                    }).padding(.vertical, 40)
                }
            }.background(.white).cornerRadius(20)
        }
    }
    
    struct _PickerView: View {
        @State private var hour: String = "00"
        @State private var min: String = "00"

        let hours = Array(0..<24)
        let mins = Array(0...59)
        let dismiss: ()->Void
        let add: (Int, Int)->Void
        var body: some View {
            ZStack{
                Button(action: {
                    dismiss()
                }, label: {
                    Color.black.opacity(0.6).ignoresSafeArea()
                })
                VStack{
                    Spacer()
                    VStack{
                        ZStack{
                            HStack{
                                Spacer()
                                Text("Reminder time")
                                Spacer()
                            }
                            HStack{
                                Spacer()
                                Button {
                                    dismiss()
                                } label: {
                                    Image("reminder_close")
                                    
                                }
                            }.padding(.trailing, 16)
                        }
                        HStack{
                            VStack{
                                Picker("", selection: $hour) {
                                    ForEach(hours, id: \.self) { hour in
                                        let value = String(format: "%02d", hour)
                                        Text(value).frame(height: 50).tag(value)
                                    }
                                }
                            }.pickerStyle(.wheel).frame(height: 150)
                            VStack{
                                Picker("", selection: $min) {
                                    ForEach(mins, id: \.self) { hour in
                                        let value = String(format: "%02d", hour)
                                        Text(value).frame(height: 50).tag(value)
                                    }
                                }
                            }.pickerStyle(.wheel).frame(height: 150)
                        }.frame(height: 150)
                        Button(action: {
                            add(Int(hour) ?? 0, Int(min) ?? 0)
                        }, label: {
                            Image("reminder_add")
                        }).padding(.vertical, 40)
                    }.padding(.vertical, 20).background(.white).cornerRadius(20)
                }
            }
        }
    }
}

#Preview {
    ReminderView(store: Store.init(initialState: Reminder.State(), reducer: {
        Reminder()
    }))
}
