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
            var fatalOps: [PendingOperation] = [] // Список для невыполнимых операций

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
                } catch let error as NetworkError {
                    // Анализируем тип ошибки
                    if case .serverError(let statusCode, _) = error, (400...499).contains(statusCode) {
                        // Это фатальная ошибка клиента (400, 404)
                        print("SynchronizationService: Encountered fatal error (status \(statusCode)) for operation on path \(operation.endpointPath). Discarding operation.")
                        fatalOps.append(operation)
                    } else {
                        // Это временная ошибка (5xx) - ничего не делаем, попробуем позже
                        print("SynchronizationService: Encountered temporary error for operation on path \(operation.endpointPath). Will retry later. Error: \(error.localizedDescription)")
                    }
                } catch {
                    // Любая другая временная ошибка
                    print("SynchronizationService: Encountered temporary error for operation on path \(operation.endpointPath). Will retry later. Error: \(error.localizedDescription)")
                }
            }

            // Удаляем и успешные, и фатальные операции
            let opsToDelete = successfulOps + fatalOps
            if !opsToDelete.isEmpty {
                try await backupService.delete(opsToDelete)
                print("SynchronizationService: Deleted \(opsToDelete.count) processed operations (\(successfulOps.count) successful, \(fatalOps.count) fatal).")
            }

        } catch {
            print("SynchronizationService: A critical error occurred during synchronization fetch: \(error)")
        }
    }
}
