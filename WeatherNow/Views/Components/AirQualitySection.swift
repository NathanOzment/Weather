import SwiftUI

struct AirQualitySection: View {
    let airQuality: AirQuality

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Air Quality")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(airQuality.category.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(tintColor)
                }

                Spacer()

                Text("\(airQuality.usAqi)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .weatherGlassChip(cornerRadius: 22, tint: tintColor.opacity(0.18))
            }

            HStack(spacing: 12) {
                metric(title: "PM2.5", value: airQuality.pm25String)
                metric(title: "PM10", value: airQuality.pm10String)
                metric(title: "Top Pollutant", value: airQuality.dominantPollutant)
            }

            Text(airQuality.healthSummary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .weatherGlassCard(cornerRadius: 28, tint: tintColor.opacity(0.10))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .weatherGlassChip(cornerRadius: 18, tint: Color.white.opacity(0.08))
    }

    private var tintColor: Color {
        switch airQuality.category {
        case .good:
            Color(red: 0.40, green: 0.86, blue: 0.58)
        case .moderate:
            Color(red: 0.98, green: 0.78, blue: 0.33)
        case .unhealthyForSensitive:
            Color(red: 0.98, green: 0.61, blue: 0.29)
        case .unhealthy:
            Color(red: 0.96, green: 0.36, blue: 0.35)
        case .veryUnhealthy:
            Color(red: 0.62, green: 0.39, blue: 0.90)
        case .hazardous:
            Color(red: 0.53, green: 0.17, blue: 0.26)
        }
    }
}

private extension AirQuality {
    var pm25String: String {
        String(format: "%.1f", pm25)
    }

    var pm10String: String {
        String(format: "%.1f", pm10)
    }
}
