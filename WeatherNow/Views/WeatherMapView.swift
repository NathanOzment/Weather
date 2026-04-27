import MapKit
import SwiftUI

struct WeatherMapView: View {
    @ObservedObject var store: WeatherStore
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCityName: String?
    @State private var layerMode: MapLayerMode = .temperature

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
                            subtitle: "Switch between temperature, rain risk, air quality, and alerts across your tracked cities",
                            symbol: "map.fill"
                        )

                        if let loadingMessage = store.loadingMessage {
                            loadingBanner(loadingMessage)
                        }

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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(layerMode.headerTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(layerMode.headerSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    updateMapPosition()
                } label: {
                    HStack(spacing: 8) {
                        if store.isRefreshingCurrentLocation {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "scope")
                        }
                        Text("Recenter")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .disabled(store.isRefreshingCurrentLocation)
                .weatherGlassButton(prominent: true)
            }

            Picker("Layer", selection: $layerMode) {
                ForEach(MapLayerMode.allCases) { mode in
                    Text(mode.shortTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Map(position: $position) {
                ForEach(points) { point in
                    Annotation(point.cityName, coordinate: point.coordinate) {
                        RadarAnnotation(
                            point: point,
                            temperatureUnit: store.temperatureUnit,
                            layerMode: layerMode,
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

            layerLegend
        }
        .padding(18)
        .weatherGlassCard(cornerRadius: 30, tint: Color.white.opacity(0.08))
    }

    private var layerLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legend")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(layerMode.legendDescription)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))

            HStack(spacing: 10) {
                ForEach(layerMode.legendItems(for: store.temperatureUnit)) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Text(item.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .weatherGlassChip(cornerRadius: 16, tint: Color.white.opacity(0.08))
                }
            }
        }
    }

    private func focusCard(for point: MapWeatherPoint) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(point.cityName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(layerMode.focusSubtitle(for: point.snapshot))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                Text(layerMode.primaryValue(for: point.snapshot, temperatureUnit: store.temperatureUnit))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 12) {
                ForEach(layerMode.metrics(for: point.snapshot, temperatureUnit: store.temperatureUnit), id: \.value) { metric in
                    mapMetric(symbol: metric.symbol, value: metric.value)
                }
            }

            if !point.snapshot.alerts.isEmpty {
                Text(point.snapshot.alerts.first?.title ?? "")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(point.tintColor(for: .alerts))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .weatherGlassChip(cornerRadius: 18, tint: point.tintColor(for: .alerts).opacity(0.18))
            }

            Button {
                Task {
                    await store.loadSavedCity(point.cityName)
                }
            } label: {
                HStack(spacing: 8) {
                    if store.cityLoadingName == point.cityName {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: point.isActive ? "checkmark.circle.fill" : "arrow.up.right.circle.fill")
                    }
                    Text(point.isActive ? "Viewing This City" : "Open Forecast")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .weatherGlassButton(prominent: !point.isActive)
            .disabled(point.isActive || store.isLoading)
        }
        .padding(20)
        .weatherGlassCard(cornerRadius: 28, tint: point.tintColor(for: layerMode).opacity(0.12))
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

                                Text(layerMode.primaryValue(for: point.snapshot, temperatureUnit: store.temperatureUnit))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)

                                Text(layerMode.railSubtitle(for: point.snapshot, temperatureUnit: store.temperatureUnit, isSaved: point.isSaved))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .frame(width: 156, alignment: .leading)
                            .padding(16)
                            .weatherGlassCard(
                                cornerRadius: 24,
                                tint: point.cityName == selectedCityName ? point.tintColor(for: layerMode).opacity(0.18) : Color.white.opacity(0.08)
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
        .weatherGlassChip(cornerRadius: 18, tint: Color.white.opacity(0.08))
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
        .weatherGlassCard(cornerRadius: 18, tint: Color.white.opacity(0.10))
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

    func tintColor(for mode: MapLayerMode) -> Color {
        switch mode {
        case .temperature:
            if snapshot.current.temperature >= 32 {
                return Color(red: 0.98, green: 0.52, blue: 0.24)
            } else if snapshot.current.temperature >= 20 {
                return Color(red: 0.99, green: 0.74, blue: 0.31)
            } else if snapshot.current.temperature >= 8 {
                return Color(red: 0.46, green: 0.76, blue: 0.95)
            } else {
                return Color(red: 0.67, green: 0.87, blue: 1.0)
            }
        case .precipitation:
            let chance = snapshot.daily.first?.precipitationChance ?? 0
            if chance >= 70 {
                return Color(red: 0.22, green: 0.57, blue: 0.89)
            } else if chance >= 40 {
                return Color(red: 0.45, green: 0.74, blue: 0.92)
            } else {
                return Color(red: 0.76, green: 0.87, blue: 0.96)
            }
        case .airQuality:
            switch snapshot.airQuality.category {
            case .good:
                return Color(red: 0.40, green: 0.86, blue: 0.58)
            case .moderate:
                return Color(red: 0.98, green: 0.78, blue: 0.33)
            case .unhealthyForSensitive:
                return Color(red: 0.98, green: 0.61, blue: 0.29)
            case .unhealthy:
                return Color(red: 0.96, green: 0.36, blue: 0.35)
            case .veryUnhealthy:
                return Color(red: 0.62, green: 0.39, blue: 0.90)
            case .hazardous:
                return Color(red: 0.53, green: 0.17, blue: 0.26)
            }
        case .alerts:
            switch snapshot.alerts.first?.level {
            case .severe:
                return Color(red: 0.96, green: 0.36, blue: 0.35)
            case .warning:
                return Color(red: 0.99, green: 0.57, blue: 0.33)
            case .elevated:
                return Color(red: 0.98, green: 0.79, blue: 0.35)
            case .none:
                return Color(red: 0.49, green: 0.78, blue: 0.98)
            }
        }
    }
}

private struct RadarAnnotation: View {
    let point: MapWeatherPoint
    let temperatureUnit: TemperatureUnit
    let layerMode: MapLayerMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(point.tintColor(for: layerMode).opacity(0.18))
                    .frame(width: isSelected ? 80 : 66, height: isSelected ? 80 : 66)

                Circle()
                    .fill(point.tintColor(for: layerMode).opacity(0.28))
                    .frame(width: isSelected ? 54 : 44, height: isSelected ? 54 : 44)

                Image(systemName: layerMode.annotationSymbol(for: point.snapshot))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.82 : 0.48), lineWidth: isSelected ? 3 : 2)
                    .frame(width: isSelected ? 54 : 44, height: isSelected ? 54 : 44)
            )
            .shadow(color: point.tintColor(for: layerMode).opacity(0.34), radius: 16, y: 10)

            VStack(spacing: 2) {
                Text(point.cityName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(layerMode.primaryValue(for: point.snapshot, temperatureUnit: temperatureUnit))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .weatherGlassChip(cornerRadius: 18, tint: point.tintColor(for: layerMode).opacity(0.10))
        }
    }
}

private enum MapLayerMode: String, CaseIterable, Identifiable {
    case temperature
    case precipitation
    case airQuality
    case alerts

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .temperature: "Temp"
        case .precipitation: "Rain"
        case .airQuality: "AQI"
        case .alerts: "Alerts"
        }
    }

    var headerTitle: String {
        switch self {
        case .temperature: "Temperature Layer"
        case .precipitation: "Precipitation Outlook"
        case .airQuality: "Air Quality Layer"
        case .alerts: "Alert Severity Layer"
        }
    }

    var headerSubtitle: String {
        switch self {
        case .temperature: "Compare which cities feel hottest, coolest, and most comfortable right now."
        case .precipitation: "Highlight where rain chances are building so you can spot wetter cities fast."
        case .airQuality: "Track which saved places look cleaner and which ones may need lighter outdoor plans."
        case .alerts: "See where the biggest forecast risks are clustering across your tracked cities."
        }
    }

    var legendDescription: String {
        switch self {
        case .temperature: "Warmer markers glow amber while cooler ones shift into softer blues."
        case .precipitation: "Darker blue signals higher rain risk over the next day."
        case .airQuality: "Cleaner air stays green, while tougher AQI climbs into orange, red, and violet."
        case .alerts: "Cities move from clear to elevated, warning, and severe based on the forecast risks."
        }
    }

    func annotationSymbol(for snapshot: WeatherSnapshot) -> String {
        switch self {
        case .temperature:
            "thermometer.medium"
        case .precipitation:
            (snapshot.daily.first?.precipitationChance ?? 0) >= 50 ? "cloud.rain.fill" : "cloud.sun.fill"
        case .airQuality:
            "aqi.medium"
        case .alerts:
            snapshot.alerts.first?.symbol ?? "checkmark.shield.fill"
        }
    }

    func primaryValue(for snapshot: WeatherSnapshot, temperatureUnit: TemperatureUnit) -> String {
        switch self {
        case .temperature:
            temperatureUnit.temperatureString(fromCelsius: snapshot.current.temperature)
        case .precipitation:
            "\(snapshot.daily.first?.precipitationChance ?? 0)%"
        case .airQuality:
            "\(snapshot.airQuality.usAqi)"
        case .alerts:
            "\(snapshot.alerts.count)"
        }
    }

    func focusSubtitle(for snapshot: WeatherSnapshot) -> String {
        switch self {
        case .temperature:
            snapshot.current.condition.title
        case .precipitation:
            snapshot.daily.first?.precipitationChance ?? 0 >= 50 ? "Rain risk is building here" : "Lower rain risk today"
        case .airQuality:
            snapshot.airQuality.category.title
        case .alerts:
            snapshot.alerts.first?.title ?? "No active risk callouts"
        }
    }

    func railSubtitle(for snapshot: WeatherSnapshot, temperatureUnit: TemperatureUnit, isSaved: Bool) -> String {
        switch self {
        case .temperature:
            isSaved ? "Saved city" : "Current focus"
        case .precipitation:
            "\(snapshot.daily.first?.precipitationChance ?? 0)% rain chance"
        case .airQuality:
            snapshot.airQuality.category.title
        case .alerts:
            snapshot.alerts.isEmpty ? "No active alerts" : "\(snapshot.alerts.count) alert\(snapshot.alerts.count == 1 ? "" : "s")"
        }
    }

    func metrics(for snapshot: WeatherSnapshot, temperatureUnit: TemperatureUnit) -> [MapMetric] {
        switch self {
        case .temperature:
            return [
                MapMetric(symbol: "thermometer.low", value: "Feels \(temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature))"),
                MapMetric(symbol: "wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed)),
                MapMetric(symbol: "drop.fill", value: "\(snapshot.current.humidity)% humidity")
            ]
        case .precipitation:
            return [
                MapMetric(symbol: "umbrella.fill", value: "\(snapshot.daily.first?.precipitationChance ?? 0)% today"),
                MapMetric(symbol: "cloud.rain.fill", value: "\(snapshot.hourly.first?.precipitationChance ?? 0)% next hour"),
                MapMetric(symbol: "eye.fill", value: "\(snapshot.current.visibility) km vis")
            ]
        case .airQuality:
            return [
                MapMetric(symbol: "aqi.medium", value: "AQI \(snapshot.airQuality.usAqi)"),
                MapMetric(symbol: "leaf.fill", value: snapshot.airQuality.category.title),
                MapMetric(symbol: "circle.hexagongrid.fill", value: snapshot.airQuality.dominantPollutant)
            ]
        case .alerts:
            return [
                MapMetric(symbol: "exclamationmark.triangle.fill", value: "\(snapshot.alerts.count) active"),
                MapMetric(symbol: "sun.max.fill", value: "UV \(snapshot.current.uvIndex)"),
                MapMetric(symbol: "wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed))
            ]
        }
    }

    func legendItems(for temperatureUnit: TemperatureUnit) -> [MapLegendItem] {
        switch self {
        case .temperature:
            return [
                MapLegendItem(title: "Hot", subtitle: temperatureUnit == .fahrenheit ? "90°+" : "32°+", color: Color(red: 0.98, green: 0.52, blue: 0.24)),
                MapLegendItem(title: "Mild", subtitle: temperatureUnit == .fahrenheit ? "68-89°" : "20-31°", color: Color(red: 0.99, green: 0.74, blue: 0.31)),
                MapLegendItem(title: "Cool", subtitle: temperatureUnit == .fahrenheit ? "67° and below" : "19° and below", color: Color(red: 0.46, green: 0.76, blue: 0.95))
            ]
        case .precipitation:
            return [
                MapLegendItem(title: "Low", subtitle: "0-39% chance", color: Color(red: 0.76, green: 0.87, blue: 0.96)),
                MapLegendItem(title: "Medium", subtitle: "40-69% chance", color: Color(red: 0.45, green: 0.74, blue: 0.92)),
                MapLegendItem(title: "High", subtitle: "70%+ chance", color: Color(red: 0.22, green: 0.57, blue: 0.89))
            ]
        case .airQuality:
            return [
                MapLegendItem(title: "Good", subtitle: "AQI under 51", color: Color(red: 0.40, green: 0.86, blue: 0.58)),
                MapLegendItem(title: "Moderate", subtitle: "AQI 51-100", color: Color(red: 0.98, green: 0.78, blue: 0.33)),
                MapLegendItem(title: "Poor", subtitle: "AQI 101+", color: Color(red: 0.96, green: 0.36, blue: 0.35))
            ]
        case .alerts:
            return [
                MapLegendItem(title: "Clear", subtitle: "No major flags", color: Color(red: 0.49, green: 0.78, blue: 0.98)),
                MapLegendItem(title: "Warning", subtitle: "Noticeable risk", color: Color(red: 0.99, green: 0.57, blue: 0.33)),
                MapLegendItem(title: "Severe", subtitle: "Highest urgency", color: Color(red: 0.96, green: 0.36, blue: 0.35))
            ]
        }
    }
}

private struct MapLegendItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
}

private struct MapMetric {
    let symbol: String
    let value: String
}
