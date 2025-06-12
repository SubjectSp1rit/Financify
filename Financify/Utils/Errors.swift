enum BankAccountServicesError: Error {
    case accountNotExists(String)
}

enum TransactionsFileCacheError: Error {
    case transactionAlreadyExists(String)
    case transactionNotExists(String)
    case fileNotExists(String)
    case wrongFormat(String)
}
