import UIKit

protocol ImageLoading: Sendable {
    func loadImage(from url: URL) async throws -> UIImage
}

final class ImageLoader: ImageLoading, @unchecked Sendable {
    private let session: URLSession
    private let cache: NSCache<NSURL, UIImage>

    init(session: URLSession = .shared, cache: NSCache<NSURL, UIImage> = ImageLoader.sharedCache) {
        self.session = session
        self.cache = cache
    }

    static let sharedCache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 200
        return cache
    }()

    func loadImage(from url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw urlError.code == .notConnectedToInternet ? NetworkError.noConnection : NetworkError.unknown(urlError)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingFailed(NSError(domain: "ImageLoader", code: -1))
        }

        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
