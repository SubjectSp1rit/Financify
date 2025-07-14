import Foundation

struct AccountState: Codable, Identifiable {
    var id: Int
    var name: String
    var balance: Decimal
    var currency: String
}
