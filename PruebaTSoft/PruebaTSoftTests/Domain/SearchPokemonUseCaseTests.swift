import Testing
@testable import PruebaTSoft

struct SearchPokemonUseCaseTests {

    private let pokemons = [
        Pokemon(id: 1, name: "Bulbasaur", imageURL: nil),
        Pokemon(id: 4, name: "Charmander", imageURL: nil),
        Pokemon(id: 6, name: "Charizard", imageURL: nil)
    ]

    @Test func executeFiltersCaseInsensitivelyBySubstring() {
        let useCase = SearchPokemonUseCase()

        let result = useCase.execute(query: "CHAR", in: pokemons)

        #expect(result.map(\.name) == ["Charmander", "Charizard"])
    }

    @Test func executeReturnsEmptyForBlankQuery() {
        let useCase = SearchPokemonUseCase()

        #expect(useCase.execute(query: "   ", in: pokemons).isEmpty)
    }

    @Test func executeReturnsEmptyWhenNothingMatches() {
        let useCase = SearchPokemonUseCase()

        #expect(useCase.execute(query: "mewtwo", in: pokemons).isEmpty)
    }

    @Test func executeTrimsWhitespaceAroundTheQuery() {
        let useCase = SearchPokemonUseCase()

        let result = useCase.execute(query: "  bulba  ", in: pokemons)

        #expect(result.map(\.name) == ["Bulbasaur"])
    }
}
