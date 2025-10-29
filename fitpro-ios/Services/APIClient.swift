import Foundation

enum HTTPMethod: String { case GET, POST, PUT, PATCH, DELETE }

struct APIError: Error, LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

struct APIRequest {
    var path: String
    var method: HTTPMethod = .GET
    var headers: [String: String] = [:]
    var body: Encodable? = nil
}

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
        // Attach auth token if present
        if let token = tokenProvider() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return try decodeResponse(data: data, response: response, as: T.self)
    }

    // MARK: - Helpers

    private func buildURLRequest(from req: APIRequest) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(req.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = req.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // merge user headers
        req.headers.forEach { k, v in urlRequest.setValue(v, forHTTPHeaderField: k) }

        // encode body if any
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
        // Your backend envelope is { success, data, message }
        struct Envelope<D: Decodable>: Decodable {
            let success: Bool
            let data: D?
            let message: String?
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if (200..<300).contains(http.statusCode) {
            // Try to decode either envelope or raw T (for health endpoints etc.)
            if let env = try? decoder.decode(Envelope<T>.self, from: data), let payload = env.data {
                return payload
            } else if let raw = try? decoder.decode(T.self, from: data) {
                return raw
            } else {
                // If body is empty but T is Void-like, allow this to fail loudly for now
                throw APIError(status: http.statusCode, message: "Decoding failed")
            }
        } else {
            // Extract server message if possible
            if let env = try? decoder.decode(Envelope<Empty>.self, from: data),
               let msg = env.message {
                throw APIError(status: http.statusCode, message: msg)
            }
            throw APIError(status: http.statusCode, message: "HTTP \(http.statusCode)")
        }
    }
}

// Type-erasure helper to encode any Encodable body
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

private struct Empty: Decodable {}
