import Foundation

struct AccountUpdateRequest: Encodable {
    var name: String
    var balance: Decimal
    var currency: String
}
