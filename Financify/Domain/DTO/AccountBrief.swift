import Foundation

struct AccountBrief: Codable, Identifiable {
    var id: Int
    var name: String
    var balance: Decimal
    var currency: String
}

extension AccountBrief {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case balance
        case currency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id       = try container.decode(Int.self,    forKey: .id)
        name     = try container.decode(String.self, forKey: .name)
        currency = try container.decode(String.self, forKey: .currency)

        let balanceStr = try container.decode(String.self, forKey: .balance)
        guard let bal = Decimal(string: balanceStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .balance,
                in: container,
                debugDescription: "Невозможно преобразовать balance '\(balanceStr)' в Decimal"
            )
        }
        balance = bal
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id,       forKey: .id)
        try container.encode(name,     forKey: .name)
        try container.encode(currency, forKey: .currency)
        let balanceStr = NSDecimalNumber(decimal: balance).stringValue
        try container.encode(balanceStr, forKey: .balance)
    }
}
