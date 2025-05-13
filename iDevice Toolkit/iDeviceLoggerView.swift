//
//  iDeviceLoggerView.swift
//  iDevice Toolkit
//
//  Created by GeoSn0w on 5/13/25.
//  Copyright © 2025 GeoSn0w. All rights reserved.
//


import SwiftUI

struct iDeviceCentralTerminal: View {
    @ObservedObject private var logger = TerminalLogger.shared
    @Environment(\.dismiss) private var dismiss
    

    private let terminalGreen = Color(red: 0/255, green: 255/255, blue: 0/255)
    private let terminalBackground = ToolkitColors.background
    
    var body: some View {
        ZStack {
            terminalBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(logger.entries.indices, id: \.self) { index in
                                HStack(alignment: .top) {
                                    Text("$")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(terminalGreen)
                                        .frame(width: 14, alignment: .leading)
                                    
                                    Text(logger.entries[index])
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(terminalGreen)
                                }
                                .padding(.vertical, 1)
                                .padding(.horizontal, 12)
                                .id(index)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(terminalBackground)
                    .onChange(of: logger.entries.count) { _ in
                        if let lastIndex = logger.entries.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}
