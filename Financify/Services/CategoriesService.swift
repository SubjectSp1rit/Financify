import Foundation
import SwiftData

protocol CategoriesServiceLogic: Actor {
    func getAllCategories() async throws -> [Category]
    func getCategories(by direction: Direction) async throws -> [Category]
}

final actor CategoriesService: CategoriesServiceLogic {
    // MARK: - DI
    let client: NetworkClient
    private let reachability: NetworkReachabilityLogic
    private let modelContext: ModelContext
    
    // MARK: - Lifecycle
    init(
        client: NetworkClient = NetworkClient(),
        reachability: NetworkReachabilityLogic,
        modelContainer: ModelContainer
    ) {
        self.client = client
        self.reachability = reachability
        self.modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Methods
    func getAllCategories() async throws -> [Category] {
        do {
            let categories: [Category] = try await client.request(.categoriesGET, method: .get)
            try await updateLocalStore(with: categories)
            return categories
        } catch {
            print("Categories fetch failed. Falling back to local data. Error: \(error.localizedDescription)")
            return try await fetchLocalCategories()
        }
    }
    
    func getCategories(by direction: Direction) async throws -> [Category] {
        let allCategories = try await getAllCategories()
        return allCategories.filter { $0.direction == direction }
    }
    
    // MARK: - Private Methods
    private func fetchLocalCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<PersistentCategory>()
        let persistent = try modelContext.fetch(descriptor)
        return persistent.map { $0.toDomain() }
    }
    
    private func updateLocalStore(with categories: [Category]) async throws {
        try modelContext.delete(model: PersistentCategory.self)
        try modelContext.save()
        
        for category in categories {
            modelContext.insert(PersistentCategory(from: category))
        }
        try modelContext.save()
    }
}
