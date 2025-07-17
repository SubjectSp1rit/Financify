import Foundation

struct TransactionRequest: Encodable {
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String
}

extension TransactionRequest {
    private enum CodingKeys: String, CodingKey {
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId,   forKey: .accountId)
        try container.encode(categoryId,  forKey: .categoryId)
        let amountString = NSDecimalNumber(decimal: amount).stringValue
        try container.encode(amountString, forKey: .amount)
        let dateString = ISO8601DateFormatter.shmr.string(from: transactionDate)
        try container.encode(dateString,   forKey: .transactionDate)
        try container.encode(comment,      forKey: .comment)
    }
}
