protocol PokemonRepositoryProtocol: Sendable {
    func fetchPokemonList(offset: Int, limit: Int) async throws -> [Pokemon]
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail
}
