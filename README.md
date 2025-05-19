<img src="app-icon-small.png" width="64" height="64">

# Stracker iOS App (version 0.0.1)

An iOS application for tracking and managing location data. This project was developed as a technical assessment for Estonian technology company. The architecture for such a small one screen app might look a bit of an overkill at first but the approach in building this app was to architect it as a good start for a bigger feature-rich app.

Deliberately no external dependencies nor libraries are used in this project. Everything reasonable is being coded from scratch (with some help from a digital friend called Claude).

I will not keep you posted if the tech company saw this app to be worthy enough to include my iOS dev skills to their ranks or not. This repo will most likely be soon deleted or switched to private so grab it while you can.

## Features

- Real-time GPS location tracking
- Background location updates
- Offline data storage with automatic synchronization
- Automatic retry mechanism for failed API calls
- Clean and intuitive user interface
- Battery-efficient location tracking
- Persistent tracking state across app restarts

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repo
2. Navigate to the project directory
3. Open `GpsTracker.xcodeproj` in Xcode
4. Find and open the `Debug` file in Xcode and check it's contents
5. Add your Api Secret instead of the text "YOUR_API_SECRET_HERE". Api secret is the long list of numbers shared with you by the production team. The correct line looks like this:
```
API_SECRET = YOUR_API_SECRET_HERE
```
6. Build and run the project (⌘+R)

> Also note that there is a Production file in the document tree. This includes app variables needed for production.

> As a rule of thumb, don't commit Debug.xcconfig nor Production.xcconfig files to this repo as these will include sensitive information only you should know.

> 💡 **Pro Tip**: If the app doesn't build, try cleaning the build folder (Shift+⌘+K) before building again. If issues persist, verify that your xcconfig files contain the correct API secret value. The xcconfig files are referenced in Xcode but live in the parent directory of the project, making them easy to edit directly in Xcode.


## Usage

1. Launch the app
2. Grant location permissions when prompted (the data about your precise location will be sent to an obscure server in the internet)
3. Toggle the tracking switch to start/stop location tracking
4. The app will automatically handle:
   - Background location updates
   - Offline data storage
   - Data synchronization when online
   - Error recovery

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern and includes:

- **Services Layer**
  - LocationService: Handles GPS tracking
  - StorageService: Manages local data persistence
  - APIService: Handles network communication
  - All services are protocol-oriented for better testability and dependency injection

- **View Layer**
  - SwiftUI-based user interface
  - Clean and responsive design

- **ViewModel Layer**
  - Business logic implementation
  - State management
  - Error handling

## Technical Details

- Written in Swift using SwiftUI
- Uses CoreLocation for GPS tracking
- Implements background task handling
- Features automatic retry mechanism for failed API calls
- Includes proper error handling and user feedback
- Implements proper memory management
- Built with protocol-oriented architecture for enhanced testability and maintainability
- Includes comprehensive unit tests for the main ViewModel, demonstrating test-driven development practices
- Also includes a short UI item check in UI tests
