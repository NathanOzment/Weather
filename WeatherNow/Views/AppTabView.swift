import SwiftUI
import UIKit

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case today
    case map
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .map: "Map"
        case .saved: "Saved"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today: "cloud.sun.fill"
        case .map: "map.fill"
        case .saved: "star.fill"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct AppTabView: View {
    @ObservedObject var store: WeatherStore

    init(store: WeatherStore) {
        self.store = store
        UITabBar.appearance().isHidden = true
    }

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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LiquidGlassTabBar(selectedTab: $store.selectedTab)
        }
    }
}

private struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.clear)
                                .frame(height: 42)
                                .weatherGlassChip(
                                    cornerRadius: 20,
                                    tint: tab == .today ? WeatherGlassPalette.warm.opacity(0.18) : WeatherGlassPalette.cool.opacity(0.16),
                                    interactive: true
                                )
                                .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                        }

                        VStack(spacing: selectedTab == tab ? 3 : 2) {
                            Image(systemName: tab.symbol)
                                .font(.caption.weight(.semibold))
                            if selectedTab == tab {
                                Text(tab.title)
                                    .font(.caption2.weight(.semibold))
                            }
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.78))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background {
            Color.clear
                .weatherGlassCard(cornerRadius: 28, tint: WeatherGlassPalette.cool.opacity(0.10))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}
