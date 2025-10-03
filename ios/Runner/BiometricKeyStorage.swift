import Foundation
import LocalAuthentication
import Security

/// iOS Secure Enclave integration for biometric key storage
/// Keys are stored in iOS Keychain with biometric access control
@available(iOS 11.0, *)
class BiometricKeyStorage {
    private let keychainTag = "com.massa.station.biometric.key"

    /// Store a key in the iOS Keychain with biometric protection
    func storeKey(key: String) -> Bool {
        // Delete any existing key first
        deleteKey()

        guard let keyData = key.data(using: .utf8) else {
            return false
        }

        // Create access control with biometric authentication requirement
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny, // Allow any enrolled biometric (existing or new)
            &error
        ) else {
            print("Failed to create access control: \(error.debugDescription)")
            return false
        }

        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecAttrAccessControl as String: accessControl,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: false, // Don't sync to iCloud
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("Successfully stored biometric key in iOS Keychain")
            return true
        } else {
            print("Failed to store biometric key: \(status)")
            return false
        }
    }

    /// Retrieve a key from the iOS Keychain (requires biometric authentication)
    func retrieveKey() -> String? {
        let context = LAContext()
        context.localizedReason = "Access your wallet securely"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: "Authenticate to access your wallet",
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            guard let keyData = result as? Data,
                  let key = String(data: keyData, encoding: .utf8) else {
                print("Failed to decode key data")
                return nil
            }
            print("Successfully retrieved biometric key from iOS Keychain")
            return key
        } else {
            print("Failed to retrieve biometric key: \(status)")
            return nil
        }
    }

    /// Delete the stored key from the iOS Keychain
    func deleteKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            print("Successfully deleted biometric key from iOS Keychain")
            return true
        } else {
            print("Failed to delete biometric key: \(status)")
            return false
        }
    }

    /// Check if a key exists in the iOS Keychain
    func hasKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
