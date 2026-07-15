@testable import PruebaTSoft

final class FetchPokemonDetailUseCaseMock: FetchPokemonDetailUseCaseProtocol, @unchecked Sendable {
    var result: Result<PokemonDetail, Error> = .failure(AppError.notFound)
    /// 1-based call index -> result, so a test can give the 1st and 2nd calls different
    /// outcomes regardless of the order they're actually consumed in.
    var resultsByCallIndex: [Int: Result<PokemonDetail, Error>] = [:]
    private(set) var requestedIDs: [Int] = []

    /// 1-based index of the call to block (spin-yielding) until `openGate()` is called — lets
    /// a test deterministically make an earlier call resolve after a later one.
    var blockedCallIndex: Int?
    private var released = false
    private var seenCallCount = 0

    func openGate() {
        released = true
    }

    func execute(id: Int) async throws -> PokemonDetail {
        requestedIDs.append(id)
        seenCallCount += 1
        let myCallIndex = seenCallCount
        if blockedCallIndex == myCallIndex {
            while !released {
                await Task.yield()
            }
        }

        if let specific = resultsByCallIndex[myCallIndex] {
            return try specific.get()
        }
        return try result.get()
    }
}
