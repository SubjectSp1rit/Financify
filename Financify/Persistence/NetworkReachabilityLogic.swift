import Foundation

protocol NetworkReachabilityLogic: Sendable {
    /// Асинхронный поток, который транслирует изменения статуса сети
    var statusStream: AsyncStream<NetworkStatus> { get }
    
    var currentStatus: NetworkStatus { get }
}
