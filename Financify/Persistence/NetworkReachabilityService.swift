import Foundation
import Network

final class NetworkReachabilityService: NetworkReachabilityLogic {
    
    // MARK: - Properties
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.financify.network-monitor")
    
    private var continuation: AsyncStream<NetworkStatus>.Continuation?
    
    private(set) var currentStatus: NetworkStatus = .offline {
        didSet {
            continuation?.yield(currentStatus)
        }
    }

    lazy var statusStream: AsyncStream<NetworkStatus> = {
        AsyncStream { continuation in
            self.continuation = continuation
            self.continuation?.yield(self.currentStatus)
        }
    }()

    // MARK: - Lifecycle
    init() {
        self.monitor = NWPathMonitor()
        self.startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Private Methods
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .satisfied {
                self.currentStatus = .online
            } else {
                self.currentStatus = .offline
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}
