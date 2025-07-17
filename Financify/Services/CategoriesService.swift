import Foundation

protocol CategoriesServiceLogic: Actor {
    func getAllCategories() async throws -> [Category]
    func getCategories(by direction: Direction) async throws -> [Category]
}

final actor CategoriesService: CategoriesServiceLogic {
    // MARK: - DI
    let client: NetworkClient
    
    // MARK: - Lifecycle
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }
    
    // MARK: - Methods
    func getAllCategories() async throws -> [Category] {
        try await categories()
    }
    
    func getCategories(by direction: Direction) async throws -> [Category] {
        try await categories().filter { $0.direction == direction }
    }
    
    // MARK: - Private Methods
    private func categories() async throws -> [Category] {
        let response: [Category] = try await client.request(.categoriesGET, method: .get)
        return response
    }
}
