//
//  APIService.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import CoreLocation
import Foundation

protocol APIServiceProtocol {
    func call(with request: APIService.Request) async throws -> APIService.Response
}

final class APIService: APIServiceProtocol {
    private var accessToken: String?
    private var tokenExpirationDate: Date?

    enum Error: Swift.Error {
        case invalidURL
        case invalidResponse
        case networkError(Swift.Error)
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    struct Request {
        let endpoint: AppConfig.API.Endpoints
        let method: HTTPMethod
        let body: Codable
    }

    struct Response {
        let isSuccess: Bool
        let statusCode: Int
        let message: String?

        var description: String {
            let status = isSuccess ? "✅ Success" : "❌ Failure"
            let statusCodeInfo = "Status Code: \(statusCode)"
            let messageInfo = message.map { "Message: \($0)" } ?? "No message"

            return """
            \(status)
            \(statusCodeInfo)
            \(messageInfo)
            """
        }

        static func success(statusCode: Int, message: String? = nil) -> Response {
            return Response(isSuccess: true, statusCode: statusCode, message: message)
        }

        static func failure(statusCode: Int, message: String? = nil) -> Response {
            return Response(isSuccess: false, statusCode: statusCode, message: message)
        }
    }

    func call(with request: Request) async throws -> Response {
        let token = try await getValidToken()

        guard let url = URL(string: AppConfig.API.baseURL+request.endpoint.rawValue) else {
            throw Error.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if request.method == .post {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request.body)
        }

        return try await performRequest(urlRequest)
    }

    private func performRequest(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            return Response.success(statusCode: httpResponse.statusCode)
        } else {
            return Response.failure(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Token
private extension APIService {
    func getValidToken() async throws -> String {
        if let token = accessToken,
           let expirationDate = tokenExpirationDate,
           expirationDate > Date()
        {
            return token
        }

        return try await fetchNewToken()
    }

    func fetchNewToken() async throws -> String {
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.API.Endpoints.oauth.rawValue) else {
            throw Error.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "grant_type": AppConfig.API.OAuth.grantType,
            "client_id": AppConfig.API.OAuth.clientId,
            "client_secret": AppConfig.API.OAuth.clientSecret,
        ]

        request.httpBody =
        parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: String.Encoding.utf8)

        struct TokenResponse: Codable {
            let access_token: String
            let expires_in: Int
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw Error.invalidResponse
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        accessToken = tokenResponse.access_token
        tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))

        return tokenResponse.access_token
    }
}
