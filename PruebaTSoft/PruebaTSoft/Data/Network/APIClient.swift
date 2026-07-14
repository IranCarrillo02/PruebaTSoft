import Foundation

protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: PokeAPIEndpoint) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: PokeAPIEndpoint) async throws -> T {
        guard let url = endpoint.url else { throw NetworkError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw Self.mapURLError(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: -1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    private static func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed:
            return .noConnection
        default:
            return .unknown(error)
        }
    }
}
