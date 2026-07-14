protocol FetchPokemonListUseCaseProtocol: Sendable {
    func execute(offset: Int, limit: Int) async throws -> [Pokemon]
}

struct FetchPokemonListUseCase: FetchPokemonListUseCaseProtocol {
    private let repository: PokemonRepositoryProtocol

    init(repository: PokemonRepositoryProtocol) {
        self.repository = repository
    }

    func execute(offset: Int, limit: Int) async throws -> [Pokemon] {
        try await repository.fetchPokemonList(offset: offset, limit: limit)
    }
}
