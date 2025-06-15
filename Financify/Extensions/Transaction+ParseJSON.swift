import Foundation

extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: jsonObject,
            options: []
        ),
              let transaction = try? JSONDecoder().decode(
                Transaction.self,
                from: data
              ) else {
            return nil
        }
        
        return transaction
    }
}
