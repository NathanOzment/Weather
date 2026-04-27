import SwiftUI

enum AppTab: Hashable {
    case today
    case map
    case saved
    case settings
}

struct AppTabView: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            HomeView(store: store)
                .tag(AppTab.today)
                .tabItem {
                    Label("Today", systemImage: "cloud.sun.fill")
                }

            WeatherMapView(store: store)
                .tag(AppTab.map)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            SavedLocationsView(store: store)
                .tag(AppTab.saved)
                .tabItem {
                    Label("Saved", systemImage: "star.fill")
                }

            SettingsView(store: store)
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
        .tint(Color(red: 0.99, green: 0.84, blue: 0.42))
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 0.62)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)

        let selectedColor = UIColor(red: 0.99, green: 0.84, blue: 0.42, alpha: 1.0)
        let normalColor = UIColor.white.withAlphaComponent(0.82)

        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
