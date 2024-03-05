//
//  Util.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension Date {
    
    // str
    func formatter(_ str: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = str
        return formatter.string(from: self)
    }
    
    // yyyy-MM-dd
    var date: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    // HH:mm
    var time: String { // HH:mm
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        return self.date == Date().date
    }
    
    // hour
    var hour: Int {
        if let hour = self.time.components(separatedBy: ":").first {
            return Int(hour) ?? 0
        }
        return 0
    }
    
    // minute
    var minute: Int {
        if let hour = self.time.components(separatedBy: ":").last {
            return Int(hour) ?? 0
        }
        return 0
    }
    
    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }
    
}

import UIKit

extension String {
    /// 根据宽度和字体，计算文字的高度
    func textAutoHeight(width: CGFloat, font: UIFont) -> CGFloat {
        let string = self as NSString
        let origin = NSStringDrawingOptions.usesLineFragmentOrigin
        let lead = NSStringDrawingOptions.usesFontLeading
        let ssss = NSStringDrawingOptions.usesDeviceMetrics

        let rect = string.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                       options: [origin, lead, ssss],
                                       attributes: [NSAttributedString.Key.font: font],
                                       context: nil)

        return rect.height
    }

    /// 根据高度和字体，计算文字的宽度
    func textAutoWidth(height: CGFloat, font: UIFont) -> CGFloat {
        let string = self as NSString
        let origin = NSStringDrawingOptions.usesLineFragmentOrigin
        let lead = NSStringDrawingOptions.usesFontLeading

        let rect = string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height),
                                       options: [origin, lead],
                                       attributes: [NSAttributedString.Key.font: font],
                                       context: nil)

        return rect.width
    }
}


@propertyWrapper
struct FileHelper<T: Codable> where T: Equatable {
    var value: T
    var defaultValue: T
    let key: String
    init(_ key: Key, default: T) {
        self.key = key.rawValue
        self.defaultValue = `default`
        self.value = UserDefaults.standard.getObject(T.self, forKey: self.key) ?? self.defaultValue
    }
    
    var wrappedValue: T {
        set  {
            value = newValue
            UserDefaults.standard.setObject(value, forKey: key)
            UserDefaults.standard.synchronize()
        }
        
        get { value }
    }
    
    enum Key: String {
        case drinks, goal, reminders, week
    }
}

extension FileHelper: Equatable {
    static func == (lhs: FileHelper<T>, rhs: FileHelper<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension UserDefaults {
    func setObject<T: Codable>(_ object: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard let object = object else {
            debugPrint("[US] object is nil.")
            self.removeObject(forKey: key)
            return
        }
        guard let encoded = try? encoder.encode(object) else {
            debugPrint("[US] encoding error.")
            return
        }
        self.setValue(encoded, forKey: key)
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else {
            debugPrint("[US] data is nil for \(key).")
            return nil
        }
        guard let object = try? JSONDecoder().decode(type, from: data) else {
            debugPrint("[US] decoding error.")
            return nil
        }
        return object
    }
}
