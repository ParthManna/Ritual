# 🌿 Ritual – Build Habits That Last

**Ritual** is a sleek, modern habit-tracking mobile application designed to help you stay consistent, reach your goals, and transform your daily routines into lifelong habits.

![App Logo](assets/images/app.png)

---

## 🚀 Features

- **Habit Tracking:** Easily create, manage, and track your daily habits with a beautiful and intuitive UI.
- **Progress Visualizations:** Stay motivated with interactive charts and heatmaps showing your consistency over time (Powered by `fl_chart`).
- **Calendar Integration:** View your history and plan your habits using the built-in calendar (Powered by `table_calendar`).
- **Smart Reminders:** Never miss a habit with customizable local notifications (Powered by `flutter_local_notifications`).
- **Google Sign-In:** Secure and seamless authentication using your Google account via Supabase Auth.
- **Cloud Sync:** Your data is securely stored and synced across devices using Supabase.
- **Profile Personalization:** Customize your profile with name updates and avatar uploads.

---

## 🛠️ Tech Stack

- **Frontend:** [Flutter](https://flutter.dev) (Dart)
- **Backend:** [Supabase](https://supabase.com) (Database, Auth, Storage)
- **Local Storage:** `shared_preferences`
- **Charts:** `fl_chart`
- **Calendar:** `table_calendar`

---

## 📦 Getting Started

### Prerequisites

- Flutter SDK: `^3.0.0`
- Android Studio or VS Code
- A Supabase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ritual.git
   cd ritual
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase:**
   - Create a project on [Supabase](https://supabase.com).
   - Get your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
   - Initialize Supabase in your `lib/main.dart`.

4. **Google Sign-In Setup:**
   - Configure OAuth 2.0 Client IDs in the Google Cloud Console.
   - Add your SHA-1 fingerprint for Android.
   - Update the `webClientId` in `lib/services/supabase_service.dart`.

5. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🎨 Design

The app uses a clean, dark-themed aesthetic with vibrant accent colors to make tracking your habits a delightful experience.

- **Background:** Dark Blue / Navy
- **Primary Color:** Custom Gradients
- **Typography:** Modern Sans-serif

---

## 🛡️ Privacy Policy

We value your privacy. Ritual only collects your name and email for authentication purposes. All habit data and camera/gallery access for avatars stay within your control. 
[Full Privacy Policy](PRIVACY.md)

---

## 👨‍💻 Author

Developed with ❤️ by **Partha Sarathi Manna**.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
