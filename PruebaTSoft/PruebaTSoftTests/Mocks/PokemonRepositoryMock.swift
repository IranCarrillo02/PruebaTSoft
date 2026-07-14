@testable import PruebaTSoft

final class PokemonRepositoryMock: PokemonRepositoryProtocol, @unchecked Sendable {
    var listResult: Result<[Pokemon], Error> = .success([])
    var detailResult: Result<PokemonDetail, Error> = .failure(AppError.notFound)

    private(set) var lastListRequest: (offset: Int, limit: Int)?
    private(set) var lastDetailRequest: Int?

    func fetchPokemonList(offset: Int, limit: Int) async throws -> [Pokemon] {
        lastListRequest = (offset, limit)
        return try listResult.get()
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        lastDetailRequest = id
        return try detailResult.get()
    }
}
