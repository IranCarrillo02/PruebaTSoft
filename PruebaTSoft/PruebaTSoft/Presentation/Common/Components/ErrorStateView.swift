import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Reintentar", action: retryAction)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Vuelve a intentar cargar la información")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
