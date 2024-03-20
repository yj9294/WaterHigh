//
//  WaterHighApp.swift
//  WaterHigh
//
//  Created by Super on 2024/2/26.
//

import SwiftUI
import GADUtil
import FacebookCore
import ComposableArchitecture

@main
struct WaterHighApp: App {
    
    @UIApplicationDelegateAdaptor(Appdelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootView(store: Store.init(initialState: Root.State(), reducer: {
                Root()
            }))
        }
    }
    
    class Appdelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            NotificationHelper.shared.register { ret in
                if ret {
                    CacheUtil.getReminders().forEach({NotificationHelper.shared.appendReminder($0.title)})
                }
            }
            ApplicationDelegate.shared.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
            GADUtil.share.requestConfig()
            return true
        }
        
        func application(
                _ app: UIApplication,
                open url: URL,
                options: [UIApplication.OpenURLOptionsKey : Any] = [:]
            ) -> Bool {
                ApplicationDelegate.shared.application(
                    app,
                    open: url,
                    sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                    annotation: options[UIApplication.OpenURLOptionsKey.annotation]
                )
            }
    }
    
    
}
