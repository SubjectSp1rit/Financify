import Foundation

/// Cколько потрачено в категории за период
struct CategorySummary {
    let category: Category
    let total: Decimal
    var percent: Double = 0
}
