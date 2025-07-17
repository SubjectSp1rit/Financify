import Foundation

protocol NetworkReachabilityLogic {
    var statusStream: AsyncStream<NetworkStatus> { get }
    
    var currentStatus: NetworkStatus { get }
}
