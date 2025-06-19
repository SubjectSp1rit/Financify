
enum SortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Сначала новые"
    case oldestFirst = "Сначала старые"
    case amountDescending = "По убыванию"
    case amountAscending = "По возрастанию"
    
    var id: Self { self }
}
