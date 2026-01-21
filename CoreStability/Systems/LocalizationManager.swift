// LocalizationManager.swift
// CoreStability
// Handles localization and provides easy access to localized strings

import Foundation

final class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    // MARK: - Localized String Helper
    
    /// Returns localized string for the given key
    func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    /// Returns localized string with format arguments
    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: args)
    }
    
    // MARK: - Language Detection
    
    var currentLanguage: String {
        return Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    var isTurkish: Bool {
        return currentLanguage == "tr"
    }
}

// MARK: - String Extension for Easy Localization

extension String {
    /// Returns localized version of this string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns localized string with format arguments
    func localized(with args: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return String(format: format, arguments: args)
    }
}

// MARK: - Convenience Shortcuts

/// Shortcut function for localization
func L(_ key: String) -> String {
    return key.localized
}

/// Shortcut function for localization with arguments
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: args)
}
