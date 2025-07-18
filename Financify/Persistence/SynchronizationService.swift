import Foundation
import Alamofire

protocol SynchronizationServiceLogic: Actor {
    func synchronize() async
}

final actor SynchronizationService: SynchronizationServiceLogic {
    private let backupService: BackupServiceLogic
    private let reachability: NetworkReachabilityLogic
    private let client: NetworkClient

    init(
        backupService: BackupServiceLogic,
        reachability: NetworkReachabilityLogic,
        client: NetworkClient = NetworkClient()
    ) {
        self.backupService = backupService
        self.reachability = reachability
        self.client = client
    }

    func synchronize() async {
        guard reachability.currentStatus == .online else { return }

        do {
            let pending = try await backupService.fetchAll()
            guard !pending.isEmpty else { return }

            print("SynchronizationService: Starting synchronization of \(pending.count) pending operations.")

            var successfulOps: [PendingOperation] = []

            for operation in pending {
                do {
                    let method = HTTPMethod(rawValue: operation.httpMethod)
                    let url = APIEndpoint.baseURL.appendingPathComponent(operation.endpointPath)
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpBody = operation.payload
                    urlRequest.method = method
                    if operation.payload != nil {
                        urlRequest.headers.add(.contentType("application/json"))
                    }

                    _ = try await client.requestStatus(with: urlRequest)
                    
                    // Если запрос прошел без ошибок, добавляем операцию в список на удаление
                    successfulOps.append(operation)
                    print("SynchronizationService: Successfully synced operation for path \(operation.endpointPath).")
                } catch {
                    // Если одна операция не удалась, логируем ошибку и продолжаем с остальными
                    print("SynchronizationService: Failed to sync operation for path \(operation.endpointPath). Error: \(error.localizedDescription)")
                }
            }

            if !successfulOps.isEmpty {
                try await backupService.delete(successfulOps)
                print("SynchronizationService: Deleted \(successfulOps.count) successfully synchronized operations.")
            }

        } catch {
            print("SynchronizationService: A critical error occurred during synchronization fetch: \(error)")
        }
    }
}
