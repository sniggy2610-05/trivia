# 🎯 Trivia Showdown

A Flutter-based multiple-choice trivia application that fetches questions from the Open Trivia Database API. Test your general knowledge, track your score, and challenge yourself with a new round!

## 📱 About the Project

Trivia Showdown is a mobile trivia game developed using Flutter and Dart. The application retrieves five easy-level General Knowledge questions from the Open Trivia Database and presents them in an interactive quiz format.

Players can select answers, receive immediate feedback, track their progress, and view their final score.

## ✨ Features

- **API Integration:** Fetches trivia questions from the Open Trivia Database.
- **JSON Parsing:** Processes API responses and converts question data into usable objects.
- **Multiple Choice:** Displays four shuffled answer options per question.
- **Instant Feedback:** Highlights correct answers in green and incorrect selections in red.
- **Score Tracking:** Keeps track of the player's score throughout the round.
- **Progress Indicator:** Displays progress through all five questions.
- **Loading State:** Shows a loading screen while questions are retrieved.
- **Error Handling:** Displays an error message and retry option if questions cannot be loaded.
- **Results Screen:** Displays the final score and percentage.
- **Replay:** Allows players to start another round.
- **Score Sync Demonstration:** Includes a simulated score synchronization feature.

## 🛠️ Technologies Used

- Flutter
- Dart
- HTTP package
- Open Trivia Database API
- JSON

## 🌐 API Information

The application uses the Open Trivia Database API.

**Endpoint:**

https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple

API parameters:

- `amount=5` — Retrieves five questions.
- `category=9` — General Knowledge.
- `difficulty=easy` — Easy difficulty.
- `type=multiple` — Multiple-choice questions.

The application checks the HTTP response status and API response code before processing the returned questions.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio
- Android emulator or Android device
- Internet connection

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/sniggy2610-05/trivia.git
   ```

2. Navigate into the project directory:

   ```bash
   cd trivia
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## 📂 Project Structure

```text
trivia/
├── android/
├── ios/
├── lib/
│   └── main.dart
├── test/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## 🧠 Critical Thinking

### 1. What should happen if connectivity drops after questions have loaded?

If the internet connection drops after the five questions have loaded, the player should still be able to finish the current round. Since the questions and answer choices have already been retrieved, the application does not need another network request to display questions, evaluate answers, update the score, or move between questions.

The loading state should only appear while the application initially retrieves questions or starts a new round. If the initial request fails because of connectivity problems, the application should display a clear error message and provide a retry option. Once a round has loaded, a temporary connection problem should not interrupt gameplay.

### 2. What information would you save locally, and why would it not be a shared leaderboard?

One useful piece of information to save locally would be the player's previous trivia scores. Saving scores on the device would allow players to review their past results after closing and reopening the application. This would help them track their personal progress without requiring an internet connection.

However, locally stored scores would not automatically become a shared leaderboard because local storage is only available on the individual player's device. Other users and devices cannot access that information. A shared leaderboard would require a cloud database or backend service to receive, store, and distribute scores between users.

Therefore, local score history would support individual progress tracking, while a shared leaderboard would require a separate cloud-based implementation.

## ☁️ Score Synchronization Note

The score synchronization feature in this project is a demonstration. It simulates a synchronization process through a short delay and displays a completion message.

**No actual HTTP POST request, cloud database write, or backend score upload is performed.**

## 👩‍💻 Author

Developed as part of **CSC 4360 – Mobile App Development**.

**In-Class Activity 15: API-to-Cloud Trivia Showdown**