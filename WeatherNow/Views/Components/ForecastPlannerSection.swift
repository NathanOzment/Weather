import SwiftUI

struct ForecastPlannerSection: View {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit

    private var planner: ForecastPlanner {
        ForecastPlanner(snapshot: snapshot, temperatureUnit: temperatureUnit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Your Day")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Group {
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 16) {
                        plannerContent
                    }
                } else {
                    plannerContent
                }
            }
        }
    }

    private var plannerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            plannerCard(
                title: planner.bestWindowTitle,
                body: planner.bestWindowBody,
                icon: "clock.badge.checkmark",
                tint: Color(red: 0.98, green: 0.76, blue: 0.33)
            )

            HStack(spacing: 12) {
                plannerCard(
                    title: "What to Wear",
                    body: planner.wearAdvice,
                    icon: "tshirt.fill",
                    tint: Color(red: 0.47, green: 0.81, blue: 0.94)
                )

                plannerCard(
                    title: "Heads Up",
                    body: planner.cautionAdvice,
                    icon: "exclamationmark.triangle.fill",
                    tint: Color(red: 0.99, green: 0.54, blue: 0.40)
                )
            }
        }
    }

    private func plannerCard(title: String, body: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .padding(10)
                .weatherGlassChip(cornerRadius: 16, tint: tint.opacity(0.16))

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .padding(18)
        .weatherGlassCard(cornerRadius: 24, tint: tint.opacity(0.08))
    }
}

private struct ForecastPlanner {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit

    private var nextDryHour: HourlyForecast? {
        snapshot.hourly.first {
            $0.precipitationChance < 35 && $0.condition != .storm
        }
    }

    private var warmestHour: HourlyForecast? {
        snapshot.hourly.max { $0.temperature < $1.temperature }
    }

    var bestWindowTitle: String {
        if let nextDryHour {
            return "Best window around \(nextDryHour.time.formatted(date: .omitted, time: .shortened))"
        }

        if let warmestHour {
            return "Warmest stretch around \(warmestHour.time.formatted(date: .omitted, time: .shortened))"
        }

        return "Watch the sky"
    }

    var bestWindowBody: String {
        if let nextDryHour {
            let temp = temperatureUnit.temperatureString(fromCelsius: nextDryHour.temperature)
            return "That hour looks calmer with \(nextDryHour.precipitationChance)% rain odds and temperatures near \(temp)."
        }

        return "Conditions stay unsettled, so shorter plans and a quick weather check will help."
    }

    var wearAdvice: String {
        let currentTemp = snapshot.current.temperature

        if currentTemp <= 4 {
            return "Bundle up with a heavier coat. Wind and cold will make it feel sharper than the thermometer suggests."
        } else if currentTemp <= 12 {
            return "A jacket or layered hoodie should feel right, especially if you're out after sunset."
        } else if currentTemp <= 22 {
            return "Light layers are your friend today. You can stay comfortable without overpacking."
        } else {
            return "Dress light and breathable. Water and shade will matter more than extra layers."
        }
    }

    var cautionAdvice: String {
        if snapshot.current.condition == .storm {
            return "Storm energy is active right now, so outdoor plans are worth delaying if you can."
        }

        if snapshot.current.condition == .rain || snapshot.hourly.contains(where: { $0.precipitationChance >= 55 }) {
            return "Rain chances stay meaningful, so keep an umbrella or a quick indoor backup nearby."
        }

        if snapshot.airQuality.category == .unhealthyForSensitive || snapshot.airQuality.category == .unhealthy {
            return "Air quality is a little rough, so lighter outdoor activity would be the more comfortable option."
        }

        if snapshot.airQuality.category == .veryUnhealthy || snapshot.airQuality.category == .hazardous {
            return "Air quality is poor enough that indoor plans make more sense than a long day outside."
        }

        if snapshot.current.uvIndex >= 7 {
            return "UV is running high, so sunscreen and a little shade time will go a long way."
        }

        if snapshot.current.windSpeed >= 28 {
            return "It is breezy enough to notice. Expect cooler-feeling air and a little extra bite in open areas."
        }

        return "Conditions look fairly cooperative, so it is a good day for flexible outdoor plans."
    }
}
