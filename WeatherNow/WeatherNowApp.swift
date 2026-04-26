import SwiftUI

@main
struct WeatherNowApp: App {
    @StateObject private var store = WeatherStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootAppView(store: store)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await store.processPendingIntentActionIfNeeded()
            }
        }
    }
}

private struct RootAppView: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                AppTabView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
        .task {
            await store.processPendingIntentActionIfNeeded()
        }
    }
}
