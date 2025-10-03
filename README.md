
# Massa Station App


## Introduction
Massa Station mobile app for interaction with Massa Blockchain.

## Features
Massa Station will initally have the following features:

### Massa Wallet
- Massa wallet  - with ability to create multiple wallets, restore wallet from private key, export wallet, send and receive transactions.
### Dusa DEX
- Dusa Integration - with ability to wrap Massa tokens, swap token between MAS and USDC, swap token between MASSA and WETH.
### Massa Explore
- Massa explorer - with ability to list all massa addresses, search for an address, and view address details.

## Security & Cryptography

Massa Station App implements multiple layers of cryptographic security to protect user funds and private keys.

### Cryptographic Algorithms

#### Blockchain Operations (via massa package)
- **Ed25519 (EdDSA)**: Used for all blockchain signing operations
  - Public/private key pair generation for Massa accounts
  - Transaction signing
  - Message signing

#### Local Storage Encryption
- **PBKDF2-HMAC-SHA256**: Key derivation from user passphrase
  - 100,000 iterations (configurable)
  - 32-byte output (256-bit master key)
  - Per-user random salt (32 bytes)
  - Executed in background isolate to avoid UI blocking

- **AES-256-CBC**: Symmetric encryption for wallet private keys
  - 256-bit encryption key derived from master key
  - 128-bit IV (Initialization Vector)
  - Per-wallet random salt for key/IV derivation
  - PKCS7 padding

- **SHA-256**: Fast verification hash
  - Master key verification (hash stored, not passphrase)
  - Constant-time comparison to prevent timing attacks

### Authentication Modes

Massa Station App supports two authentication modes to protect your wallet:

#### 1. Biometric Authentication
When biometric authentication is enabled:
- A secure random 32-byte master key is generated automatically
- The master key is securely stored in platform-specific secure storage:
  - **Android**: Encrypted using Android Keystore (hardware-backed on supported devices)
  - **iOS**: Stored in Keychain with Secure Enclave protection
- Access to the master key requires biometric authentication (fingerprint, Face ID, etc.)
- No passphrase needed - authentication is purely biometric
- Provides the most convenient experience on supported devices

#### 2. Passphrase Authentication
When biometric authentication is not wanted or unavailable:
- The master key is derived from your passphrase using PBKDF2-HMAC-SHA256
- The master key is never stored, only cached in RAM during active sessions
- You must enter your passphrase each time the session expires
- Works on all devices regardless of biometric hardware support

### Security Architecture

#### 1. Passphrase Setup (First Time)
```
User Passphrase
    ↓
Generate random salt (32 bytes)
    ↓
PBKDF2-SHA256 (100k iterations) → Master Key (32 bytes)
    ↓
SHA-256(Master Key) → Verification Hash
    ↓
Store: salt + verification hash (in secure storage)
Cache: Master Key (in RAM only, auto-timeout)
```

**Storage:**
- `master_key_salt`: Random salt for PBKDF2 (stored)
- `passphrase_verify_hash`: SHA-256 hash of master key (stored)
- Master key: **Never stored**, only cached in RAM

#### 2. Login Flow

**Biometric Mode:**
```
User authenticates with biometric (fingerprint/Face ID)
    ↓
Platform verifies biometric
    ↓
If verified: Retrieve master key from secure storage
    ↓
Cache master key in RAM
```

**Passphrase Mode:**
```
User enters passphrase
    ↓
Load stored salt
    ↓
PBKDF2-SHA256(passphrase, salt) → Derived Master Key
    ↓
SHA-256(Derived Master Key) =?= Stored Hash
    ↓
If match: Cache master key in RAM
If mismatch: Reject login
```

**Security Features:**
- Biometric authentication handled by platform (hardware-backed)
- Passphrase: Constant-time hash comparison (prevents timing attacks)
- Master key cached in RAM with auto-timeout
- Brute-force protection: 3 failed attempts → 30s lockout

#### 3. Wallet Creation/Import
```
Generate/Import Ed25519 private key
    ↓
Get master key from RAM cache
    ↓
Generate random salt (16 bytes)
    ↓
PBKDF2(master_key, salt, 1 iter, 48 bytes) → Key (32) + IV (16)
    ↓
AES-256-CBC(private_key, key, iv) → Encrypted Key
    ↓
Store: {address, encrypted_key, salt}
```

**Per-Wallet Encryption:**
- Each wallet has unique random salt
- Keys derived from master key + salt
- Fast derivation (1 iteration - master key already strong)
- Private keys encrypted individually

#### 4. Transaction Signing
```
User initiates transaction
    ↓
Get master key from RAM (or reject if session expired)
    ↓
Decrypt wallet private key (AES-256-CBC)
    ↓
Sign transaction (Ed25519)
    ↓
Clear decrypted key from memory
```

**Key Access:**
- Private keys decrypted on-demand only
- Kept in memory only during signing
- Automatic session timeout protection

### Platform-Specific Storage

#### Android
- **EncryptedSharedPreferences**: Android Keystore-backed encryption
  - Hardware-backed keys (on supported devices)
  - AES-256-GCM encryption at rest

#### iOS
- **Keychain**: Secure Enclave-backed storage
  - `kSecAttrAccessible`: `first_unlock` (available after device unlock)
  - Hardware encryption on all modern devices

### Dependencies

- `pointycastle: ^3.9.1` - Pure Dart cryptography (PBKDF2, AES)
- `flutter_secure_storage` - Platform secure storage wrapper
- `crypto` - SHA-256 hashing
- `massa` - Ed25519 blockchain operations


## Development Status
### Massa wallet
- [x] Create wallet
- [x] Store wallet in secure storage
- [x] View wallet details
- [x] Restore wallet from private key
- [x] Export wallet private key and as QR code
- [x] Send transaction from one address to another
- [x] Receive transaction
### Dusa Dex
- [x] Wrap MAS to WMAS
- [x] Unwrap WMAS to MAS
- [x] Swap MAS to USDC.e
- [x] Swap USDC.e to MAS
- [x] Swap MAS to WETH
- [x] Swap WETH to MAS
### Massa explorer
- [x] List all staking addreses
- [x] Search for an address
- [x] View address details
- [x] Search for domain name
- [x] View  domain name details
- [x] Purchase a domain name if available
- [x] Search for operation
- [x] View  view operation details
- [x] Search for block
- [x] View  view block details


## Testing Flutter App

Follow the steps below to set up and test the Flutter app on your computer:

---

### Prerequisites

1. **Install Flutter SDK**  
   Download and install the [Flutter SDK](https://docs.flutter.dev/get-started/install) for your operating system. Follow the installation guide specific to your platform (macOS, Linux, or Windows).

2. **Set Up Emulators/Simulators**  
   - **Android**: Install the [Android Emulator](https://developer.android.com/studio/run/emulator). You can set it up via Android Studio by adding an emulator in the AVD Manager.  
   - **iOS** (macOS only): Install Xcode and set up the [iOS Simulator](https://developer.apple.com/documentation/safari-developer-tools/installing-xcode-and-simulators).

3. **Install a Code Editor (Optional)**  
   Install [Visual Studio Code](https://code.visualstudio.com/) for an optimized development and testing experience. You may also install Flutter and Dart extensions for better support.

---

   ### Steps to Test the App

1. **Clone the Repository**
   Clone the project to your local machine:
   ```bash
   git clone git@github.com:massalabs/massa-station-app.git
   cd massa-station-app

2. **Install Dependencies**  
   Navigate to the app's root folder and run the following command to install all required packages:
   ```bash
   flutter pub get

3. **Install Dependencies**  
   Launch an Emulator/Simulator
     * **Android**: Start the Android Emulator via Android Studio or the flutter emulators command.
     * **iOS**: Open Xcode and launch the iOS Simulator.

4. **Verify Device Detection**  
   Check if Flutter has detected the connected devices or emulators:
    ```bash
    flutter devices

5. **Run the App**
   Launch the app by specifying the device identifier obtained in the previous step:  
    ```bash
    flutter run -d <device-id>
   Replace <device-id> with the actual emulator or physical device identifier.

6. **Start Testing**
   The app will launch on the selected device/emulator. You can now interact with and test the app's features.

### Building the App for Android and iOS

Follow these steps to build the app for Android and iOS:

#### Building for Android
1. **Generate the APK**  
   Run the following command to build the APK:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be located in the `build/app/outputs/flutter-apk/` directory.

2. **Generate the App Bundle**  
   To upload the app to the Google Play Store, build an Android App Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```
   The generated AAB will be located in the `build/app/outputs/bundle/release/` directory.

3. **Sign the APK/AAB**  
   Ensure the APK or AAB is signed with your release key. Follow the [official Flutter guide](https://docs.flutter.dev/deployment/android) for signing and publishing.

#### Building for iOS
1. **Set Up Xcode**  
   Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select a Build Target**  
   In Xcode, select your desired device or simulator as the build target.

3. **Build the App**  
   Build the app by selecting `Product > Archive` from the Xcode menu.

4. **Sign and Distribute**  
   Use Xcode's interface to sign the app with your Apple Developer account and distribute it via TestFlight or the App Store. Follow the [official Flutter guide](https://docs.flutter.dev/deployment/ios) for detailed instructions.



### Support
This project is supported by a [Massa Foundation Grant](https://massa.foundation)

### Contribute
You can contribute to this package, request new features or report any bug by visiting the package repository.


## License

The MIT License (MIT).



