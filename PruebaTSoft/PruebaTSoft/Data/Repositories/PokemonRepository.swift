final class PokemonRepository: PokemonRepositoryProtocol, @unchecked Sendable {
    private let apiClient: APIClientProtocol
    private let localDataSource: PokemonLocalDataSourceProtocol

    init(apiClient: APIClientProtocol, localDataSource: PokemonLocalDataSourceProtocol) {
        self.apiClient = apiClient
        self.localDataSource = localDataSource
    }

    func fetchPokemonList(offset: Int, limit: Int) async throws -> [Pokemon] {
        do {
            let endpoint = PokeAPIEndpoint.pokemonList(offset: offset, limit: limit)
            let response: PokemonListResponseDTO = try await apiClient.request(endpoint)
            let pokemons = response.results.compactMap(PokemonMapper.toDomain(listItem:))
            try? localDataSource.saveList(pokemons, startingAt: offset)
            return pokemons
        } catch {
            if let cached = try? localDataSource.cachedList(offset: offset, limit: limit), !cached.isEmpty {
                return cached
            }
            throw Self.mapToAppError(error)
        }
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        do {
            let dto: PokemonDetailDTO = try await apiClient.request(.pokemonDetail(id: id))
            let detail = PokemonMapper.toDomain(detail: dto)
            try? localDataSource.saveDetail(detail)
            return detail
        } catch {
            if let cached = try? localDataSource.cachedDetail(id: id) {
                return cached
            }
            throw Self.mapToAppError(error)
        }
    }

    private static func mapToAppError(_ error: Error) -> AppError {
        guard let networkError = error as? NetworkError else { return .unknown }
        switch networkError {
        case .noConnection:
            return .noConnection
        case .invalidURL, .invalidResponse:
            return .invalidResponse
        case .decodingFailed:
            return .decodingFailed
        case .unknown:
            return .unknown
        }
    }
}
