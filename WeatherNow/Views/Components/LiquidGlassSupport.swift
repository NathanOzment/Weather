import SwiftUI

extension View {
    @ViewBuilder
    func weatherGlassCard(cornerRadius: CGFloat = 30, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26, *) {
            background {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                (tint ?? Color.white.opacity(0.10)).opacity(0.55),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                shape
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)

                shape
                    .inset(by: 1)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                (tint ?? Color.white.opacity(0.10)).opacity(0.26),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .blendMode(.screen)
            }
            glassEffect(
                (tint.map { Glass.regular.tint($0) } ?? .regular).interactive(interactive),
                in: shape
            )
            .shadow(color: .black.opacity(0.16), radius: 22, y: 12)
        } else {
            background(
                shape
                    .fill(.ultraThinMaterial.opacity(0.88))
                    .overlay {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.14),
                                        (tint ?? Color.white.opacity(0.08)).opacity(0.42),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            )
            .overlay(
                shape
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
        }
    }

    @ViewBuilder
    func weatherGlassChip(cornerRadius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26, *) {
            background {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                (tint ?? Color.white.opacity(0.08)).opacity(0.55),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                shape
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            glassEffect(
                (tint.map { Glass.regular.tint($0) } ?? .regular).interactive(interactive),
                in: shape
            )
            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
        } else {
            background(
                shape
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.14 : 0.20))
            )
            .overlay(
                shape
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
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

    func weatherGlassSegmentedControl(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        padding(6)
            .weatherGlassCard(cornerRadius: cornerRadius, tint: tint, interactive: true)
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
