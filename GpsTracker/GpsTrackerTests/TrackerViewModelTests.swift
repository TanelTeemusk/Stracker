import XCTest
import CoreLocation
@testable import GpsTracker

// MARK: - Test Class
final class TrackerViewModelTests: XCTestCase {
    var sut: TrackerViewModel!
    var mockLocationService: MockLocationService!
    var mockStorageService: MockStorageService!
    var mockAPIService: MockAPIService!
    
    override func setUp() {
        super.setUp()
        mockLocationService = MockLocationService()
        mockStorageService = MockStorageService()
        mockAPIService = MockAPIService()
        sut = TrackerViewModel(
            locationService: mockLocationService,
            storageService: mockStorageService,
            apiService: mockAPIService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockLocationService = nil
        mockStorageService = nil
        mockAPIService = nil
        super.tearDown()
    }
    
    // MARK: - Tracking State Tests
    
    func testStartTracking_WhenAuthorized_ShouldStartTracking() {
        // Given
        mockLocationService.mockAuthorizationStatus = .authorizedAlways
        
        // When
        sut.startTracking()
        
        // Then
        XCTAssertTrue(sut.isTracking)
        XCTAssertNil(sut.statusErrorMessage)
        XCTAssertTrue(mockLocationService.startUpdatingLocationCalled)
    }
    
    func testStartTracking_WhenNotAuthorized_ShouldShowError() {
        // Given
        mockLocationService.mockAuthorizationStatus = .denied
        
        // When
        sut.startTracking()
        
        // Then
        XCTAssertFalse(sut.isTracking)
        XCTAssertNotNil(sut.statusErrorMessage)
        XCTAssertTrue(mockLocationService.startUpdatingLocationCalled, "startUpdatingLocation should be called to check authorization")
    }
    
    func testStopTracking_ShouldStopAndPostLocations() async {
        // Given
        let expectation = XCTestExpectation(description: "API call completed")
        mockLocationService.mockAuthorizationStatus = .authorizedAlways
        sut.startTracking()
        
        // Add a test location
        let testLocation = CLLocation(latitude: 59.4370, longitude: 24.7536)
        mockStorageService.saveLocation(testLocation)
        
        // Set up completion handler
        mockAPIService.onCallComplete = {
            expectation.fulfill()
        }
        
        // When
        sut.stopTracking()
        
        // Then
        XCTAssertFalse(sut.isTracking)
        XCTAssertTrue(mockLocationService.stopUpdatingLocationCalled)
        
        // Wait for async operation to complete
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAPIService.postLocationsCalled, "API service should be called to post locations")
    }
    
    func testStopTracking_WhenNoLocations_ShouldNotCallAPI() async {
        // Given
        let expectation = XCTestExpectation(description: "API call completed")
        expectation.isInverted = true // This expectation should NOT be fulfilled
        
        mockLocationService.mockAuthorizationStatus = .authorizedAlways
        sut.startTracking()
        
        // Set up completion handler
        mockAPIService.onCallComplete = {
            expectation.fulfill()
        }
        
        // When
        sut.stopTracking()
        
        // Then
        XCTAssertFalse(sut.isTracking)
        XCTAssertTrue(mockLocationService.stopUpdatingLocationCalled)
        
        // Wait for async operation to complete
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(mockAPIService.postLocationsCalled, "API service should not be called when there are no locations")
    }
    
    // MARK: - Location Update Tests
    
    func testLocationUpdate_ShouldSaveLocation() {
        // Given
        let testLocation = CLLocation(latitude: 59.4370, longitude: 24.7536)
        
        // When
        mockLocationService.startUpdatingLocation(
            onUpdate: { [weak self] location in
                self?.mockStorageService.saveLocation(location)
            },
            onAuthChange: { _ in },
            onError: { _ in }
        )
        
        // Simulate location update
        mockLocationService.simulateLocationUpdate(testLocation)
        
        // Then
        XCTAssertEqual(mockStorageService.savedLocations.count, 1)
        XCTAssertEqual(mockStorageService.savedLocations.first?.latitude, testLocation.coordinate.latitude)
        XCTAssertEqual(mockStorageService.savedLocations.first?.longitude, testLocation.coordinate.longitude)
    }
    
    func testStorageService_ShouldRespectMaxLocations() {
        // Given
        let maxLocations = 10
        let locations = (0..<maxLocations + 5).map { i in
            CLLocation(latitude: 59.4370 + Double(i) * 0.0001, longitude: 24.7536)
        }
        
        // When
        locations.forEach { location in
            mockStorageService.saveLocation(location)
        }
        
        // Then
        XCTAssertEqual(mockStorageService.savedLocations.count, maxLocations)
        XCTAssertEqual(mockStorageService.savedLocations.last?.latitude, locations.last?.coordinate.latitude)
    }
    
    func testAPIError_ShouldNotClearLocations() async {
        // Given
        let expectation = XCTestExpectation(description: "API call completed")
        mockAPIService.shouldFail = true
        mockLocationService.mockAuthorizationStatus = .authorizedAlways
        sut.startTracking()
        
        // Add test location
        let testLocation = CLLocation(latitude: 59.4370, longitude: 24.7536)
        mockStorageService.saveLocation(testLocation)
        
        // Set up completion handler
        mockAPIService.onCallComplete = {
            expectation.fulfill()
        }
        
        // When
        sut.stopTracking()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAPIService.postLocationsCalled)
        XCTAssertEqual(mockStorageService.savedLocations.count, 1, "Locations should not be cleared on API error")
    }
}

// MARK: - Mock Classes
class MockLocationService: LocationServiceProtocol {
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var isMonitoring = false
    var startUpdatingLocationCalled = false
    var stopUpdatingLocationCalled = false
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var authChangeHandler: ((CLAuthorizationStatus) -> Void)?
    
    var isAuthorized: Bool {
        return mockAuthorizationStatus == .authorizedAlways
    }
    
    func requestAuthorization() {}
    
    func startUpdatingLocation(
        onUpdate: @escaping (CLLocation) -> Void,
        onAuthChange: @escaping (CLAuthorizationStatus) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        startUpdatingLocationCalled = true
        locationUpdateHandler = onUpdate
        errorHandler = onError
        authChangeHandler = onAuthChange
        onAuthChange(mockAuthorizationStatus)
    }
    
    func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
        locationUpdateHandler = nil
        errorHandler = nil
        authChangeHandler = nil
    }
    
    // Helper method to simulate location updates
    func simulateLocationUpdate(_ location: CLLocation) {
        locationUpdateHandler?(location)
    }
    
    // Helper method to simulate authorization changes
    func simulateAuthChange(_ status: CLAuthorizationStatus) {
        mockAuthorizationStatus = status
        authChangeHandler?(status)
    }
    
    // Helper method to simulate errors
    func simulateError(_ error: Error) {
        errorHandler?(error)
    }
}

class MockStorageService: StorageServiceProtocol {
    var savedLocations: [LocationData] = []
    var removeAllLocationsCalled = false
    let maxLocations = 10
    
    func saveLocation(_ location: CLLocation) {
        let locationData = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            createdDateTime: location.timestamp
        )
        
        // If we're at max capacity, remove the oldest location
        if savedLocations.count >= maxLocations {
            savedLocations.removeFirst()
        }
        
        savedLocations.append(locationData)
    }
    
    func removeAllLocations() {
        removeAllLocationsCalled = true
        savedLocations.removeAll()
    }
}

class MockAPIService: APIServiceProtocol {
    var shouldFail = false
    var postLocationsCalled = false
    var onCallComplete: (() -> Void)?
    
    func call(with request: APIService.Request) async throws -> APIService.Response {
        postLocationsCalled = true
        // Add a small delay to simulate network call
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        onCallComplete?()
        
        if shouldFail {
            throw NSError(domain: "test", code: -1)
        }
        
        return APIService.Response.success(statusCode: 200, message: "Success")
    }
} 
