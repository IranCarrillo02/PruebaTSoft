import Foundation

enum NetworkError: Error {
    case invalidURL
    case noConnection
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case unknown(Error)
}
