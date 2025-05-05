# 📱 PKBM RAWA CINDE ATTENDANCE APP

This mobile application is a digital attendance system developed using **Flutter** and **Firebase**. It is designed for use by PKBM Rawa Cinde to streamline attendance tracking for tutors and learners during learning activities.

## 🚀 Key Features

* **Login & Authentication** via Firebase Authentication.
* **Dashboard** for tutors and admins:

  * Tutors can view their class schedules and submit attendance.
  * Admins can manage tutor, learner, class data, and attendance records.
* **Data Management**:

  * Tutor: add, edit, delete.
  * Learner: add, edit, delete.
  * Class: create new classes and set schedules.
* **Attendance Tracking**:

  * Record attendance based on time (and optionally location).
  * View attendance history for tutors and learners.
* **Attendance Reports**:

  * Generate daily/monthly summary reports.

## 🛠️ Technologies Used

* **Frontend**: Flutter
* **Backend & Database**: Firebase (Authentication, Firestore, Cloud Storage)
* **Platform**: Android

## ⚙️ Installation Guide

1. **Clone the repository**:

   ```bash
   git clone https://github.com/lutzzzx/Absensi-PKBM.git
   cd pkbm-attendance-app
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Connect to Firebase**:

   * Create a Firebase project and enable Authentication, Firestore, and Storage.
   * Download the `google-services.json` file and place it in the `android/app/` directory.

4. **Run the application**:

   ```bash
   flutter run
   ```

## 👥 User Roles

* **Admin**:

  * Manage tutor, learner, and class data.
  * View and export attendance reports.
* **Tutor**:

  * View assigned classes.
  * Submit attendance and view attendance history.

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 📬 Contact

-   **Email**: [luthfizulfikri1@gmail.com](mailto:luthfizulfikri1@gmail.com)
-   **GitHub**: [https://github.com/lutzzzx/Absensi-PKBM](https://github.com/lutzzzx/Absensi-PKBM)
