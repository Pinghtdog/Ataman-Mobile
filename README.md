# ATAMAN Mobile

ATAMAN Mobile is a comprehensive healthcare coordination application designed for Naga City, serving as a vital component of the ATAMAN ecosystem. Built with Flutter, it provides a seamless and accessible experience for patients and healthcare providers, ensuring continuity of care from emergency response to routine consultations.

The application empowers users with real-time health alerts, digital medical records, and direct access to telemedicine, bridging the gap between citizens and healthcare facilities.

---

## 🚀 Core Features

### 🩺 Smart Triage & Emergency
* **AI-Powered Triage**: Guided symptom checking using Google Gemini AI to determine care urgency.
* **Emergency Request**: One-tap emergency assistance with real-time coordination and location tracking.
* **Incident Capture**: Rapid data entry for first responders and bystanders to report medical incidents.

### 📅 Care Management
* **Appointment Booking**: Schedule visits for general check-ups, specialized consultations, or vaccinations.
* **Telemedicine**: High-quality video consultations powered by ZegoCloud for remote care.
* **Referral Tracking**: Real-time status updates on medical referrals between primary care and specialized facilities.

### 📋 Medical Records & ID
* **Digital Medical ID**: Quick access to essential patient information (allergies, blood type) via QR codes.
* **Medical History**: Secure access to past diagnoses, treatments, prescriptions, and vaccination records.
* **Family Management**: Manage health profiles for family members within a single centralized account.

### 💊 Resource Access
* **Medicine Availability**: Real-time tracking of medicine stock levels across city hospitals and facilities.
* **Health Alerts**: Stay informed with localized health advisories, outbreak notifications, and public health news.

---

## 🛠 Tech Stack

| Layer                | Technology                                     |
|----------------------|------------------------------------------------|
| **Framework**        | Flutter (Dart)                                 |
| **State Management** | BLoC (flutter_bloc)                            |
| **Dependency Injection** | GetIt                                      |
| **Backend & Auth**   | Supabase (Database, Auth, Realtime)            |
| **Push Notifications** | Firebase Cloud Messaging (FCM)               |
| **Video Communication** | ZegoCloud UIKit                             |
| **AI Integration**   | Google Gemini AI                               |
| **Local Storage**    | Hive (Offline Sync Support)                    |
| **Maps & Location**  | Google Maps Flutter, Geolocator                |
| **PDF & Printing**   | PDF, Printing, PDFX                            |

---

## 🏁 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.6.2 or later)
* [Dart SDK](https://dart.dev/get-started/sdk)
* Android Studio / VS Code
* Supabase & Firebase project credentials

### Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Pinghtdog/Ataman-Mobile.git
    cd Ataman-Mobile
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    Create a `.env` file in the root directory and add your credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    GEMINI_API_KEY=your_gemini_api_key
    ZEGO_APP_ID=your_zego_app_id
    ZEGO_APP_SIGN=your_zego_app_sign
    ```

4.  **Database Setup**
    The project includes SQL scripts in the root directory for setting up the Supabase backend:
    * `database_setup.sql`: Main schema initialization.
    * `database_setup_vaccines.sql`: Vaccine-specific tables.
    * `database_seed_medicine.sql` & `database_seed_facility_medicines.sql`: Reference data.

5.  **Run the application**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

The project follows a **Feature-First Architecture**, promoting modularity and scalability.

```
lib/
├── core/              # Shared logic, themes, routes, and services
│   ├── services/      # Initialization, Sync, and Local Storage
│   ├── theme/         # App styling and constants
│   ├── utils/         # Helpers (formatting, validators, etc.)
│   └── widgets/       # Reusable UI components
├── features/          # Feature-based modules
│   ├── auth/          # Login, Registration, ID Verification
│   ├── booking/       # Appointment management
│   ├── emergency/     # Emergency requests and coordination
│   ├── facility/      # Facility information and discovery
│   ├── health_alerts/ # Real-time health notifications
│   ├── medical_records/# History, Referrals, and Medical ID
│   ├── medicine_access/# Hospital medicine stock tracking
│   ├── notification/  # In-app and push notification logic
│   ├── profile/       # User settings and family management
│   ├── telemedicine/  # Video calls and consultations
│   ├── triage/        # Symptom checking and history
│   └── vaccination/   # Vaccine scheduling and records
├── l10n/              # Localization (Multilingual support)
├── main.dart          # Application entry point
└── injector.dart      # Dependency injection setup
```

---

## ⚙️ Background Services

*   **Sync Service**: Handles background synchronization of local data (Hive) with the Supabase backend.
*   **Referral Status Service**: Monitors and updates the status of medical referrals in real-time.

---

## 🤝 System Integration

ATAMAN Mobile works in tandem with the **ATAMAN Web** platform, ensuring:
* **Data Continuity**: Synchronized medical records between mobile and hospital systems.
* **Real-time Coordination**: Instant notification to hospitals for incoming emergency cases.
* **Localized Care**: Tailored healthcare services specifically for Naga City residents.

---
Developed for the **Naga City Healthcare System**.

* **RUN dart doc to get the full documentation on each file and open the generated index.html locally 