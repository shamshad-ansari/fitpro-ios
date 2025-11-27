import Foundation

// MARK: - Support types at file scope

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

struct APIError: Error, LocalizedError, Equatable, Codable {
    let status: Int
    let message: String

    var errorDescription: String? { message }
}

// Server response envelope: { success, data, message }
struct Envelope<D: Decodable>: Decodable {
    let success: Bool
    let data: D?
    let message: String?
}

// Type-erasure helper to encode any Encodable body
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// For endpoints returning no data payload
private struct Empty: Decodable {}

// MARK: - Request type (with query support)

struct APIRequest {
    var path: String
    var method: HTTPMethod = .GET
    var headers: [String: String] = [:]
    var query: [String: String]? = nil
    var body: Encodable? = nil
}

// MARK: - API Client

@MainActor
final class APIClient {
    private let baseURL: URL
    private let tokenProvider: () -> String?

    init(baseURL: URL, tokenProvider: @escaping () -> String? = { nil }) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
    }

    func send<T: Decodable>(_ req: APIRequest, as type: T.Type) async throws -> T {
        var urlRequest = try buildURLRequest(from: req)

        if let token = tokenProvider(), !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return try decodeResponse(data: data, response: response, as: T.self)
    }

    // MARK: - Helpers

    private func buildURLRequest(from req: APIRequest) throws -> URLRequest {
        var url = baseURL
        if req.path.hasPrefix("/") {
            url.appendPathComponent(String(req.path.dropFirst()))
        } else {
            url.appendPathComponent(req.path)
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let q = req.query, !q.isEmpty {
            components?.queryItems = q.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = components?.url else {
            throw APIError(status: -1, message: "Invalid URL")
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = req.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        req.headers.forEach { k, v in
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }

        if let enc = req.body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            urlRequest.httpBody = try encoder.encode(AnyEncodable(enc))
        }

        return urlRequest
    }

    private func decodeResponse<T: Decodable>(data: Data, response: URLResponse, as: T.Type) throws -> T {
        guard let http = response as? HTTPURLResponse else {
            throw APIError(status: -1, message: "Invalid response")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if (200..<300).contains(http.statusCode) {
            if let env = try? decoder.decode(Envelope<T>.self, from: data) {
                if let payload = env.data {
                    return payload
                }
                if env.success {
                    return (Optional<T>.none as! T)
                }
                throw APIError(status: http.statusCode, message: env.message ?? "Unknown error")
            }

            if let raw = try? decoder.decode(T.self, from: data) {
                return raw
            }

            throw APIError(status: http.statusCode, message: "Decoding failed")
        } else {
            if let env = try? decoder.decode(Envelope<Empty>.self, from: data),
               let msg = env.message, !msg.isEmpty {
                throw APIError(status: http.statusCode, message: msg)
            }

            throw APIError(status: http.statusCode, message: "HTTP \(http.statusCode)")
        }
    }
}
