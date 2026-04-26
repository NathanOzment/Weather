import SwiftUI

struct HomeView: View {
    @ObservedObject var store: WeatherStore
    @State private var showingDetails = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground(colors: gradientColors(for: store.snapshot?.current.condition ?? .clear))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BrandHeader(
                            eyebrow: "Right Now",
                            title: store.lastResolvedLocation,
                            subtitle: store.snapshot?.freshnessText ?? "Search for a city or use your location",
                            symbol: store.snapshot?.current.condition.sfSymbol ?? "cloud.sun.fill"
                        )
                        if let statusMessage = store.statusMessage {
                            statusBanner(statusMessage)
                        }
                        searchBar
                        preferencesBar

                        if let snapshot = store.snapshot {
                            CurrentConditionsCard(
                                snapshot: snapshot,
                                temperatureUnit: store.temperatureUnit,
                                onSaveCity: { store.addCurrentCityToSaved() },
                                onShowDetails: { showingDetails = true }
                            )
                            WeatherAlertsSection(snapshot: snapshot)
                            SavedCitiesSection(
                                savedCities: store.savedCities,
                                activeCity: store.activeCityName,
                                onSelectCity: { city in
                                    Task {
                                        await store.loadSavedCity(city)
                                    }
                                },
                                onDeleteCity: { city in
                                    store.removeSavedCity(city)
                                }
                            )
                            AirQualitySection(airQuality: snapshot.airQuality)
                            WeatherInsightsSection(snapshot: snapshot, temperatureUnit: store.temperatureUnit)
                            ForecastPlannerSection(snapshot: snapshot, temperatureUnit: store.temperatureUnit)
                            HourlyForecastSection(hourly: snapshot.hourly, temperatureUnit: store.temperatureUnit)
                            DailyForecastSection(daily: snapshot.daily, temperatureUnit: store.temperatureUnit)
                        } else if store.isLoading {
                            ProgressView("Loading forecast...")
                                .frame(maxWidth: .infinity, minHeight: 260)
                                .tint(.white)
                                .foregroundStyle(.white)
                        } else {
                            ContentUnavailableView(
                                "Forecast unavailable",
                                systemImage: "cloud.slash",
                                description: Text("Pull to refresh or search for a city to try again.")
                            )
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await store.refresh()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EmptyView()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Button {
                            Task {
                                await store.refresh()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingDetails) {
            if let snapshot = store.snapshot {
                NavigationStack {
                    WeatherDetailView(snapshot: snapshot, temperatureUnit: store.temperatureUnit)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await store.load()
        }
        .alert("Weather update issue", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    store.errorMessage = nil
                }
            }
        ), actions: {
            Button("OK") {
                store.errorMessage = nil
            }
        }, message: {
            Text(store.errorMessage ?? "")
        })
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.75))

            TextField("Search city", text: $store.searchQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(.white)
                .onChange(of: store.searchQuery) { _, _ in
                    store.refreshSuggestions()
                }
                .onSubmit {
                    Task {
                        await store.searchCity()
                    }
                }

            Button("Go") {
                Task {
                    await store.searchCity()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .weatherGlassButton(prominent: true)
        }
        .padding(14)
        .weatherGlassCard(cornerRadius: 20, tint: Color.white.opacity(0.08))
        .overlay(alignment: .bottom) {
            if !store.suggestions.isEmpty {
                suggestionList
                    .padding(.top, 66)
            }
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(store.suggestions) { suggestion in
                Button {
                    Task {
                        await store.selectSuggestion(suggestion)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if suggestion.id != store.suggestions.last?.id {
                    Divider()
                        .overlay(Color.white.opacity(0.12))
                }
            }
        }
        .weatherGlassCard(cornerRadius: 18, tint: Color.white.opacity(0.08))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    private var preferencesBar: some View {
        HStack(spacing: 14) {
            Picker("Units", selection: Binding(
                get: { store.temperatureUnit },
                set: { store.updateTemperatureUnit($0) }
            )) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text("°\(unit.title)").tag(unit)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task {
                    await store.refresh()
                }
            } label: {
                Label("Local", systemImage: "location.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .weatherGlassButton()
        }
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: store.isShowingCachedWeather ? "clock.arrow.circlepath" : "info.circle.fill")
                .foregroundStyle(store.isShowingCachedWeather ? Color(red: 0.99, green: 0.84, blue: 0.42) : .white)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(14)
        .weatherGlassCard(
            cornerRadius: 18,
            tint: store.isShowingCachedWeather ? Color(red: 0.33, green: 0.26, blue: 0.10).opacity(0.32) : Color.white.opacity(0.08)
        )
    }

    private func gradientColors(for condition: WeatherCondition) -> [Color] {
        switch condition {
        case .clear:
            [Color(red: 0.98, green: 0.62, blue: 0.26), Color(red: 0.96, green: 0.78, blue: 0.42), Color(red: 0.39, green: 0.74, blue: 0.96)]
        case .partlyCloudy:
            [Color(red: 0.19, green: 0.28, blue: 0.52), Color(red: 0.32, green: 0.50, blue: 0.76), Color(red: 0.76, green: 0.82, blue: 0.91)]
        case .cloudy:
            [Color(red: 0.15, green: 0.18, blue: 0.29), Color(red: 0.36, green: 0.43, blue: 0.56), Color(red: 0.62, green: 0.69, blue: 0.79)]
        case .rain:
            [Color(red: 0.07, green: 0.12, blue: 0.23), Color(red: 0.11, green: 0.28, blue: 0.42), Color(red: 0.28, green: 0.53, blue: 0.62)]
        case .storm:
            [Color(red: 0.08, green: 0.07, blue: 0.16), Color(red: 0.20, green: 0.18, blue: 0.35), Color(red: 0.42, green: 0.38, blue: 0.61)]
        case .snow:
            [Color(red: 0.36, green: 0.50, blue: 0.70), Color(red: 0.58, green: 0.71, blue: 0.84), Color(red: 0.90, green: 0.95, blue: 0.98)]
        case .fog:
            [Color(red: 0.24, green: 0.27, blue: 0.33), Color(red: 0.46, green: 0.50, blue: 0.56), Color(red: 0.72, green: 0.76, blue: 0.80)]
        }
    }
}
