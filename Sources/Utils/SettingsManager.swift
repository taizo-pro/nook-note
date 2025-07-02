import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var settings = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "NookNoteSettings"
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey) {
            do {
                settings = try JSONDecoder().decode(AppSettings.self, from: data)
            } catch {
                print("Failed to decode settings: \(error)")
                settings = AppSettings()
            }
        }
    }
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
    }
    
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("Failed to encode settings: \(error)")
        }
    }
    
    // MARK: - Keychain Integration (for secure token storage)
    
    private let keychainService = "com.nooknote.app"
    private let tokenKey = "github_personal_access_token"
    
    func saveTokenToKeychain(_ token: String) {
        let tokenData = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save token to keychain: \(status)")
        }
    }
    
    func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let tokenData = result as? Data,
           let token = String(data: tokenData, encoding: .utf8) {
            return token
        }
        
        return nil
    }
    
    func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}