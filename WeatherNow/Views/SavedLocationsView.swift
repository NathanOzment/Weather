import SwiftUI

struct SavedLocationsView: View {
    @ObservedObject var store: WeatherStore
    @State private var detailSnapshot: WeatherSnapshot?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground(colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.21),
                    Color(red: 0.14, green: 0.23, blue: 0.39),
                    Color(red: 0.32, green: 0.47, blue: 0.62)
                ])

                if store.savedCities.isEmpty {
                    ContentUnavailableView(
                        "No saved cities yet",
                        systemImage: "star.slash",
                        description: Text("Save a city from the Today tab to build your forecast list.")
                    )
                    .foregroundStyle(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            BrandHeader(
                                eyebrow: "Watchlist",
                                title: "Your Cities",
                                subtitle: store.isRefreshingSavedCities ? "Refreshing your saved forecasts now" : "\(store.savedCities.count) saved forecasts ready to reopen",
                                symbol: "star.circle.fill"
                            )

                            Button {
                                Task {
                                    await store.refreshSavedCities()
                                }
                            } label: {
                                Label(store.isRefreshingSavedCities ? "Refreshing Saved Cities..." : "Refresh Saved Cities", systemImage: store.isRefreshingSavedCities ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.clockwise.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .weatherGlassButton(prominent: true)
                            .disabled(store.isRefreshingSavedCities)

                            CityComparisonSection(
                                snapshots: store.savedCities.compactMap { store.cachedSnapshot(for: $0) },
                                temperatureUnit: store.temperatureUnit
                            )

                            ForEach(store.savedCities, id: \.self) { city in
                                HStack(spacing: 14) {
                                    Button {
                                        detailSnapshot = store.cachedSnapshot(for: city)
                                        Task {
                                            await store.loadSavedCity(city)
                                            detailSnapshot = store.snapshot
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(city)
                                                    .font(.headline.weight(.semibold))
                                                Text(store.cachedUpdatedText(for: city) ?? "Open detailed forecast")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white.opacity(0.72))
                                                if let cachedSnapshot = store.cachedSnapshot(for: city), cachedSnapshot.isStale {
                                                    Text("Saved forecast may be getting stale")
                                                        .font(.caption.weight(.medium))
                                                        .foregroundStyle(Color(red: 0.99, green: 0.84, blue: 0.42))
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.white.opacity(0.58))
                                        }
                                        .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        store.removeSavedCity(city)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.white.opacity(0.85))
                                            .frame(width: 34, height: 34)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(18)
                                .weatherGlassCard(cornerRadius: 24, tint: Color.white.opacity(0.08))
                            }
                        }
                        .padding(20)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: Binding(
            get: { detailSnapshot.map(IdentifiedSnapshot.init) },
            set: { wrapped in detailSnapshot = wrapped?.snapshot }
        )) { wrapped in
            NavigationStack {
                WeatherDetailView(snapshot: wrapped.snapshot, temperatureUnit: store.temperatureUnit)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct IdentifiedSnapshot: Identifiable {
    let id = UUID()
    let snapshot: WeatherSnapshot
}
