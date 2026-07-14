struct PokemonDetailDTO: Decodable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let baseExperience: Int?
    let sprites: PokemonSpritesDTO
    let types: [PokemonTypeSlotDTO]
    let abilities: [PokemonAbilitySlotDTO]
    let stats: [PokemonStatSlotDTO]
}

struct PokemonSpritesDTO: Decodable {
    let frontDefault: String?
}

struct PokemonTypeSlotDTO: Decodable {
    let type: NamedResourceDTO
}

struct PokemonAbilitySlotDTO: Decodable {
    let ability: NamedResourceDTO
    let isHidden: Bool
}

struct PokemonStatSlotDTO: Decodable {
    let baseStat: Int
    let stat: NamedResourceDTO
}
