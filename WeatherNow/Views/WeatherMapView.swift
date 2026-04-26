import MapKit
import SwiftUI

struct WeatherMapView: View {
    @ObservedObject var store: WeatherStore
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCityName: String?

    private var points: [MapWeatherPoint] {
        let snapshots = store.mapSnapshots.isEmpty ? [WeatherSamples.snapshot] : store.mapSnapshots

        return snapshots.map { snapshot in
            MapWeatherPoint(
                cityName: snapshot.cityName,
                coordinates: Coordinates(latitude: snapshot.latitude, longitude: snapshot.longitude),
                snapshot: snapshot,
                isActive: snapshot.cityName == store.activeCityName,
                isSaved: store.savedCities.contains(snapshot.cityName)
            )
        }
    }

    private var selectedPoint: MapWeatherPoint? {
        if let selectedCityName {
            return points.first { $0.cityName == selectedCityName }
        }

        return points.first { $0.isActive } ?? points.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground(colors: [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.15, green: 0.29, blue: 0.48), Color(red: 0.39, green: 0.65, blue: 0.82)])

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BrandHeader(
                            eyebrow: "Radar View",
                            title: "Live Weather Map",
                            subtitle: "Compare your current city and saved forecasts at a glance",
                            symbol: "map.fill"
                        )

                        mapCard

                        if let selectedPoint {
                            focusCard(for: selectedPoint)
                        }

                        cityRail
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await store.load()
            selectedCityName = selectedCityName ?? store.activeCityName ?? points.first?.cityName
            updateMapPosition()
        }
        .onChange(of: store.activeCityName) { _, newValue in
            if selectedCityName == nil {
                selectedCityName = newValue
            }
            updateMapPosition()
        }
        .onChange(of: points) { _, _ in
            if selectedCityName == nil || !points.contains(where: { $0.cityName == selectedCityName }) {
                selectedCityName = store.activeCityName ?? points.first?.cityName
            }
            updateMapPosition()
        }
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Radar-Inspired Outlook")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Pins show saved cities, while color halos reflect current conditions.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    updateMapPosition()
                } label: {
                    Label("Recenter", systemImage: "scope")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.18))
            }

            Map(position: $position) {
                ForEach(points) { point in
                    Annotation(point.cityName, coordinate: point.coordinate) {
                        RadarAnnotation(
                            point: point,
                            temperatureUnit: store.temperatureUnit,
                            isSelected: point.cityName == selectedCityName
                        )
                        .onTapGesture {
                            selectedCityName = point.cityName
                        }
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func focusCard(for point: MapWeatherPoint) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(point.cityName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(point.snapshot.current.condition.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                Text(store.temperatureUnit.temperatureString(fromCelsius: point.snapshot.current.temperature))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 12) {
                mapMetric(symbol: "drop.fill", value: "\(point.snapshot.current.humidity)% humidity")
                mapMetric(symbol: "wind", value: store.temperatureUnit.speedString(fromKilometersPerHour: point.snapshot.current.windSpeed))
                mapMetric(symbol: "umbrella.fill", value: "\(point.snapshot.daily.first?.precipitationChance ?? 0)% precip")
            }

            Button {
                Task {
                    await store.loadSavedCity(point.cityName)
                }
            } label: {
                Label(point.isActive ? "Viewing This City" : "Open Forecast", systemImage: point.isActive ? "checkmark.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(point.isActive ? Color.white.opacity(0.16) : point.tintColor.opacity(0.85))
            .disabled(point.isActive)
        }
        .padding(20)
        .background(point.tintColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var cityRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracked Cities")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(points) { point in
                        Button {
                            selectedCityName = point.cityName
                            updateMapPosition()
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(point.cityName, systemImage: point.snapshot.current.condition.sfSymbol)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(store.temperatureUnit.temperatureString(fromCelsius: point.snapshot.current.temperature))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)

                                Text(point.isSaved ? "Saved city" : "Current focus")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .frame(width: 150, alignment: .leading)
                            .padding(16)
                            .background(
                                (point.cityName == selectedCityName ? point.tintColor.opacity(0.28) : Color.white.opacity(0.08)),
                                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func mapMetric(symbol: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(value)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.86))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1), in: Capsule())
    }

    private func updateMapPosition() {
        guard !points.isEmpty else { return }

        let coordinates = points.map(\.coordinate)
        let center = CLLocationCoordinate2D(
            latitude: coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count),
            longitude: coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        )

        let latitudeDelta = max((coordinates.map(\.latitude).max() ?? center.latitude) - (coordinates.map(\.latitude).min() ?? center.latitude), 3)
        let longitudeDelta = max((coordinates.map(\.longitude).max() ?? center.longitude) - (coordinates.map(\.longitude).min() ?? center.longitude), 3)

        position = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta * 1.8, longitudeDelta: longitudeDelta * 1.8)
            )
        )
    }
}

private struct MapWeatherPoint: Identifiable, Equatable {
    let cityName: String
    let coordinates: Coordinates
    let snapshot: WeatherSnapshot
    let isActive: Bool
    let isSaved: Bool

    var id: String { cityName }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }

    var tintColor: Color {
        switch snapshot.current.condition {
        case .clear:
            Color(red: 0.98, green: 0.70, blue: 0.29)
        case .partlyCloudy:
            Color(red: 0.56, green: 0.79, blue: 0.98)
        case .cloudy:
            Color(red: 0.61, green: 0.67, blue: 0.79)
        case .rain:
            Color(red: 0.30, green: 0.70, blue: 0.86)
        case .storm:
            Color(red: 0.53, green: 0.48, blue: 0.94)
        case .snow:
            Color(red: 0.82, green: 0.92, blue: 1.0)
        case .fog:
            Color(red: 0.72, green: 0.76, blue: 0.80)
        }
    }
}

private struct RadarAnnotation: View {
    let point: MapWeatherPoint
    let temperatureUnit: TemperatureUnit
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(point.tintColor.opacity(0.18))
                    .frame(width: isSelected ? 80 : 66, height: isSelected ? 80 : 66)

                Circle()
                    .fill(point.tintColor.opacity(0.28))
                    .frame(width: isSelected ? 54 : 44, height: isSelected ? 54 : 44)

                Image(systemName: point.snapshot.current.condition.sfSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.82 : 0.48), lineWidth: isSelected ? 3 : 2)
                    .frame(width: isSelected ? 54 : 44, height: isSelected ? 54 : 44)
            )
            .shadow(color: point.tintColor.opacity(0.34), radius: 16, y: 10)

            VStack(spacing: 2) {
                Text(point.cityName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(temperatureUnit.temperatureString(fromCelsius: point.snapshot.current.temperature))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
