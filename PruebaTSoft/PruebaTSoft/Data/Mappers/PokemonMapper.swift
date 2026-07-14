import Foundation

enum PokemonMapper {

    // MARK: - Network DTO -> Domain

    static func toDomain(listItem: PokemonListItemDTO) -> Pokemon? {
        guard let id = extractID(from: listItem.url) else { return nil }
        return Pokemon(id: id, name: listItem.name.capitalized, imageURL: spriteURL(for: id))
    }

    static func toDomain(detail dto: PokemonDetailDTO) -> PokemonDetail {
        PokemonDetail(
            id: dto.id,
            name: dto.name.capitalized,
            imageURL: dto.sprites.frontDefault.flatMap(URL.init(string:)) ?? spriteURL(for: dto.id),
            heightDecimeters: dto.height,
            weightHectograms: dto.weight,
            baseExperience: dto.baseExperience,
            types: dto.types.map { $0.type.name.capitalized },
            abilities: dto.abilities.map { PokemonAbility(name: $0.ability.name.capitalized, isHidden: $0.isHidden) },
            stats: dto.stats.map { PokemonStat(name: $0.stat.name, baseValue: $0.baseStat) }
        )
    }

    // MARK: - SwiftData cache <-> Domain

    static func toDomain(cached: CachedPokemon) -> Pokemon {
        Pokemon(
            id: cached.id,
            name: cached.name,
            imageURL: cached.imageURLString.flatMap(URL.init(string:))
        )
    }

    static func toCached(_ pokemon: Pokemon, order: Int) -> CachedPokemon {
        CachedPokemon(
            id: pokemon.id,
            name: pokemon.name,
            imageURLString: pokemon.imageURL?.absoluteString,
            order: order
        )
    }

    static func toDomain(cached: CachedPokemonDetail) -> PokemonDetail {
        PokemonDetail(
            id: cached.id,
            name: cached.name,
            imageURL: cached.imageURLString.flatMap(URL.init(string:)),
            heightDecimeters: cached.heightDecimeters,
            weightHectograms: cached.weightHectograms,
            baseExperience: cached.baseExperience,
            types: cached.types,
            abilities: cached.abilities.map { PokemonAbility(name: $0.name, isHidden: $0.isHidden) },
            stats: cached.stats.map { PokemonStat(name: $0.name, baseValue: $0.baseValue) }
        )
    }

    static func toCached(_ detail: PokemonDetail) -> CachedPokemonDetail {
        CachedPokemonDetail(
            id: detail.id,
            name: detail.name,
            imageURLString: detail.imageURL?.absoluteString,
            heightDecimeters: detail.heightDecimeters,
            weightHectograms: detail.weightHectograms,
            baseExperience: detail.baseExperience,
            types: detail.types,
            abilities: detail.abilities.map { CachedAbility(name: $0.name, isHidden: $0.isHidden) },
            stats: detail.stats.map { CachedStat(name: $0.name, baseValue: $0.baseValue) }
        )
    }

    // MARK: - Helpers

    static func extractID(from urlString: String) -> Int? {
        let trimmed = urlString.hasSuffix("/") ? String(urlString.dropLast()) : urlString
        guard let lastComponent = trimmed.split(separator: "/").last else { return nil }
        return Int(lastComponent)
    }

    static func spriteURL(for id: Int) -> URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
}
