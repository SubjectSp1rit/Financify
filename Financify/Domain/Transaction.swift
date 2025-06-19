import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    let createdAt: Date
    let updatedAt: Date
}
