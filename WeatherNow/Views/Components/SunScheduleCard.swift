import SwiftUI

struct SunScheduleCard: View {
    let schedule: SunSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sun Schedule")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Group {
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 14) {
                        scheduleContent
                    }
                } else {
                    scheduleContent
                }
            }
        }
    }

    private var scheduleContent: some View {
        HStack(spacing: 12) {
            scheduleBlock(
                title: "Sunrise",
                value: schedule.sunrise.formatted(date: .omitted, time: .shortened),
                icon: "sunrise.fill",
                accent: .yellow
            )
            scheduleBlock(
                title: "Sunset",
                value: schedule.sunset.formatted(date: .omitted, time: .shortened),
                icon: "sunset.fill",
                accent: .orange
            )
        }
    }

    private func scheduleBlock(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .font(.title3)
                .padding(10)
                .weatherGlassChip(cornerRadius: 16, tint: accent.opacity(0.16))
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
        .padding(16)
        .weatherGlassCard(cornerRadius: 24, tint: accent.opacity(0.08))
    }
}
