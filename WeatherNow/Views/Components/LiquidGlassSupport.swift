import SwiftUI

extension View {
    @ViewBuilder
    func weatherGlassCard(cornerRadius: CGFloat = 30, tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            glassEffect(
                tint.map { Glass.regular.tint($0) } ?? .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    func weatherGlassChip(cornerRadius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            glassEffect(
                (tint.map { Glass.regular.tint($0) } ?? .regular).interactive(interactive),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.12 : 0.20))
            )
        }
    }

    @ViewBuilder
    func weatherGlassOrb(size: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        frame(width: size, height: size)
            .ifAvailableGlassOrb(size: size, tint: tint, interactive: interactive)
    }
}

private extension View {
    @ViewBuilder
    func ifAvailableGlassOrb(size: CGFloat, tint: Color?, interactive: Bool) -> some View {
        if #available(iOS 26, *) {
            glassEffect(
                (tint.map { Glass.regular.tint($0) } ?? .regular).interactive(interactive),
                in: Circle()
            )
        } else {
            background(
                Circle()
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.16 : 0.22))
            )
        }
    }
}

struct WeatherGlassButtonStyleModifier: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content
        }
    }
}

extension View {
    func weatherGlassButton(prominent: Bool = false) -> some View {
        modifier(WeatherGlassButtonStyleModifier(prominent: prominent))
    }

    func weatherLoadingSheen(active: Bool = true) -> some View {
        modifier(WeatherLoadingSheenModifier(active: active))
    }
}

private struct WeatherLoadingSheenModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = -1.1

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.10),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: max(geometry.size.width * 0.45, 96))
                        .rotationEffect(.degrees(18))
                        .offset(x: geometry.size.width * phase)
                        .blendMode(.screen)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                    .onAppear {
                        phase = -1.1
                        withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                            phase = 1.2
                        }
                    }
                }
            }
    }
}
