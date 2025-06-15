import Foundation

final actor CategoriesService {
    // MARK: - Methods
    func getAllCategories() async throws -> [Category] {
        try await categories()
    }
    
    func getCategories(by direction: Direction) async throws -> [Category] {
        try await categories().filter { $0.direction == direction }
    }
    
    // MARK: - Private Methods
    private func categories() async throws -> [Category] {
        [
            Category(id: 0, name: "Аренда квартиры", emoji: "h", isIncome: false),
            Category(id: 1, name: "Одежда", emoji: "o", isIncome: false),
            Category(id: 2, name: "На собачку", emoji: "d", isIncome: false),
            Category(id: 3, name: "Ремонт квартиры", emoji: "r", isIncome: false),
            Category(id: 4, name: "Продукты", emoji: "g", isIncome: false),
            Category(id: 5, name: "Спортзал", emoji: "s", isIncome: false),
            Category(id: 6, name: "Медицина", emoji: "m", isIncome: false),
            Category(id: 7, name: "Аптека", emoji: "a", isIncome: false),
            Category(id: 8, name: "Машина", emoji: "c", isIncome: false),
            Category(id: 9, name: "Зарплата", emoji: "z", isIncome: true)
        ]
    }
}
