import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: WeatherStore
    @State private var page = 0
    @State private var selectedUnit: TemperatureUnit = .fahrenheit
    @State private var selectedStarterCity = "Chicago"
    @State private var isFinishing = false
    @Namespace private var glassNamespace

    private let starterCities = ["Chicago", "New York", "San Francisco", "Austin"]
    private let starterCityColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Weather That Feels Instant",
            subtitle: "Live local conditions, fast city search, and deep-dive forecasts in a clean native iOS app.",
            symbol: "sparkles",
            colors: [Color(red: 0.98, green: 0.57, blue: 0.29), Color(red: 0.94, green: 0.80, blue: 0.45)]
        ),
        OnboardingPage(
            title: "Build Your Forecast List",
            subtitle: "Save cities, reopen them from cache, and jump back into the places you check most.",
            symbol: "star.square.on.square.fill",
            colors: [Color(red: 0.25, green: 0.54, blue: 0.92), Color(red: 0.50, green: 0.78, blue: 0.96)]
        ),
        OnboardingPage(
            title: "See More Than One Number",
            subtitle: "Track hourly trends, sunrise and sunset, pressure, visibility, and seven-day outlooks.",
            symbol: "chart.line.uptrend.xyaxis.circle.fill",
            colors: [Color(red: 0.12, green: 0.74, blue: 0.67), Color(red: 0.63, green: 0.90, blue: 0.79)]
        )
    ]

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                Group {
                    if #available(iOS 26, *) {
                        GlassEffectContainer(spacing: 20) {
                            onboardingContent
                        }
                    } else {
                        onboardingContent
                    }
                }
                .padding(24)
                .padding(.bottom, 24)
            }
        }
    }

    private var onboardingContent: some View {
        let isFinalPage = page == pages.count - 1

        return VStack(alignment: .leading, spacing: isFinalPage ? 18 : 24) {
            HStack {
                Text("WeatherNow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button("Skip") {
                    Task {
                        await finishOnboarding()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(.white.opacity(0.92))
                .weatherGlassButton()
            }

            Spacer(minLength: isFinalPage ? 0 : 24)

            card(for: pages[page])

            if page == pages.count - 1 {
                setupControls
                    .onboardingGlassTransition(id: "setup-controls", namespace: glassNamespace)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.white : Color.white.opacity(0.28))
                        .frame(width: index == page ? 28 : 10, height: 10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .weatherGlassChip(cornerRadius: 18, tint: Color.white.opacity(0.08))

            if page == pages.count - 1 {
                primaryActionButton(title: buttonTitle) {
                    Task {
                        await finishOnboarding()
                    }
                }
                .onboardingGlassTransition(id: "primary-action-final", namespace: glassNamespace)
            } else {
                primaryActionButton(title: buttonTitle) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        page += 1
                    }
                }
                .onboardingGlassTransition(id: "primary-action-next", namespace: glassNamespace)
            }
        }
    }

    private var buttonTitle: String {
        if isFinishing {
            return "Loading Forecast..."
        }
        return page == pages.count - 1 ? "Start Exploring" : "Continue"
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.16),
                Color(red: 0.12, green: 0.21, blue: 0.35),
                Color(red: 0.25, green: 0.41, blue: 0.56)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func card(for page: OnboardingPage) -> some View {
        let isFinalPage = self.page == pages.count - 1

        return VStack(alignment: .leading, spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: isFinalPage ? 152 : 240)

                Image(systemName: page.symbol)
                    .font(.system(size: isFinalPage ? 52 : 78))
                    .foregroundStyle(.white)
            }

            Text(page.title)
                .font(.system(size: isFinalPage ? 24 : 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(page.subtitle)
                .font(isFinalPage ? .subheadline : .title3)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(isFinalPage ? 18 : 24)
        .weatherGlassCard(cornerRadius: 34, tint: Color.white.opacity(0.08))
    }

    private var setupControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Up Your Start")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Picker("Units", selection: $selectedUnit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text("°\(unit.title)").tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .weatherGlassSegmentedControl(cornerRadius: 22, tint: Color.white.opacity(0.10))

            VStack(alignment: .leading, spacing: 10) {
                Text("Starter City")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.86))

                LazyVGrid(columns: starterCityColumns, spacing: 10) {
                    ForEach(starterCities, id: \.self) { city in
                        Button {
                            selectedStarterCity = city
                        } label: {
                            Text(city)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .weatherGlassChip(
                            cornerRadius: 16,
                            tint: selectedStarterCity == city ? Color.white.opacity(0.18) : Color.white.opacity(0.08),
                            interactive: true
                        )
                    }
                }
            }
        }
        .padding(16)
        .weatherGlassCard(cornerRadius: 26, tint: Color.white.opacity(0.08))
    }

    private func primaryActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .foregroundStyle(.white)
        .weatherGlassButton(prominent: true)
        .disabled(isFinishing)
    }

    private func finishOnboarding() async {
        guard !isFinishing else { return }
        isFinishing = true
        await store.completeOnboarding(preferredUnit: selectedUnit, starterCity: selectedStarterCity)
        isFinishing = false
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]
}

private extension View {
    @ViewBuilder
    func onboardingGlassTransition(id: String, namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            self
        }
    }
}
