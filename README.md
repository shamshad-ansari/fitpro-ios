# FitPro - Intelligent Workout & Nutrition Tracker

![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-iOS%2017+-lightgrey?style=flat-square)
![Backend](https://img.shields.io/badge/Backend-Node.js%20%26%20Express-green?style=flat-square)
![Database](https://img.shields.io/badge/Database-MongoDB%20Atlas-green?style=flat-square)
![Cloud](https://img.shields.io/badge/Deployment-AWS%20Elastic%20Beanstalk-orange?style=flat-square)

**FitPro** is a comprehensive, full-stack iOS fitness application built to help users track workouts, monitor nutrition, and visualize their progress. Designed with a high-fidelity **SwiftUI** frontend and a robust **Node.js** backend, it features real-time data synchronization, dynamic workout routines, and interactive analytics.

---

## 📱 App Screenshots

| Dashboard | Workout Tracker | Nutrition Log | Profile & Stats |
|:---:|:---:|:---:|:---:|
| <img src="docs/dashboard.png" width="200"> | <img src="docs/workout.png" width="200"> | <img src="docs/nutrition.png" width="200"> | <img src="docs/profile.png" width="200"> |

> *Note: Replace `docs/image.png` with actual screenshots in your repo.*

---

## 🎬 Project Demo

![App Demo](path/to/your/demo.gif)

<!-- To add a demo GIF:
1. Record your app using a screen recorder or iOS Simulator recording
2. Convert to GIF if needed using ezgif.com or similar tool
3. Add the GIF to your repository (e.g., in 'docs' or 'assets' folder)
4. Update the path above or use GitHub raw URL:
   - <img src="https://raw.githubusercontent.com/username/fitpro/main/docs/demo.gif" width="600" alt="App Demo">
-->

---

## ✨ Key Features

### 💪 Workout Management
* **Custom Routines:** Create, edit, and organize personalized workout plans (e.g., "Push Day", "Leg Day").
* **Active Session Mode:** Live workout tracking with set-by-set logging, rest timers, and weight recording.
* **History & Logs:** View detailed logs of past workouts, including total volume, duration, and specific exercises performed.

### 🍎 Nutrition Tracking
* **Macro Monitoring:** Log daily meals (Breakfast, Lunch, Dinner, Snacks) with protein, carb, and fat breakdowns.
* **Visual Summaries:** Interactive ring charts and progress bars to visualize daily calorie goals vs. consumption.

### 📊 Analytics & Gamification
* **Dashboard:** "At a glance" view of current streaks, weekly workout counts, and active calories.
* **Progress Tracking:** Visual graphs for volume (kg) lifted over time and consistency streaks.

### ☁️ Cloud Sync
* **Secure Auth:** JWT-based authentication via a custom Node.js backend.
* **Data Persistence:** All user data is stored securely in **MongoDB Atlas**.
* **Deployment:** Backend API is fully deployed and scalable on **AWS Elastic Beanstalk**.

---

## 🛠 Tech Stack

### iOS (Frontend)
* **Language:** Swift 5.9
* **Framework:** SwiftUI
* **Architecture:** MVVM (Model-View-ViewModel) + Service Factory Pattern
* **State Management:** Swift Observation Framework (`@Observable`)
* **Networking:** Generic API Client with `async/await`

### Backend (API)
* **Runtime:** Node.js (v18+)
* **Framework:** Express.js
* **Database:** MongoDB (Mongoose ODM)
* **Authentication:** JSON Web Tokens (JWT) & bcrypt

### Infrastructure
* **Database Hosting:** MongoDB Atlas (AWS Region)
* **API Hosting:** AWS Elastic Beanstalk
* **Storage:** AWS S3 (planned for media)

---

## 🏗 Architecture

The app follows a clean **MVVM** architecture to ensure separation of concerns and testability.

* **Views:** Pure SwiftUI views that observe the ViewModel.
* **ViewModels:** Handle business logic, state management, and communication with Services.
* **Services:** Isolated networking layers (e.g., `WorkoutsService`, `NutritionService`) created via a **ServiceFactory**.
* **Models:** Codable structs mirroring the MongoDB schema.

---

## 🚀 Getting Started

### Prerequisites
* Xcode 15.0+ (iOS 17.0+ Simulator)
* Node.js 18+ & npm
* MongoDB Atlas Account (or local Mongo instance)

### 1. Backend Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/fitpro.git
cd fitpro/backend

# Install dependencies
npm install

# Configure Environment Variables
# Create a .env file in the backend root
echo "PORT=4000" >> .env
echo "MONGO_URI=your_mongodb_connection_string" >> .env
echo "JWT_SECRET=your_super_secret_key" >> .env

# Run the server
npm run dev
```

### 2. iOS Setup

1. Open `fitpro-ios/FitPro.xcodeproj` in Xcode.
2. Navigate to `Config/API.swift`.
3. Set the `baseURL` to your local or cloud endpoint:
```swift
// Local Testing
static let baseURL = URL(string: "http://localhost:4000")!

// AWS Production
// static let baseURL = URL(string: "http://fitpro-env.eba-xyz.us-east-1.elasticbeanstalk.com")!
```

4. Build and Run (Cmd + R).

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Authenticate user & get JWT |
| GET | `/api/workouts` | Get all user routines |
| POST | `/api/workouts` | Create a new routine |
| PATCH | `/api/workouts/:id` | Update existing routine |
| POST | `/api/workouts/sessions` | Log a completed workout session |
| GET | `/api/nutrition/summary` | Get daily macro summary |

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for review.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
