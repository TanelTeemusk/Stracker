//
//  TrackerViewModel.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation

protocol TrackerViewModelProtocol {
    var isTracking: Bool { get }
    var statusErrorMessage: String? { get }
    func startTracking()
    func stopTracking()
}

final class TrackerViewModel: NSObject, TrackerViewModelProtocol, ObservableObject {
    // MARK: - Public Variables
    @Published var isTracking = false
    @Published var statusErrorMessage: String?

    // MARK: - Private Variables
    private let locationService: LocationServiceProtocol
    private let apiService: APIServiceProtocol
    private let storageService: StorageServiceProtocol


    private var retryTimer: Timer?
    private let retryStateKey = "com.gpstracker.retryState"
    private let trackingStateKey = "com.gpstracker.trackingState"

    init(locationService: LocationServiceProtocol,
         storageService: StorageServiceProtocol,
         apiService: APIServiceProtocol) {
        self.locationService = locationService
        self.storageService = storageService
        self.apiService = apiService
        super.init()
        isTracking = UserDefaults.standard.bool(forKey: trackingStateKey)
        if isTracking { startTracking() }
        checkAndRescheduleRetry()
    }

    deinit {
        retryTimer?.invalidate()
        locationService.stopUpdatingLocation()
    }
}

// MARK: - Location tracking
extension TrackerViewModel {
    func startTracking() {
        statusErrorMessage = nil

        configureLocationTracking()

        if locationService.isAuthorized {
            isTracking = true
            UserDefaults.standard.set(true, forKey: trackingStateKey)
        } else {
            stopTracking()
            statusErrorMessage = "We are unable to update your location at the moment. Are you sure our app is authorized to receive location updates in the iOS settings?"
        }

        locationService.requestAuthorization()
    }

    func stopTracking() {
        locationService.stopUpdatingLocation()
        isTracking = false
        UserDefaults.standard.set(false, forKey: trackingStateKey)

        dismissRetryTask()
        postSavedLocation()
    }

    private func configureLocationTracking() {
        locationService.startUpdatingLocation(
            onUpdate: { [weak self] location in
                self?.storageService.saveLocation(location)
            },
            onAuthChange: { [weak self] status in
                self?.handleAuthorizationChange(status)
            },
            onError: { [weak self] error in
                self?.stopTracking()
                self?.statusErrorMessage = "We are unable to update your location at the moment. Are you sure our app is authorized to receive location updates in the iOS settings?"
            }
        )
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        statusErrorMessage = nil
        if status == .authorizedAlways && isTracking {
            configureLocationTracking()
        } else if status == .denied || status == .restricted {
            stopTracking()
            statusErrorMessage = "Location access denied. Please enable it in your phone settings."
        }
    }
}

// MARK: - Api access functionality
extension TrackerViewModel {
    private func postSavedLocation() {
        let locations = storageService.savedLocations
        if locations.isEmpty {
            dismissRetryTask()
            return
        }

        let request = APIService.Request(endpoint: .coordinates,
                                         method: .post,
                                         body: locations)
        Task {
            do {
                let response = try await apiService.call(with: request)
                print("Response: \(response.description)")
                if response.isSuccess {
                    storageService.removeAllLocations()
                } else {
                    scheduleRetryTask(after: AppConfig.Main.apiFailRetryInterval)
                }
            } catch {
                print("Failed to send coordinates: \(error.localizedDescription)")
                scheduleRetryTask(after: AppConfig.Main.apiFailRetryInterval)
            }
        }
    }
}

// MARK: - Scheduled retry functionality
extension TrackerViewModel {
    private func checkAndRescheduleRetry() {
        if let retryDate = UserDefaults.standard.object(forKey: retryStateKey) as? Date {
            let timeInterval = retryDate.timeIntervalSinceNow
            if timeInterval > 0 {
                scheduleRetryTask(after: Int(timeInterval))
            } else {
                postSavedLocation()
            }
        }
    }

    func scheduleRetryTask(after seconds: Int) {
        retryTimer?.invalidate()

        // Store the retry time
        let retryDate = Date().addingTimeInterval(TimeInterval(seconds))
        UserDefaults.standard.set(retryDate, forKey: retryStateKey)

        retryTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.postSavedLocation()
        }
    }

    func dismissRetryTask() {
        retryTimer?.invalidate()
        UserDefaults.standard.removeObject(forKey: retryStateKey)
    }
}
