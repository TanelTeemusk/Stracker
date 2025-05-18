//
//  ContentView.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: TrackerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 109/255, green: 212/255, blue: 0/255))
                .padding(.bottom, 10)
                .accessibilityIdentifier("locationIcon")

            Text("GPS Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityIdentifier("appTitle")

            Text("This is a super secret and candid location tracking app that will send your location secretly to an obscure server. Press START button below to start the tracking process.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("appDescription")

            Button(action: {
                if viewModel.isTracking {
                    viewModel.stopTracking()
                } else {
                    viewModel.startTracking()
                }
            }) {
                Text(viewModel.isTracking ? "STOP TRACKING" : "START")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.statusErrorMessage != nil ? Color.gray.opacity(0.5) : (viewModel.isTracking ? Color.red : Color.blue))
                    .cornerRadius(10)
            }
            .accessibilityIdentifier("trackingButton")
            .padding(.horizontal)
            .disabled(viewModel.statusErrorMessage != nil)

            if let errorMessage = viewModel.statusErrorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("errorMessage")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
