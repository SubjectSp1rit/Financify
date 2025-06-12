import Foundation

struct BankAccount: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    var balance: Decimal
    var currency: String
    let createdAt: Date
    let updatedAt: Date
}
