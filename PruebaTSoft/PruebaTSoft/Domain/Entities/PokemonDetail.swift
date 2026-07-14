import Foundation

struct PokemonDetail: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let imageURL: URL?
    let heightDecimeters: Int
    let weightHectograms: Int
    let baseExperience: Int?
    let types: [String]
    let abilities: [PokemonAbility]
    let stats: [PokemonStat]

    var heightInMeters: Double { Double(heightDecimeters) / 10 }
    var weightInKilograms: Double { Double(weightHectograms) / 10 }
}

struct PokemonAbility: Hashable, Sendable {
    let name: String
    let isHidden: Bool
}

struct PokemonStat: Hashable, Sendable {
    let name: String
    let baseValue: Int
}
