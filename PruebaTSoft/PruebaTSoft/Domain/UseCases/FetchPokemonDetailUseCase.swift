protocol FetchPokemonDetailUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> PokemonDetail
}

struct FetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol {
    private let repository: PokemonRepositoryProtocol

    init(repository: PokemonRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> PokemonDetail {
        try await repository.fetchPokemonDetail(id: id)
    }
}
