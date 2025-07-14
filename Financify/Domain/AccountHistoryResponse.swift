import Foundation

struct AccountHistoryResponse: Codable {
    var accountId: Int
    var accountName: String
    var currency: String
    var currentBalance: Decimal
    var history: [AccountHistory]
}
