import Foundation

extension Transaction {
    var jsonObject: Any {
        guard let data = try? JSONEncoder().encode(self),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return [:] as [String: Any]
        }
        
        return json
    }
}
