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
            let glass = (tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? .regular).interactive(interactive)
            glassEffect(glass, in: shape)
            .overlay {
                shape
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8)

                if let tint {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.04),
                                    tint.opacity(0.03),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        } else {
            background(
                shape
                    .fill(.ultraThinMaterial.opacity(0.78))
                    .overlay {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        (tint ?? Color.white.opacity(0.04)).opacity(0.16),
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
            .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
        }
    }

    @ViewBuilder
    func weatherGlassChip(cornerRadius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26, *) {
            let glass = (tint.map { Glass.regular.tint($0.opacity(0.16)) } ?? .regular).interactive(interactive)
            glassEffect(glass, in: shape)
            .overlay {
                shape
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8)

                if let tint {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    tint.opacity(0.03),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        } else {
            background(
                shape
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.10 : 0.14))
            )
            .overlay(
                shape
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
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
                (tint.map { Glass.regular.tint($0.opacity(0.14)) } ?? .regular).interactive(interactive),
                in: Circle()
            )
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        } else {
            background(
                Circle()
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.14 : 0.18))
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
