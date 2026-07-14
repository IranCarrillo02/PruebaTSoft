import SwiftData

@Model
final class CachedPokemon {
    @Attribute(.unique) var id: Int
    var name: String
    var imageURLString: String?
    var order: Int

    init(id: Int, name: String, imageURLString: String?, order: Int) {
        self.id = id
        self.name = name
        self.imageURLString = imageURLString
        self.order = order
    }
}
