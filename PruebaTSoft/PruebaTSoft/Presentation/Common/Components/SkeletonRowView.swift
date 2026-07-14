import SwiftUI

struct SkeletonRowView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 56, height: 56)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 120, height: 16)
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isAnimating ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

struct SkeletonListView: View {
    private let rowCount = 8

    var body: some View {
        List(0..<rowCount, id: \.self) { _ in
            SkeletonRowView()
        }
        .listStyle(.plain)
        .accessibilityHidden(true)
    }
}
