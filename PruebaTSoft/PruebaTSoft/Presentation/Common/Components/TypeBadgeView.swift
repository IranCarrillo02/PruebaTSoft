import SwiftUI

struct TypeBadgeView: View {
    let type: String

    var body: some View {
        Text(type)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
            .accessibilityLabel("Tipo \(type)")
    }
}
