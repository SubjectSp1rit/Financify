import Foundation

struct AccountUpdateRequest: Codable {
    var name: String
    var balance: Decimal
    var currency: String
}

extension AccountUpdateRequest {
    private enum CodingKeys: String, CodingKey {
        case name
        case balance
        case currency
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        currency = try container.decode(String.self, forKey: .currency)

        let balanceString = try container.decode(String.self, forKey: .balance)
        guard let decimalBalance = Decimal(string: balanceString) else {
            throw DecodingError.dataCorruptedError(forKey: .balance, in: container, debugDescription: "Balance string is not a valid decimal.")
        }
        balance = decimalBalance
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name,     forKey: .name)
        let balString = NSDecimalNumber(decimal: balance).stringValue
        try container.encode(balString, forKey: .balance)
        try container.encode(currency, forKey: .currency)
    }
}
