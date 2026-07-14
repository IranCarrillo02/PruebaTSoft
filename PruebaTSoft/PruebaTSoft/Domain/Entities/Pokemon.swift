import Foundation

struct Pokemon: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let imageURL: URL?
}
