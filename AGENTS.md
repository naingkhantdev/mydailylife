# Global Flutter Rules

IMPORTANT:
Always read and follow these instructions before modifying code.

## Flutter

- Do not manually create, edit, delete, or patch generated files such as `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, generated router files, or generated API files unless the user explicitly asks.
- Do not run `flutter analyze` by yourself.
- Do not run `dart analyze` by yourself.
- Do not run `dart format` by yourself.
- Do not run `flutter test` by yourself.
- Do not run `flutter run` by yourself.
- Do not run `flutter pub run build_runner build` by yourself.
- Do not run `dart run build_runner build` by yourself.
- If formatting, analysis, testing, running, or code generation is needed, tell the user the exact command to run.

## Workflow

- Only modify source files unless the user asks for project configuration changes.
- Keep edits minimal.
- Avoid unrelated formatting changes.
- Show changed file names after edits.

## When code generation is needed

Ask user to run:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

and wait for output.

## Architecture Preference

VO -> responses -> api -> data_agent -> data_agent_impl -> repository -> repo_provider -> goRouter -> UI

---

# RoutineSync - Comprehensive App Detail & Architecture

## 📱 1. App Overview
**Name:** RoutineSync  
**Tech Stack:** Flutter, Dart, Riverpod (State Management), Firebase (Firestore, Auth)  
**Primary Goal:** A holistic lifestyle tracking app managing daily routines, professional work logs, a 6-day PPL gym split, and automated calorie tracking.

---

## ⏰ 2. Daily Master Schedule
- **07:00 AM - 08:00 AM:** Breakfast & Calorie Logging
- **08:00 AM - 12:00 PM:** Work Focus Mode
- **12:00 PM - 01:00 PM:** Lunch, Calorie Logging & Mobile Legends Break
- **01:00 PM - 05:00 PM:** Work & Daily Log Input (Recording accomplishments)
- **05:00 PM - 06:00 PM:** Commute & Rest
- **06:00 PM - 07:30 PM:** Gym Training (PPL Split)
- **07:30 PM - 08:00 PM:** Dinner & Calorie Logging
- **08:00 PM - 09:30 PM:** Study Time (e.g., Flutter/Riverpod upskilling)
- **09:30 PM - 11:00 PM:** Gaming Time

---

## 🏋️‍♂️ 3. Gym Training Plan (6-Day PPL Split)
- **Monday:** Push 1 (Chest, Shoulders, Triceps)
- **Tuesday:** Pull 1 (Back, Rear Delts, Biceps)
- **Wednesday:** Legs 1 & Core (Quads, Calves, Abs)
- **Thursday:** Push 2 (Chest, Shoulders, Triceps)
- **Friday:** Pull 2 (Back, Biceps)
- **Saturday:** Legs 2 & Core (Hamstrings, Glutes, Abs)
- **Sunday:** Total Rest & Recovery

---

## 🍔 4. Diet & Calorie Tracking Feature
- **Meal Slots:** Breakfast, Lunch, Dinner.
- **Functionality:** Users can add food items to specific meals. The app automatically calculates the total calories for the day.
- **Data Model:** ```dart
  class MealItem {
  final String name;
  final int calories;
  // ...
  }
  ```

---

## 🗄️ 5. Firebase Database Structure (Firestore)

### Collection: `users`
**Document:** `{userId}`
- **Collection:** `daily_logs`
    - **Document:** `{YYYY-MM-DD}` (e.g., "2026-07-13")
        - `work_notes` (String)
        - `study_notes` (String)
        - `gaming_notes` (String)
        - `breakfast` (Array of Map: `[{name: "Egg", calories: 78}, ...]`)
        - `lunch` (Array of Map)
        - `dinner` (Array of Map)
        - `total_calories` (Integer - Auto calculated)

- **Collection:** `tasks` (For recurring daily routines)
    - **Document:** `{taskId}`
        - `title` (String)
        - `startTime` (String)
        - `endTime` (String)
        - `recurringDays` (Array of Integers: [1,2,3,4,5,6])

### Collection: `foods` (Global Calorie Dictionary - Optional)
**Document:** `{foodId}`
- `name`: "Boiled Egg"
- `calories`: 78

---

## 📂 6. Flutter Folder Structure (`lib/`)

```text
lib/
│
├── models/
│   ├── task_model.dart      
│   ├── daily_log_model.dart  # Includes MealItem logic & auto-calorie calculation
│
├── providers/               
│   ├── auth_provider.dart   
│   ├── routine_provider.dart
│   ├── diet_provider.dart    # Manages calorie addition and meal lists
│   └── gym_provider.dart    
│
├── services/                
│   ├── firestore_service.dart 
│   ├── auth_service.dart    
│   └── nutrition_api_service.dart # (Optional) For external food calorie fetching
│
├── screens/                 
│   ├── home_screen.dart     
│   ├── work_log_screen.dart 
│   ├── diet_screen.dart      # UI for adding food & showing total calories
│   ├── gym_plan_screen.dart 
│   └── night_split_screen.dart 
│
├── widgets/                 
│   ├── meal_input_card.dart  # Widget for adding food items
│   ├── calorie_summary.dart  # Displays total calories visually
│   └── timeline_card.dart   
│
└── main.dart                
```

## 🛠️ 7. Next Steps for Development
1. **Initialize Project:** Set up Flutter and connect to Firebase using `flutterfire_cli`.
2. **Build Models:** Implement `TaskModel` and `DailyLogModel` (with `totalCalories` getter).
3. **Setup State:** Create Riverpod providers for managing the state of Daily Logs and Meals.
4. **Develop UI:** Build the Home Screen timeline, integrating the Work Log and Calorie Summary widgets.
5. **Testing:** Verify Firestore CRUD operations and ensure real-time updates via StreamProvider.
