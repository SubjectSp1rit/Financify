import Foundation
import Network

@MainActor
final class ConnectivityManager: ObservableObject {
    static let shared = ConnectivityManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityManagerQueue")
    
    @Published var isOnline: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
