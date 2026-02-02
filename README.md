# Ataman Mobile (Android)

Ataman Mobile is the Android companion application for the ATAMAN healthcare coordination system designed for Naga City. It extends core hospital and patient-side workflows to mobile devices, enabling faster data capture, real-time updates, and accessible care coordination in both urgent and routine healthcare scenarios.

The mobile app supports first responders, patients, and healthcare workers by providing guided access to patient information, facility routing, and follow-up care, ensuring continuity beyond hospital walls.

---

## Core Features

### Mobile Patient Identification

* QR code scanning for rapid patient lookup
* Secure access to essential patient details and linked profiles
* Reduced manual data entry during time-sensitive situations

### Care Navigation & Status Updates

* Guided flow for patients and responders based on medical needs
* Real-time status indicators for referrals and care progression
* Seamless synchronization with the Ataman hospital command center

### Telemedicine Access

* Mobile-friendly teleconsultation entry points
* Follow-up check-ins for patients after discharge
* Continuous communication with assigned healthcare providers

### Incident & Case Capture

* On-site data capture by bystanders or responders
* Structured input for symptoms, location, and basic context
* Automatic preparation of patient data before facility arrival

### Secure Authentication

* Supabase-powered authentication
* Role-aware access for patients, responders, and staff
* Encrypted session handling for sensitive medical data

---

## Tech Stack

| Layer            | Technology                    |
| ---------------- | ----------------------------- |
| Platform         | Android (Kotlin)              |
| UI               | Jetpack Compose / XML Layouts |
| Architecture     | MVVM                          |
| Backend & Auth   | Supabase                      |
| Realtime Data    | Supabase Realtime             |
| QR Scanning      | ML Kit / CameraX              |
| Networking       | Retrofit                      |
| State Management | ViewModel, Flow / LiveData    |

---

## Getting Started

### Prerequisites

* Android Studio (latest stable version)
* JDK 17 or later
* Android SDK (API level as specified in the project)
* Supabase project credentials

---

### Installation & Setup

1. **Clone the repository**

   ```
   git clone https://github.com/Pinghtdog/Ataman-Mobile.git
   cd Ataman-Mobile/android
   ```

2. **Open in Android Studio**

   * Select **Open an existing project**
   * Choose the `android` directory

3. **Set up environment variables**

   Add your credentials in `local.properties` or the appropriate config file:

   ```
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

4. **Sync Gradle**

   * Allow Android Studio to download dependencies
   * Resolve any missing SDK versions if prompted

---

### Run the App

* Connect a physical device or start an emulator
* Click **Run ▶** in Android Studio

The app will launch on the selected device.

---

## Project Structure

```
android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/ataman/
│   │   │   │   ├── ui/            # Screens and UI components
│   │   │   │   ├── viewmodel/     # ViewModels
│   │   │   │   ├── data/          # Repositories and models
│   │   │   │   ├── network/       # API and Supabase clients
│   │   │   │   └── utils/         # Helpers and utilities
│   │   │   └── res/               # Layouts, drawables, values
│   └── build.gradle
├── gradle/
└── settings.gradle
```

---

## System Role

Ataman Mobile works in tandem with **Ataman Web**, ensuring:

* Hospitals receive prepared, structured information
* Patients and responders are guided instead of guessing
* Care continues beyond admission through mobile follow-ups

Together, the web and mobile platforms form a unified healthcare coordination infrastructure for Naga City.
