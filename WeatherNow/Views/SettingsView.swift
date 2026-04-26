import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground(colors: [
                    Color(red: 0.11, green: 0.12, blue: 0.18),
                    Color(red: 0.19, green: 0.22, blue: 0.31),
                    Color(red: 0.34, green: 0.42, blue: 0.54)
                ])

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        BrandHeader(
                            eyebrow: "Preferences",
                            title: "Settings",
                            subtitle: "Tune units, onboarding, and your saved experience",
                            symbol: "slider.horizontal.3"
                        )

                        settingsCard {
                            Text("Units")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)

                            Picker("Units", selection: Binding(
                                get: { store.temperatureUnit },
                                set: { store.updateTemperatureUnit($0) }
                            )) {
                                ForEach(TemperatureUnit.allCases) { unit in
                                    Text("°\(unit.title)").tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        settingsCard {
                            Text("Saved Cities")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("\(store.savedCities.count) locations saved")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.74))

                            Button(role: .destructive) {
                                store.clearSavedCities()
                            } label: {
                                Text("Clear Saved Cities")
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .weatherGlassButton(prominent: true)
                            .disabled(store.savedCities.isEmpty)
                        }

                        settingsCard {
                            Text("WeatherNow")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("A SwiftUI weather app with local conditions, saved places, and deep-dive forecasts powered by Open-Meteo.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))

                            Button {
                                Task {
                                    await store.refresh()
                                }
                            } label: {
                                Label("Refresh Current Location", systemImage: "location.fill")
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .weatherGlassButton(prominent: true)

                            Button {
                                store.resetOnboarding()
                            } label: {
                                Text("Show Onboarding Again")
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .weatherGlassButton()
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(18)
        .weatherGlassCard(cornerRadius: 26, tint: Color.white.opacity(0.08))
    }
}
