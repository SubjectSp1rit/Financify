import Foundation

struct AccountCreateRequest: Encodable {
    var name: String
    var balance: Decimal
    var currency: String
}
