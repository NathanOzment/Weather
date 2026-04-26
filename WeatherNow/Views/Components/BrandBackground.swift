import SwiftUI

struct BrandBackground: View {
    let colors: [Color]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.11))
                .frame(width: 280, height: 280)
                .blur(radius: 12)
                .offset(x: 140, y: -250)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 340, height: 220)
                .rotationEffect(.degrees(-22))
                .offset(x: -140, y: 260)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WeatherNow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Forecasts with atmosphere")
                    .font(.caption.weight(.medium))
                    .opacity(0.72)
            }
            .foregroundStyle(.white.opacity(0.16))
            .padding(24)
        }
        .ignoresSafeArea()
    }
}
