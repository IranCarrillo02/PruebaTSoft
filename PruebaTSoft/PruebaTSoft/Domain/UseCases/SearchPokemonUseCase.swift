import Foundation

protocol SearchPokemonUseCaseProtocol: Sendable {
    func execute(query: String, in pokemons: [Pokemon]) -> [Pokemon]
}

struct SearchPokemonUseCase: SearchPokemonUseCaseProtocol {
    func execute(query: String, in pokemons: [Pokemon]) -> [Pokemon] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return [] }
        return pokemons.filter { $0.name.lowercased().contains(normalizedQuery) }
    }
}
