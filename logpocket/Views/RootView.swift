//
//  RootView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct RootView: View {
    @State private var isOnboardingComplete: Bool = UserDefaultsManager.shared.loadSettings().hasCompletedOnboarding
    
    var body: some View {
        Group {
            if isOnboardingComplete {
                HomeView()
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
    }
}

#Preview {
    RootView()
}
