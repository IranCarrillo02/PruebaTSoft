import SwiftUI

struct AsyncCachedImage: View {
    let url: URL?
    let imageLoader: ImageLoading

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if didFail {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        image = nil
        didFail = false
        guard let url else {
            didFail = true
            return
        }
        do {
            image = try await imageLoader.loadImage(from: url)
        } catch {
            didFail = true
        }
    }
}
