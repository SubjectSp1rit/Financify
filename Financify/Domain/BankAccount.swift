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

extension BankAccount {
    func convertToAccountUpdateRequest() -> AccountUpdateRequest {
        return AccountUpdateRequest(
            name:       self.name,
            balance:    self.balance,
            currency:   self.currency
        )
    }
}

extension BankAccount {
    private enum CodingKeys: String, CodingKey {
        case id, userId, name, balance, currency, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id     = try c.decode(Int.self,    forKey: .id)
        userId = try c.decode(Int.self,    forKey: .userId)
        name   = try c.decode(String.self, forKey: .name)

        let balStr = try c.decode(String.self, forKey: .balance)
        guard let bal = Decimal(string: balStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .balance, in: c,
                debugDescription: "balance должен быть строкой-числом"
            )
        }
        balance = bal

        currency = try c.decode(String.self, forKey: .currency)

        let createdStr = try c.decode(String.self, forKey: .createdAt)
        let updatedStr = try c.decode(String.self, forKey: .updatedAt)
        guard
            let created = ISO8601DateFormatter.shmr.dateNormalized(from: createdStr),
            let updated = ISO8601DateFormatter.shmr.dateNormalized(from: updatedStr)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: c,
                debugDescription: "createdAt/updatedAt неверного формата"
            )
        }
        createdAt = created
        updatedAt = updated
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,     forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(name,   forKey: .name)
        try c.encode(String(describing: balance), forKey: .balance)
        try c.encode(currency, forKey: .currency)

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
