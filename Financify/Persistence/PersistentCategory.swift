import Foundation
import SwiftData

@Model
final class PersistentCategory: Sendable {
    @Attribute(.unique)
    var id: Int
    var name: String
    
    private var emojiString: String
    
    @Transient
    var emoji: Character {
        get {
            return emojiString.first!
        }
        set {
            self.emojiString = String(newValue)
        }
    }
    
    var isIncome: Bool
    
    init(id: Int, name: String, emoji: Character, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emojiString = String(emoji)
        self.isIncome = isIncome
    }
    
    convenience init(from domain: Category) {
        self.init(
            id: domain.id,
            name: domain.name,
            emoji: domain.emoji,
            isIncome: domain.isIncome
        )
    }
    
    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji,
            isIncome: isIncome
        )
    }
}
