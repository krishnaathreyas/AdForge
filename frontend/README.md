# Ad-Forge Frontend 📱✨

This is the official Flutter application for the Ad-Forge project, built for the Samsung Hackathon. It provides a mobile interface for scanning products and generating customized, AI-powered video advertisements based on local marketing contexts.

---

### 📸 Screenshots

| Home Screen | Scanner Screen | Context Screen | Results Screen |
| :---: | :---: | :---: | :---: |
| *(Your Home Screenshot Here)* | *(Your Scanner Screenshot Here)* | *(Your Context Screenshot Here)* | *(Your Results Screenshot Here)* |


---

### ✨ Features

* **Product Scanning:** Utilizes the device's camera to scan QR codes and identify products.
* **Contextual Input:** Allows users to provide detailed marketing context, upload a store image for hyper-personalization, and select a regional location for dialect-specific voiceovers.
* **Asynchronous Ad Generation:** Communicates with a powerful AWS backend to kick off a multi-stage AI video generation process.
* **Real-time Status Polling:** Periodically checks the backend for the status of the video generation job and updates the UI in real-time.
* **In-App Video Playback:** Displays the final, generated video ad with playback controls.
* **Native Device Integration:** Features options to download the final video to the device's gallery and share it using the native share sheet.
* **State Management:** Built with a clean, provider-based state management architecture.

---

### 🛠️ Tech Stack & Key Packages

This application is built with the Flutter framework and the Dart programming language.

* **State Management:** `provider`
* **QR Code Scanning:** `mobile_scanner`
* **Video Playback:** `video_player`
* **Native Features:**
    * `gal` (for saving to the gallery)
    * `share_plus` (for the native share menu)
    * `image_picker` (for uploading images)
    * `permission_handler`
* **Networking:** `dio` & `http`

---

### 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

**Prerequisites:**
* You must have the Flutter SDK installed. You can find instructions [here](https://flutter.dev/docs/get-started/install).

**Installation & Setup:**
1.  Clone the repository.
2.  Navigate to the `frontend` directory:
    ```sh
    cd frontend
    ```
3.  Install all the necessary packages:
    ```sh
    flutter pub get
    ```
4.  Run the app on a connected device or emulator:
    ```sh
    flutter run
    ```

---

### 📂 Project Structure

The code within the `lib/` directory is organized to follow clean architecture principles:

* **`main.dart`**: The entry point of the application and the main navigation shell.
* **`models/`**: Contains the `Product` data model.
* **`providers/`**: Contains the `AppProvider`, which acts as the central "brain" for all state management.
* **`screens/`**: Contains the UI code for each of the four main screens (Home, Scan, Context, Results).
* **`services/`**: Contains the `ApiService`, which handles all communication with the backend.
* **`theme/`**: Contains the `AppTheme` file for a centralized, professional look and feel.

---

