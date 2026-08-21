# RoutineSync — full process in sequence

Sequence diagrams traced from the code in `lib/`, in runtime order: from the first frame of the
splash screen to the moment sign-out empties the user id and every Firestore write becomes a no-op.

Diagrams are Mermaid and render on GitHub. Theme colours are deliberately left to the renderer so
they read in both light and dark.

For the structural view — route map, layers, provider graph and the branch-by-branch decisions —
see [`flowcharts.md`](flowcharts.md).

> **Opening these in a Mermaid viewer?** Feed it a single diagram, not this whole file — a
> Mermaid-only renderer reads the first line (`# RoutineSync — full process in sequence`) and reports
> *"No diagram type detected"*. Each diagram is also saved on its own in
> [`diagrams/`](diagrams/), ready to paste into mermaid.live or a plugin.

| Stage | Flow |
| --- | --- |
| — | [One session, end to end](#one-session-end-to-end) |
| 01 | [Cold start and the splash gate](#01--cold-start-and-the-splash-gate) |
| 02 | [Signing in, two ways](#02--signing-in-two-ways) |
| 03 | [Provider hydration: uid in, data out](#03--provider-hydration-uid-in-data-out) |
| 04 | [Marking a routine done or missed](#04--marking-a-routine-done-or-missed) |
| 05 | [Meals, notes, and the save queue](#05--meals-notes-and-the-save-queue) |
| 06 | [Gym plan, technique library, live session](#06--gym-plan-technique-library-live-session) |
| 07 | [Reading it back: history and dashboard](#07--reading-it-back-history-and-dashboard) |
| 08 | [Sign out and account teardown](#08--sign-out-and-account-teardown) |
| — | [Where the data lands](#where-the-data-lands) |

---

## One session, end to end

The condensed path a single user takes through the app. Every arrow here is expanded in one of the
eight stages below.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant App as main + MyApp
  participant S as SplashScreen
  participant A as AuthService
  participant R as Riverpod controllers
  participant F as FirestoreService
  participant DB as Cloud Firestore

  U->>App: Launch RoutineSync
  App->>App: Firebase.initializeApp, load SharedPreferences
  App->>S: runApp inside ProviderScope
  S->>A: currentUser
  alt Session restored
    S->>F: prepareUserWorkspace uid
    F->>DB: set users/{uid} merge
    S-->>U: HomeScreen
  else No session
    S-->>U: LoginScreen
    U->>A: Email or Google sign-in
  end
  A-->>R: authStateChanges emits User, uid propagates
  R->>F: load tasks, techniques, history, today's log
  F->>DB: get users/{uid} subcollections
  DB-->>R: saved documents, or empty on a new account
  R-->>U: Today, Diet, Gym, History
  loop Through the day
    U->>R: Log meals, mark routines done, tick gym sets
    R-->>U: State updates before the network answers
    R->>F: save the changed document
    F->>DB: set or delete users/{uid}/...
  end
  U->>A: Sign out
  A-->>R: authStateChanges emits null, uid becomes empty
  R->>R: Controllers rebuilt, writes guarded off
```

---

## 01 — Cold start and the splash gate

`main` resolves Firebase and SharedPreferences before the first frame, so the saved theme is already
known when the splash paints. The splash then runs the network round trip *alongside* its 1.6 second
animation rather than after it.

**Files:** `lib/main.dart:22` · `lib/screens/splash_screen.dart:33` · `lib/providers/theme_provider.dart:13` · `lib/providers/auth_provider.dart:41`

```mermaid
sequenceDiagram
  autonumber
  participant M as main
  participant FB as Firebase
  participant SP as SharedPreferences
  participant App as MyApp / MaterialApp
  participant S as SplashScreen
  participant A as AuthService
  participant F as FirestoreService

  M->>FB: initializeApp with DefaultFirebaseOptions
  FB-->>M: ready
  M->>SP: getInstance
  SP-->>M: preferences
  M->>App: runApp, ProviderScope overrides sharedPreferencesProvider
  App->>App: watch themeModeProvider, restored light / dark / system
  App->>S: home is SplashScreen
  par Entrance animation, 1600 ms
    S->>S: AnimationController.forward
  and Workspace prep, started in initState
    S->>A: currentUser
    A-->>S: User or null
    opt User present
      S->>F: prepareUserWorkspace uid, email, displayName
      F-->>S: null on success, or the error object
    end
  end
  S->>S: animation completed, await the workspace future
  opt Workspace failed
    S-->>S: SnackBar, could not load your data
  end
  alt Signed in
    S->>App: pushReplacement to HomeScreen
  else Signed out
    S->>App: pushReplacement to LoginScreen
  end
```

- **Why:** preferences are read before `runApp` so the splash never flashes the wrong appearance for a frame.
- The route is chosen from the *cached* `currentUser`, not from the auth stream — a persisted session skips the login screen entirely.
- **Failure path:** a rejected profile write (undeployed security rules, for instance) still lets you in, but surfaces as a snackbar rather than vanishing silently.

---

## 02 — Signing in, two ways

Email/password and Google both land on the same finish line: a `UserCredential`, a profile document,
then `/home`. Google takes the native picker on mobile and a popup on web, because Android
special-cases `google.com` and fails the redirect flow.

**Files:** `lib/screens/login_screen.dart:311` · `lib/services/auth_service.dart:44` · `lib/providers/auth_provider.dart:41`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant L as LoginScreen
  participant A as AuthService
  participant G as GoogleSignIn plugin
  participant FA as FirebaseAuth
  participant F as FirestoreService
  participant DB as Cloud Firestore

  alt Email and password
    U->>L: Fill the form, tap Continue or Create account
    L->>L: Validate, and on sign-up check both passwords match
    L->>A: signInWithEmail or signUpWithEmail
    A->>FA: signInWithEmailAndPassword or createUserWithEmailAndPassword
  else Continue with Google
    U->>L: Tap Continue with Google
    L->>A: signInWithGoogle
    alt Web
      A->>FA: signInWithPopup, GoogleAuthProvider
    else Android and iOS
      A->>G: signIn, native account picker
      G-->>A: GoogleSignInAccount, or null if dismissed
      A->>FA: signInWithCredential, idToken and accessToken
    end
  end

  alt Credential accepted
    FA-->>L: UserCredential
    L->>F: syncUserWorkspace, then prepareUserWorkspace
    F->>DB: set users/{uid} with email, display_name, updated_at, merge
    F-->>L: null, or the error that stopped it
    opt Workspace failed
      L-->>U: SnackBar, signed in but data could not load
    end
    L->>L: pushReplacementNamed /home
  else FirebaseAuthException
    FA-->>L: invalid-credential, email-already-in-use, weak-password, canceled
    L-->>U: Field-level message under email or password
  end
```

- **Why:** Google is a verified provider, so signing in with an address that already has a password account links them and keeps the same uid — and therefore the same data.
- Dismissing the account picker is turned into a `canceled` exception and deliberately shows no error.
- **Watch:** a missing SHA-1 fingerprint surfaces as a `PlatformException` (ApiException: 10), caught separately from auth errors.

---

## 03 — Provider hydration: uid in, data out

`currentUserIdProvider` is the hinge of the whole app. Every data controller watches it, so a new uid
tears the old controllers down and rebuilds them against the new account's collections. Each one
seeds itself with built-in defaults first, so no screen is ever blank while Firestore answers.

**Files:** `lib/providers/auth_provider.dart:12` · `lib/providers/routine_provider.dart:63` · `lib/providers/gym_provider.dart:114` · `lib/providers/diet_provider.dart:93` · `lib/providers/history_provider.dart:78`

```mermaid
sequenceDiagram
  autonumber
  participant FA as FirebaseAuth
  participant AS as authStateProvider
  participant ID as currentUserIdProvider
  participant C as Data controllers
  participant F as FirestoreService
  participant DB as Cloud Firestore

  FA-->>AS: authStateChanges emits User
  AS-->>ID: uid, or the cached currentUser while the stream warms up
  Note over ID,C: An empty string means signed out, and every write is guarded against it
  ID-->>C: rebuild Routine, GymTechnique, History and DailyLog controllers
  C->>C: seed state with defaults so the first frame is already useful
  C->>F: getTasks, getGymTechniques, getRoutineHistory, getDailyLog
  F->>DB: get users/{uid}/tasks, gym_techniques, routine_history, daily_logs
  alt Documents exist
    DB-->>C: saved data
    C->>C: sort by time, run gym technique migration, adopt unless the user already edited
  else Collection empty, new account
    C->>F: saveTasks and saveGymTechniques with the built-in plan
    F->>DB: batch set the defaults
  else Request fails
    C->>C: keep defaults in memory, app stays usable offline
  end
```

- **Why:** every controller checks `_hasLocalChanges` before adopting a Firestore result, so a fetch that lands late never overwrites something you just typed.
- `currentUserProvider` falls back to the SDK's cached user while the stream delivers its first value, so a restart never flickers through a signed-out state.

---

## 04 — Marking a routine done or missed

Tapping a block on Today opens an action sheet, then a note dialog. The entry is written to state
first and pushed to Firestore after — the timeline never waits on the network.

**Files:** `lib/screens/home_screen.dart:133` · `lib/providers/history_provider.dart:33` · `lib/services/firestore_service.dart:173`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant H as HomeScreen
  participant Sh as Task action sheet
  participant HC as HistoryController
  participant F as FirestoreService
  participant DB as Cloud Firestore

  U->>H: Tap a routine block
  H->>Sh: showModalBottomSheet with today's entry and meal slot
  alt Done
    U->>Sh: Done
    Sh->>H: close sheet, open the note dialog
    U->>H: Save note, or Done only for no remark
    H->>HC: markDone task, remark
  else Missed
    U->>Sh: Missed
    Sh->>H: close sheet, ask what got in the way
    U->>H: Save
    H->>HC: markMissed task, reason
  else Clear today
    U->>Sh: Clear
    Sh->>HC: clearToday task
  end
  HC->>HC: write the entry into a map keyed date and task id
  HC-->>U: Today, Dashboard and History repaint at once
  alt Recorded
    HC->>F: saveRoutineHistoryEntry
    F->>DB: set users/{uid}/routine_history/{yyyy-MM-dd:taskId}
  else Cleared
    HC->>F: deleteRoutineHistoryEntry
    F->>DB: delete the same document
  end
  opt Write fails
    HC->>HC: swallow, the optimistic entry stays for this session
  end
```

- **Why:** the document id is `yyyy-MM-dd:taskId`, so re-marking the same task on the same day overwrites rather than duplicating.
- Meal-slot tasks (`breakfast`, `lunch`, `dinner`) get a quick meal entry card in the same sheet, which routes into stage 05.

---

## 05 — Meals, notes, and the save queue

The day's log is one document. Because meals, work notes, study notes and evening notes all mutate
it, `DailyLogController` coalesces writes: while a save is in flight, further edits set a flag
instead of firing a second request, and the loop re-saves the newest state.

**Files:** `lib/providers/diet_provider.dart:108` · `lib/widgets/food_manager_modal.dart:147` · `lib/screens/work_log_screen.dart:69` · `lib/screens/night_split_screen.dart:75`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant D as Diet or Today screen
  participant FD as FoodDictionaryController
  participant DL as DailyLogController
  participant F as FirestoreService
  participant DB as Cloud Firestore

  FD->>F: getFoodDictionary on construction
  F->>DB: get users/{uid}/foods/dictionary
  DB-->>FD: saved list, or null to keep the starter foods
  alt Pick from the saved food list
    U->>D: Open the food manager, search, choose a quantity
    D->>FD: upsert or delete
    FD->>F: saveFoodDictionary with the whole list
    FD-->>D: filtered list with calories per item
  else Type it straight in
    U->>D: Name and calories on the meal card
  end
  D->>DL: addMealItem slot, item
  DL->>DL: roll onto today's document if the date moved
  DL->>DL: copyWith the new breakfast, lunch or dinner list
  DL-->>U: Calorie summary updates immediately
  DL->>DL: mark local changes, then queue a save
  alt No save in flight
    DL->>F: saveDailyLog uid, log
    F->>DB: set users/{uid}/daily_logs/{yyyy-MM-dd}
    loop While an edit arrived during the write
      DL->>F: saveDailyLog with the newest state
      F->>DB: set the same document again
    end
  else Save already running
    DL->>DL: flag it queued and return, no second request
  end
  opt Write fails
    DL->>DL: keep the optimistic log for this session
  end
  Note over DL,DB: Work log and evening split notes take the same path through updateNotes
```

- **Why:** one document per calendar day (`yyyy-MM-dd`) keeps history a simple collection read — see stage 07.
- The controller's date is re-checked before every edit and whenever the app resumes, so a session left open overnight starts a new document instead of writing this morning's breakfast into yesterday.
- **Watch:** a saved dictionary replaces the starter foods wholesale rather than merging with them — otherwise deleting a built-in food would bring it back on the next launch.

---

## 06 — Gym plan, technique library, live session

The weekly plan is derived, not stored: seven day templates are filled by grouping saved techniques
on `weekday`. Loading also migrates old data — retired leg exercises are removed, defaults are
re-pinned to their current day and name, and missing ones are added back.

**Files:** `lib/providers/gym_provider.dart:16` · `lib/providers/gym_provider.dart:114` · `lib/providers/gym_session_provider.dart:8` · `lib/screens/gym_technique_manager_screen.dart:72`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant M as Technique manager
  participant GC as GymTechniqueController
  participant P as gymPlanProvider and todayGymProvider
  participant GS as GymSessionController
  participant F as FirestoreService
  participant DB as Cloud Firestore

  GC->>F: getGymTechniques on construction
  F->>DB: get users/{uid}/gym_techniques
  DB-->>GC: saved techniques
  GC->>GC: drop retired leg work, re-pin default day and name, add missing defaults
  opt Migration changed something
    GC->>F: saveGymTechniques, then delete the retired ids
    F->>DB: batch set and per-document deletes
  end
  GC-->>P: technique list
  P->>P: group by weekday across the seven day templates
  P-->>U: Gym plan screen, plus today's workout on Home and Dashboard
  U->>M: Add, edit or delete a technique with cue, instructions, image
  M->>GC: addTechnique, updateTechnique or deleteTechnique
  GC->>GC: update state first
  GC->>F: saveGymTechnique or deleteGymTechnique
  F->>DB: set or delete users/{uid}/gym_techniques/{id}
  GS->>F: getGymSessions on construction
  F->>DB: get users/{uid}/gym_sessions
  DB-->>GS: one document per logged day
  U->>GS: set targets, tick a set, mark an exercise done, untick or clear it
  GS->>GS: update today's log first
  GS->>F: saveGymSession, or deleteGymSession once the day holds nothing
  F->>DB: set or delete users/{uid}/gym_sessions/{yyyy-MM-dd}
  GS-->>U: progress ring, completed sets over target sets
  Note over GS: Ticks survive a restart and past days stay readable as history
```

- **Why:** technique ids are stable across plan changes, so a saved cue, instruction or image follows an exercise when it moves to another training day.
- `total_volume_kg` is derived from the exercise list and written anyway, the same call `DailyLogModel` makes with `total_calories`: it keeps the day's headline number readable straight out of the document.
- **Watch:** a day's document is deleted once every set is unticked and the targets are back at their defaults, so an emptied day does not linger as a blank history entry.

---

## 07 — Reading it back: history and dashboard

Nothing new is fetched per screen — history and dashboard compose the same providers other screens
write to, plus one `FutureProvider` that pulls the full run of daily logs.

**Files:** `lib/screens/history_screen.dart:24` · `lib/screens/dashboard_screen.dart` · `lib/providers/diet_provider.dart:17`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant V as History or Dashboard
  participant HP as historyProvider
  participant RP as routineProvider
  participant LH as dailyLogHistoryProvider
  participant F as FirestoreService
  participant DB as Cloud Firestore

  U->>V: Open Dashboard from the drawer, or History from Settings
  V->>HP: watch the entry map, already in memory
  V->>RP: watch the routine list
  V->>LH: watch the FutureProvider
  LH->>F: getDailyLogs uid
  F->>DB: get users/{uid}/daily_logs
  DB-->>LH: one document per day
  alt Data
    LH-->>V: list of daily logs
    V->>V: join entries to tasks, compute streaks, calories and completion
    V-->>U: day by day timeline
  else Loading
    V-->>U: skeleton and progress
  else Error
    V-->>U: empty state with a retry route
  end
  Note over V: Dashboard adds todayGymProvider, gymSessionProvider and the in-memory weight value, and keeps only the last seven days
```

- History entries already live in memory from stage 04, so only the calorie history costs a round trip.
- The dashboard's seven-day strip lists only dates that hold a routine entry or a logged meal, so days before the account existed never show as `0/5`.
- **Watch:** the dashboard's body weight is a plain `StateProvider` defaulting to 190 lb — it is not saved anywhere.

---

## 08 — Sign out and account teardown

Signing out clears the cached Google account before Firebase's, so the next sign-in shows the picker
instead of silently reusing the account that just left. The uid then empties, which is what actually
disconnects the data layer.

**Files:** `lib/screens/settings_screen.dart` · `lib/services/auth_service.dart:74` · `lib/services/firestore_service.dart:14`

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant D as SettingsScreen
  participant A as AuthService
  participant G as GoogleSignIn plugin
  participant FA as FirebaseAuth
  participant ID as currentUserIdProvider
  participant C as Data controllers

  U->>D: Sign out
  opt Mobile
    A->>G: signOut, clear the cached account
    G-->>A: done, failures ignored on purpose
  end
  D->>A: signOut
  A->>FA: signOut
  D->>D: pushReplacementNamed /login once the navigator is still mounted
  FA-->>ID: authStateChanges emits null, uid becomes an empty string
  ID-->>C: controllers disposed and rebuilt for the empty user
  C->>C: any late save resolves against an empty uid
  Note over C: FirestoreService treats an empty uid as signed out and no-ops every read and write
```

- **Why:** Firestore rejects an empty document id, and a widget can rebuild for a frame mid-sign-out — the empty-uid guard is what stops that frame from throwing.
- Signing in as a different account follows the same path in reverse: new uid, new controllers, stage 03 again.

---

## Where the data lands

One tree per account, keyed by Firebase uid. The rules in `firestore.rules` allow read and write only
when `request.auth.uid` matches the `{userId}` in the path, and deny everything outside `/users`.

| Path | Document id | Written by |
| --- | --- | --- |
| `users/{uid}` | uid | Profile: email, display name, server timestamp — refreshed on every sign-in |
| `users/{uid}/tasks` | task id | Routine manager; seeded with the built-in day plan on a new account |
| `users/{uid}/daily_logs` | `yyyy-MM-dd` | Meals, work notes, study and gaming notes — one document per day |
| `users/{uid}/routine_history` | `yyyy-MM-dd:taskId` | Done / missed status with an optional remark |
| `users/{uid}/gym_techniques` | technique id | Weekday, name, cue, instructions, image URL |
| `users/{uid}/gym_sessions` | `yyyy-MM-dd` | Per-exercise target, working weight and ticked sets, plus the day's `total_volume_kg` |
| `users/{uid}/foods` | `dictionary` | The food list offered when logging a meal, as one array |
| `users/{uid}/weight_log` | `yyyy-MM-dd` | One body-weight reading per day, the dashboard trend line |

Every collection above is keyed to the account, so all of it survives a reinstall. Nothing the user
enters is memory-only any more — the body weight was the last holdout and now lives in `weight_log`.

### How much is read

Each history read is bounded by `FirestoreService.historyWindowDays` (90). `daily_logs`,
`gym_sessions` and `weight_log` order by document id — which is the date — and take a limit;
`routine_history` filters on its stored `date` field. Opening the app used to cost the whole of every
collection, which grew with every day of use.

### What is watched rather than fetched

Today's `daily_logs` document and today's `gym_sessions` document are followed with `snapshots()`, so
a meal or a ticked set from another device lands without a restart. Both controllers ignore incoming
snapshots while one of their own writes is still in flight, and both re-point at the new document when
the day rolls over. Everything else is still a one-shot read: the routine list, technique library and
day plan change rarely, and a stale one is corrected on the next launch.

### When a write fails

`SyncStatusController` (`lib/providers/sync_status_provider.dart`) wraps every save. Controllers still
apply their change locally first and never block on the network, but a failure is now recorded against
the document's key instead of being swallowed. `SyncBanner`, wrapped around the navigator in
`MaterialApp.builder`, shows the count with a retry on any screen, and the Settings account card
reports the same state calmly. Retrying re-runs the stored operation, which reads the controller's
current state — so a retry always sends the newest version, not the one that failed.

### Reminders

`NotificationService` schedules one weekly notification per routine per weekday it runs on, built from
the `startTime` label the routine already carries. `ReminderController` listens to `routineProvider`,
so renaming, retiming or deleting a routine reschedules on its own, and it stores the on/off choice in
`SharedPreferences` beside the theme. Alarms are inexact on purpose, which avoids Android's
exact-alarm permission; a refused permission leaves the switch off and says so.
