//
//  TweakService.swift
//  iDevice Toolkit
//
//  Created by GeoSn0w on 5/12/25.
//

import Foundation
import Combine

class TweaksService {
    static let shared = TweaksService()
    
    private init() {}
    
    private let githubUrl = "https://raw.githubusercontent.com/GeoSn0w/iDevice-Toolkit/refs/heads/main/TweakRepo/tweaks.json"
    
    func loadTweaks() -> AnyPublisher<[TweakPathForFile], Error> {
        return fetchTweaksFromGitHub()
            .handleEvents(receiveOutput: { tweaks in
                print("[+] Successfully fetched and using \(tweaks.count) tweaks from GitHub")
            })
            .catch { [weak self] error -> AnyPublisher<[TweakPathForFile], Error> in
                print("[!] Failed to fetch tweaks from GitHub: \(error.localizedDescription)")
                
                guard let self = self else {
                    return Fail(error: NSError(domain: "TweaksService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])).eraseToAnyPublisher()
                }
                
                return self.loadDefaultTweaks()
                    .handleEvents(receiveOutput: { _ in
                        print("[+] Using default tweaks as fallback")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchTweaksFromGitHub() -> AnyPublisher<[TweakPathForFile], Error> {
        guard let url = URL(string: githubUrl) else {
            return Fail(error: NSError(domain: "TweaksService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid GitHub URL"])).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data in
                do {
                    let decoder = JSONDecoder()
                    let tweaks = try decoder.decode([TweakPathForFile].self, from: data)
                    print("[+] Successfully fetched tweaks from GitHub")
                    return tweaks
                } catch {
                    print("[!] Tweaks JSON decoding error: \(error.localizedDescription)")
                    throw error
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func loadDefaultTweaks() -> AnyPublisher<[TweakPathForFile], Error> {
        guard let path = Bundle.main.path(forResource: "default_tweaks", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            
            return Just(DefaultTweaks.tweaks)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Just(data)
            .tryMap { data in
                let decoder = JSONDecoder()
                return try decoder.decode([TweakPathForFile].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

struct DefaultTweaks {
    static let tweaks: [TweakPathForFile] = {
        guard let jsonData = defaultTweaksJSON.data(using: .utf8),
              let tweaks = try? JSONDecoder().decode([TweakPathForFile].self, from: jsonData) else {
            print("[!] Failed to parse hardcoded tweaks JSON")
            return []
        }
        return tweaks
    }()
    
    // The default tweaks JSON string in case the user has no wifi, etc.
    
    static let defaultTweaksJSON = """
    [
      {
        "icon": "dock.rectangle",
        "name": "Hide the Dock",
        "paths": [
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockDark.materialrecipe",
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockLight.materialrecipe"
        ],
        "description": "Completely remove the dock background from your home screen. Tweak by @Skadz108.",
        "category": "Aesthetics"
      },
      {
        "icon": "line.3.horizontal",
        "name": "Hide the Home Bar",
        "paths": [
          "/System/Library/PrivateFrameworks/MaterialKit.framework/Assets.car"
        ],
        "description": "Remove the bottom home indicator bar. Tweak by @Skadz108.",
        "category": "Aesthetics"
      },
      {
        "icon": "folder",
        "name": "Hide Folder Backgrounds",
        "paths": [
          "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderDark.materialrecipe",
          "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderLight.materialrecipe"
        ],
        "description": "Make app folders completely transparent. Tweak by @Skadz108.",
        "category": "Aesthetics"
      },
      {
        "icon": "lock.iphone",
        "name": "Hide Unlock Background",
        "paths": [
          "/System/Library/PrivateFrameworks/CoverSheet.framework/dashBoardPasscodeBackground.materialrecipe"
        ],
        "description": "Remove the passcode entry background on the lock screen",
        "category": "Aesthetics"
      },
      {
        "icon": "bubble.left",
        "name": "Clean Message Bubbles",
        "paths": [
          "/System/Library/PrivateFrameworks/ChatKit.framework/bubbleDark.materialrecipe",
          "/System/Library/PrivateFrameworks/ChatKit.framework/bubbleLight.materialrecipe"
        ],
        "description": "Simplify the look of chat bubbles in Messages",
        "category": "Experimental"
      },
      {
        "icon": "square.stack.3d.forward.dottedline",
        "name": "Transparent Player & Notis",
        "paths": [
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeLight.visualstyleset",
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeDark.visualstyleset",
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/plattersDark.materialrecipe",
          "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderLight.materialrecipe",
          "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderDark.materialrecipe",
          "/System/Library/PrivateFrameworks/CoreMaterial.framework/platters.materialrecipe"
        ],
        "description": "Transparent Media Player & Notifications. Tweak by @straight_tamago / mdc0",
        "category": "Aesthetics"
      },
      {
        "icon": "eye.slash.fill",
        "name": "Kill Camera Shutter Sound",
        "paths": [
           "/System/Library/Audio/UISounds/photoShutter.caf",
                  "/System/Library/Audio/UISounds/begin_record.caf",
                  "/System/Library/Audio/UISounds/end_record.caf",
                  "/System/Library/Audio/UISounds/Modern/camera_shutter_burst.caf",
                  "/System/Library/Audio/UISounds/Modern/camera_shutter_burst_begin.caf",
                  "/System/Library/Audio/UISounds/Modern/camera_shutter_burst_end.caf"
          ],
        "description": "Disables camera shutter sound. Killing the Camera app may re-enable it. Tweak by @straight_tamago",
        "category": "Privacy"
      },
       {
        "icon": "eye.slash.fill",
        "name": "Kill Call Recording Sound",
        "paths": [
           "/var/mobile/Library/CallServices/Greetings/default/StartDisclosure.caf",
            "/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a",
            "/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf",
            "/System/Library/PrivateFrameworks/ConversationKit.framework/call_recording_countdown.caf"
          ],
        "description": "Disables the notification sound for enabled call recording on iOS 18+. Tweak by @straight_tamago",
        "category": "Privacy"
      },
    ]
    """
}
