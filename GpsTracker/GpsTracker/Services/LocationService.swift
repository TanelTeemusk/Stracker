//
//  LocationService.swift
//  GpsTracker
//
//  Created by tanel teemusk on 17.05.2025.
//

import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    var isAuthorized: Bool { get }
    var isMonitoring: Bool { get }

    func requestAuthorization()
    func startUpdatingLocation(
        onUpdate: @escaping (CLLocation) -> Void,
        onAuthChange: @escaping (CLAuthorizationStatus) -> Void,
        onError: @escaping (Error) -> Void
    )
    func stopUpdatingLocation()
}

final class LocationService: NSObject, LocationServiceProtocol {
    // MARK: - Public properties
    var isMonitoring = false

    var isAuthorized: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            return true
        default:
            return false
        }
    }

    // MARK: - Private properties
    private let locationManager: CLLocationManager
    private let minTimeInterval: TimeInterval
    private let distanceFilter: CLLocationDistance
    private var lastLocationUpdate: Date?

    // MARK: - Callback closures
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    private var authChangeHandler: ((CLAuthorizationStatus) -> Void)?
    private var errorHandler: ((Error) -> Void)?

    // MARK: - Initialization
    init(locationManager: CLLocationManager, minTimeInterval: TimeInterval = 10.0, distanceFilter: CLLocationDistance = 10.0) {
        self.locationManager = locationManager
        self.minTimeInterval = minTimeInterval
        self.distanceFilter = distanceFilter
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = distanceFilter // Disabled per task request
        locationManager.activityType = .other
    }

    // MARK: - LocationServiceProtocol
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func startUpdatingLocation(
        onUpdate: @escaping (CLLocation) -> Void,
        onAuthChange: @escaping (CLAuthorizationStatus) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        locationUpdateHandler = onUpdate
        authChangeHandler = onAuthChange
        errorHandler = onError

        if isAuthorized {
            locationManager.startUpdatingLocation()
            isMonitoring = true
        } else {
            requestAuthorization()
        }
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isMonitoring = false

        // Clear handlers to prevent memory leaks
        locationUpdateHandler = nil
        authChangeHandler = nil
        errorHandler = nil
    }

    // MARK: - Deinitializer
    deinit {
        stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, let updateHandler = locationUpdateHandler else { return }

        // Apply time filtering to avoid too frequent updates
        let currentTime = Date()
        if let lastUpdate = lastLocationUpdate,
           currentTime.timeIntervalSince(lastUpdate) < minTimeInterval {
            return
        }

        lastLocationUpdate = currentTime
        updateHandler(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorHandler?(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authChangeHandler?(status)

        // If we just got authorized and we should be monitoring, start updates
        if status == .authorizedAlways && isMonitoring {
            locationManager.startUpdatingLocation()
        }
    }
}
