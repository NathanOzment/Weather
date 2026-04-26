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
                                subtitle: "\(store.savedCities.count) saved forecasts ready to reopen",
                                symbol: "star.circle.fill"
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
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                        }
                        .padding(20)
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
