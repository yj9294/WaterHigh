//
//  CacheUtil.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation

struct CacheUtil {
    static func getDrinks() -> [DrinkModel] {
        UserDefaults.standard.getObject([DrinkModel].self, forKey: "drinks.model") ?? []
    }
    
    static func setDrinks(_ drinks: [DrinkModel]?) {
        UserDefaults.standard.setObject(drinks, forKey: "drinks.model")
        UserDefaults.standard.synchronize()
    }
    
    static func getGoal() -> Int {
        UserDefaults.standard.getObject(Int.self, forKey: "goal") ?? 2000
    }
    
    static func setGoal(_ goal: Int) {
        UserDefaults.standard.setObject(goal, forKey: "goal")
        UserDefaults.standard.synchronize()
    }
    
    static func getReminders() -> [ReminderModel] {
        let reminders = UserDefaults.standard.getObject([ReminderModel].self, forKey: "reminders") ?? ReminderModel.models
        return reminders
    }
    
    static func setReminders(_ reminders: [ReminderModel]) {
        UserDefaults.standard.setObject(reminders, forKey: "reminders")
        UserDefaults.standard.synchronize()
    }
    
    static func getWeekMode() -> Bool {
        UserDefaults.standard.getObject(Bool.self, forKey: "week.mode") ?? false
    }
    
    static func setWeekMode(_ weekMode: Bool) {
        UserDefaults.standard.setObject(weekMode, forKey: "week.mode")
        UserDefaults.standard.synchronize()
    }
    
    static func getImpressionDate(_ item: HomeItem) -> Date {
        UserDefaults.standard.getObject(Date.self, forKey: item.rawValue) ?? Date().addingTimeInterval(-11)
    }
    
    static func setImpressionDate(_ item: HomeItem, date: Date) {
        UserDefaults.standard.setObject(date, forKey: item.rawValue)
    }
}
