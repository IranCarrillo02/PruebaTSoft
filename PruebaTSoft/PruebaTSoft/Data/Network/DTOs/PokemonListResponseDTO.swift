struct PokemonListResponseDTO: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListItemDTO]
}

struct PokemonListItemDTO: Decodable {
    let name: String
    let url: String
}
