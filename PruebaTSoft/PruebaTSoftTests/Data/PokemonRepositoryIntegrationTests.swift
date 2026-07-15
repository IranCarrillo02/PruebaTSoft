import Foundation
import SwiftData
import Testing
@testable import PruebaTSoft

@Suite(.serialized)
@MainActor
struct PokemonRepositoryIntegrationTests {

    private static let listJSON = Data("""
    {
        "count": 1302,
        "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
        "previous": null,
        "results": [
            { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" }
        ]
    }
    """.utf8)

    private static let detailJSON = Data("""
    {
        "id": 1,
        "name": "bulbasaur",
        "height": 7,
        "weight": 69,
        "base_experience": 64,
        "sprites": { "front_default": "https://example.com/1.png" },
        "types": [ { "type": { "name": "grass" } } ],
        "abilities": [ { "ability": { "name": "overgrow" }, "is_hidden": false } ],
        "stats": [ { "base_stat": 45, "stat": { "name": "hp" } } ]
    }
    """.utf8)

    private func makeRepository() throws -> PokemonRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CachedPokemon.self, CachedPokemonDetail.self,
            configurations: configuration
        )
        let apiClient = APIClient(session: URLProtocolStub.makeSession())
        let localDataSource = PokemonLocalDataSource(modelContainer: container)
        return PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)
    }

    @Test func fetchListDecodesRealJSONOverTheNetworkStackAndPersistsIt() async throws {
        URLProtocolStub.reset()
        let listURL = try #require(PokeAPIEndpoint.pokemonList(offset: 0, limit: 20).url)
        URLProtocolStub.stub(url: listURL, data: Self.listJSON)
        let repository = try makeRepository()

        let pokemons = try await repository.fetchPokemonList(offset: 0, limit: 20)

        #expect(pokemons.map(\.name) == ["Bulbasaur"])
        #expect(pokemons.first?.imageURL?.absoluteString.contains("1.png") == true)
    }

    @Test func fetchListFallsBackToPersistedCacheWhenNetworkIsUnavailable() async throws {
        URLProtocolStub.reset()
        let listURL = try #require(PokeAPIEndpoint.pokemonList(offset: 0, limit: 20).url)
        URLProtocolStub.stub(url: listURL, data: Self.listJSON)
        let repository = try makeRepository()

        _ = try await repository.fetchPokemonList(offset: 0, limit: 20)

        URLProtocolStub.reset() // network now "unreachable" for this URL
        let fallbackResult = try await repository.fetchPokemonList(offset: 0, limit: 20)

        #expect(fallbackResult.map(\.name) == ["Bulbasaur"])
    }

    @Test func fetchDetailDecodesRealJSONOverTheNetworkStackAndPersistsIt() async throws {
        URLProtocolStub.reset()
        let detailURL = try #require(PokeAPIEndpoint.pokemonDetail(id: 1).url)
        URLProtocolStub.stub(url: detailURL, data: Self.detailJSON)
        let repository = try makeRepository()

        let detail = try await repository.fetchPokemonDetail(id: 1)

        #expect(detail.name == "Bulbasaur")
        #expect(detail.types == ["Grass"])
        #expect(detail.abilities == [PokemonAbility(name: "Overgrow", isHidden: false)])
        #expect(detail.stats == [PokemonStat(name: "hp", baseValue: 45)])
    }

    @Test func fetchDetailFallsBackToPersistedCacheWhenNetworkIsUnavailable() async throws {
        URLProtocolStub.reset()
        let detailURL = try #require(PokeAPIEndpoint.pokemonDetail(id: 1).url)
        URLProtocolStub.stub(url: detailURL, data: Self.detailJSON)
        let repository = try makeRepository()

        _ = try await repository.fetchPokemonDetail(id: 1)

        URLProtocolStub.reset()
        let fallbackDetail = try await repository.fetchPokemonDetail(id: 1)

        #expect(fallbackDetail.name == "Bulbasaur")
    }

    @Test func fetchDetailForA404ResponseThrowsNotFoundWhenThereIsNoCache() async throws {
        URLProtocolStub.reset()
        let missingID = 999_999
        let detailURL = try #require(PokeAPIEndpoint.pokemonDetail(id: missingID).url)
        URLProtocolStub.stub(url: detailURL, statusCode: 404, data: Data("{\"detail\":\"Not found.\"}".utf8))
        let repository = try makeRepository()

        await #expect(throws: AppError.notFound) {
            try await repository.fetchPokemonDetail(id: missingID)
        }
    }
}
