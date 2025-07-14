import Foundation

struct AccountBrief: Codable, Identifiable {
    var id: Int
    var name: String
    var balance: Decimal
    var currency: String
}
