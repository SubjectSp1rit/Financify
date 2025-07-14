import Foundation

struct TransactionResponse: Decodable, Identifiable {
    var id: Int
    var account: AccountBrief
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date
}
