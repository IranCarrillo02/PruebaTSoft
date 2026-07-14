import Foundation
@testable import PruebaTSoft

final class APIClientMock: APIClientProtocol, @unchecked Sendable {
    var resultProvider: ((PokeAPIEndpoint) throws -> Any)?
    private(set) var requestedURLs: [URL?] = []

    func request<T: Decodable>(_ endpoint: PokeAPIEndpoint) async throws -> T {
        requestedURLs.append(endpoint.url)
        guard let resultProvider, let value = try resultProvider(endpoint) as? T else {
            throw NetworkError.unknown(NSError(domain: "APIClientMock", code: -1))
        }
        return value
    }
}
