//
//  iDeviceToolbox.swift
//  iDevice Toolbox
//
//  Created by GeoSn0w on 5/12/25.
//

import SwiftUI

@main
struct ideviceToolboxBegin: App {
    @State private var isSplashActive = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                                withAnimation {
                                    isSplashActive = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isSplashActive)
        }
    }
}

extension String: @retroactive Error {}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 70))
                        .foregroundColor(ToolkitColors.accent)
                        .padding(.bottom, 10)
                    
                    Text("iDevice Toolkit")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("by iDevice Central")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ToolkitColors.accent.opacity(0.9))
                        .padding(.top, 4)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.scale = 1.0
                        self.opacity = 1.0
                    }
                }
                
                Spacer()
                
                Text("Unlocking iOS Customization")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.7))
                    .padding(.bottom, 30)
                    .opacity(opacity)
            }
        }
    }
}
