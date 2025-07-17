import Foundation

struct TransactionResponse: Decodable, Identifiable {
    var id: Int
    var account: AccountBrief
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
}

extension TransactionResponse {
    private enum CodingKeys: String, CodingKey {
        case id
        case account
        case category
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(Int.self,          forKey: .id)
        account  = try c.decode(AccountBrief.self, forKey: .account)
        category = try c.decode(Category.self,     forKey: .category)

        let amtStr = try c.decode(String.self, forKey: .amount)
        guard let amt = Decimal(string: amtStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount, in: c,
                debugDescription: "Невозможно преобразовать amount '\(amtStr)' в Decimal"
            )
        }
        amount = amt

        let txStr = try c.decode(String.self, forKey: .transactionDate)
        guard let txDate = ISO8601DateFormatter.shmr.dateNormalized(from: txStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .transactionDate, in: c,
                debugDescription: "Неверный формат transactionDate: '\(txStr)'"
            )
        }
        transactionDate = txDate

        comment = try c.decodeIfPresent(String.self, forKey: .comment)

        let createdStr = try c.decode(String.self, forKey: .createdAt)
        let updatedStr = try c.decode(String.self, forKey: .updatedAt)
        guard
            let created = ISO8601DateFormatter.shmr.dateNormalized(from: createdStr),
            let updated = ISO8601DateFormatter.shmr.dateNormalized(from: updatedStr)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: c,
                debugDescription: "Неверный формат createdAt/updatedAt"
            )
        }
        createdAt = created
        updatedAt = updated
    }
}

// TransactionResponse -> Transaction
extension TransactionResponse {
    func convertToTransaction() -> Transaction {
        return Transaction(
            id:                 self.id,
            accountId:          self.account.id,
            categoryId:         self.category.id,
            amount:             self.amount,
            transactionDate:    self.transactionDate,
            comment:            self.comment,
            createdAt:          self.createdAt,
            updatedAt:          self.updatedAt
        )
    }
}
