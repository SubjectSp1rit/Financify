import Foundation

struct TransactionRequest: Encodable {
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String
}
