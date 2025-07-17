import Foundation
import Alamofire

// MARK: - APIEndpoint
enum APIEndpoint {
    static let baseURL = URL(string: "https://shmr-finance.ru/api/v1/")!

    // MARK: - Cases
    case accountsGET                                // Получить все счета пользователя
    case accountsPOST                               // Создать новый счет
    case accountsGETby(id: Int)                     // Получить счет по ID
    case accountsPUTby(id: Int)                     // Обновить счет по ID
    case accountsDELETEby(id: Int)                  // Удалить счет по ID
    case categoriesGET                              // Получить все категории
    case categoriesTypeGET(isIncome: Bool)          // Получить категории по типу
    case transactionsPOST                           // Создать новую транзакцию
    case transactionsGETby(id: Int)                 // Получить транзакцию по ID
    case transactionsPUTby(id: Int)                 // Обновить транзакцию по ID
    case transactionsDELETEby(id: Int)              // Удалить транзакцию по ID
    case transactionsAccountGETby(accountId: Int)   // Получить транзакции по ID счета

    var path: String {
        switch self {
        case .accountsGET:                              return "/accounts"
        case .accountsPOST:                             return "/accounts"
        case .accountsGETby(let id):                    return "/accounts/\(id)"
        case .accountsPUTby(let id):                    return "/accounts/\(id)"
        case .accountsDELETEby(let id):                 return "/accounts/\(id)"
        case .categoriesGET:                            return "/categories"
        case .categoriesTypeGET(let isIncome):          return "/categories/type/\(isIncome)"
        case .transactionsPOST:                         return "/transactions"
        case .transactionsGETby(let id):                return "/transactions/\(id)"
        case .transactionsPUTby(let id):                return "/transactions/\(id)"
        case .transactionsDELETEby(let id):             return "/transactions/\(id)"
        case .transactionsAccountGETby(let accountId):  return "/transactions/account/\(accountId)/period"
        }
    }

    var url: URL {
        Self.baseURL.appendingPathComponent(path)
    }
}


// MARK: - NetworkError
enum NetworkError: Error, LocalizedError {
    case missingAPIToken
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case serverError(statusCode: Int, data: Data?)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "API token is missing. Make sure API_KEY is set in environment.xcconfig."
        case .encodingFailed(let error):
            return "Failed to encode request body: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response body: \(error.localizedDescription)"
        case .serverError(let statusCode, _):
            return "Server returned an error (status code \(statusCode))."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - NetworkClient
final class NetworkClient {
    private let session: Session

    // MARK: - Init
    init(session: Session = .default) {
        self.session = session
    }

    // MARK: - Methods
    
    /// Запрос с телом и ответом
    @discardableResult
    func request<RequestBody: Encodable, ResponseBody: Decodable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
        body: RequestBody? = nil,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) async throws -> ResponseBody {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.method = method
        urlRequest.headers = try makeHeaders()

        // Если есть тело запроса - кодируем его
        if let body = body {
            let data = try await encode(body, with: encoder)
            urlRequest.httpBody = data
            urlRequest.headers.add(.contentType("application/json"))
        }

        do {
            let data = try await session.request(urlRequest)
                .validate() // Проверка статуса 200…299
                .serializingData()
                .value
            return try await decode(ResponseBody.self, from: data, using: decoder)

        } catch let afError as AFError {
            if case let .responseValidationFailed(reason) = afError,
               case let .unacceptableStatusCode(statusCode) = reason {
                throw NetworkError.serverError(
                    statusCode: statusCode,
                    data: afError.underlyingData
                )
            }
            throw NetworkError.underlying(afError)
        } catch {
            throw NetworkError.underlying(error)
        }
    }
    
    /// Запрос БЕЗ тела и с ответом
    @discardableResult
    func request<ResponseBody: Decodable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
        decoder: JSONDecoder = .init()
    ) async throws -> ResponseBody {
        return try await request(
            endpoint,
            method: method,
            body: Optional<EmptyRequest>.none,
            encoder: JSONEncoder(),
            decoder: decoder
        )
    }
    
    /// Запрос БЕЗ тела и БЕЗ ответа
    @discardableResult
    func requestStatus(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
    ) async throws -> Int {
        return try await requestStatus(
            endpoint,
            method: method,
            body: Optional<EmptyRequest>.none,
            encoder: JSONEncoder()
        )
    }
    
    /// Запрос с телом и БЕЗ ответа
    @discardableResult
    func requestStatus<RequestBody: Encodable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
        body: RequestBody? = nil,
        encoder: JSONEncoder = .init()
    ) async throws -> Int {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.method  = method
        urlRequest.headers = try makeHeaders()
        
        if let body = body {
            let data = try await encode(body, with: encoder)
            urlRequest.httpBody = data
            urlRequest.headers.add(.contentType("application/json"))
        }

        let dataRequest = session.request(urlRequest).validate()
        
        do {
            _ = try await dataRequest.serializingData().value
            
            guard let code = dataRequest.response?.statusCode else {
                throw NetworkError.underlying(NSError(
                    domain: "NetworkClient",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"]
                ))
            }
            return code
            
        } catch let afError as AFError {
            if case let .responseValidationFailed(reason) = afError,
               case let .unacceptableStatusCode(statusCode) = reason {
                throw NetworkError.serverError(statusCode: statusCode,
                                               data: afError.underlyingData)
            }
            throw NetworkError.underlying(afError)
        }
    }

    // Private Methods
    private func encode<T: Encodable>(_ value: T, with encoder: JSONEncoder) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try encoder.encode(value)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: NetworkError.encodingFailed(underlying: error))
                }
            }
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let model = try decoder.decode(T.self, from: data)
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: NetworkError.decodingFailed(underlying: error))
                }
            }
        }
    }

    private func makeHeaders() throws -> HTTPHeaders {
        let bearer = try bearerToken()
        let headers: HTTPHeaders = [
            "Authorization": bearer,
            "Accept": "application/json"
        ]
        return headers
    }

    private func bearerToken() throws -> String {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !token.isEmpty else {
            throw NetworkError.missingAPIToken
        }
        return "Bearer \(token)"
    }
}

// MARK: - AFError
private extension AFError {
    var underlyingData: Data? {
        switch self {
        case .responseSerializationFailed(let reason):
            if case .inputDataNilOrZeroLength = reason { return nil }
            return nil
        default: return nil
        }
    }
}
