import SwiftUI

@main
struct WeatherNowApp: App {
    @StateObject private var store = WeatherStore()

    var body: some Scene {
        WindowGroup {
            if store.hasCompletedOnboarding {
                AppTabView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
    }
}
