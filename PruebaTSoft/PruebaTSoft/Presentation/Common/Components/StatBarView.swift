import SwiftUI

struct StatBarView: View {
    let stat: PokemonStat
    private let maxValue: Double = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(displayName)
                    .font(.caption)
                Spacer()
                Text("\(stat.baseValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName): \(stat.baseValue) de \(Int(maxValue))")
    }

    private var progress: Double {
        min(Double(stat.baseValue) / maxValue, 1.0)
    }

    private var displayName: String {
        stat.name.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
