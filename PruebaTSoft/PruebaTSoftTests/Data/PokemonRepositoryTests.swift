import Foundation
import Testing
@testable import PruebaTSoft

@MainActor
struct PokemonRepositoryTests {

    @Test func fetchListReturnsNetworkResultAndCachesIt() async throws {
        let apiClient = APIClientMock()
        let localDataSource = PokemonLocalDataSourceMock()
        apiClient.resultProvider = { _ in
            PokemonListResponseDTO(
                count: 1,
                next: nil,
                previous: nil,
                results: [PokemonListItemDTO(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")]
            )
        }
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        let result = try await repository.fetchPokemonList(offset: 0, limit: 20)

        #expect(result.map(\.name) == ["Bulbasaur"])
        #expect(localDataSource.saveListCallCount == 1)
        #expect(apiClient.requestedURLs.first ?? nil == PokeAPIEndpoint.pokemonList(offset: 0, limit: 20).url)
    }

    @Test func fetchListFallsBackToCacheWhenNetworkFails() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.noConnection }
        let localDataSource = PokemonLocalDataSourceMock()
        localDataSource.listStorage = [Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)]
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        let result = try await repository.fetchPokemonList(offset: 0, limit: 20)

        #expect(result.map(\.name) == ["Bulbasaur"])
    }

    @Test func fetchListThrowsAppErrorWhenNetworkFailsAndCacheEmpty() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.noConnection }
        let localDataSource = PokemonLocalDataSourceMock()
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        await #expect(throws: AppError.noConnection) {
            try await repository.fetchPokemonList(offset: 0, limit: 20)
        }
    }

    @Test func fetchDetailReturnsNetworkResultAndCachesIt() async throws {
        let apiClient = APIClientMock()
        let localDataSource = PokemonLocalDataSourceMock()
        apiClient.resultProvider = { _ in
            PokemonDetailDTO(
                id: 1,
                name: "bulbasaur",
                height: 7,
                weight: 69,
                baseExperience: 64,
                sprites: PokemonSpritesDTO(frontDefault: nil),
                types: [],
                abilities: [],
                stats: []
            )
        }
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        let result = try await repository.fetchPokemonDetail(id: 1)

        #expect(result.name == "Bulbasaur")
        #expect(localDataSource.saveDetailCallCount == 1)
        #expect(apiClient.requestedURLs.first ?? nil == PokeAPIEndpoint.pokemonDetail(id: 1).url)
    }

    @Test func fetchDetailFallsBackToCacheWhenNetworkFails() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.noConnection }
        let localDataSource = PokemonLocalDataSourceMock()
        let cachedDetail = PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            imageURL: nil,
            heightDecimeters: 7,
            weightHectograms: 69,
            baseExperience: 64,
            types: [],
            abilities: [],
            stats: []
        )
        localDataSource.detailStorage[1] = cachedDetail
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        let result = try await repository.fetchPokemonDetail(id: 1)

        #expect(result == cachedDetail)
    }

    @Test func fetchDetailThrowsAppErrorWhenNetworkFailsAndCacheEmpty() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.invalidResponse(statusCode: 500) }
        let localDataSource = PokemonLocalDataSourceMock()
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        await #expect(throws: AppError.invalidResponse) {
            try await repository.fetchPokemonDetail(id: 1)
        }
    }

    @Test func fetchDetailThrowsNotFoundForA404WithNoCache() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.invalidResponse(statusCode: 404) }
        let localDataSource = PokemonLocalDataSourceMock()
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        await #expect(throws: AppError.notFound) {
            try await repository.fetchPokemonDetail(id: 999_999)
        }
    }

    @Test func fetchDetailFallsBackToCacheEvenOnA404WhenCacheExists() async throws {
        let apiClient = APIClientMock()
        apiClient.resultProvider = { _ in throw NetworkError.invalidResponse(statusCode: 404) }
        let localDataSource = PokemonLocalDataSourceMock()
        let cachedDetail = PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            imageURL: nil,
            heightDecimeters: 7,
            weightHectograms: 69,
            baseExperience: 64,
            types: [],
            abilities: [],
            stats: []
        )
        localDataSource.detailStorage[1] = cachedDetail
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        let result = try await repository.fetchPokemonDetail(id: 1)

        #expect(result == cachedDetail)
    }
}
