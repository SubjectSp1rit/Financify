import Foundation

extension Transaction {
    private static let csvDateFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()
    
    static func parse(csvLine: String, delimiter: Character = ",") -> Transaction? {
        let columns = csvLine
            .split(separator: delimiter, omittingEmptySubsequences: false)
            .map(String.init)
        
        guard columns.count == 8 else { return nil }
        
        guard
            let id = Int(columns[0]),
            let accountId = Int(columns[1]),
            let categoryId = Int(columns[2]),
            let amount = Decimal(string: columns[3]),
            let transactionDate = csvDateFormatter.date(from: columns[4]),
            let createdAt = csvDateFormatter.date(from: columns[6]),
            let updatedAt = csvDateFormatter.date(from: columns[7])
        else {
            return nil
        }
        
        let comment = columns[5]
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .replacingOccurrences(of: "\"\"", with: "\"")
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
