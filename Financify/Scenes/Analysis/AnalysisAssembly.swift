import UIKit

enum AnalysisAssembly {
    static func build(
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic,
        onClose: @escaping () -> Void
    ) -> UIViewController {
        let presenter = AnalysisPresenter()
        let interactor = AnalysisInteractor(
            presenter: presenter,
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService
        )
        let view = AnalysisViewController(interactor: interactor)
        view.onClose = onClose
        presenter.view = view
        
        return view
    }
}
