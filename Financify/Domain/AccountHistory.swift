import Foundation

struct AccountHistory: Codable, Identifiable {
    var id: Int
    var accountId: Int
    var changeType: String
    var previousState: AccountState
    var newState: AccountState
    var changeTimestamp: Date
    var createdAt: Date
}
