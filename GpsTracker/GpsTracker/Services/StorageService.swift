//
//  StorageService.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation

protocol StorageServiceProtocol {
    var savedLocations: [LocationData] { get }
    func saveLocation(_ location: CLLocation)
    func removeAllLocations()
}

final class StorageService: StorageServiceProtocol {
    // MARK: - Public Variables
    var savedLocations: [LocationData] {
        if let data = userDefaults.data(forKey: AppConfig.Storage.locationDataKey),
           let locations = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, LocationData.self], from: data) as? [LocationData] {
            return locations
        }
        return []
    }

    // MARK: - Private Variables
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveLocation(_ location: CLLocation) {
        let newLocation = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            createdDateTime: location.timestamp
        )

        var locations = savedLocations
        locations.append(newLocation)

        if locations.count > AppConfig.Storage.maxStoredLocations {
            locations = Array(locations.suffix(AppConfig.Storage.maxStoredLocations))
        }

        if let archived = try? NSKeyedArchiver.archivedData(withRootObject: locations, requiringSecureCoding: true) {
            userDefaults.set(archived, forKey: AppConfig.Storage.locationDataKey)
        }

        print("Saved location: \(newLocation.latitude), \(newLocation.longitude) at \(newLocation.createdDateTime), locations saved: \(locations.count)")
    }

    func removeAllLocations() {
        userDefaults.removeObject(forKey: AppConfig.Storage.locationDataKey)
    }
}
