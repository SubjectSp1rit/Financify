import Foundation
import SwiftData

@Model
final class PendingOperation: Sendable {
    @Attribute(.unique)
    var id: UUID
    
    var timestamp: Date
    
    var httpMethod: String
    
    var endpointPath: String
    
    var payload: Data?

    init(httpMethod: String, endpointPath: String, payload: Data? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.httpMethod = httpMethod
        self.endpointPath = endpointPath
        self.payload = payload
    }
}
