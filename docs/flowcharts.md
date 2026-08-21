# RoutineSync — flowcharts

Structure and decisions, drawn from the code in `lib/`. Where
[`sequence-diagrams.md`](sequence-diagrams.md) shows *who talks to whom over time*, this file shows
*what the app is made of* and *which branch it takes*.

Diagrams are Mermaid and render on GitHub.

> **Opening these in a Mermaid viewer?** Feed it a single diagram, not this whole file — a
> Mermaid-only renderer reads the first line (`# RoutineSync — flowcharts`) and reports
> *"No diagram type detected"*. Each diagram is also saved on its own in
> [`diagrams/`](diagrams/), ready to paste into mermaid.live or a plugin.

| # | Chart |
| --- | --- |
| 01 | [Screen and navigation map](#01--screen-and-navigation-map) |
| 02 | [Launch and routing decision](#02--launch-and-routing-decision) |
| 03 | [Sign-in decision tree](#03--sign-in-decision-tree) |
| 04 | [Layers: widget to Firestore](#04--layers-widget-to-firestore) |
| 05 | [Provider dependency graph](#05--provider-dependency-graph) |
| 06 | [Controller hydration decision](#06--controller-hydration-decision) |
| 07 | [The daily-log save queue](#07--the-daily-log-save-queue) |
| 08 | [Gym technique migration and plan derivation](#08--gym-technique-migration-and-plan-derivation) |
| 09 | [Marking a routine](#09--marking-a-routine) |

---

## 01 — Screen and navigation map

Eleven routes, all resolved by `onGenerateRoute` in `lib/main.dart`. The drawer is the hub: every
destination is reached with `pushReplacementNamed`, so the back stack never stacks up. Only the task
editor is a real `push`.

The drawer carries only the five screens opened daily. Everything occasional — work log, evening
split, history, routines — plus appearance and sign-out sits one level down on `/settings`.

```mermaid
flowchart TD
  Start(["App launch"]) --> Splash["SplashScreen<br/>not a named route"]
  Splash -->|"no session"| Login["LoginScreen<br/>/login"]
  Splash -->|"session restored"| Home
  Login -->|"pushReplacementNamed"| Home["Today<br/>/home"]

  Home --> Drawer{{"AppDrawer<br/>five daily screens"}}
  Drawer --> Dash["Dashboard<br/>/dashboard"]
  Drawer --> Gym["Gym plan<br/>/gym"]
  Drawer --> Tech["Gym techniques<br/>/gym-techniques"]
  Drawer --> Diet["Diet and calories<br/>/diet"]
  Drawer --> Set["Settings<br/>/settings"]

  Set --> Work["Work log<br/>/work-log"]
  Set --> Night["Evening split<br/>/night-split"]
  Set --> Hist["History<br/>/history"]
  Set --> Routines["Routines<br/>/routines"]
  Set -->|"sign out"| Login
  Set -.->|"appearance"| Theme["Auto / Light / Dark<br/>ThemeModeSelector"]

  Home -.->|"bottom sheet"| Sheet["Task action sheet<br/>done, missed, clear, quick meal"]
  Diet -.->|"modal"| Food["Food manager<br/>dictionary and quantity"]
  Tech -.->|"bottom sheet"| TechEd["Technique editor"]
  Routines -.->|"push"| Editor["TaskEditorScreen<br/>new or edit"]
  Dash -.->|"dialog"| Weight["Body weight entry"]

  classDef entry fill:#E4EEF7,stroke:#0F4C81,color:#001935
  classDef modal fill:#FFFBEB,stroke:#B45309,color:#3A2A05
  class Start,Splash,Login entry
  class Sheet,Food,TechEd,Editor,Weight,Theme modal
```

- Every screen except the splash and the task editor pulls in `AppDrawer` with its own
  `currentRoute`, which is what drives the selected state.
- `_buildAppRoute` returns `null` for an unrecognised name and no `onUnknownRoute` is configured, so
  route names are effectively a closed set defined by `AppRoutes`.

---

## 02 — Launch and routing decision

The branch that decides whether you ever see the login screen. Note that both the animation and the
workspace sync have to finish — whichever is slower sets the timing.

```mermaid
flowchart TD
  A(["main"]) --> B["Firebase.initializeApp"]
  B --> C["SharedPreferences.getInstance"]
  C --> D["runApp with ProviderScope<br/>preferences injected as an override"]
  D --> E["MyApp reads themeModeProvider<br/>light, dark or system"]
  E --> F["SplashScreen"]

  F --> G["Start 1600 ms animation"]
  F --> H{"Cached currentUser<br/>present?"}
  H -->|"no"| I["Skip the workspace sync"]
  H -->|"yes"| J["prepareUserWorkspace<br/>set users/uid with merge"]
  J --> K{"Write<br/>succeeded?"}
  K -->|"yes"| L["Ready"]
  K -->|"no"| M["Keep the error object"]

  G --> N{"Animation<br/>complete?"}
  N -->|"not yet"| G
  N -->|"yes"| O["await the workspace future"]
  I --> O
  L --> O
  M --> O

  O --> P{"Error to<br/>report?"}
  P -->|"yes"| Q["SnackBar: could not load your data"]
  P -->|"no"| R
  Q --> R{"Signed in?"}
  R -->|"yes"| S(["HomeScreen"])
  R -->|"no"| T(["LoginScreen"])

  classDef fail fill:#FEF0EC,stroke:#B4402A,color:#3A1409
  class M,Q fail
```

---

## 03 — Sign-in decision tree

One screen, two modes, two providers, and a table of Firebase error codes mapped onto specific
fields rather than a generic failure message.

```mermaid
flowchart TD
  A(["LoginScreen"]) --> B{"Which action?"}

  B -->|"Continue / Create account"| C{"Sign-up mode?"}
  C -->|"yes"| D{"Passwords<br/>match?"}
  D -->|"no"| E["Inline: passwords do not match"]
  D -->|"yes"| F["createUserWithEmailAndPassword"]
  C -->|"no"| G["signInWithEmailAndPassword"]

  B -->|"Continue with Google"| H{"Platform?"}
  H -->|"web"| I["signInWithPopup"]
  H -->|"mobile"| J["GoogleSignIn.signIn"]
  J --> K{"Account<br/>picked?"}
  K -->|"dismissed"| L["Throw code canceled<br/>shown as nothing at all"]
  K -->|"yes"| M["signInWithCredential<br/>idToken and accessToken"]

  B -->|"Forgot?"| N{"Email field<br/>filled?"}
  N -->|"no"| O["Inline: enter your email"]
  N -->|"yes"| P["sendPasswordResetEmail"]

  F --> Q{"Firebase<br/>accepted?"}
  G --> Q
  I --> Q
  M --> Q

  Q -->|"no"| R["Map the code onto a field<br/>invalid-credential, email-already-in-use,<br/>weak-password, too-many-requests"]
  Q -->|"yes"| S["syncUserWorkspace"]
  S --> T{"Profile write<br/>succeeded?"}
  T -->|"no"| U["SnackBar: signed in, data could not load"]
  T -->|"yes"| V(["pushReplacementNamed /home"])
  U --> V

  classDef fail fill:#FEF0EC,stroke:#B4402A,color:#3A1409
  classDef ok fill:#F0FDF4,stroke:#15803D,color:#052E16
  class E,O,R,U fail
  class V,P ok
```

---

## 04 — Layers: widget to Firestore

Screens never touch the Firebase SDKs. Everything crosses two boundaries: a Riverpod controller that
owns state, and a service that owns the SDK call.

```mermaid
flowchart TD
  subgraph UI["UI · lib/screens, lib/widgets"]
    S1["Today, Dashboard, Diet,<br/>Work log, Evening split, History, Settings"]
    S2["Gym plan, Gym techniques,<br/>Routines, Login, Splash"]
    S3["AppDrawer, meal cards,<br/>food manager, technique cards"]
  end

  subgraph State["State · lib/providers"]
    P1["RoutineController"]
    P2["DailyLogController"]
    P3["HistoryController"]
    P4["GymTechniqueController"]
    P5["GymSessionController"]
    P6["FoodDictionaryController"]
    P7["ThemeModeController"]
    P8["WeightController"]
    P9["SyncStatusController"]
    P10["ReminderController"]
  end

  subgraph Domain["Models · lib/models"]
    M1["TaskModel"]
    M2["DailyLogModel + MealItem"]
    M3["RoutineHistoryEntry"]
    M4["GymTechniqueModel"]
    M5["GymSessionLog + GymExerciseSession"]
    M6["WeightEntryModel"]
  end

  subgraph Svc["Services · lib/services"]
    V1["FirestoreService"]
    V2["AuthService"]
    V3["NotificationService"]
  end

  subgraph Ext["Platform"]
    E1[("Cloud Firestore<br/>users/uid/...")]
    E2["Firebase Auth<br/>+ Google Sign-In"]
    E3["SharedPreferences"]
    E4["Local notifications"]
  end

  UI --> State
  State --> Domain
  P1 --> V1
  P2 --> V1
  P3 --> V1
  P4 --> V1
  P5 --> V1
  P6 --> V1
  P8 --> V1
  UI --> V2
  P1 --> P10
  P10 --> V3
  V1 --> E1
  V2 --> E2
  P7 --> E3
  P10 --> E3
  V3 --> E4
  P1 & P2 & P3 & P4 & P5 & P6 & P8 -. "every write" .-> P9

  classDef db fill:#ECFEFF,stroke:#0E7490,color:#042F2E
  class E1,E2,E3,E4 db
```

- `json_serializable` generates the `toJson` / `fromJson` on most models; the `.g.dart` files are
  build output and are never edited by hand. `GymDayModel`, `GymSessionLog` and `WeightEntryModel`
  map themselves by hand, so adding a field to them needs no code generation run.
- Every controller that writes reports the result into `SyncStatusController`. Optimistic local state
  is unchanged — the difference is that a failure is now countable and retryable rather than silent.
- `FirestoreService` treats an empty user id as "signed out" and no-ops, which is what makes the
  sign-out frame safe.

---

## 05 — Provider dependency graph

`currentUserIdProvider` is the hinge. Everything that persists watches it, so changing accounts
disposes the old controllers and rebuilds them against the new tree.

```mermaid
flowchart LR
  A["authServiceProvider"] --> B["authStateProvider<br/>StreamProvider"]
  B --> C["currentUserProvider<br/>stream value, else cached user"]
  A --> C
  C --> D{{"currentUserIdProvider<br/>uid or empty string"}}
  E["firestoreServiceProvider"] --> F

  D --> F["routineProvider"]
  D --> G["dailyLogProvider"]
  D --> H["historyProvider"]
  D --> I["gymTechniqueProvider"]
  D --> J["dailyLogHistoryProvider"]
  D --> M["gymSessionProvider"]
  D --> N["foodDictionaryProvider"]
  D --> R["weightProvider"]
  E --> G
  E --> H
  E --> I
  E --> J
  E --> M
  E --> N
  E --> R

  I --> K["gymPlanProvider<br/>derived, 7 day templates"]
  K --> L["todayGymProvider<br/>DateTime.now weekday"]

  P["sharedPreferencesProvider<br/>overridden in main"] --> Q["themeModeProvider"]
  P --> T["reminderProvider"]
  S["notificationServiceProvider<br/>overridden in main"] --> T
  F --> T
  U{{"syncStatusProvider<br/>no dependencies"}}
  F & G & H & I & M & N & R --> U

  classDef hinge fill:#ECFEFF,stroke:#0E7490,color:#042F2E
  class D,U hinge
```

`syncStatusProvider` is the second hinge: it depends on nothing, so every controller can report a
failed write into it without creating a cycle. `reminderProvider` watches the routine list, which is
what reschedules notifications when a routine is renamed, retimed or deleted.

---

## 06 — Controller hydration decision

The same shape runs in `RoutineController`, `GymTechniqueController`, `HistoryController` and
`DailyLogController`: state is useful immediately, and the network result is adopted only if it is
still safe to do so.

```mermaid
flowchart TD
  A(["Controller constructed for a uid"]) --> B["Seed state with built-in defaults<br/>routine plan, gym techniques, today's empty log"]
  B --> C["Fetch from Firestore"]
  C --> D{"Request<br/>succeeded?"}
  D -->|"no"| E["Keep defaults<br/>app stays usable offline"]
  D -->|"yes"| F{"Still<br/>mounted?"}
  F -->|"no"| G["Drop the result"]
  F -->|"yes"| H{"User already<br/>edited locally?"}
  H -->|"yes"| I["Keep the local state<br/>never overwrite a live edit"]
  H -->|"no"| J{"Collection<br/>empty?"}
  J -->|"yes"| K["Write the defaults up<br/>new account seeding"]
  J -->|"no"| L["Sort, migrate, adopt as state"]
  L --> M(["UI repaints with saved data"])
  K --> M
  E --> M
  I --> M

  classDef warn fill:#FFFBEB,stroke:#B45309,color:#3A2A05
  class E,I,G warn
```

---

## 07 — The daily-log save queue

One document holds the whole day, and four screens edit it. `DailyLogController` coalesces writes so
fast typing cannot open a queue of overlapping requests.

```mermaid
flowchart TD
  A(["addMealItem, removeMealItem or updateNotes"]) --> B["state = state.copyWith<br/>totals recomputed"]
  B --> C["UI repaints immediately"]
  B --> D["hasLocalChanges = true"]
  D --> E{"Save already<br/>in flight?"}
  E -->|"yes"| F["saveQueued = true<br/>return without a request"]
  E -->|"no"| G["saveInProgress = true"]
  G --> H["Take the current state"]
  H --> I["saveDailyLog<br/>set users/uid/daily_logs/yyyy-MM-dd"]
  I --> J{"Write<br/>threw?"}
  J -->|"yes"| K["Swallow it<br/>optimistic state survives the session"]
  J -->|"no"| L["Written"]
  K --> M
  L --> M{"saveQueued<br/>and still mounted?"}
  M -->|"yes"| H
  M -->|"no"| N["saveInProgress = false"]
  N --> O(["Idle"])
  F --> O

  classDef warn fill:#FFFBEB,stroke:#B45309,color:#3A2A05
  class K warn
```

The loop re-reads `state` each pass, so the last write always carries the newest version of the day —
intermediate edits are skipped rather than queued one by one.

---

## 08 — Gym technique migration and plan derivation

The weekly plan is computed, never stored. Saved techniques are cleaned up on load so an old account
converges on the current plan without losing the cues and images the user wrote.

```mermaid
flowchart TD
  A(["getGymTechniques for this uid"]) --> B{"Any saved<br/>techniques?"}
  B -->|"no"| C["Write defaultGymTechniques<br/>up to Firestore"]
  B -->|"yes"| D["Remove retired ids<br/>the leg-loading exercises"]
  D --> E["Re-pin defaults to their<br/>current weekday and name<br/>keeping user cue, instructions, image"]
  E --> F["Add back any default<br/>missing from the saved set"]
  F --> G{"Did anything<br/>change?"}
  G -->|"no"| H["Adopt as state"]
  G -->|"yes"| I["saveGymTechniques<br/>+ delete each retired document"]
  I --> H
  C --> H

  H --> J["gymPlanProvider"]
  J --> K["For each of the 7 day templates,<br/>collect techniques with that weekday"]
  K --> L["todayGymProvider<br/>picks DateTime.now weekday"]
  L --> M(["Today's workout card<br/>on Home and Dashboard"])
  K --> N(["Gym plan screen<br/>full week"])

  classDef db fill:#ECFEFF,stroke:#0E7490,color:#042F2E
  class C,I db
```

Technique ids are stable across plan changes, which is why a cue written for an exercise follows it
when the exercise moves to a different training day.

---

## 09 — Marking a routine

Two taps and an optional note. The distinction that matters: **Done only** records a completion with
an empty remark, while dismissing the dialog records nothing at all.

```mermaid
flowchart TD
  A(["Tap a routine block on Today"]) --> B["Action sheet opens<br/>with today's entry, if any"]
  B --> C{"Choice"}

  C -->|"Done"| D["Note dialog:<br/>what did you accomplish?"]
  D --> E{"Which button?"}
  E -->|"Save note"| F["markDone with remark"]
  E -->|"Done only"| G["markDone with empty remark"]
  E -->|"dismissed"| H["Nothing recorded"]

  C -->|"Missed"| I["Note dialog:<br/>what got in the way?"]
  I --> J{"Which button?"}
  J -->|"Save"| K["markMissed with reason"]
  J -->|"Cancel"| H

  C -->|"Clear"| L["clearToday<br/>remove the entry"]
  C -->|"Meal slot task"| M["Quick meal entry<br/>routes into chart 07"]

  F --> N["Entry keyed yyyy-MM-dd:taskId"]
  G --> N
  K --> N
  N --> O["State updates, screens repaint"]
  O --> P["set the history document"]
  L --> Q["delete the history document"]

  classDef db fill:#ECFEFF,stroke:#0E7490,color:#042F2E
  classDef warn fill:#FFFBEB,stroke:#B45309,color:#3A2A05
  class P,Q db
  class H warn
```

Because the key contains the date, marking the same task twice in one day overwrites the earlier
entry instead of creating a second one.
