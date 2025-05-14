import SwiftUI
import DeviceKit
import Combine
import UIKit
import UniformTypeIdentifiers

struct TweakPathForFile: Identifiable, Codable {
    var id: String { name }
    var icon: String
    var name: String
    var paths: [String]
    var description: String
    var category: TweakCategory
    
    enum CodingKeys: String, CodingKey {
        case icon, name, paths, description, category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        icon = try container.decode(String.self, forKey: .icon)
        name = try container.decode(String.self, forKey: .name)
        paths = try container.decode([String].self, forKey: .paths)
        description = try container.decode(String.self, forKey: .description)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        if let decodedCategory = TweakCategory(rawValue: categoryString) {
            category = decodedCategory
        } else {
            category = .experimental
        }
    }
}

extension TweakPathForFile {
    init(icon: String, name: String, paths: [String], description: String, category: TweakCategory) {
        self.icon = icon
        self.name = name
        self.paths = paths
        self.description = description
        self.category = category
    }
}

enum TweakCategory: String, Codable, CaseIterable {
    case aesthetics = "Aesthetics"
    case performance = "Performance"
    case privacy = "Privacy"
    case experimental = "Experimental"
    case custom = "Custom Tweaks"
}

// Helper extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// File document type for the custom tweaks
struct TweakDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType.json] }
    
    var tweak: TweakPathForFile
    
    init(tweak: TweakPathForFile) {
        self.tweak = tweak
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let decodedTweak = try? JSONDecoder().decode(TweakPathForFile.self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.tweak = decodedTweak
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(tweak)
        return FileWrapper(regularFileWithContents: data)
    }
}

// Share sheet for exporting tweaks
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CustomTweaksCategoryButton: View {
    @Binding var showCustomTweakCreator: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
                showCustomTweakCreator = true
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ToolkitColors.green)
                    .frame(width: 26)
                
                Text("Create Custom Tweak")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ToolkitColors.categoryHeaderBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

enum ToolkitColors {
    struct ColorComponents {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
        
        var color: Color {
            Color(.sRGB, red: red/255, green: green/255, blue: blue/255, opacity: alpha/255)
        }
    }
    
    private static let palette = (
        midnight: ColorComponents(red: 15, green: 26, blue: 42, alpha: 255),
        azure: ColorComponents(red: 23, green: 46, blue: 76, alpha: 255),
        cobalt: ColorComponents(red: 31, green: 64, blue: 104, alpha: 255),
        slate: ColorComponents(red: 37, green: 58, blue: 80, alpha: 255),
        
        navyBlue: ColorComponents(red: 30, green: 58, blue: 95, alpha: 255),
        slateGray: ColorComponents(red: 37, green: 58, blue: 80, alpha: 255),
        electric: ColorComponents(red: 97, green: 218, blue: 251, alpha: 255),
        neon: ColorComponents(red: 0, green: 255, blue: 157, alpha: 255),
        glow: ColorComponents(red: 37, green: 255, blue: 113, alpha: 255),
        moss: ColorComponents(red: 29, green: 59, blue: 44, alpha: 255)
    )
    
    static var background: Color { palette.midnight.color }
    static var darkBlue: Color { palette.azure.color }
    static var mediumBlue: Color { palette.cobalt.color }
    static var headerBackground: Color { palette.cobalt.color }
    static var categoryBackground: Color { palette.slate.color }
    static var accent: Color { palette.electric.color }
    static var green: Color { palette.neon.color }
    static var glowGreen: Color { palette.glow.color }
    static var darkGreen: Color { palette.moss.color }
    static var capsuleBackground: Color { palette.navyBlue.color }
    static var categoryHeaderBackground: Color { palette.slateGray.color }
}

struct NeonBorder: ViewModifier {
    var isActive: Bool
    var color: Color = ToolkitColors.accent
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? color : Color.clear, lineWidth: 1.5)
                    .blur(radius: isActive ? 2.5 : 0)
            )
    }
}

struct GlowText: View {
    var text: String
    var color: Color = ToolkitColors.green
    
    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: 2, x: 0, y: 0)
    }
}

struct StepProgressView: View {
    var currentStep: Int
    var totalSteps: Int
    var stepText: String
    var hasError: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    stepItem(step: step)
                    
                    if step < totalSteps - 1 {
                        connectingLine(fromStep: step)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            GlowText(text: stepText, color: hasError ? Color.red : ToolkitColors.green)
                .frame(height: 30)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ToolkitColors.darkBlue.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ToolkitColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func stepItem(step: Int) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(getStepColor(step))
                .frame(width: 18, height: 18)
                .shadow(color: getStepShadowColor(step), radius: 4)
                .zIndex(1)
            
            Text(getStepName(step))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(step <= currentStep ? .white : .gray)
        }
    }
    
    @ViewBuilder
    private func connectingLine(fromStep step: Int) -> some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [
                    getConnectionColor(step: step, isStart: true),
                    getConnectionColor(step: step, isStart: false)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(height: 2)
            .offset(y: -13)
    }
    
    private func getStepName(_ step: Int) -> String {
        switch step {
        case 0: return "start"
        case 1: return "Exploit"
        case 2: return "Tweak"
        case 3: return "Done"
        default: return "Step \(step + 1)"
        }
    }
    
    private func getStepColor(_ step: Int) -> Color {
        if hasError && step == currentStep {
            return Color.red
        } else if step < currentStep {
            return ToolkitColors.green
        } else if step == currentStep {
            if step == 3 && !hasError {
                return ToolkitColors.green
            }
            return ToolkitColors.accent
        } else {
            return ToolkitColors.darkBlue
        }
    }
    
    private func getStepShadowColor(_ step: Int) -> Color {
        if hasError && step == currentStep {
            return Color.red.opacity(0.6)
        } else if step < currentStep {
            return ToolkitColors.green.opacity(0.6)
        } else if step == currentStep {
            return ToolkitColors.accent.opacity(0.6)
        } else {
            return Color.clear
        }
    }
    
    private func getConnectionColor(step: Int, isStart: Bool) -> Color {
        if isStart {
            if hasError && step + 1 == currentStep {
                return step < currentStep ? ToolkitColors.green : ToolkitColors.darkBlue
            } else {
                return step < currentStep ? ToolkitColors.green : (step == currentStep ? ToolkitColors.accent : ToolkitColors.darkBlue)
            }
        }
        else {
            if hasError && step + 1 == currentStep {
                return Color.red
            } else {
                return step + 1 < currentStep ? ToolkitColors.green : (step + 1 == currentStep ? ToolkitColors.accent : ToolkitColors.darkBlue)
            }
        }
    }
}

struct ToolkitButton: View {
    var icon: String
    var text: String
    var disabled: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(disabled ? ToolkitColors.darkBlue.opacity(0.3) : ToolkitColors.mediumBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(disabled ? Color.gray.opacity(0.2) : ToolkitColors.accent.opacity(0.5), lineWidth: 1)
                    )
            )
            .foregroundColor(disabled ? .gray : .white)
            .opacity(disabled ? 0.7 : 1)
        }
        .disabled(disabled)
    }
}

struct TweakCategoryView: View {
    var category: TweakCategory
    var tweaks: [TweakPathForFile]
    @Binding var isExpanded: Bool
    @Binding var enabledTweakIds: [String]
    @Binding var hasEnabledTweaks: Bool
    @ObservedObject var customTweakManager = CustomTweakManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            categoryHeader
            
            if isExpanded {
                tweaksList
            }
        }
    }
    
    private var categoryHeader: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: getCategoryIcon(category))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ToolkitColors.accent)
                    .frame(width: 26)
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("\(tweaks.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ToolkitColors.capsuleBackground)
                    )
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ToolkitColors.categoryHeaderBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var tweaksList: some View {
        VStack(spacing: 8) {
            ForEach(tweaks) { tweak in
                TweakRowView(
                    tweak: tweak,
                    isEnabled: enabledTweakIds.contains(tweak.id),
                    toggleAction: { toggleTweak(tweak) },
                    deleteAction: category == .custom ? { deleteTweak(tweak) } : nil,
                    isCustomTweak: category == .custom
                )
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
    }
    
    private func deleteTweak(_ tweak: TweakPathForFile) {
        if enabledTweakIds.contains(tweak.id) {
                enabledTweakIds.removeAll { $0 == tweak.id }
                hasEnabledTweaks = !enabledTweakIds.isEmpty
        }
            
        customTweakManager.deleteTweak(withID: tweak.id)
    }
    
    private func getCategoryIcon(_ category: TweakCategory) -> String {
        switch category {
        case .aesthetics: return "paintbrush.fill"
        case .performance: return "bolt.fill"
        case .privacy: return "lock.shield.fill"
        case .experimental: return "atom"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    private func toggleTweak(_ tweak: TweakPathForFile) {
        if enabledTweakIds.contains(tweak.id) {
            enabledTweakIds.removeAll { $0 == tweak.id }
        } else {
            enabledTweakIds.append(tweak.id)
        }
        
        hasEnabledTweaks = !enabledTweakIds.isEmpty
    }
}

struct TweakRowView: View {
    var tweak: TweakPathForFile
    var isEnabled: Bool
    var toggleAction: () -> Void
    var deleteAction: (() -> Void)? = nil
    var isCustomTweak: Bool = false
    
    @State private var showDetails: Bool = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tweakButton
            
            if showDetails {
                detailsView
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Custom Tweak"),
                message: Text("Are you sure you want to delete \"\(tweak.name)\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let delete = deleteAction {
                        delete()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var tweakButton: some View {
        Button(action: toggleAction) {
            HStack(spacing: 12) {
                // Tweak icon
                Image(systemName: tweak.icon)
                    .font(.system(size: 15))
                    .frame(width: 18)
                    .foregroundColor(isEnabled ? ToolkitColors.green : .white.opacity(0.7))
                
                // Tweak name
                Text(tweak.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 16) { // Increase spacing between buttons
                    // Delete button - only for custom tweaks
                    if isCustomTweak {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(Color.red.opacity(0.8))
                        }
                    }
                    
                    // Info button
                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(ToolkitColors.accent.opacity(0.7))
                    }
                }
                .padding(.trailing, 8)
                
                // Toggle indicator
                ZStack {
                    Circle()
                        .stroke(isEnabled ? ToolkitColors.green.opacity(0.9) : Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if isEnabled {
                        Circle()
                            .fill(ToolkitColors.green)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ToolkitColors.darkBlue.opacity(0.3))
                    .modifier(NeonBorder(isActive: isEnabled, color: ToolkitColors.green.opacity(0.5)))
            )
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tweak.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.top, 6)
            
            Text("Target Paths:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ToolkitColors.accent.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.top, 4)
            
            ForEach(tweak.paths, id: \.self) { path in
                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
            }
        }
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private class CancellableStore {
    var cancellables = Set<AnyCancellable>()
}

struct ContentView: View {
    @StateObject private var updateService = UpdateService.shared
    @State private var updateCheckCancellable: AnyCancellable?
    let device = Device.current
    @AppStorage("enabledTweaks") private var enabledTweakIds: [String] = []
    @State private var progressStep: Int = 0
    @State private var progressText: String = "Ready when you are"
    @State private var showLogs: Bool = false
    @State private var hasError: Bool = false
    @State private var categoryExpanded: [TweakCategory: Bool] = Dictionary(uniqueKeysWithValues: TweakCategory.allCases.map { ($0, false) })
    @State private var isVersionCompatible: Bool = true
    @State private var showAbout: Bool = false
    @State private var showRespringInstructions: Bool = false
    @State private var tweaksAppliedSuccessfully: Bool = false
    
    @State private var tweaks: [TweakPathForFile] = []
    @State private var isLoadingTweaks: Bool = false
    @State private var tweakLoadError: String? = nil
    @State private var hasEnabledTweaks: Bool = false
    @State private var showTerminalLog: Bool = false
    
    @StateObject private var customTweakManager = CustomTweakManager.shared
    @State private var showCustomTweakCreator: Bool = false
    @State private var cancellableStore = CancellableStore()
    
    private var enabledTweaks: [TweakPathForFile] {
        let builtInTweaks = tweaks.filter { tweak in enabledTweakIds.contains(tweak.id) }
        let enabledCustomTweaks = customTweakManager.customTweaks.filter { tweak in
                enabledTweakIds.contains(tweak.id)
        }
        return builtInTweaks + enabledCustomTweaks
    }
    
    private var tweaksByCategory: [TweakCategory: [TweakPathForFile]] {
        var categories = Dictionary(grouping: tweaks) { $0.category }
        categories[.custom] = customTweakManager.customTweaks
        return categories
    }
    
    // MARK: Body
    var body: some View {
        mainView
            .onAppear {
                print("iDevice Toolkit\n[*] Detected device  \(device.systemName!) \(device.systemVersion!), \(device.description)")
                checkVersionCompatibility()
                iDeviceLogger("[i] iDevice Central: Terminal session started")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    updateService.checkForUpdates()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadTweaks()
                    customTweakManager.loadCustomTweaks()
                }
                
            }
            .overlay {
                if updateService.showUpdateAlert {
                    UpdateAlertView()
                }
            }
            .sheet(isPresented: $showTerminalLog) {
                iDeviceCentralTerminal()
            }
            .sheet(isPresented: $showCustomTweakCreator) {
                CustomTweakCreatorView()
            }
    }
    
    private func checkVersionCompatibility() {
        let version = device.systemVersion ?? ""
        let versionComponents = version.split(separator: ".").map { Int($0) ?? 0 }
        
        if versionComponents.count >= 2 {
            let majorVersion = versionComponents[0]
            let minorVersion = versionComponents[1]
            let patchVersion = versionComponents.count >= 3 ? versionComponents[2] : 0
            
            isVersionCompatible = false
            
            // iOS 16.0 - iOS 16.7.10 Supported
            if majorVersion == 16 && minorVersion >= 0 {
                isVersionCompatible = true
            }
            // iOS 17.0 - iOS 17.7.5 Supported
            else if majorVersion == 17 && (minorVersion < 7 || (minorVersion == 7 && patchVersion <= 5)) {
                isVersionCompatible = true
            }
            // iOS 18.0 - iOS 18.3.2 Supported
            else if majorVersion == 18 && (minorVersion < 4) {
                isVersionCompatible = true
            }
            // iOS 15 and lower, iOS 17.7.6+, iOS 18.4+ Not Supported
            else {
                isVersionCompatible = false
            }
            
            if !isVersionCompatible {
                progressText = "Incompatible iOS version"
                hasError = true
                print("[!] Incompatible iOS version detected: \(version)")
                iDeviceLogger("[i] Incompatible iOS version detected")
            }
        }
    }
    
    private func loadTweaks() {
            isLoadingTweaks = true
            tweakLoadError = nil
            
            DispatchQueue.global(qos: .userInitiated).async {
                TweaksService.shared.loadTweaks()
                    .sink(
                        receiveCompletion: { completion in
                            DispatchQueue.main.async {
                                self.isLoadingTweaks = false
                                
                                if case .failure(let error) = completion {
                                    iDeviceLogger("[!] Failed to load tweaks: \(error.localizedDescription)")
                                    self.tweakLoadError = error.localizedDescription
                                    print("[!] Failed to load tweaks: \(error.localizedDescription)")
                                    self.tweakLoadError = error.localizedDescription
                                }
                            }
                        },
                        receiveValue: { loadedTweaks in
                            DispatchQueue.main.async {
                                self.tweaks = loadedTweaks
                                print("[+] Successfully loaded \(loadedTweaks.count) tweaks")
                                if !loadedTweaks.isEmpty {
                                    let categories = Dictionary(grouping: loadedTweaks) { $0.category }
                                    for (category, tweaks) in categories {
                                        iDeviceLogger("   • \(category.rawValue): \(tweaks.count) tweaks")
                                }
                            }
                        }
                    }
                )
            .store(in: &self.cancellableStore.cancellables)
        }
    }
    
    private var mainView: some View {
        ZStack {
            ToolkitColors.background
                .ignoresSafeArea()
            
            if isLoadingTweaks && tweaks.isEmpty {
                loadingView
            } else {
                ScrollViewReader { scrollProxy in
                    VStack(spacing: 0) {
                        headerView
                        
                        if let error = tweakLoadError {
                            errorView(message: error)
                        } else {
                            ScrollView {
                                contentStack
                            }
                            
                            applyButtonView(scrollProxy: scrollProxy)
                        }
                    }
                }
            }
            
            if showAbout {
                aboutOverlay
            }
            if showRespringInstructions {
                respringInstructionsOverlay
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading tweaks...")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            Text("This might take a moment")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ToolkitColors.background)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            
            Text("Failed to load tweaks")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: loadTweaks) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(ToolkitColors.accent)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showAbout.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.9))
            }
            .padding(.trailing, 8)
            
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ToolkitColors.accent)
                
                Text("iDevice Toolkit")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button(action: {
                iDeviceLogger("Opening terminal window")
                withAnimation {
                    showTerminalLog.toggle()
                }
            }) {
                Image(systemName: "terminal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.9))
            }
            .padding(.trailing, 8)
            
            Button(action: {
                updateService.checkForUpdates()
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ToolkitColors.accent.opacity(0.9))
                    .rotationEffect(.degrees(updateService.isCheckingForUpdates ? 360 : 0))
                    .animation(updateService.isCheckingForUpdates ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: updateService.isCheckingForUpdates)
            }
            .disabled(updateService.isCheckingForUpdates)
            .padding(.leading, 8)
            
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(ToolkitColors.headerBackground)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .edgesIgnoringSafeArea(.top)
        )
        .preferredColorScheme(.dark)
    }
    
    private var contentStack: some View {
        VStack(spacing: 22) {
            deviceInfoView
            
            tweaksSection
        }
    }
    
    private var deviceInfoView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.description)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(device.systemName!) \(device.systemVersion!)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(ToolkitColors.darkGreen)
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .fill(!isVersionCompatible ? Color.red : ToolkitColors.green)
                        .frame(width: 8, height: 8)
                        .opacity(progressStep > 0 || !isVersionCompatible ? 1.0 : 0.0)
                }
                
                Text(!isVersionCompatible ? "Incompatible" : (progressStep > 0 ? "Active" : "Ready"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(!isVersionCompatible ? Color.red : (progressStep > 0 ? ToolkitColors.green : .gray))
            }
            .padding(.horizontal, 22)
            
            StepProgressView(
                currentStep: progressStep,
                totalSteps: 4,
                stepText: progressText,
                hasError: hasError || !isVersionCompatible
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ToolkitColors.darkBlue.opacity(0.2))
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .id("progressArea")
    }
    
    private var tweaksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Tweaks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
            
            ForEach(TweakCategory.allCases, id: \.self) { category in
                if let categoryTweaks = tweaksByCategory[category], !categoryTweaks.isEmpty {
                    TweakCategoryView(
                        category: category,
                        tweaks: categoryTweaks,
                        isExpanded: .init(
                            get: { categoryExpanded[category] ?? false },
                            set: { categoryExpanded[category] = $0 }
                        ),
                        enabledTweakIds: $enabledTweakIds,
                        hasEnabledTweaks: $hasEnabledTweaks
                    )
                    .padding(.bottom, 8)
                }
            }
            
            CustomTweaksCategoryButton(showCustomTweakCreator: $showCustomTweakCreator)
                .padding(.bottom, 8)
            
            revertTweaksInfoPanel
                .padding(.bottom, 8)
            
            JailbreakNewsButton()
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }
    
    private var customTweaksCategoryView: some View {
            VStack(spacing: 0) {
                CustomTweaksCategoryButton(showCustomTweakCreator: $showCustomTweakCreator)
                
                if !customTweakManager.customTweaks.isEmpty {
                    TweakCategoryView(
                        category: .custom,
                        tweaks: customTweakManager.customTweaks,
                        isExpanded: .init(
                            get: { categoryExpanded[.custom] ?? false },
                            set: { categoryExpanded[.custom] = $0 }
                        ),
                        enabledTweakIds: $enabledTweakIds,
                        hasEnabledTweaks: $hasEnabledTweaks
                    )
                .padding(.top, 8)
            }
        }
    }
    
    private var revertTweaksInfoPanel: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(ToolkitColors.accent)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to Revert Tweaks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("All tweaks are applied directly to RAM and not persistent storage. If you encounter any issues or want to revert to stock settings, simply restart your device to clear all tweaks from memory.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ToolkitColors.darkBlue.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ToolkitColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    struct JailbreakNewsButton: View {
        var body: some View {
            Button(action: {
                if let url = URL(string: "https://idevicecentral.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ToolkitColors.green)
                        .frame(width: 26)
                    
                    Text("iOS Jailbreak News")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ToolkitColors.categoryHeaderBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func applyButtonView(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 12) {
            ToolkitButton(
                icon: tweaksAppliedSuccessfully ? "arrow.clockwise" : "bolt.fill",
                text: tweaksAppliedSuccessfully ? "Respring to apply" :
                    (progressStep > 0 ? "Cancel Operation" : "Apply Tweaks"),
                disabled: !hasEnabledTweaks && progressStep == 0 && !tweaksAppliedSuccessfully || !isVersionCompatible
            ) {
                if progressStep > 0 {
                    resetProgress()
                } else if tweaksAppliedSuccessfully {
                    withAnimation {
                        showRespringInstructions = true
                    }
                } else {
                    runOperation()
                    
                    withAnimation {
                        scrollProxy.scrollTo("progressArea", anchor: .top)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(ToolkitColors.background)
                .shadow(color: .black.opacity(0.4), radius: 8, y: -4)
        )
    }
    
    private var aboutOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showAbout = false
                    }
                }
            VStack(spacing: 0) {
                HStack {
                    Text("About iDevice Toolkit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showAbout = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ToolkitColors.darkBlue)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("iDevice Toolkit")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ToolkitColors.accent)
                        
                        Text("An advanced toolset for customizing iOS devices")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Group {
                            Text("Made by [iDevice Central](https://idevicecentral.com)")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                            
                            Text("• [GeoSn0w on Twitter](https://twitter.com/FCE365)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                                .padding(.top, 4)
                            
                            Text("• [iDevice Central on YouTube](https://youtube.com/@idevicecentral)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.vertical, 4)
                        
                        Group {
                            Text("• All tweaks are done in by modifying the RAM, so if something goes wrong, you can reboot the device to wipe all tweaks and go back to stock.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• Exploit developed by Ian Beer of Google Project Zero")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        Group {
                            Text("**Credits & Thanks**")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.bottom, 4)
                            
                            Text("• Thanks to [jailbreak.party](https://github.com/jailbreakdotparty) of dirtyZero project for the original inspiration, code and tweak paths")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                            
                            Text("• Thanks to [straight_tamago](https://twitter.com/straight_tamago) of mdc0 project for the original inspiration, code and tweak paths")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                            
                            Text("• Special thanks to Ian Beer for the CVE-2025-24203 bug ([view details](https://project-zero.issues.chromium.org/issues/391518636))")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                            
                            Text("• [Tool-box icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/tool-box)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .tint(ToolkitColors.accent)
                        }
                    }
                    .padding(16)
                }
                .background(ToolkitColors.background)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.6)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.5), radius: 20)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
    
    // MARK: Functions
    private func runOperation() {
        guard !enabledTweaks.isEmpty else { return }
        hasError = false
        
        iDeviceLogger("[*] Starting operation with \(enabledTweaks.count) enabled tweaks")
        
        withAnimation {
            progressStep = 1
            progressText = "Running exploit..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                progressStep = 2
                progressText = "Applying \(self.enabledTweaks.count) tweaks..."
                
                var applyingString = "[+] Applying the selected tweaks: "
                let tweakNames = self.enabledTweaks.map { $0.name }.joined(separator: ", ")
                applyingString += tweakNames
                iDeviceLogger(applyingString)
                
                iDeviceLogger("\n[*] Detailed tweak information:")
                for (index, tweak) in self.enabledTweaks.enumerated() {
                    iDeviceLogger("\n[\(index + 1)/\(self.enabledTweaks.count)] Tweak: \(tweak.name)")
                    
                    iDeviceLogger("    • Paths to modify:")
                    
                    for (pathIndex, path) in tweak.paths.enumerated() {
                        iDeviceLogger("      \(pathIndex + 1). \(path)")
                    }
                }
                
                iDeviceLogger("\n[*] Beginning tweak application process...")
            }
            
            let stats = TweakStats()
            
            self.processTweaks(tweaks: self.enabledTweaks, index: 0, stats: stats) {
                self.proceedToVerification(successCount: stats.successCount, failedCount: stats.failedCount)
                withAnimation {
                    showTerminalLog.toggle()
                    
                }}
        }
    }
    
    private class TweakStats {
        var successCount: Int = 0
        var failedCount: Int = 0
        var pathsSucceeded: Int = 0
        var pathsFailed: Int = 0
        
        var pathFailures: [(path: String, reason: String)] = []
        
        func addFailedPath(path: String, reason: String) {
            pathsFailed += 1
            pathFailures.append((path: path, reason: reason))
        }
    }
    
    private func processTweaks(tweaks: [TweakPathForFile], index: Int, stats: TweakStats, completion: @escaping () -> Void) {
        guard index < tweaks.count else {
            iDeviceLogger("\n[*] iDevice ToolKit Tweak Log")
            if stats.successCount > 0 {
                iDeviceLogger("[✓] \(stats.successCount) tweaks successfully applied")
            }
            if stats.failedCount > 0 {
                iDeviceLogger("[✗] \(stats.failedCount) tweaks failed to apply")
            }
            completion()
            return
        }
        
        let tweak = tweaks[index]
        iDeviceLogger("\n[*] Processing tweak [\(index + 1)/\(tweaks.count)]: \(tweak.name)")
        
        let pathStats = TweakStats()
        
        self.processPaths(tweak: tweak, pathIndex: 0, pathStats: pathStats) {
            iDeviceLogger("----------------------------------------------")
            
            if pathStats.pathsFailed == 0 {
                stats.successCount += 1
                iDeviceLogger("✅ TWEAK STATUS: \(tweak.name) - SUCCESSFULLY APPLIED")
                iDeviceLogger("   • All \(pathStats.pathsSucceeded) paths successfully modified")
            } else if pathStats.pathsSucceeded > 0 {
                stats.failedCount += 1
                iDeviceLogger("⚠️ TWEAK STATUS: \(tweak.name) - PARTIALLY APPLIED")
                iDeviceLogger("   • \(pathStats.pathsSucceeded) paths succeeded")
                iDeviceLogger("   • \(pathStats.pathsFailed) paths failed")
                
                if !pathStats.pathFailures.isEmpty {
                    iDeviceLogger("   • Failure details:")
                    for (index, failure) in pathStats.pathFailures.enumerated() {
                        iDeviceLogger("     \(index + 1). Path: \(failure.path)")
                        iDeviceLogger("        Reason: \(failure.reason)")
                    }
                }
            } else {
                stats.failedCount += 1
                iDeviceLogger("❌ TWEAK STATUS: \(tweak.name) - FAILED")
                iDeviceLogger("   • All \(pathStats.pathsFailed) paths failed to apply")
                
                if !pathStats.pathFailures.isEmpty {
                    iDeviceLogger("   • Failure details:")
                    for (index, failure) in pathStats.pathFailures.enumerated() {
                        iDeviceLogger("     \(index + 1). Path: \(failure.path)")
                        iDeviceLogger("        Reason: \(failure.reason)")
                    }
                }
            }
            iDeviceLogger("----------------------------------------------")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.processTweaks(tweaks: tweaks, index: index + 1, stats: stats, completion: completion)
            }
        }
    }
    private func processPaths(tweak: TweakPathForFile, pathIndex: Int, pathStats: TweakStats, completion: @escaping () -> Void) {
        guard pathIndex < tweak.paths.count else {
            iDeviceLogger("[*] Finished processing all paths for \(tweak.name)")
            completion()
            return
        }
        
        let path = tweak.paths[pathIndex]
        
        iDeviceLogger("[>] Tweak \(tweak.name): Processing path [\(pathIndex + 1)/\(tweak.paths.count)]: \(path)")
        
        do {
            let errorReason = try runExploitForPath(path: path)
            if errorReason == nil {
                pathStats.pathsSucceeded += 1
                iDeviceLogger("[+] Successfully exploited path: \(path)")
            } else if let reason = errorReason {
                pathStats.addFailedPath(path: path, reason: reason)
                iDeviceLogger("[!] Error applying path: \(path)")
                iDeviceLogger("    Error details: \(reason)")
            }
        } catch {
            let reason: String
            if let nsError = error as NSError? {
                reason = nsError.localizedDescription
                pathStats.addFailedPath(path: path, reason: reason)
            } else {
                reason = error.localizedDescription
                pathStats.addFailedPath(path: path, reason: reason)
            }
            
            iDeviceLogger("[!] Error applying path: \(path)")
            iDeviceLogger("    Error details: \(reason)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.processPaths(tweak: tweak, pathIndex: pathIndex + 1, pathStats: pathStats, completion: completion)
        }
    }
    
    private func proceedToVerification(successCount: Int, failedCount: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                progressStep = 3
                progressText = "Verifying changes..."
                
                iDeviceLogger("\n[*] Verifying tweak application results")
                
                self.hasError = successCount == 0 && failedCount > 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        iDeviceLogger("\n================================================")
                        iDeviceLogger("            FINAL OPERATION RESULT              ")
                        iDeviceLogger("================================================")
                        
                        if failedCount == 0 {
                            progressText = "Tweaks applied successfully!"
                            iDeviceLogger("✅ SUCCESS: All \(successCount) tweaks applied successfully!")
                            tweaksAppliedSuccessfully = true
                            progressStep = 0
                        } else if successCount > 0 {
                            progressText = "\(successCount) tweaks applied, \(failedCount) failed"
                            iDeviceLogger("⚠️ PARTIAL SUCCESS: \(successCount) tweaks applied, \(failedCount) failed")
                            tweaksAppliedSuccessfully = successCount > 0
                            progressStep = 0
                        } else {
                            progressText = "Failed to apply any tweaks"
                            iDeviceLogger("❌ FAILED: Could not apply any tweaks")
                            self.hasError = true
                            tweaksAppliedSuccessfully = false
                        }
                        
                        if tweaksAppliedSuccessfully {
                            iDeviceLogger("\n[*] NEXT STEPS:")
                            iDeviceLogger("   1. Respring your device to apply changes")
                            iDeviceLogger("   2. Go to Settings > Display & Brightness")
                            iDeviceLogger("   3. Tap Display Zoom and switch views to trigger respring")
                        } else {
                            iDeviceLogger("\n[*] NEXT STEPS:")
                            iDeviceLogger("   • Try again with different tweaks or check device compatibility")
                        }
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let timestamp = dateFormatter.string(from: Date())
                        iDeviceLogger("\n[*] Operation completed at \(timestamp)")
                        iDeviceLogger("================================================")
                    }
                }
            }
        }
    }
    
    private var respringInstructionsOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showRespringInstructions = false
                        tweaksAppliedSuccessfully = false
                    }
                }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Respring Required")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showRespringInstructions = false
                            tweaksAppliedSuccessfully = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ToolkitColors.darkBlue)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Due to exploit limitations, you need to manually respring your device for the tweaks to take effect.")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Instructions:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ToolkitColors.accent)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text("1.")
                                    .foregroundColor(.white)
                                    .frame(width: 20, alignment: .leading)
                                Text("Go to Settings > Display & Brightness")
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            HStack(alignment: .top) {
                                Text("2.")
                                    .foregroundColor(.white)
                                    .frame(width: 20, alignment: .leading)
                                Text("Scroll down to Display Zoom")
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            HStack(alignment: .top) {
                                Text("3.")
                                    .foregroundColor(.white)
                                    .frame(width: 20, alignment: .leading)
                                Text("Switch between Default and Larger Text options")
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            HStack(alignment: .top) {
                                Text("4.")
                                    .foregroundColor(.white)
                                    .frame(width: 20, alignment: .leading)
                                Text("This will cause a respring")
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            HStack(alignment: .top) {
                                Text("5.")
                                    .foregroundColor(.white)
                                    .frame(width: 20, alignment: .leading)
                                Text("You can switch back to your preferred option afterward")
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .font(.system(size: 14))
                        
                        Spacer(minLength: 20)
                        
                        Button(action: {
                            withAnimation {
                                showRespringInstructions = false
                                tweaksAppliedSuccessfully = false
                            }
                        }) {
                            Text("Got it!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(ToolkitColors.accent)
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                    }
                    .padding(16)
                }
                .background(ToolkitColors.background)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.5)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.5), radius: 20)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
    
    private func resetProgress() {
        withAnimation {
            progressStep = 0
            progressText = "> Ready when you are"
            hasError = false
            tweaksAppliedSuccessfully = false
        }
        print("[!] Tweaking canceled by user.")
    }
    
    private func runExploitForPath(path: String) throws -> String? {
        iDeviceLogger("[*] Running exploit for path: \(path)")
        
        guard let cPath = strdup(path) else {
            let errorMessage = "Failed to allocate memory for path"
            iDeviceLogger("[!] ERROR: \(errorMessage)")
            return errorMessage
        }
        
        defer {
            free(cPath)
        }
        
        let result = poc(cPath)
        
        if result != 0 {
            let errorMessage: String
            switch result {
            case 2: // ENOENT
                errorMessage = "File not found - The path doesn't exist"
            case 13: // EACCES
                errorMessage = "Permission denied - Cannot access the file"
            case 1: // EPERM
                errorMessage = "Operation not permitted - Insufficient privileges"
            case 21: // EISDIR
                errorMessage = "Expected a file but found a directory"
            case 20: // ENOTDIR
                errorMessage = "Expected a directory but found a file"
            case 28: // ENOSPC
                errorMessage = "No space left on device"
            case 9: // EBADF
                errorMessage = "Bad file descriptor"
            case 22: // EINVAL
                errorMessage = "Invalid argument for operation"
            default:
                errorMessage = "Exploit failed with code \(result)"
            }
            
            iDeviceLogger("[!] EXPLOIT ERROR: \(errorMessage)")
            throw NSError(domain: "ExploitError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: errorMessage])
            
        } else {
            iDeviceLogger("[+] Exploit succeeded for path: \(path)")
            return nil
        }
    }
}

#Preview {
    ContentView()
}
