import SwiftUI

struct SavedCitiesSection: View {
    let savedCities: [String]
    let activeCity: String?
    let onSelectCity: (String) -> Void
    let onDeleteCity: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Cities")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            if savedCities.isEmpty {
                Text("Save a city from the main card to build your watchlist.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .weatherGlassCard(cornerRadius: 22, tint: Color.white.opacity(0.08))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(savedCities, id: \.self) { city in
                            HStack(spacing: 8) {
                                Button {
                                    onSelectCity(city)
                                } label: {
                                    Text(city)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 10)
                                        .padding(.leading, 14)
                                }

                                Button {
                                    onDeleteCity(city)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .padding(.trailing, 12)
                            }
                            .weatherGlassChip(
                                cornerRadius: 18,
                                tint: activeCity == city ? Color.white.opacity(0.18) : Color.white.opacity(0.08),
                                interactive: true
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
