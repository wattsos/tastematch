import Foundation
import Security

/// Generates and persists a stable device-scoped anonymous identifier in the Keychain.
/// Survives app reinstalls only if iCloud Keychain backup is enabled; otherwise
/// a new UUID is generated on reinstall (acceptable for anonymous-first flow).
enum DeviceInstallID {

    private static let service = "com.lu23.TasteMatch.deviceID"
    private static let account = "device_install_id"

    /// Returns the existing ID or creates and persists a new one.
    static var current: String {
        if let existing = load() { return existing }
        let fresh = UUID().uuidString
        save(fresh)
        return fresh
    }

    // MARK: - Private

    private static func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private static func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        // Delete any stale entry first
        let deleteQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass:                 kSecClassGenericPassword,
            kSecAttrService:           service,
            kSecAttrAccount:           account,
            kSecValueData:             data,
            kSecAttrAccessible:        kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
