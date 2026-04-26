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
    }
}
