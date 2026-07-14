import Foundation

enum PokeAPIEndpoint {
    case pokemonList(offset: Int, limit: Int)
    case pokemonDetail(id: Int)

    private static let baseURL = URL(string: "https://pokeapi.co/api/v2")!

    var url: URL? {
        switch self {
        case let .pokemonList(offset, limit):
            var components = URLComponents(
                url: Self.baseURL.appendingPathComponent("pokemon"),
                resolvingAgainstBaseURL: false
            )
            components?.queryItems = [
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            return components?.url
        case let .pokemonDetail(id):
            return Self.baseURL.appendingPathComponent("pokemon/\(id)")
        }
    }
}
