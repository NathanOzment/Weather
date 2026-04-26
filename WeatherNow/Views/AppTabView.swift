import SwiftUI

struct AppTabView: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        TabView {
            HomeView(store: store)
                .tabItem {
                    Label("Today", systemImage: "cloud.sun.fill")
                }

            SavedLocationsView(store: store)
                .tabItem {
                    Label("Saved", systemImage: "star.fill")
                }

            SettingsView(store: store)
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
        .tint(Color(red: 0.99, green: 0.84, blue: 0.42))
    }
}
