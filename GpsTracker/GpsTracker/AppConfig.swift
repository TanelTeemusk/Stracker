//
//  AppConfig.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation

enum AppConfig {
    // MARK: - API Configuration
    enum Main {
        // Seconds to pass before next retry when api call fails.
        static let apiFailRetryInterval: Int = 600
    }
    enum API {
        static var baseURL: String {
            if let host = Bundle.main.infoDictionary?["APIBaseURL"] as? String {
                return "https://" + host
            }

            return "https://demo-api.invendor.com"
        }

        enum Endpoints: String {
            case oauth = "/connect/token"
            case coordinates = "/api/GPSEntries/bulk"
        }

        enum OAuth {
            static let clientId = "test-app"
            static var clientSecret: String {
                return Bundle.main.infoDictionary?["APISecret"] as? String ?? ""
            }
            static let grantType = "client_credentials"
        }
    }

    // MARK: - Storage Configuration
    enum Storage {
        static let maxStoredLocations = 1000
        static let locationDataKey = "savedLocations"
    }
}
