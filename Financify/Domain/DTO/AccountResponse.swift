import Foundation

struct AccountResponse: Decodable, Identifiable {
    var id: Int
    var name: String
    var balance: Decimal
    var currency: String
    var incomeStats: [StatItem]
    var expenseStats: [StatItem]
    var createdAt: Date
    var updatedAt: Date
}
