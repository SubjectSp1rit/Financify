import Foundation

struct AccountUpdateRequest: Encodable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name,     forKey: .name)
        let balString = NSDecimalNumber(decimal: balance).stringValue
        try container.encode(balString, forKey: .balance)
        try container.encode(currency, forKey: .currency)
    }
}
