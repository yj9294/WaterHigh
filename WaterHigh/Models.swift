//
//  Models.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation

struct DrinkModel: Codable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var date: Date
    var item: RecordItem // 列别
    var name: String
    var ml: Int // 毫升
    var goal: Int
    
    var trueName: String {
        item == .custom ? name : item.title
    }
}


struct ChartsModel: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var progress: CGFloat
    var ml: Int
    var unit: String // 描述 类似 9:00 或者 Mon  或者03/01 或者 Jan
}


struct ReminderModel: Codable, Hashable, Equatable {
    var hour: Int
    var minute: Int
    var title: String {
        // 注意 hour 采用 24 进制
        return String(format: "%02d:%02d", hour, minute)
    }
    
    var timeSinceNowInSec: TimeInterval {
        let dateStr = Date().date + " " + title
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = formatter.date(from: dateStr)
        var d = date?.timeIntervalSinceNow ?? 0
        if d < 0 {
            // 在当前之前就往后推一天
            d += (24 * 3600)
        }
        return d
    }
    
    static let models: [ReminderModel] = Array(8...20).filter({$0 % 2 == 0}).map({ReminderModel(hour: $0, minute: 0)})
    
    static func parse(_ time: String ) -> ReminderModel {
        let hour: Int = Int(time.components(separatedBy: ":").first ?? "") ?? 0
        let minute: Int = Int(time.components(separatedBy: ":").last ?? "") ?? 0
        return ReminderModel(hour: hour, minute: minute)
    }
}

enum KeepItem: String, CaseIterable {
    case th_days, week, month, th_months, six_months, year
    var icon: String {
        let drinks = CacheUtil.getDrinks()
        return hasConsecutiveDates(drinks, number) ? enableIcon : disableIcon
    }
    
    var numbers: [Int] {
        [3, 7, 30, 100, 200, 300]
    }
    
    var number: Int {
        numbers[Self.allCases.firstIndex(of: self) ?? 0]
    }
    
    var enableIcon: String {
        return "keep_\(number)"
    }
    
    var disableIcon: String {
        return enableIcon + "_gray"
    }
    
    func hasConsecutiveDates(_ drinks: [DrinkModel], _ n: Int) -> Bool {
        
        let dateModels: [[DrinkModel]] =  drinks.reduce([[]]) { partialResult, model in
            var result = partialResult
            if var p = result.first {
                if let f = p.first, f.date.date == model.date.date  {
                    p.insert(model, at: 0)
                    result[0] = p
                    return result
                }
                result.insert([model], at: 0)
                return result
            }
            result = [[model]]
            return result
        }
        
        var dates = dateModels.compactMap{$0.first}.map { $0.date }
        
        dates.sort { l1, l2 in
            l1 < l2
        }
        
        guard n > 1, dates.count >= n else {
            // 如果 n 不大于 1 或者日期数组长度小于 n，则直接返回 false
            return false
        }

        for i in 0...(dates.count - n) {
            let startDate = dates[i]
            let endDate = dates[i + n - 1]

            // 计算当前日期范围内的日期数量
            let currentDates = dates.filter { $0 >= startDate && $0 <= endDate }

            if currentDates.count == n {
                // 找到了 n 个连续的日期
                return true
            }
        }

        // 未找到 n 个连续的日期
        return false
    }
}

enum ArchiveItem: String, CaseIterable {
    case one, ten, th, houndred, tw_houndred, th_houndred
    var icon: String {
        let drinks = CacheUtil.getDrinks()
        return hasKeepGoal(drinks, number) ? enableIcon : disableIcon
    }
    var numbers: [Int] {
        [1, 10, 30, 100, 200, 300]
    }
    
    var number: Int {
        numbers[Self.allCases.firstIndex(of: self) ?? 0]
    }
    
    var enableIcon: String {
        return "archive_\(number)"
    }
    
    var disableIcon: String {
        return enableIcon + "_gray"
    }
    
    func hasKeepGoal(_ models: [DrinkModel], _ n: Int) -> Bool {
        let dateModels: [[DrinkModel]] =  models.reduce([[]]) { partialResult, model in
            var result = partialResult
            if var p = result.first {
                if let f = p.first, f.date.date == model.date.date  {
                    p.insert(model, at: 0)
                    result[0] = p
                    return result
                }
                result.insert([model], at: 0)
                return result
            }
            result = [[model]]
            return result
        }
        
        let goals = dateModels.map { dateModels in
            let ml = dateModels.map({$0.ml}).reduce(0, +)
            let goal = dateModels.first?.goal ?? 2000
            return MedalGoalModel(ml: ml, goal: goal)
        }
        
        return goals.filter({$0.ml >= $0.goal}).count >= n
    }

}

struct MedalGoalModel {
    var ml: Int
    var goal: Int
}

