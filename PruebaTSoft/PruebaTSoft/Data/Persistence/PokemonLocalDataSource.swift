import Foundation
import SwiftData

protocol PokemonLocalDataSourceProtocol: Sendable {
    @MainActor func cachedList(offset: Int, limit: Int) throws -> [Pokemon]
    @MainActor func saveList(_ pokemons: [Pokemon], startingAt offset: Int) throws
    @MainActor func cachedDetail(id: Int) throws -> PokemonDetail?
    @MainActor func saveDetail(_ detail: PokemonDetail) throws
}

@MainActor
final class PokemonLocalDataSource: PokemonLocalDataSourceProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private var context: ModelContext { modelContainer.mainContext }

    func cachedList(offset: Int, limit: Int) throws -> [Pokemon] {
        let descriptor = FetchDescriptor<CachedPokemon>(
            predicate: #Predicate { $0.order >= offset && $0.order < offset + limit },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor).map(PokemonMapper.toDomain(cached:))
    }

    func saveList(_ pokemons: [Pokemon], startingAt offset: Int) throws {
        for (index, pokemon) in pokemons.enumerated() {
            let order = offset + index
            let pokemonID = pokemon.id
            let descriptor = FetchDescriptor<CachedPokemon>(predicate: #Predicate { $0.id == pokemonID })
            if let existing = try context.fetch(descriptor).first {
                existing.name = pokemon.name
                existing.imageURLString = pokemon.imageURL?.absoluteString
                existing.order = order
            } else {
                context.insert(PokemonMapper.toCached(pokemon, order: order))
            }
        }
        try context.save()
    }

    func cachedDetail(id: Int) throws -> PokemonDetail? {
        let descriptor = FetchDescriptor<CachedPokemonDetail>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first.map(PokemonMapper.toDomain(cached:))
    }

    func saveDetail(_ detail: PokemonDetail) throws {
        let detailID = detail.id
        let descriptor = FetchDescriptor<CachedPokemonDetail>(predicate: #Predicate { $0.id == detailID })
        if let existing = try context.fetch(descriptor).first {
            existing.name = detail.name
            existing.imageURLString = detail.imageURL?.absoluteString
            existing.heightDecimeters = detail.heightDecimeters
            existing.weightHectograms = detail.weightHectograms
            existing.baseExperience = detail.baseExperience
            existing.types = detail.types
            existing.abilities = detail.abilities.map { CachedAbility(name: $0.name, isHidden: $0.isHidden) }
            existing.stats = detail.stats.map { CachedStat(name: $0.name, baseValue: $0.baseValue) }
        } else {
            context.insert(PokemonMapper.toCached(detail))
        }
        try context.save()
    }
}
