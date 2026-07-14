import Foundation

enum AppError: LocalizedError, Equatable {
    case noConnection
    case invalidResponse
    case decodingFailed
    case notFound
    case persistenceFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No hay conexión a internet. Verifica tu red e inténtalo de nuevo."
        case .invalidResponse:
            return "El servidor respondió de forma inesperada. Inténtalo de nuevo más tarde."
        case .decodingFailed:
            return "No se pudo interpretar la información recibida."
        case .notFound:
            return "No se encontró la información solicitada."
        case .persistenceFailed:
            return "No se pudo guardar la información localmente."
        case .unknown:
            return "Ocurrió un error inesperado. Inténtalo de nuevo."
        }
    }
}
