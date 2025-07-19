import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: Int
    let accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
}

extension Transaction {
    func convertToTransactionRequest() -> TransactionRequest {
        return TransactionRequest(
            accountId:          self.accountId,
            categoryId:         self.categoryId,
            amount:             self.amount,
            transactionDate:    self.transactionDate,
            comment:            self.comment ?? ""
        )
    }
}

extension Transaction {
    private enum CodingKeys: String, CodingKey {
        case id, accountId, categoryId
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(Int.self, forKey: .id)
        accountId  = try c.decode(Int.self, forKey: .accountId)
        categoryId = try c.decode(Int.self, forKey: .categoryId)

        let amtStr = try c.decode(String.self, forKey: .amount)
        guard let amt = Decimal(string: amtStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount, in: c,
                debugDescription: "Невозможно преобразовать amount из '\(amtStr)'"
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

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(accountId, forKey: .accountId)
        try c.encode(categoryId, forKey: .categoryId)

        let amtString = NSDecimalNumber(decimal: amount).stringValue
        try c.encode(amtString, forKey: .amount)

        try c.encode(
            ISO8601DateFormatter.shmr.string(from: transactionDate),
            forKey: .transactionDate
        )

        try c.encodeIfPresent(comment, forKey: .comment)

        try c.encode(
            ISO8601DateFormatter.shmr.string(from: createdAt),
            forKey: .createdAt
        )
        try c.encode(
            ISO8601DateFormatter.shmr.string(from: updatedAt),
            forKey: .updatedAt
        )
    }
}

