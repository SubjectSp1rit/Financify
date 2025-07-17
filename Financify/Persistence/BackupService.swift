import Foundation
import SwiftData

import Foundation

protocol BackupServiceLogic {
    /// Добавляет новую операцию в очередь на синхронизацию.
    /// - Parameters:
    ///   - httpMethod: HTTP-метод запроса.
    ///   - endpointPath: Путь к эндпоинту.
    ///   - payload: Тело запроса (если есть)
    func add(httpMethod: String, endpointPath: String, payload: Data?) async throws
    
    /// Извлекает все отложенные операции, отсортированные по времени создания.
    func fetchAll() async throws -> [PendingOperation]
    
    /// Удаляет массив успешно синхронизированных операций.
    func delete(_ operations: [PendingOperation]) async throws
}

final class BackupService: BackupServiceLogic {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(httpMethod: String, endpointPath: String, payload: Data?) async throws {
        let operation = PendingOperation(
            httpMethod: httpMethod,
            endpointPath: endpointPath,
            payload: payload
        )
        modelContext.insert(operation)
        try modelContext.save()
    }

    func fetchAll() async throws -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        return try modelContext.fetch(descriptor)
    }

    func delete(_ operations: [PendingOperation]) async throws {
        for operation in operations {
            modelContext.delete(operation)
        }
        try modelContext.save()
    }
}
