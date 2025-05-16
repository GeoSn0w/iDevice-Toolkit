//
//  iDeviceFileUtil.swift
//  iDevice Toolkit
//
//  Created by GeoSn0w on 5/16/25.
//  Copyright © 2025 GeoSn0w. All rights reserved.
//

import SwiftUI
import Combine
import UIKit
import UniformTypeIdentifiers
import AVFoundation

public func isAudioFile(path: String) -> Bool {
    let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
    let audioExtensions = ["mp3", "m4a", "aac", "wav", "caf", "aiff", "aif", "flac"]
    return audioExtensions.contains(fileExtension)
}

struct FileContentView: View {
    let file: FileDetails
    @ObservedObject var viewModel: SystemFileManagerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showCopiedPathToast: Bool = false
    
    var body: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                contentView
            }
            
            if showCopiedPathToast {
                VStack {
                    Spacer()
                    Text("Path copied to clipboard")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ToolkitColors.darkBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopiedPathToast = false
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .foregroundColor(ToolkitColors.accent)
            }
            
            Spacer()
            
            Text(file.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = file.path
                withAnimation {
                    showCopiedPathToast = true
                }
            }) {
                Text("Copy Path")
                    .foregroundColor(ToolkitColors.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ToolkitColors.headerBackground)
    }
    
    private var contentView: some View {
        let fileExtension = URL(fileURLWithPath: file.path).pathExtension.lowercased()
        let fileType = viewModel.detectFileType(for: file.path)
        
        if isAudioFile(path: file.path) {
            return AnyView(crappyAudioPlayerViewButWhateverIamTiredAtThisPoint(filePath: file.path, fileName: file.name))
        }
        
        switch fileType {
        case "Image":
            return AnyView(imageContentView)
        case "Property List", "Binary Property List":
            return AnyView(plistContentView)
        case "Text File", "XML File", "HTML File", "Source Code", "JSON File":
            return AnyView(textContentView)
        default:
            return AnyView(hexContentView)
        }
    }
    
    class AudioPlayerDelegate: NSObject, ObservableObject, AVAudioPlayerDelegate {
        @Published var didFinishPlaying: Bool = false
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            DispatchQueue.main.async {
                self.didFinishPlaying = true
            }
        }
    }

    struct crappyAudioPlayerViewButWhateverIamTiredAtThisPoint: View {
        let filePath: String
        let fileName: String
        
        @State private var audioPlayer: AVAudioPlayer?
        @State private var isPlaying: Bool = false
        @State private var showError: Bool = false
        @State private var errorMessage: String = ""
        
        @StateObject private var playerDelegate = AudioPlayerDelegate()
        
        var body: some View {
            VStack(spacing: 20) {
                Text(fileName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ToolkitColors.darkBlue.opacity(0.3))
                        .frame(height: 100)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundColor(isPlaying ? ToolkitColors.accent : .gray)
                }
                .padding(.horizontal)
                
                Button(action: {
                    togglePlayback()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(ToolkitColors.accent)
                }
                .padding()
                
                if let audioPlayer = audioPlayer {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Format:")
                                .font(.caption)
                                .foregroundColor(ToolkitColors.accent)
                            
                            Spacer()
                            
                            Text(getAudioFormat(filePath: filePath))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Duration:")
                                .font(.caption)
                                .foregroundColor(ToolkitColors.accent)
                            
                            Spacer()
                            
                            Text(formatTime(audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ToolkitColors.darkBlue.opacity(0.3))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .onAppear {
                setupAudioPlayer()
            }
            .onDisappear {
                stopPlayback()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Audio Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: playerDelegate.didFinishPlaying) { didFinish in
                if didFinish {
                    isPlaying = false
                    playerDelegate.didFinishPlaying = false
                }
            }
        }
        
        private func setupAudioPlayer() {
            do {
                let url = URL(fileURLWithPath: filePath)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer?.delegate = playerDelegate
                audioPlayer?.prepareToPlay()
            } catch {
                errorMessage = "Failed to load audio: \(error.localizedDescription)"
                showError = true
            }
        }
        
        private func togglePlayback() {
            if isPlaying {
                audioPlayer?.pause()
            } else {
                audioPlayer?.play()
            }
            
            isPlaying.toggle()
        }
        
        private func stopPlayback() {
            audioPlayer?.stop()
            isPlaying = false
        }
        
        private func formatTime(_ time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        private func getAudioFormat(filePath: String) -> String {
            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
            
            switch fileExtension {
            case "mp3":
                return "MP3"
            case "m4a", "aac":
                return "AAC"
            case "wav":
                return "WAV"
            case "caf":
                return "Core Audio Format"
            case "aiff", "aif":
                return "AIFF"
            case "flac":
                return "FLAC"
            default:
                return "Audio File"
            }
        }
    }

    private var imageContentView: some View {
        VStack {
            if let image = viewModel.loadImage(from: file.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                errorView(message: "Failed to load image")
            }
            
            Text("Size: \(viewModel.formattedFileSize(size: file.size))")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom)
        }
    }
    
    private var plistContentView: some View {
        VStack {
            let result = viewModel.readFileContent(path: file.path)
            
            if let content = result.content {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let error = result.error {
                errorView(message: error)
            } else {
                errorView(message: "Unknown error loading plist content")
            }
        }
    }
    
    private var textContentView: some View {
        VStack {
            let result = viewModel.readFileContent(path: file.path)
            
            if let content = result.content {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let error = result.error {
                errorView(message: error)
            } else {
                errorView(message: "Unknown error loading text content")
            }
        }
    }
    
    private var hexContentView: some View {
        VStack {
            if let hexDump = viewModel.generateHexDump(for: file.path) {
                ScrollView {
                    Text(hexDump)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                errorView(message: "Failed to generate hex dump")
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .padding()
            
            Text(message)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct FileDetails: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let creationDate: Date?
    let modificationDate: Date?
    let owner: String
    let permissions: String
    let fileType: String
    
    init(path: String) {
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        self.isDirectory = fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
        
        if let attributes = try? fileManager.attributesOfItem(atPath: path) {
            self.size = attributes[.size] as? Int64 ?? 0
            self.creationDate = attributes[.creationDate] as? Date
            self.modificationDate = attributes[.modificationDate] as? Date
            self.owner = attributes[.ownerAccountName] as? String ?? "Unknown"
            
            if let permissions = attributes[.posixPermissions] as? NSNumber {
                self.permissions = String(format: "%o", permissions.int16Value)
            } else {
                self.permissions = "Unknown"
            }
            
            if let fileType = attributes[.type] as? String {
                self.fileType = fileType
            } else {
                self.fileType = isDirectory ? "Directory" : "File"
            }
        } else {
            self.size = 0
            self.creationDate = nil
            self.modificationDate = nil
            self.owner = "Unknown"
            self.permissions = "Unknown"
            self.fileType = isDirectory ? "Directory" : "File"
        }
    }
}

class SystemFileManagerModel: ObservableObject {
    @Published var currentPath: String = "/System"
    @Published var navigationStack: [String] = []
    @Published var files: [FileDetails] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    
    var filteredFiles: [FileDetails] {
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func loadDirectory(path: String) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var fileList: [FileDetails] = []
            
            let fileManager = FileManager.default
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                
                for item in contents {
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    let fileDetails = FileDetails(path: fullPath)
                    fileList.append(fileDetails)
                }
                
                fileList.sort { (file1, file2) -> Bool in
                    if file1.isDirectory && !file2.isDirectory {
                        return true
                    } else if !file1.isDirectory && file2.isDirectory {
                        return false
                    } else {
                        return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
                    }
                }
                
                DispatchQueue.main.async {
                    self?.files = fileList
                    self?.currentPath = path
                    self?.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    iDeviceLogger("[!] Failed to list directory contents at \(path): \(error.localizedDescription)")
                    self?.files = []
                    self?.isLoading = false
                }
            }
        }
    }
    
    func navigateToDirectory(path: String) {
        navigationStack.append(currentPath)
        loadDirectory(path: path)
    }
    
    func navigateBack() {
        guard !navigationStack.isEmpty else { return }
        
        let previousPath = navigationStack.removeLast()
        loadDirectory(path: previousPath)
    }
    
    func detectFileType(for path: String) -> String {
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        switch fileExtension {
        case "plist":
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: [.alwaysMapped, .uncached])
                if data.count >= 8 {
                    let signature = data.prefix(8)
                    if signature.starts(with: [98, 112, 108, 105, 115, 116]) {
                        return "Binary Property List"
                    }
                }
                return "Property List"
            } catch {
                return "Property List"
            }
        case "xml":
            return "XML File"
        case "html", "htm":
            return "HTML File"
        case "txt", "log", "md":
            return "Text File"
        case "png", "jpg", "jpeg", "gif", "heic":
            return "Image"
        case "pdf":
            return "PDF Document"
        case "c", "h", "swift", "m", "cpp", "php", "js", "css":
            return "Source Code"
        case "zip", "rar", "tar", "gz":
            return "Archive"
        case "json":
            return "JSON File"
        case "mp3":
            return "MP3 Audio File"
        case "m4a", "aac":
            return "AAC Audio File"
        case "wav":
            return "WAV Audio File"
        case "caf":
            return "CAF Audio File"
        case "aiff", "aif":
            return "AIFF Audio File"
        case "flac":
            return "FLAC Audio File"
        case "":
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                return "Directory"
            }

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: [.alwaysMapped, .uncached])
                if data.count >= 8 {
                    let signature = data.prefix(8)
                    if signature.starts(with: [98, 112, 108, 105, 115, 116]) { // "bplist" in ASCII
                        return "Binary Property List"
                    }
                }
            } catch {
            }
            
            return "Binary File"
        default:
            return "Unknown File Type"
        }
    }
    
    func getFileIcon(for file: FileDetails) -> String {
        if file.isDirectory {
            return "folder.fill"
        }
        
        let fileExtension = URL(fileURLWithPath: file.path).pathExtension.lowercased()
        
        switch fileExtension {
        case "plist":
            return "doc.text.fill"
        case "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "html", "htm":
            return "globe"
        case "txt", "log", "md":
            return "doc.text"
        case "png", "jpg", "jpeg", "gif", "heic":
            return "photo"
        case "pdf":
            return "doc.fill"
        case "c", "h", "swift", "m", "cpp", "php", "js", "css":
            return "chevron.left.slash.chevron.right"
        case "zip", "rar", "tar", "gz":
            return "archivebox.fill"
        case "json":
            return "curlybraces"
        case "mp3", "m4a", "aac", "wav", "caf", "aiff", "aif", "flac":
            return "music.note"
        default:
            if let firstBytes = try? Data(contentsOf: URL(fileURLWithPath: file.path), options: [.alwaysMapped, .uncached]).prefix(8) {
                let signature = firstBytes.map { String(format: "%02x", $0) }.joined()
                if signature.hasPrefix("62706c697374") {
                    return "doc.text.fill"
                }
            }
            
            return "doc.fill"
        }
    }
    
    func readFileContent(path: String) -> (content: String?, error: String?) {
        if path.isEmpty { return (nil, "Invalid file path") }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
        
            if detectFileType(for: path) == "Binary Property List" {
                do {
                    let plistObj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    let xmlData = try PropertyListSerialization.data(fromPropertyList: plistObj, format: .xml, options: 0)
                    
                    if let xmlString = String(data: xmlData, encoding: .utf8) {
                        return (xmlString, nil)
                    } else {
                        return (nil, "Failed to convert binary plist to readable format")
                    }
                } catch {
                    return (nil, "Error processing plist: \(error.localizedDescription)")
                }
            }
            
            var isText = true
            let sampleData = data.prefix(min(1024, data.count))
            for byte in sampleData {
                if (byte < 32 || byte > 126) && !([9, 10, 13].contains(byte)) {
                    isText = false
                    break
                }
            }
            
            if isText {
                if let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                    return (content, nil)
                }
            }
            
            return (nil, "Binary file - cannot display content")
            
        } catch {
            return (nil, "Error reading file: \(error.localizedDescription)")
        }
    }
    
    func formattedFileSize(size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct SystemFileManagerView: View {
    @StateObject private var viewModel = SystemFileManagerModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showFileDetails: Bool = false
    @State private var selectedFile: FileDetails? = nil
    @State private var showFileContent: Bool = false
    @State private var fileContent: String = ""
    @State private var fileError: String? = nil
    @State private var showFileOptionsAlert: Bool = false
    @State private var showCopiedPathToast: Bool = false
    @State private var isSearching: Bool = false
    
    var body: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                searchBarView
                
                pathNavigationView
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredFiles.isEmpty {
                    emptyDirectoryView
                } else {
                    fileListView
                }
            }
            
            if showCopiedPathToast {
                VStack {
                    Spacer()
                    Text("Path copied to clipboard")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ToolkitColors.darkBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopiedPathToast = false
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadDirectory(path: "/System")
        }
        .alert(isPresented: $showFileOptionsAlert) {
            createFileOptionsAlert()
        }
        .sheet(isPresented: $showFileDetails) {
            fileDetailsView
        }
        .sheet(isPresented: $showFileContent) {
            if let selectedFile = selectedFile {
                FileContentView(file: selectedFile, viewModel: viewModel)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.9))
            }
            .padding(.trailing, 8)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ToolkitColors.accent)
                
                Text("System File Manager")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isSearching.toggle()
                }
            }) {
                Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.9))
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(ToolkitColors.headerBackground)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
    }
    
    private var searchBarView: some View {
        Group {
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search files...", text: $viewModel.searchText)
                        .foregroundColor(.white)
                        .accentColor(ToolkitColors.accent)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ToolkitColors.darkBlue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var pathNavigationView: some View {
        VStack(spacing: 0) {
            HStack {
                if !viewModel.navigationStack.isEmpty {
                    Button(action: {
                        viewModel.navigateBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Back")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(ToolkitColors.accent)
                    }
                    .padding(.trailing, 8)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(viewModel.currentPath.split(separator: "/").enumerated()), id: \.offset) { index, component in
                            if index > 0 || component.count > 0 {
                                Text("/")
                                    .foregroundColor(.gray)
                            }
                            
                            if component.count > 0 {
                                Text(String(component))
                                    .foregroundColor(.white)
                            } else if index == 0 {
                                Text("Root")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                Menu {
                    Button("Copy Path") {
                        UIPasteboard.general.string = viewModel.currentPath
                        withAnimation {
                            showCopiedPathToast = true
                        }
                    }
                    
                    Button("Jump to Root") {
                        viewModel.navigationStack.removeAll()
                        viewModel.loadDirectory(path: "/")
                    }
                    
                    Button("Jump to /System") {
                        viewModel.navigationStack.removeAll()
                        viewModel.loadDirectory(path: "/System")
                    }
                    
                    Button("Jump to Frameworks") {
                        viewModel.navigationStack.removeAll()
                        viewModel.loadDirectory(path: "/System/Library/Frameworks")
                    }
                    
                    Button("Jump to Developer") {
                        viewModel.navigationStack.removeAll()
                        viewModel.loadDirectory(path: "/Developer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(ToolkitColors.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(ToolkitColors.darkBlue.opacity(0.3))
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading files...")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            Spacer()
        }
    }
    
    private var emptyDirectoryView: some View {
        VStack {
            Spacer()
            
            if viewModel.searchText.isEmpty {
                Image(systemName: "folder")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .padding()
                
                Text("This directory is empty or I don't have access to its contents. The exploit is not helping me in this. Sorry.")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .padding()
                
                Text("No files match '\(viewModel.searchText)'")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Text("Clear Search")
                        .foregroundColor(ToolkitColors.accent)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
        }
    }
    
    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredFiles) { file in
                    fileRowView(file)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    private func fileRowView(_ file: FileDetails) -> some View {
        Button(action: {
            if file.isDirectory {
                viewModel.navigateToDirectory(path: file.path)
            } else {
                selectedFile = file
                showFileOptionsAlert = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.getFileIcon(for: file))
                    .font(.system(size: 20))
                    .foregroundColor(file.isDirectory ? ToolkitColors.accent : .gray)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(file.isDirectory ? "Directory" : viewModel.detectFileType(for: file.path))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if !file.isDirectory {
                            Text(viewModel.formattedFileSize(size: file.size))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                if file.isDirectory {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                } else {
                    Button(action: {
                        selectedFile = file
                        showFileDetails = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(ToolkitColors.accent.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
    
    private var fileDetailsView: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        showFileDetails = false
                    }) {
                        Text("Close")
                            .foregroundColor(ToolkitColors.accent)
                    }
                    
                    Spacer()
                    
                    Text("File Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        if let file = selectedFile {
                            UIPasteboard.general.string = file.path
                            withAnimation {
                                showCopiedPathToast = true
                            }
                        }
                    }) {
                        Text("Copy Path")
                            .foregroundColor(ToolkitColors.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ToolkitColors.headerBackground)
                
                if let file = selectedFile {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: viewModel.getFileIcon(for: file))
                                    .font(.system(size: 40))
                                    .foregroundColor(ToolkitColors.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(file.isDirectory ? "Directory" : viewModel.detectFileType(for: file.path))
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                detailRow(title: "Path", value: file.path)
                                
                                if !file.isDirectory {
                                    detailRow(title: "Size", value: viewModel.formattedFileSize(size: file.size))
                                }
                                
                                if let created = file.creationDate {
                                    detailRow(title: "Created", value: dateFormatter.string(from: created))
                                }
                                
                                if let modified = file.modificationDate {
                                    detailRow(title: "Modified", value: dateFormatter.string(from: modified))
                                }
                                
                                detailRow(title: "Owner", value: file.owner)
                                detailRow(title: "Permissions", value: file.permissions)
                                detailRow(title: "Type", value: file.fileType)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ToolkitColors.darkBlue.opacity(0.3))
                            )
                            .padding(.horizontal, 16)
                            
                            if !file.isDirectory {
                                Button(action: {
                                    openFile(file: file)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                        Text("Open File")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(ToolkitColors.mediumBlue)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }
    
    private var fileContentView: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        showFileContent = false
                    }) {
                        Text("Close")
                            .foregroundColor(ToolkitColors.accent)
                    }
                    
                    Spacer()
                    
                    if let file = selectedFile {
                        Text(file.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let file = selectedFile {
                            UIPasteboard.general.string = file.path
                            withAnimation {
                                showCopiedPathToast = true
                            }
                        }
                    }) {
                        Text("Copy Path")
                            .foregroundColor(ToolkitColors.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ToolkitColors.headerBackground)
                
                if let file = selectedFile {
                    if isAudioFile(path: file.path) {
                        FileContentView(file: selectedFile!, viewModel: viewModel)
                    } else {
                        let fileType = viewModel.detectFileType(for: file.path)
                        
                        if fileType == "Image" {
                            if let image = UIImage(contentsOfFile: file.path) {
                                ScrollView {
                                    VStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .padding()
                                        
                                        Text("Resolution: \(Int(image.size.width)) × \(Int(image.size.height))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                errorView(message: "Failed to load image")
                            }
                        } else if !fileContent.isEmpty {
                            ScrollView {
                                Text(fileContent)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else if fileError?.contains("Binary file") == true {
                            ScrollView {
                                if let hexDump = generateHexDump(for: file.path) {
                                    Text(hexDump)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    errorView(message: "Failed to generate hex dump")
                                }
                            }
                        } else if let error = fileError {
                            errorView(message: error)
                        }
                    }
                }
            }
            
            if showCopiedPathToast {
                VStack {
                    Spacer()
                    Text("Path copied to clipboard")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ToolkitColors.darkBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopiedPathToast = false
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func errorView(message: String) -> some View {
            VStack {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .padding()
                
                Text(message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
    }
    
    private func generateHexDump(for path: String, maxBytes: Int = 4096) -> String? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
            defer { fileHandle.closeFile() }
            
            let data = fileHandle.readData(ofLength: maxBytes)
            let fileSize = try FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64 ?? 0
            
            var hexDump = ""
            var ascii = ""
            var line = ""
            
            for (index, byte) in data.enumerated() {
                let hex = String(format: "%02X ", byte)
                line += hex
                
                let char = (byte >= 32 && byte <= 126) ? String(format: "%c", byte) : "."
                ascii += char
                
                if (index + 1) % 16 == 0 || index == data.count - 1 {
                    while line.count < 16 * 3 {
                        line += "   "
                    }
                    
                    let address = String(format: "%08X", (index / 16) * 16)
                    hexDump += "\(address)  \(line) |" + ascii + "|\n"
                    
                    line = ""
                    ascii = ""
                }
            }
        
            if fileSize > Int64(maxBytes) {
                hexDump += "\n... (showing first \(maxBytes) bytes of \(fileSize) total bytes)"
            }
            
            return hexDump
            
        } catch {
            return "Error generating hex dump: \(error.localizedDescription)"
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ToolkitColors.accent)
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
    
    private func createFileOptionsAlert() -> Alert {
        guard let file = selectedFile else {
            return Alert(title: Text("Error"), message: Text("No file selected"), dismissButton: .default(Text("OK")))
        }
        
        return Alert(
            title: Text(file.name),
            message: Text("Choose an action for this file"),
            primaryButton: .default(Text("Open")) {
                openFile(file: file)
            },
            secondaryButton: .default(Text("View Details")) {
                showFileDetails = true
            }
        )
    }
    
    private func openFile(file: FileDetails) {
        selectedFile = file
        
        let fileExtension = URL(fileURLWithPath: file.path).pathExtension.lowercased()
        let audioExtensions = ["mp3", "m4a", "aac", "wav", "caf", "aiff", "aif", "flac"]
        
        if audioExtensions.contains(fileExtension) {
            self.fileContent = ""
            self.fileError = nil
            showFileContent = true
            return
        }
        
        let result = viewModel.readFileContent(path: file.path)
        self.fileContent = result.content ?? ""
        self.fileError = result.error
        showFileContent = true
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
}

extension ContentView {
    @ViewBuilder
    var fileManagerButton: some View {
        Button(action: {
            withAnimation {
                showFileManager.toggle()
            }
        }) {
            Image(systemName: "folder")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ToolkitColors.accent.opacity(0.9))
        }
        .sheet(isPresented: $showFileManager) {
            SystemFileManagerView()
        }
    }
}

extension SystemFileManagerModel {
    func canViewFileContent(file: FileDetails) -> Bool {
        let fileType = detectFileType(for: file.path)
        
        switch fileType {
        case "Property List", "Binary Property List", "XML File", "HTML File",
             "Text File", "Source Code", "JSON File":
            return true
        case "Image":
            return true
        case "MP3 Audio File", "AAC Audio File", "WAV Audio File",
             "CAF Audio File", "AIFF Audio File", "FLAC Audio File":
            return true
        case "PDF Document":
            return true
        default:
            return true
        }
    }
    
    func loadImage(from path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return UIImage(contentsOfFile: path)
    }
    
    func syntaxHighlightHTML(html: String) -> AttributedString {
        var attributedString = AttributedString(html)
        //TODO: maybe some syntax highlighting shit?
        return attributedString
    }
    
    func isPlist(path: String) -> Bool {
        return path.hasSuffix(".plist") || detectFileType(for: path) == "Binary Property List"
    }
    
    func generateHexDump(for path: String, maxBytes: Int = 4096) -> String? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
            defer { fileHandle.closeFile() }
            
            let data = fileHandle.readData(ofLength: maxBytes)
            let fileSize = try FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64 ?? 0
            
            var hexDump = ""
            var ascii = ""
            var line = ""
            
            for (index, byte) in data.enumerated() {
                let hex = String(format: "%02X ", byte)
                line += hex
            
                let char = (byte >= 32 && byte <= 126) ? String(format: "%c", byte) : "."
                ascii += char
                
                if (index + 1) % 16 == 0 || index == data.count - 1 {
                    while line.count < 16 * 3 {
                        line += "   "
                    }
                    
                    let address = String(format: "%08X", (index / 16) * 16)
                    hexDump += "\(address)  \(line) |" + ascii + "|\n"
                    
                    line = ""
                    ascii = ""
                }
            }
            
            if fileSize > Int64(maxBytes) {
                hexDump += "\n... (showing first \(maxBytes) bytes of \(fileSize) total bytes)"
            }
            
            return hexDump
            
        } catch {
            return "Error generating hex dump: \(error.localizedDescription)"
        }
    }
    
    func convertBinaryPlistToXML(path: String) -> String? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            do {
                let plistObj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                let xmlData = try PropertyListSerialization.data(fromPropertyList: plistObj, format: .xml, options: 0)
                
                if let xmlString = String(data: xmlData, encoding: .utf8) {
                    return xmlString
                }
            } catch {
                return "Error processing plist: \(error.localizedDescription)"
            }
        } catch {
            return "Error reading file: \(error.localizedDescription)"
        }
        
        return nil
    }
    
    func loadPlistAsPropertyList(from path: String) -> [String: Any]? {
        if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return dict
        }
        return nil
    }
}
