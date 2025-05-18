//
//  GpsTrackerApp.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import SwiftUI
import CoreLocation

@main
struct GpsTrackerApp: App {
    private let locationService: LocationService
    private let storageService: StorageService
    private let apiService: APIService
    private let viewModel: TrackerViewModel

    init() {
        // Default initialization
        let locationManager = CLLocationManager()
        self.locationService = LocationService(locationManager: locationManager)
        self.storageService = StorageService()
        self.apiService = APIService()
        self.viewModel = TrackerViewModel(
            locationService: locationService,
            storageService: storageService,
            apiService: apiService
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
