import Foundation

struct TransactionRequest: Codable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        comment = try container.decode(String.self, forKey: .comment)

        let amountString = try container.decode(String.self, forKey: .amount)
        guard let decimalAmount = Decimal(string: amountString) else {
            throw DecodingError.dataCorruptedError(forKey: .amount, in: container, debugDescription: "Amount string is not a valid decimal.")
        }
        amount = decimalAmount

        let dateString = try container.decode(String.self, forKey: .transactionDate)
        guard let date = ISO8601DateFormatter.shmr.dateNormalized(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .transactionDate, in: container, debugDescription: "Date string is not a valid ISO8601 date.")
        }
        transactionDate = date
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
