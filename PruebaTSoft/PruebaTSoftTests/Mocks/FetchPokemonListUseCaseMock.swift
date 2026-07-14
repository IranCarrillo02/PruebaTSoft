@testable import PruebaTSoft

final class FetchPokemonListUseCaseMock: FetchPokemonListUseCaseProtocol, @unchecked Sendable {
    var resultsByOffset: [Int: Result<[Pokemon], Error>] = [:]
    private(set) var requestedOffsets: [Int] = []

    func execute(offset: Int, limit: Int) async throws -> [Pokemon] {
        requestedOffsets.append(offset)
        guard let result = resultsByOffset[offset] else { return [] }
        return try result.get()
    }
}
