import Foundation

final actor TransactionsFileCache {
    // MARK: - Properties
    private(set) var transactions: [Transaction] = [
        Transaction(id: 0, accountId: 0, categoryId: 1, amount: 1500, transactionDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, createdAt: Date(), updatedAt: Date()),
        Transaction(id: 1, accountId: 0, categoryId: 2, amount: 15040, transactionDate: Date(), comment: "Rammstein", createdAt: Date(), updatedAt: Date()),
        Transaction(id: 2, accountId: 0, categoryId: 3, amount: 100, transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        Transaction(id: 3, accountId: 0, categoryId: 9, amount: 1000, transactionDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, comment: "ласт додеп",createdAt: Date(), updatedAt: Date()),
        Transaction(id: 4, accountId: 0, categoryId: 9, amount: 2000, transactionDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, comment: "длинное описаниеееееееееееееееее", createdAt: Date(), updatedAt: Date()),
        Transaction(id: 5, accountId: 0, categoryId: 9, amount: 3000, transactionDate: Date(), createdAt: Date(), updatedAt: Date()),
        //Transaction(id: 5, accountId: 0, categoryId: 9, amount: 8000, transactionDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!, createdAt: Date(), updatedAt: Date()) // Спустя 1 месяц (для дебага обновления баланса)
    ]
    
    // MARK: - Methods
    func addTransaction(_ transaction: Transaction) throws {
        // Бросаем ошибку если транзакция уже существует
        if transactions.contains(where: { $0.id == transaction.id }) {
            throw TransactionsFileCacheError.transactionAlreadyExists("Ошибка при добавлении транзакции: транзакция с id = \(transaction.id) уже существует.")
        }
        
        transactions.append(transaction)
    }
    
    func updateTransaction(_ transaction: Transaction) throws {
        // Бросаем ошибку если транзакции не существует
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else {
            throw TransactionsFileCacheError.transactionNotExists("Ошибка при изменении транзакции: транзакции с id = \(transaction.id) не существует.")
        }
        
        transactions[index] = transaction
    }
    
    func deleteTransaction(byId id: Int) throws {
        // Бросаем ошибку если транзакции не существует
        if !transactions.contains(where:  { $0.id == id }) {
            throw TransactionsFileCacheError.transactionNotExists("Ошибка при удалении транзакции: транзакции с id = \(id) не существует.")
        }
        
        transactions.removeAll { $0.id == id }
    }
    
    func saveTo(jsonFile: String) async throws {
        let fileURL = createFileURL(for: jsonFile)
        let jsonObjects = transactions.map { $0.jsonObject }
        
        try await Task.detached(priority: .background) {
            let data = try JSONSerialization.data(
                withJSONObject: jsonObjects,
                options: [.prettyPrinted]
            )
            try data.write(to: fileURL)
        }.value
    }
    
    func loadFrom(jsonFile: String) async throws {
        let fileURL = createFileURL(for: jsonFile)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TransactionsFileCacheError.fileNotExists("Ошибка при загрузке данных из .json-файла: файла \(fileURL) не существует.")
        }
        
        let jsonObjects = try await Task.detached(priority: .background) {
            let data = try Data(contentsOf: fileURL)
            return try JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [Any] ?? []
        }.value
        
        transactions = jsonObjects.compactMap { Transaction.parse(jsonObject: $0) }
    }
    
    func loadFrom(csvFile: String) async throws {
        let fileURL = createFileURL(for: csvFile)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TransactionsFileCacheError.fileNotExists("Ошибка при загрузке данных из .csv-файла: файла \(fileURL) не существует.")
        }
        
        let csvObjects: String = try await Task.detached(priority: .background) {
            let data = try Data(contentsOf: fileURL)
            guard let str = String(
                data: data,
                encoding: .utf8
            ) else {
                throw TransactionsFileCacheError.wrongFormat(
                    "Ошибка при загрузке данных из .csv-файла: невозможно прочитать \(fileURL) как UTF-8."
                )
            }
            return str
        }.value
        
        let allLines = csvObjects
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let dataLines: [String]
        if let first = allLines.first?.lowercased(), first.hasPrefix("id,") {
            dataLines = Array(allLines.dropFirst())
        } else {
            dataLines = allLines
        }
        
        var parsed: [Transaction] = []
        for line in dataLines {
            if let transaction = Transaction.parse(csvLine: line),
               !parsed.contains(where: { $0.id == transaction.id }) {
                parsed.append(transaction)
            }
        }
        
        transactions = parsed
    }
    
    // MARK: - Private Methods
    private func createFileURL(for filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    }
}
