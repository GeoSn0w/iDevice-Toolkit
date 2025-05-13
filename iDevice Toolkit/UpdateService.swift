//
//  UpdateService.swift
//  iDevice Toolkit
//
//  Created by GeoSn0w on 5/13/25.
//  Copyright © 2025 GeoSn0w. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

struct AppUpdate: Codable, Identifiable {
    var id: String { latestVersion }
    let latestVersion: String
    let minCompatibleVersion: String
    let releaseDate: String
    let downloadURL: String
    let releaseNotes: [String]
    let criticalUpdate: Bool
}

class UpdateService: ObservableObject {
    static let shared = UpdateService()
    
    private let updateURL = "https://raw.githubusercontent.com/GeoSn0w/iDevice-Toolkit/refs/heads/main/CoreAppService/currentVer.json"
    public let currentVersion = "1.2.0"
    
    @Published var isCheckingForUpdates = false
    @Published var updateAvailable: AppUpdate? = nil
    @Published var showUpdateAlert = false
    @Published var updateError: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        updateError = nil
        
        guard let url = URL(string: updateURL) else {
            handleError("Invalid update URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AppUpdate.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isCheckingForUpdates = false
                    
                    if case .failure(let error) = completion {
                        self.handleError("Failed to check for updates: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] update in
                    guard let self = self else { return }
                    
                    if self.isNewerVersion(update.latestVersion, thanCurrent: self.currentVersion) {
                        self.updateAvailable = update
                        self.showUpdateAlert = true
                        print("[+] Update available: \(update.latestVersion)")
                    } else {
                        print("[i] No updates available. Current: \(self.currentVersion), Latest: \(update.latestVersion)")
                        self.updateAvailable = nil
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleError(_ message: String) {
        print("[!] \(message)")
        isCheckingForUpdates = false
        updateError = message
    }
    
    private func isNewerVersion(_ newVersion: String, thanCurrent currentVersion: String) -> Bool {
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        guard newComponents.count >= 3, currentComponents.count >= 3 else {
            return false
        }
        
        if newComponents[0] > currentComponents[0] {
            return true
        } else if newComponents[0] < currentComponents[0] {
            return false
        }
        
        if newComponents[1] > currentComponents[1] {
            return true
        } else if newComponents[1] < currentComponents[1] {
            return false
        }
        
        return newComponents[2] > currentComponents[2]
    }
}

struct UpdateAlertView: View {
    @ObservedObject var updateService = UpdateService.shared
    @Environment(\.openURL) var openURL
    @State private var showReleaseNotes = false
    
    var body: some View {
        if let update = updateService.updateAvailable {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if !update.criticalUpdate {
                            withAnimation {
                                updateService.showUpdateAlert = false
                            }
                        }
                    }
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(update.criticalUpdate ? Color.red : ToolkitColors.accent)
                        
                        Text(update.criticalUpdate ? "Critical Update Available" : "Update Available")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !update.criticalUpdate {
                            Button(action: {
                                withAnimation {
                                    updateService.showUpdateAlert = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(ToolkitColors.darkBlue)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Version")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text(updateService.currentVersion)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(ToolkitColors.accent)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("New Version")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text(update.latestVersion)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(ToolkitColors.green)
                                }
                            }
                            .padding(.top, 8)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Button(action: {
                                    withAnimation {
                                        showReleaseNotes.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text("What's New")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: showReleaseNotes ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if showReleaseNotes {
                                    ForEach(update.releaseNotes, id: \.self) { note in
                                        HStack(alignment: .top) {
                                            Text("•")
                                                .foregroundColor(ToolkitColors.accent)
                                            Text(note)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            
                            HStack {
                                Text("Released on:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text(update.releaseDate)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                            
                            HStack(spacing: 12) {
                                if !update.criticalUpdate {
                                    Button(action: {
                                        withAnimation {
                                            updateService.showUpdateAlert = false
                                        }
                                    }) {
                                        Text("Later")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                Button(action: {
                                    if let url = URL(string: update.downloadURL) {
                                        openURL(url)
                                    }
                                }) {
                                    Text(update.criticalUpdate ? "Update Now" : "Download")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(update.criticalUpdate ? Color.red : ToolkitColors.accent)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.top, 12)
                        }
                        .padding(16)
                    }
                    .background(ToolkitColors.background)
                }
                .frame(width: UIScreen.main.bounds.width * 0.9)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.5), radius: 20)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }
}
