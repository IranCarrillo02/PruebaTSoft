@testable import PruebaTSoft

final class PokemonLocalDataSourceMock: PokemonLocalDataSourceProtocol, @unchecked Sendable {
    var listStorage: [Pokemon] = []
    var detailStorage: [Int: PokemonDetail] = [:]
    var shouldThrowOnSave = false

    private(set) var saveListCallCount = 0
    private(set) var saveDetailCallCount = 0

    @MainActor
    func cachedList(offset: Int, limit: Int) throws -> [Pokemon] {
        Array(listStorage.dropFirst(offset).prefix(limit))
    }

    @MainActor
    func saveList(_ pokemons: [Pokemon], startingAt offset: Int) throws {
        saveListCallCount += 1
        if shouldThrowOnSave { throw AppError.persistenceFailed }
        for (index, pokemon) in pokemons.enumerated() {
            let targetIndex = offset + index
            while listStorage.count <= targetIndex {
                listStorage.append(pokemon)
            }
            listStorage[targetIndex] = pokemon
        }
    }

    @MainActor
    func cachedDetail(id: Int) throws -> PokemonDetail? {
        detailStorage[id]
    }

    @MainActor
    func saveDetail(_ detail: PokemonDetail) throws {
        saveDetailCallCount += 1
        if shouldThrowOnSave { throw AppError.persistenceFailed }
        detailStorage[detail.id] = detail
    }
}
