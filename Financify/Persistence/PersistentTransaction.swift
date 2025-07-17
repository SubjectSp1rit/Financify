import Foundation
import SwiftData

@Model
final class PersistentTransaction {
    @Attribute(.unique)
    var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    convenience init(from domain: Transaction) {
        self.init(
            id: domain.id,
            accountId: domain.accountId,
            categoryId: domain.categoryId,
            amount: domain.amount,
            transactionDate: domain.transactionDate,
            comment: domain.comment,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
    
    func toDomain() -> Transaction {
        Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
