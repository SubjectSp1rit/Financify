import XCTest
@testable import Financify

final class TransactionTests: XCTestCase {
    // MARK: - Properties
    private let sample = Transaction(
        id:  1,
        accountId: 10,
        categoryId: 20,
        amount: 1234.56,
        transactionDate: Date(timeIntervalSinceReferenceDate: 86_400),
        comment: "Кино",
        createdAt: Date(timeIntervalSinceReferenceDate: 86_400),
        updatedAt: Date(timeIntervalSinceReferenceDate: 86_400)
    )

    // MARK: - Tests
    /// Проверяем, что jsonObject возвращает словарь с правильными ключами и значениями
    func testJSONObject_ReturnsDictionaryMirror() throws {
        let sut = sample

        let json = sut.jsonObject

        let dict = try XCTUnwrap(json as? [String: Any])

        XCTAssertEqual(dict["id"] as? Int, sut.id)
        XCTAssertEqual(dict["accountId"] as? Int, sut.accountId)
        XCTAssertEqual(dict["categoryId"] as? Int, sut.categoryId)
        XCTAssertEqual(dict["comment"] as? String, sut.comment)

        let amount = try XCTUnwrap(dict["amount"] as? Double)
        XCTAssertEqual(amount,
                       (sut.amount as NSDecimalNumber).doubleValue,
                       accuracy: 1e-6)

        let txTime = try XCTUnwrap(dict["transactionDate"] as? Double)
        XCTAssertEqual(txTime,
                       sut.transactionDate.timeIntervalSinceReferenceDate,
                       accuracy: 1e-6)
    }
    
    /// Проверяем, что parse возвращает корректный Transaction из словаря
    func testParse_WithValidDictionary_ReturnsEquivalentTransaction() throws {
        let json = sample.jsonObject

        let decoded = try XCTUnwrap(Transaction.parse(jsonObject: json))

        XCTAssertEqual(decoded.id, sample.id)
        XCTAssertEqual(decoded.accountId, sample.accountId)
        XCTAssertEqual(decoded.categoryId,  sample.categoryId)
        XCTAssertEqual(decoded.comment, sample.comment)
        XCTAssertEqual(decoded.amount, sample.amount)

        XCTAssertEqual(decoded.transactionDate.timeIntervalSinceReferenceDate,
                       sample.transactionDate.timeIntervalSinceReferenceDate,
                       accuracy: 1e-6)
    }
    
    /// Проверяем, что parse возвращает nil если какого-либо  ключа нет в словаре
    func testParse_WithMissingRequiredKey_ReturnsNil() {
        let jsonNoId: [String: Any] = [
            "accountId": 10, "categoryId": 20, "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoAccountId: [String: Any] = [
            "id": 10, "categoryId": 20, "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoCategoryId: [String: Any] = [
            "id": 10, "accountId": 20, "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoAmount: [String: Any] = [
            "id": 10, "accountId": 20, "categoryId": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoTransactionDate: [String: Any] = [
            "id": 10, "accountId": 20, "categoryId": 1000,
            "amount": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoComment: [String: Any] = [
            "id": 10, "accountId": 20, "categoryId": 1000,
            "amount": 0.0, "transactionDate": 0.0,
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonNoCreatedAt: [String: Any] = [
            "id": 10, "accountId": 20, "categoryId": 1000,
            "amount": 0.0, "transactionDate": 0.0,
            "comment": "", "updatedAt": 0.0
        ]
        
        let jsonNoUpdatedAt: [String: Any] = [
            "id": 10, "accountId": 20, "categoryId": 1000,
            "amount": 0.0, "transactionDate": 0.0,
            "comment": "", "createdAt": 0.0
        ]

        XCTAssertNil(Transaction.parse(jsonObject: jsonNoId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoAccountId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoCategoryId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoAmount))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoTransactionDate))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoComment))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoCreatedAt))
        XCTAssertNil(Transaction.parse(jsonObject: jsonNoUpdatedAt))
    }

    // Проверяем, что parse возвращает nil если типы значений не соответствуют ожидаемым
    func testParse_WithWrongType_ReturnsNil() {
        let jsonWrongId: [String: Any] = [
            "id": "WRONG", "accountId": 10, "categoryId": 20, "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonWrongAccountId: [String: Any] = [
            "id": 0, "accountId": "WRONG", "categoryId": 20, "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonWrongCategoryId: [String: Any] = [
            "id": 0, "accountId": 0, "categoryId": "WRONG", "amount": 1000,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonWrongAmount: [String: Any] = [
            "id": 0, "accountId": 0, "categoryId": 0, "amount": "WRONG",
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonWrongTransactionDate: [String: Any] = [
            "id": 0, "accountId": 0, "categoryId": 0, "amount": 0,
            "transactionDate": "WRONG", "comment": "",
            "createdAt": 0.0, "updatedAt": 0.0
        ]
        
        let jsonWrongCreatedAt: [String: Any] = [
            "id": 0, "accountId": 0, "categoryId": 0, "amount": 0,
            "transactionDate": 0.0, "comment": "",
            "createdAt": "WRONG", "updatedAt": 0.0
        ]
        
        let jsonWrongUpdatedAt: [String: Any] = [
            "id": 0, "accountId": 0, "categoryId": 0, "amount": 0,
            "transactionDate": 0.0, "comment": "",
            "createdAt": 0.0, "updatedAt": "WRONG"
        ]

        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongAccountId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongCategoryId))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongAmount))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongTransactionDate))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongCreatedAt))
        XCTAssertNil(Transaction.parse(jsonObject: jsonWrongUpdatedAt))
    }

    /// Проверяем, что круг Transaction -> jsonObject -> parse -> Transaction работает корректно и Transaction идентичны
    func testRoundTrip_EncodeDecode_PreservesAllFields() throws {
        let original = sample

        let decoded = try XCTUnwrap(Transaction.parse(jsonObject: original.jsonObject))

        XCTAssertEqual(decoded, original)
    }
}
