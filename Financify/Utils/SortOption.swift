
enum SortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Сначала новые"
    case oldestFirst = "Сначала старые"
    case amountDescending = "По убыванию"
    case amountAscending = "По возрастанию"
    
    var id: Self { self }
    
    var iconName: String {
        switch self {
        case .newestFirst:      return "calendar.circle"
        case .oldestFirst:      return "calendar.circle.fill"
        case .amountDescending: return "rublesign.circle"
        case .amountAscending:  return "rublesign.circle.fill"
        }
    }
}
