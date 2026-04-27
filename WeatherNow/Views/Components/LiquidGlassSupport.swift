import SwiftUI

enum WeatherGlassPalette {
    static let cool = Color(red: 0.43, green: 0.58, blue: 0.86)
    static let slate = Color(red: 0.24, green: 0.32, blue: 0.53)
    static let warm = Color(red: 0.99, green: 0.83, blue: 0.36)
    static let mint = Color(red: 0.40, green: 0.82, blue: 0.72)
}

extension View {
    @ViewBuilder
    func weatherGlassCard(cornerRadius: CGFloat = 30, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26, *) {
            let glass = (tint.map { Glass.regular.tint($0.opacity(0.12)) } ?? .regular).interactive(interactive)
            glassEffect(glass, in: shape)
            .overlay {
                ZStack {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    .clear,
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)

                    Ellipse()
                        .fill(Color.white.opacity(interactive ? 0.24 : 0.18))
                        .frame(width: max(cornerRadius * 5.4, 150), height: max(cornerRadius * 2.0, 68))
                        .blur(radius: 12)
                        .offset(x: -cornerRadius * 0.35, y: -cornerRadius * 0.9)

                    Ellipse()
                        .fill((tint ?? WeatherGlassPalette.cool).opacity(interactive ? 0.14 : 0.10))
                        .frame(width: max(cornerRadius * 4.1, 120), height: max(cornerRadius * 1.5, 54))
                        .blur(radius: 16)
                        .offset(x: cornerRadius * 0.85, y: cornerRadius * 0.95)

                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.black.opacity(0.08)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.multiply)
                }
                .mask(shape)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        } else {
            background(
                shape
                    .fill(.ultraThinMaterial.opacity(0.78))
                    .overlay {
                        ZStack {
                            shape
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.10),
                                            (tint ?? Color.white.opacity(0.04)).opacity(0.14),
                                            Color.white.opacity(0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Ellipse()
                                .fill(Color.white.opacity(0.16))
                                .frame(width: max(cornerRadius * 5.0, 136), height: max(cornerRadius * 1.8, 60))
                                .blur(radius: 12)
                                .offset(x: -cornerRadius * 0.3, y: -cornerRadius * 0.8)
                        }
                        .mask(shape)
                    }
            )
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
        }
    }

    @ViewBuilder
    func weatherGlassChip(cornerRadius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26, *) {
            let glass = (tint.map { Glass.regular.tint($0.opacity(0.10)) } ?? .regular).interactive(interactive)
            glassEffect(glass, in: shape)
            .overlay {
                ZStack {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )

                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    .clear,
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)

                    Ellipse()
                        .fill(Color.white.opacity(interactive ? 0.22 : 0.16))
                        .frame(width: max(cornerRadius * 4.4, 84), height: max(cornerRadius * 1.4, 28))
                        .blur(radius: 8)
                        .offset(x: -cornerRadius * 0.18, y: -cornerRadius * 0.62)

                    Ellipse()
                        .fill((tint ?? WeatherGlassPalette.cool).opacity(interactive ? 0.12 : 0.08))
                        .frame(width: max(cornerRadius * 3.0, 64), height: max(cornerRadius, 20))
                        .blur(radius: 10)
                        .offset(x: cornerRadius * 0.65, y: cornerRadius * 0.5)
                }
                .mask(shape)
            }
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        } else {
            background(
                shape
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.10 : 0.12))
                    .overlay {
                        Ellipse()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: max(cornerRadius * 3.8, 72), height: max(cornerRadius * 1.1, 22))
                            .blur(radius: 8)
                            .offset(x: -cornerRadius * 0.15, y: -cornerRadius * 0.5)
                            .mask(shape)
                    }
            )
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
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
                (tint.map { Glass.regular.tint($0.opacity(0.10)) } ?? .regular).interactive(interactive),
                in: Circle()
            )
            .overlay {
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )

                    Ellipse()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: size * 0.72, height: size * 0.28)
                        .blur(radius: 7)
                        .offset(x: -size * 0.1, y: -size * 0.22)

                    Ellipse()
                        .fill((tint ?? WeatherGlassPalette.cool).opacity(0.10))
                        .frame(width: size * 0.56, height: size * 0.46)
                        .blur(radius: 9)
                        .offset(x: size * 0.12, y: size * 0.16)
                }
                .mask(Circle())
            }
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        } else {
            background(
                Circle()
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.14 : 0.18))
                    .overlay {
                        Ellipse()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: size * 0.72, height: size * 0.28)
                            .blur(radius: 7)
                            .offset(x: -size * 0.1, y: -size * 0.22)
                            .mask(Circle())
                    }
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
