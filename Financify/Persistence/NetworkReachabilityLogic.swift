// Financify/Financify/Persistence/NetworkReachabilityLogic.swift

import Foundation

protocol NetworkReachabilityLogic: Sendable {
    /// Асинхронный поток, который транслирует изменения статуса сети.
    /// Значения всегда приходят на MainActor.
    var statusStream: AsyncStream<NetworkStatus> { get }
    
    /// Текущий (мгновенный) статус сети.
    /// Подходит для инициализации. Для отслеживания изменений используйте statusStream.
    var currentStatus: NetworkStatus { get }
}
