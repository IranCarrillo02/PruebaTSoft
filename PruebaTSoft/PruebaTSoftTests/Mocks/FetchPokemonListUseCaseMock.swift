@testable import PruebaTSoft

final class FetchPokemonListUseCaseMock: FetchPokemonListUseCaseProtocol, @unchecked Sendable {
    var resultsByOffset: [Int: Result<[Pokemon], Error>] = [:]
    /// Keyed by `limit` — lets tests give the search index fetch (a distinctly large limit)
    /// a different dataset than regular pagination calls, without touching existing tests
    /// that only ever set `resultsByOffset`.
    var resultsByLimit: [Int: Result<[Pokemon], Error>] = [:]
    private(set) var requestedOffsets: [Int] = []
    private(set) var requestedCalls: [(offset: Int, limit: Int)] = []

    /// Offsets whose calls should block (spin-yielding, no real sleep) until enough calls have
    /// been "released" via `openGate(for:callsToAllow:)` — lets a test deterministically control
    /// completion order (including which of two calls to the *same* offset resolves first) to
    /// reproduce out-of-order async completion, instead of guessing at wall-clock timing.
    private var gatedOffsets: Set<Int> = []
    private var releasedCallCountByOffset: [Int: Int] = [:]
    private var seenCallCountByOffset: [Int: Int] = [:]

    func gate(offset: Int) {
        gatedOffsets.insert(offset)
    }

    func openGate(for offset: Int, callsToAllow: Int = 1) {
        releasedCallCountByOffset[offset, default: 0] += callsToAllow
    }

    func execute(offset: Int, limit: Int) async throws -> [Pokemon] {
        requestedOffsets.append(offset)
        requestedCalls.append((offset, limit))

        if gatedOffsets.contains(offset) {
            seenCallCountByOffset[offset, default: 0] += 1
            let myCallIndex = seenCallCountByOffset[offset]!
            while (releasedCallCountByOffset[offset] ?? 0) < myCallIndex {
                await Task.yield()
            }
        }

        if let result = resultsByLimit[limit] {
            return try result.get()
        }
        guard let result = resultsByOffset[offset] else { return [] }
        return try result.get()
    }
}
