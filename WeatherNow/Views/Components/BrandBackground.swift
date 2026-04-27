import SwiftUI

struct BrandBackground: View {
    let colors: [Color]
    @State private var drift = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ambientBlob(
                color: Color.white.opacity(0.22),
                size: 320,
                blur: 22
            )
            .offset(x: drift ? 166 : 116, y: drift ? -290 : -236)
            .scaleEffect(pulse ? 1.1 : 0.92)
            .animation(.easeInOut(duration: 19).repeatForever(autoreverses: true), value: drift)
            .animation(.easeInOut(duration: 13).repeatForever(autoreverses: true), value: pulse)

            ambientBlob(
                color: colors.last?.opacity(0.22) ?? Color.white.opacity(0.16),
                size: 260,
                blur: 36
            )
            .offset(x: drift ? -164 : -124, y: drift ? 194 : 254)
            .scaleEffect(pulse ? 0.96 : 1.12)
            .animation(.easeInOut(duration: 21).repeatForever(autoreverses: true), value: drift)
            .animation(.easeInOut(duration: 16).repeatForever(autoreverses: true), value: pulse)

            ambientBlob(
                color: Color.white.opacity(0.08),
                size: 210,
                blur: 18
            )
            .offset(x: drift ? -136 : -84, y: drift ? -74 : -116)
            .scaleEffect(pulse ? 1.06 : 0.9)
            .animation(.easeInOut(duration: 18).repeatForever(autoreverses: true), value: drift)
            .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: pulse)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.05),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 420, height: 150)
                .rotationEffect(.degrees(-24))
                .blur(radius: 22)
                .offset(x: drift ? 120 : 78, y: drift ? -16 : 22)
                .blendMode(.screen)
                .animation(.easeInOut(duration: 24).repeatForever(autoreverses: true), value: drift)

            Circle()
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1.2)
                .frame(width: 244, height: 244)
                .blur(radius: 1)
                .offset(x: drift ? 118 : 146, y: drift ? 316 : 276)
                .blendMode(.screen)
                .animation(.easeInOut(duration: 26).repeatForever(autoreverses: true), value: drift)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: 340, height: 220)
                .rotationEffect(.degrees(-22))
                .offset(x: -140, y: 260)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WeatherNow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Forecasts with atmosphere and a little bit of scene")
                    .font(.caption.weight(.medium))
                    .opacity(0.72)
            }
            .foregroundStyle(.white.opacity(0.16))
            .padding(24)
        }
        .ignoresSafeArea()
        .onAppear {
            drift = true
            pulse = true
        }
    }

    private func ambientBlob(color: Color, size: CGFloat, blur: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color,
                        color.opacity(0.4),
                        .clear
                    ],
                    center: .center,
                    startRadius: 12,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: blur)
    }
}
