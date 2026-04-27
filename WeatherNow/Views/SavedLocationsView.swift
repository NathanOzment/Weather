import SwiftUI

struct SavedLocationsView: View {
    @ObservedObject var store: WeatherStore
    @State private var detailSnapshot: WeatherSnapshot?
    @State private var openingCityName: String?

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
                    .padding(24)
                    .weatherGlassCard(cornerRadius: 30)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if store.isRefreshingSavedCities {
                                loadingBanner("Updating saved forecasts...")
                            }

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
                                            openingCityName = city
                                            await store.loadSavedCity(city)
                                            detailSnapshot = store.snapshot
                                            openingCityName = nil
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(city)
                                                    .font(.headline.weight(.semibold))
                                                HStack(spacing: 8) {
                                                    Text(store.cachedUpdatedText(for: city) ?? "Open detailed forecast")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.72))

                                                    if store.cachedSnapshot(for: city) != nil {
                                                        Text("Cached")
                                                            .font(.caption.weight(.semibold))
                                                            .foregroundStyle(.white.opacity(0.9))
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 6)
                                                            .weatherGlassLens(cornerRadius: 16, tint: WeatherGlassPalette.cool.opacity(0.12))
                                                    }
                                                }
                                                if let cachedSnapshot = store.cachedSnapshot(for: city), cachedSnapshot.isStale {
                                                    Text("Saved forecast may be getting stale")
                                                        .font(.caption.weight(.medium))
                                                        .foregroundStyle(Color(red: 0.99, green: 0.84, blue: 0.42))
                                                }
                                            }

                                            Spacer()

                                            if openingCityName == city {
                                                ProgressView()
                                                    .tint(.white)
                                            } else {
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.white.opacity(0.58))
                                            }
                                        }
                                        .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(openingCityName != nil)

                                    Button {
                                        store.removeSavedCity(city)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.white.opacity(0.85))
                                            .frame(width: 34, height: 34)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(openingCityName != nil || store.isRefreshingSavedCities)
                                    .padding(8)
                                    .weatherGlassLens(cornerRadius: 18, tint: Color.white.opacity(0.08))
                                }
                                .padding(18)
                                .weatherGlassCard(cornerRadius: 26, tint: WeatherGlassPalette.slate.opacity(0.14))
                            }
                        }
                        .padding(20)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 20)
                    }
                }
            }
            .navigationTitle("Saved Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

    private func loadingBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(14)
        .weatherGlassCard(cornerRadius: 18)
    }
}

private struct IdentifiedSnapshot: Identifiable {
    let id = UUID()
    let snapshot: WeatherSnapshot
}
