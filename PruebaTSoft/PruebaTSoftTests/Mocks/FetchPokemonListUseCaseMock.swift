@testable import PruebaTSoft

final class FetchPokemonListUseCaseMock: FetchPokemonListUseCaseProtocol, @unchecked Sendable {
    var resultsByOffset: [Int: Result<[Pokemon], Error>] = [:]
    /// Keyed by `limit` — lets tests give the search index fetch (a distinctly large limit)
    /// a different dataset than regular pagination calls, without touching existing tests
    /// that only ever set `resultsByOffset`.
    var resultsByLimit: [Int: Result<[Pokemon], Error>] = [:]
    private(set) var requestedOffsets: [Int] = []
    private(set) var requestedCalls: [(offset: Int, limit: Int)] = []

    func execute(offset: Int, limit: Int) async throws -> [Pokemon] {
        requestedOffsets.append(offset)
        requestedCalls.append((offset, limit))
        if let result = resultsByLimit[limit] {
            return try result.get()
        }
        guard let result = resultsByOffset[offset] else { return [] }
        return try result.get()
    }
}
