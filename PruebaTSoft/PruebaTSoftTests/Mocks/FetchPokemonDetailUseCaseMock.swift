@testable import PruebaTSoft

final class FetchPokemonDetailUseCaseMock: FetchPokemonDetailUseCaseProtocol, @unchecked Sendable {
    var result: Result<PokemonDetail, Error> = .failure(AppError.notFound)
    private(set) var requestedIDs: [Int] = []

    func execute(id: Int) async throws -> PokemonDetail {
        requestedIDs.append(id)
        return try result.get()
    }
}
