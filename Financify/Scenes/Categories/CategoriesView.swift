import SwiftUI

struct CategoriesView: View {
    // MARK: - Properties
    @StateObject private var viewModel: CategoriesViewModel
    
    // MARK: - Lifecycle
    init(categoriesService: CategoriesServiceLogic) {
        let vm = CategoriesViewModel(
            categoriesService: categoriesService
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(String.categoriesSectionTitle) {
                    ForEach(viewModel.filteredCategories) { category in
                        CategoryCell(
                            category: category
                        )
                    }
                }
            }
            .overlay(alignment: .center) {
                // Пока данные грузятся - показываем анимацию загрузки по центру экрана
                if viewModel.isLoading && viewModel.categories.isEmpty {
                    LoadingAnimation()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(String.categoriesTitle)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Поиск статей"
            ) {
                // Подсказки при поиске
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
            .task {
                await viewModel.fetchCategories()
            }
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let categoriesTitle: String = "Мои статьи"
    static let categoriesSectionTitle: String = "СТАТЬИ"
}
