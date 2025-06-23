import Foundation

// MARK: - Public API Exports

/// Main public interface for Datalyr iOS SDK
public extension DatalyrSDK {
    
    /// Convenience method to initialize with basic configuration
    /// - Parameters:
    ///   - workspaceId: Your Datalyr workspace ID
    ///   - apiKey: Your Datalyr API key
    ///   - debug: Enable debug logging (default: false)
    static func configure(workspaceId: String, apiKey: String, debug: Bool = false) async throws {
        let config = DatalyrConfig(
            workspaceId: workspaceId,
            apiKey: apiKey,
            debug: debug
        )
        
        try await shared.initialize(config: config)
    }
    
    /// Convenience method to initialize with full configuration
    /// - Parameters:
    ///   - workspaceId: Your Datalyr workspace ID
    ///   - apiKey: Your Datalyr API key
    ///   - debug: Enable debug logging
    ///   - enableAutoEvents: Enable automatic event tracking
    ///   - enableAttribution: Enable attribution tracking
    static func configure(
        workspaceId: String,
        apiKey: String,
        debug: Bool = false,
        enableAutoEvents: Bool = true,
        enableAttribution: Bool = true
    ) async throws {
        let autoEventConfig = AutoEventConfig(
            trackSessions: true,
            trackScreenViews: true,
            trackAppUpdates: true,
            trackPerformance: false
        )
        
        let config = DatalyrConfig(
            workspaceId: workspaceId,
            apiKey: apiKey,
            debug: debug,
            enableAutoEvents: enableAutoEvents,
            enableAttribution: enableAttribution,
            autoEventConfig: autoEventConfig
        )
        
        try await shared.initialize(config: config)
    }
}

// MARK: - Global Convenience Functions

/// Global convenience function to track events
/// - Parameters:
///   - eventName: Name of the event
///   - properties: Optional event properties
public func datalyrTrack(_ eventName: String, properties: [String: Any]? = nil) async {
    await DatalyrSDK.shared.track(eventName, eventData: properties)
}

/// Global convenience function to track screen views
/// - Parameters:
///   - screenName: Name of the screen
///   - properties: Optional screen properties
public func datalyrScreen(_ screenName: String, properties: [String: Any]? = nil) async {
    await DatalyrSDK.shared.screen(screenName, properties: properties)
}

/// Global convenience function to identify users
/// - Parameters:
///   - userId: User identifier
///   - properties: Optional user properties
public func datalyrIdentify(_ userId: String, properties: [String: Any]? = nil) async {
    await DatalyrSDK.shared.identify(userId, properties: properties)
}

/// Global convenience function to create user aliases
/// - Parameters:
///   - newUserId: New user identifier
///   - previousId: Previous user identifier (optional)
public func datalyrAlias(_ newUserId: String, previousId: String? = nil) async {
    await DatalyrSDK.shared.alias(newUserId, previousId: previousId)
}

/// Global convenience function to reset user session
public func datalyrReset() async {
    await DatalyrSDK.shared.reset()
}

/// Global convenience function to flush events
public func datalyrFlush() async {
    await DatalyrSDK.shared.flush()
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public extension View {
    /// Track screen view when this view appears
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - properties: Optional screen properties
    /// - Returns: Modified view with screen tracking
    func datalyrScreen(_ screenName: String, properties: [String: Any]? = nil) -> some View {
        self.onAppear {
            Task {
                await DatalyrSDK.shared.screen(screenName, properties: properties)
            }
        }
    }
    
    /// Track custom event when this view appears
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - properties: Optional event properties
    /// - Returns: Modified view with event tracking
    func datalyrTrack(_ eventName: String, properties: [String: Any]? = nil) -> some View {
        self.onAppear {
            Task {
                await DatalyrSDK.shared.track(eventName, eventData: properties)
            }
        }
    }
}
#endif

// MARK: - UIKit Integration

#if canImport(UIKit)
import UIKit

public extension UIViewController {
    /// Automatically track screen view when view controller appears
    /// Override this method to customize screen tracking
    @objc func datalyrTrackScreenView() {
        let screenName = String(describing: type(of: self))
        
        Task {
            await DatalyrSDK.shared.screen(screenName, properties: [
                "controller_class": screenName
            ])
        }
    }
    
    /// Track custom event from view controller
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - properties: Optional event properties
    func datalyrTrack(_ eventName: String, properties: [String: Any]? = nil) {
        Task {
            await DatalyrSDK.shared.track(eventName, eventData: properties)
        }
    }
}

// MARK: - UIViewController Swizzling Helper

public extension DatalyrSDK {
    /// Enable automatic screen tracking for all UIViewControllers
    /// Call this method after SDK initialization to automatically track screen views
    static func enableAutomaticScreenTracking() {
        UIViewController.swizzleViewDidAppear()
    }
}

private extension UIViewController {
    static func swizzleViewDidAppear() {
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(datalyr_viewDidAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(
            UIViewController.self,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            class_replaceMethod(
                UIViewController.self,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc func datalyr_viewDidAppear(_ animated: Bool) {
        // Call original method
        datalyr_viewDidAppear(animated)
        
        // Track screen view
        datalyrTrackScreenView()
    }
}
#endif

// MARK: - Deep Link Handling

public extension DatalyrSDK {
    /// Handle deep link for attribution tracking
    /// Call this method from your AppDelegate or SceneDelegate when the app is opened via URL
    /// - Parameter url: The deep link URL
    func handleDeepLink(_ url: URL) async {
        // Use the public setAttributionData method to handle deep links
        let attributionData = getAttributionData()
        await setAttributionData(attributionData)
    }
}

// MARK: - Error Handling

public extension DatalyrSDK {
    /// Check if SDK is properly initialized
    /// - Returns: True if initialized, false otherwise
    var isInitialized: Bool {
        return getStatus().initialized
    }
    
    /// Get last error if any occurred during initialization
    /// - Returns: Last error or nil
    func getLastError() -> Error? {
        // In a production implementation, you might want to store the last error
        return nil
    }
} 