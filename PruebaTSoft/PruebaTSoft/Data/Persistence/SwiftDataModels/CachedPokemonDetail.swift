import SwiftData

struct CachedAbility: Codable {
    let name: String
    let isHidden: Bool
}

struct CachedStat: Codable {
    let name: String
    let baseValue: Int
}

@Model
final class CachedPokemonDetail {
    @Attribute(.unique) var id: Int
    var name: String
    var imageURLString: String?
    var heightDecimeters: Int
    var weightHectograms: Int
    var baseExperience: Int?
    var types: [String]
    var abilities: [CachedAbility]
    var stats: [CachedStat]

    init(
        id: Int,
        name: String,
        imageURLString: String?,
        heightDecimeters: Int,
        weightHectograms: Int,
        baseExperience: Int?,
        types: [String],
        abilities: [CachedAbility],
        stats: [CachedStat]
    ) {
        self.id = id
        self.name = name
        self.imageURLString = imageURLString
        self.heightDecimeters = heightDecimeters
        self.weightHectograms = weightHectograms
        self.baseExperience = baseExperience
        self.types = types
        self.abilities = abilities
        self.stats = stats
    }
}
