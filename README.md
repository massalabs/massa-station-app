
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
   git clone git@github.com:nafsilabs/mug.git
   cd mug

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



