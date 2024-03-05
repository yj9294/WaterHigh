//
//  PrivacyView.swift
//  WaterHigh
//
//  Created by Super on 2024/2/28.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct Privacy {
    @ObservableState
    struct State: Equatable {}
    enum Action: Equatable {
        case dismiss
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .dismiss = action {
                return .run { _ in
                    await dismiss()
                }
            }
            return .none
        }
    }
}

struct PrivacyView: View {
    let store: StoreOf<Privacy>
    var body: some View {
        VStack{
            NavigationBar(title: "Privacy Policy") {
                store.send(.dismiss)
            }
            ScrollView{
                WithPerceptionTracking {
                    VStack(alignment: .leading) {
                        Text("""
We take your privacy very seriously. When you use the Water High Water App, we are committed to protecting your personal information and data. Please read the following privacy policy carefully to understand how we collect, use and protect your information:

Information Collection: When you use the Water High Water App, we may collect and store personal information you provide, including but not limited to name, email address, and drinking habits data. We may also collect anonymized usage data through technologies used by applications and browsers in order to improve our services and user experience.

Use of information: We will use your personal information for the following purposes: to provide and maintain the service of Water High Water App; To send you notifications about App features, updates, and promotions; To provide you with personalized drinking advice and health tips; And improving our products and services.

Information sharing: We do not sell, trade or transfer your personal information to any third party. We only share your information with partners and service providers when necessary to support our business operations and subject to confidentiality agreements with them.

Information Protection: We take various security measures to protect your personal information from unauthorized access, use or disclosure. The technology and security measures we use meet industry standards and are regularly updated and reviewed to keep your information safe.

Privacy Options: You may choose not to provide certain personal information, but this may affect your use of some features of the Water High Drinking App. You can also view, correct or delete your personal information at any time through the app Settings or by contacting us.

By using the Water High Water App, you consent to the collection, use and sharing of information as described in this Privacy Policy. If you have any questions or comments about our Privacy policy, please contact us at UHs11111577@outlook.com
""").font(.system(size: 16, weight: .regular))
                    }
                }
            }.padding(.all, 20)
            Spacer()
        }
    }
}
