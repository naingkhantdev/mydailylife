import 'package:flutter/widgets.dart';

import '../models/daily_log_model.dart';
import '../models/task_model.dart';
import '../providers/language_provider.dart';

/// Every user-facing string in the app, in English and Myanmar.
///
/// Hand-rolled instead of `gen-l10n` so there is no code generation step and
/// no ARB files to keep in sync: each string is a getter whose English and
/// Myanmar text sit on the same line, which makes a missing translation
/// impossible rather than a silent fallback to English.
///
/// Deliberately *not* translated: user-entered data (routine titles, food
/// names, notes) and the seeded exercise / technique library — gym terms are
/// what people actually say at the gym, in English, in Myanmar too.
///
/// Read through `context.strings`, which [AppStringsScope] provides from
/// `MaterialApp.builder`, so dialogs and sheets resolve it as well.
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isMyanmar => language == AppLanguage.myanmar;

  String _t(String english, String myanmar) => isMyanmar ? myanmar : english;

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------

  String get cancel => _t('Cancel', 'မလုပ်တော့ပါ');
  String get save => _t('Save', 'သိမ်းရန်');
  String get delete => _t('Delete', 'ဖျက်ရန်');
  String get edit => _t('Edit', 'ပြင်ရန်');
  String get add => _t('Add', 'ထည့်ရန်');
  String get done => _t('Done', 'ပြီးပါပြီ');
  String get close => _t('Close', 'ပိတ်ရန်');
  String get retryNow => _t('Retry now', 'ထပ်ကြိုးစားရန်');
  String get signedOut => _t('Signed out', 'အကောင့်မှ ထွက်ထားသည်');

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get settings => _t('Settings', 'ဆက်တင်များ');
  String get appearanceEyebrow => _t('APPEARANCE', 'အသွင်အပြင်');
  String get theme => _t('Theme', 'အရောင်ပုံစံ');
  String get themeHint => _t(
        'Auto follows your phone, so the app switches with it at night.',
        'အလိုအလျောက်ကို ရွေးထားပါက ဖုန်းနှင့်အတူ ညဘက်တွင် အမှောင်ပုံစံသို့ ပြောင်းပေးပါမည်။',
      );
  String get themeAuto => _t('Auto', 'အလိုအလျောက်');
  String get themeLight => _t('Light', 'အလင်း');
  String get themeDark => _t('Dark', 'အမှောင်');
  String get languageEyebrow => _t('LANGUAGE', 'ဘာသာစကား');
  String get appLanguage => _t('App language', 'အက်ပ် ဘာသာစကား');
  String get remindersEyebrow => _t('REMINDERS', 'သတိပေးချက်များ');
  String get routineAlerts => _t('Routine alerts', 'လုပ်ငန်းစဉ် သတိပေးချက်');
  String get featuresEyebrow => _t('FEATURES', 'လုပ်ဆောင်ချက်များ');
  String get manageFeatures => _t('Manage features', 'လုပ်ဆောင်ချက်များ စီမံရန်');
  String get manageFeaturesHint => _t(
        'Turn off what you do not use — the drawer and Home screen stay '
            'simple around only what is on.',
        'မသုံးသည်များကို ပိတ်ထားပါ — မီနူးနှင့် ပင်မစာမျက်နှာတွင် '
            'ဖွင့်ထားသည်များကိုသာ ပြပါမည်။',
      );
  String get moduleDiet => _t('Daily Food Management', 'နေ့စဉ် အစားအသောက် စီမံမှု');
  String get moduleDietHint =>
      _t('Log meals and track calories.', 'အစားအစာ မှတ်တမ်းတင်ပြီး ကယ်လိုရီ ခြေရာခံပါ။');
  String get moduleTime => _t('Time Management', 'အချိန် စီမံမှု');
  String get moduleTimeHint => _t(
        'Plan your day and track routines.',
        'နေ့စဉ်အစီအစဉ် ချပြီး လုပ်ငန်းစဉ်များကို ခြေရာခံပါ။',
      );
  String get moduleGym => _t('Gym Management', 'ဂျင် စီမံမှု');
  String get moduleGymHint => _t(
        'Plan workouts and log gym sets.',
        'လေ့ကျင့်ခန်း စီစဉ်ပြီး ဆက်များကို မှတ်တမ်းတင်ပါ။',
      );
  String get moreScreensEyebrow => _t('MORE SCREENS', 'အခြား စာမျက်နှာများ');
  String get logsAndPlanning => _t('Logs & planning', 'မှတ်တမ်းနှင့် အစီအစဉ်');
  String get workLog => _t('Work log', 'အလုပ်မှတ်တမ်း');
  String get workLogHint => _t('What you got done today', 'ယနေ့ ပြီးမြောက်ခဲ့သည်များ');
  String get eveningSplit => _t('Evening split', 'ညနေပိုင်း');
  String get eveningSplitHint =>
      _t('Study and gaming notes', 'စာလေ့လာမှုနှင့် ဂိမ်း မှတ်စုများ');
  String get history => _t('History', 'မှတ်တမ်းဟောင်းများ');
  String get historyHint => _t(
        'Past days, routines and meals',
        'ယခင်ရက်များ၊ လုပ်ငန်းစဉ်နှင့် အစားအစာများ',
      );
  String get routines => _t('Routines', 'လုပ်ငန်းစဉ်များ');
  String get routinesHint => _t(
        'Edit the recurring day plan',
        'ထပ်တလဲလဲ နေ့စဉ်အစီအစဉ်ကို ပြင်ဆင်ရန်',
      );
  String get accountEyebrow => _t('ACCOUNT', 'အကောင့်');
  String get yourData => _t('Your data', 'သင့်ဒေတာ');
  String unsavedChanges(int count) => _t(
        '$count change${count == 1 ? '' : 's'} not saved yet',
        'မသိမ်းရသေးသော ပြောင်းလဲမှု $count ခု',
      );
  String get saving => _t('Saving…', 'သိမ်းနေသည်…');
  String get allSaved => _t(
        'All changes saved. Only you can see them.',
        'အပြောင်းအလဲအားလုံး သိမ်းပြီးပါပြီ။ သင်တစ်ဦးတည်းသာ မြင်နိုင်ပါသည်။',
      );
  String get signOut => _t('Sign out', 'အကောင့်မှ ထွက်ရန်');
  String get remindRoutineStart =>
      _t('Remind me when a routine starts', 'လုပ်ငန်းစဉ် စချိန်တွင် သတိပေးပါ');
  String get remindersUnavailable =>
      _t('Not available on this device.', 'ဤဖုန်းတွင် အသုံးမပြုနိုင်ပါ။');
  String get remindersBlocked => _t(
        'Blocked in system settings — allow notifications first.',
        'ဖုန်းဆက်တင်တွင် ပိတ်ထားသည် — အသိပေးချက်များကို ဦးစွာ ခွင့်ပြုပါ။',
      );
  String get updating => _t('Updating…', 'အပ်ဒိတ်လုပ်နေသည်…');
  String get remindersOffHint => _t(
        'Uses the start times already on your routines.',
        'လုပ်ငန်းစဉ်များတွင် သတ်မှတ်ထားသော စချိန်များကို အသုံးပြုပါသည်။',
      );
  String remindersScheduled(int count) => _t(
        count == 1
            ? '1 weekly reminder scheduled.'
            : '$count weekly reminders scheduled.',
        'အပတ်စဉ် သတိပေးချက် $count ခု သတ်မှတ်ထားသည်။',
      );

  // ---------------------------------------------------------------------------
  // Navigation (drawer items double as screen titles)
  // ---------------------------------------------------------------------------

  String get today => _t('Today', 'ယနေ့');
  String get dashboard => _t('Dashboard', 'အနှစ်ချုပ်');
  String get gymPlan => _t('Gym plan', 'ဂျင် အစီအစဉ်');
  String get gymTechniques => _t('Gym techniques', 'ဂျင် နည်းစနစ်များ');
  String get gymHistory => _t('Gym history', 'ဂျင် မှတ်တမ်း');
  String get dietAndCalories => _t('Diet & calories', 'အစားအသောက်နှင့် ကယ်လိုရီ');
  String get closeMenu => _t('Close menu', 'မီနူး ပိတ်ရန်');

  // ---------------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------------

  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];
  static const _weekdaysMy = [
    'တနင်္လာ', 'အင်္ဂါ', 'ဗုဒ္ဓဟူး', 'ကြာသပတေး', 'သောကြာ', 'စနေ', 'တနင်္ဂနွေ',
  ];
  // The one-syllable forms Myanmar calendars print in narrow day columns.
  static const _weekdaysShortMy = ['လာ', 'ဂါ', 'ဟူး', 'တေး', 'ကြာ', 'နေ', 'နွေ'];
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsMy = [
    'ဇန်နဝါရီ', 'ဖေဖော်ဝါရီ', 'မတ်', 'ဧပြီ', 'မေ', 'ဇွန်', 'ဇူလိုင်',
    'ဩဂုတ်', 'စက်တင်ဘာ', 'အောက်တိုဘာ', 'နိုဝင်ဘာ', 'ဒီဇင်ဘာ',
  ];

  /// [weekday] is `DateTime.weekday`: 1 = Monday … 7 = Sunday.
  String weekday(int weekday) =>
      (isMyanmar ? _weekdaysMy : _weekdaysEn)[weekday - 1];

  String weekdayShort(int weekday) => isMyanmar
      ? _weekdaysShortMy[weekday - 1]
      : _weekdaysEn[weekday - 1].substring(0, 3);

  /// [month] is `DateTime.month`: 1 = January.
  String month(int month) => (isMyanmar ? _monthsMy : _monthsEn)[month - 1];

  String monthShort(int month) =>
      isMyanmar ? _monthsMy[month - 1] : _monthsEn[month - 1].substring(0, 3);

  /// "October 13, 2026" / "2026 ခုနှစ် အောက်တိုဘာ 13 ရက်".
  String longDate(DateTime date) => isMyanmar
      ? '${date.year} ခုနှစ် ${month(date.month)} ${date.day} ရက်'
      : '${month(date.month)} ${date.day}, ${date.year}';

  /// "Oct 13" / "အောက်တိုဘာ 13".
  String shortDate(DateTime date) => isMyanmar
      ? '${month(date.month)} ${date.day}'
      : '${monthShort(date.month)} ${date.day}';

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  String get manageRoutines => _t('Manage routines', 'လုပ်ငန်းစဉ်များ စီမံရန်');
  String get dailyRoutine => _t('Daily routine', 'နေ့စဉ် လုပ်ငန်းစဉ်');
  String get markAsMissed => _t('Mark as missed', 'လွတ်သွားကြောင်း မှတ်ရန်');
  String get missedReasonLabel =>
      _t('What got in the way?', 'ဘာက အဟန့်အတား ဖြစ်ခဲ့သလဲ?');
  String get missedReasonHint => _t(
        'Optional note for your history',
        'မှတ်တမ်းအတွက် မှတ်စု (မထည့်လည်း ရပါသည်)',
      );
  String get completeTask => _t('Complete task', 'ပြီးမြောက်ကြောင်း မှတ်ရန်');
  String get shortNote => _t('Short note', 'မှတ်စု အတို');
  String get shortNoteHint => _t(
        'Optional: what did you accomplish?',
        'မထည့်လည်း ရပါသည် — ဘာတွေ ပြီးမြောက်ခဲ့သလဲ?',
      );
  String get doneOnly => _t('Done only', 'ပြီးကြောင်းသာ မှတ်ရန်');
  String get saveNote => _t('Save note', 'မှတ်စု သိမ်းရန်');
  String doneOfTotal(int done, int total) =>
      _t('$done of $total done', '$total ခုအနက် $done ခု ပြီးပါပြီ');
  String get todaysTraining => _t("TODAY'S TRAINING", 'ယနေ့ လေ့ကျင့်ခန်း');
  String get recoveryDayViewPlan =>
      _t('Recovery day · View plan', 'အနားယူရက် · အစီအစဉ် ကြည့်ရန်');
  String exercisesViewTechnique(int count) => _t(
        '$count exercises · View technique',
        'လေ့ကျင့်ခန်း $count မျိုး · နည်းစနစ် ကြည့်ရန်',
      );
  String setsViewTechnique(int completed, int target) => _t(
        '$completed/$target sets · View technique',
        'ဆက် $completed/$target · နည်းစနစ် ကြည့်ရန်',
      );
  String get now => _t('NOW', 'ယခု');
  String until(String time) => _t('Until $time', '$time အထိ');
  String get missed => _t('Missed', 'လွတ်သွားသည်');
  String get clearStatus => _t('Clear status', 'အခြေအနေ ဖယ်ရှားရန်');
  String get nothingTurnedOn => _t('Nothing turned on', 'ဘာမှ ဖွင့်မထားပါ');
  String get nothingTurnedOnHint => _t(
        'Turn on Daily Food Management, Time Management, or Gym '
            'Management in Settings to start using RoutineSync.',
        'RoutineSync ကို စသုံးရန် ဆက်တင်များတွင် နေ့စဉ် အစားအသောက်၊ '
            'အချိန် သို့မဟုတ် ဂျင် စီမံမှုကို ဖွင့်ပါ။',
      );
  String get openSettings => _t('Open Settings', 'ဆက်တင်များ ဖွင့်ရန်');
  String get nothingScheduledToday =>
      _t('Nothing scheduled today', 'ယနေ့ အစီအစဉ် မရှိပါ');
  String get nothingScheduledTodayHint => _t(
        'Add a routine and it will show up here at the right time of day.',
        'လုပ်ငန်းစဉ်တစ်ခု ထည့်လိုက်ပါက သင့်တော်သည့်အချိန်တွင် ဤနေရာ၌ ပေါ်လာပါမည်။',
      );
  String get addRoutine => _t('Add a routine', 'လုပ်ငန်းစဉ် ထည့်ရန်');

  /// "Mon, Oct 13" / "တနင်္လာ၊ အောက်တိုဘာ 13".
  String weekdayDate(DateTime date) => isMyanmar
      ? '${weekday(date.weekday)}၊ ${shortDate(date)}'
      : '${weekdayShort(date.weekday)}, ${shortDate(date)}';

  /// "Mon 13" / "လာ 13".
  String weekdayDay(DateTime date) => '${weekdayShort(date.weekday)} ${date.day}';

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  String get last7Days => _t('Last 7 days', 'နောက်ဆုံး 7 ရက်');
  String get viewAll => _t('View all', 'အားလုံး ကြည့်ရန်');
  String get pastDaysEmpty => _t(
        'Past days appear here once you close out a day.',
        'တစ်ရက် ကုန်ဆုံးသွားသည်နှင့် ယခင်ရက်များ ဤနေရာတွင် ပေါ်လာပါမည်။',
      );
  String get updateCurrentWeight =>
      _t('Update current weight', 'လက်ရှိ ကိုယ်အလေးချိန် ပြင်ရန်');
  String get weightInLb => _t('Weight in lb', 'ကိုယ်အလေးချိန် (ပေါင်)');
  String get restDay => _t('Rest day', 'အနားယူရက်');
  String doneOf(int done, int total) => _t('$done of $total', '$done / $total');
  String get nothingScheduledLower =>
      _t('nothing scheduled', 'အစီအစဉ် မရှိပါ');
  String get routinesDone => _t('routines done', 'လုပ်ငန်းစဉ် ပြီးပါပြီ');
  String get calories => _t('Calories', 'ကယ်လိုရီ');
  String get gymSets => _t('Gym sets', 'ဂျင် ဆက်များ');
  String get weight => _t('Weight', 'ကိုယ်အလေးချိန်');
  String get everyRoutineHasStatus => _t(
        'Every routine has a status',
        'လုပ်ငန်းစဉ်အားလုံး အခြေအနေ မှတ်ပြီးပါပြီ',
      );
  String missedCount(int count) => _t('$count missed', '$count ခု လွတ်');
  String openCount(int count) => _t('$count open', '$count ခု ကျန်');

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  String get noPastDaysYet => _t('No past days yet', 'ယခင်ရက်များ မရှိသေးပါ');
  String get noPastDaysYetHint => _t(
        'Complete routines and add short remarks today. Past daily facts '
            'will appear here clearly by date.',
        'ယနေ့ လုပ်ငန်းစဉ်များ ပြီးမြောက်အောင်လုပ်ပြီး မှတ်စုတိုများ ထည့်ပါ။ '
            'ယခင်ရက်များ၏ မှတ်တမ်းကို ရက်စွဲအလိုက် ဤနေရာတွင် ပြပါမည်။',
      );
  String get goToToday => _t('Go to today', 'ယနေ့သို့ သွားရန်');
  String get pastDailyFactsEyebrow =>
      _t('PAST DAILY FACTS', 'ယခင် နေ့စဉ်မှတ်တမ်းများ');
  String get yourDaysRemembered =>
      _t('Your days, clearly remembered', 'သင့်နေ့ရက်များကို ရှင်းလင်းစွာ မှတ်ထားသည်');
  String get openDateHint => _t(
        'Open a date to see what happened and the remarks you saved.',
        'ဖြစ်ခဲ့သည်များနှင့် သိမ်းထားသော မှတ်စုများကို ကြည့်ရန် ရက်စွဲကို ဖွင့်ပါ။',
      );
  String get historyHeroTitle => _t(
        'Patterns become visible\nwhen days are remembered.',
        'နေ့ရက်များကို မှတ်ထားမှသာ\nပုံစံများကို မြင်လာမည်။',
      );
  String get trackedDays => _t('TRACKED DAYS', 'မှတ်ထားသောရက်');
  String get wins => _t('WINS', 'အောင်မြင်မှု');
  String get completion => _t('COMPLETION', 'ပြီးမြောက်မှု');
  String doneCountChip(int count) => _t('$count done', '$count ခု ပြီး');
  String untrackedCount(int count) =>
      _t('$count untracked', '$count ခု မမှတ်ရသေး');
  String get work => _t('Work', 'အလုပ်');
  String get study => _t('Study', 'စာလေ့လာမှု');
  String get gaming => _t('Gaming', 'ဂိမ်း');
  String get kcalLogged => _t('kcal logged', 'kcal မှတ်ထားသည်');
  String foodItems(int count) => _t(
        count == 1 ? 'food item' : 'food items',
        'အစားအစာ',
      );
  String get noRoutinesScheduledDay => _t(
        'No routines were scheduled for this day.',
        'ဤနေ့တွင် လုပ်ငန်းစဉ် စီစဉ်ထားခြင်း မရှိခဲ့ပါ။',
      );
  String fullyCompletedDay(int total) => _t(
        'A fully completed day: all $total routines were done.',
        'အပြည့်အဝ ပြီးမြောက်သောနေ့ — လုပ်ငန်းစဉ် $total ခုလုံး ပြီးခဲ့သည်။',
      );
  String dayBrief(int done, int total, int missed, int pending) => _t(
        '$done of $total routines were completed, with $missed missed and '
            '$pending left untracked.',
        'လုပ်ငန်းစဉ် $total ခုအနက် $done ခု ပြီးခဲ့ပြီး $missed ခု လွတ်သွားကာ '
            '$pending ခု မမှတ်ရသေးပါ။',
      );
  String get statusDone => _t('DONE', 'ပြီး');
  String get statusMissed => _t('MISSED', 'လွတ်');
  String get statusNoUpdate => _t('NO UPDATE', 'မမှတ်ရသေး');
  String get archivedRoutine => _t('Archived routine', 'ဖယ်ထားသော လုပ်ငန်းစဉ်');

  // ---------------------------------------------------------------------------
  // Routines
  // ---------------------------------------------------------------------------

  /// Joins short lists ("Mon, Wed") with the script's own separator.
  String get listSeparator => _t(', ', '၊ ');
  String get addTask => _t('Add task', 'လုပ်ငန်း ထည့်ရန်');
  String get yourScheduleEyebrow => _t('YOUR SCHEDULE', 'သင့် အချိန်ဇယား');
  String get keepDayRealistic =>
      _t('Keep the day realistic', 'လက်တွေ့ကျသော နေ့တစ်နေ့ ဖြစ်ပါစေ');
  String get routinesIntro => _t(
        'Your original tasks are preserved. Edit their time, days, title, '
            'or category—or add a routine that fits your life.',
        'မူလ လုပ်ငန်းများကို ထိန်းသိမ်းထားပါသည်။ အချိန်၊ ရက်၊ အမည် သို့မဟုတ် '
            'အမျိုးအစားကို ပြင်နိုင်သလို သင့်ဘဝနှင့် ကိုက်ညီသော လုပ်ငန်းစဉ်ကိုလည်း ထည့်နိုင်ပါသည်။',
      );
  String get noTasksYet => _t('No tasks yet', 'လုပ်ငန်း မရှိသေးပါ');
  String get noTasksYetHint => _t(
        'Add the first part of your day to get started.',
        'စတင်ရန် သင့်နေ့၏ ပထမဆုံး အပိုင်းကို ထည့်ပါ။',
      );
  String get addFirstTask => _t('Add your first task', 'ပထမဆုံး လုပ်ငန်း ထည့်ရန်');
  String get deleteTaskTitle => _t('Delete this task?', 'ဤလုပ်ငန်းကို ဖျက်မလား?');
  String deleteTaskBody(String title) => _t(
        '“$title” will be removed from your future schedule. '
            'Past history remains available.',
        '“$title” ကို နောင် အချိန်ဇယားမှ ဖယ်ရှားပါမည်။ '
            'ယခင် မှတ်တမ်းများ ဆက်ရှိနေပါမည်။',
      );
  String get taskOptions => _t('Task options', 'လုပ်ငန်း ရွေးချယ်စရာများ');
  String get editTask => _t('Edit task', 'လုပ်ငန်း ပြင်ရန်');
  String get newTask => _t('New task', 'လုပ်ငန်းသစ်');
  String get taskName => _t('Task name', 'လုပ်ငန်း အမည်');
  String get enterTaskName => _t('Enter a task name', 'လုပ်ငန်း အမည် ထည့်ပါ');
  String get timeLabel => _t('TIME', 'အချိန်');
  String get starts => _t('Starts', 'စချိန်');
  String get ends => _t('Ends', 'ပြီးချိန်');
  String get repeatsOn => _t('REPEATS ON', 'ထပ်လုပ်မည့် ရက်များ');
  String get selectOneDay =>
      _t('Select at least one day.', 'အနည်းဆုံး တစ်ရက် ရွေးပါ။');
  String get categoryEyebrow => _t('CATEGORY', 'အမျိုးအစား');
  String get saveChanges => _t('Save changes', 'ပြောင်းလဲမှုများ သိမ်းရန်');
  String get addToRoutine => _t('Add to routine', 'လုပ်ငန်းစဉ်ထဲ ထည့်ရန်');
  String get everyDay => _t('Every day', 'နေ့တိုင်း');
  String get weekdaysOnly => _t('Weekdays', 'ရုံးဖွင့်ရက်များ');

  String category(RoutineCategory category) => switch (category) {
        RoutineCategory.meal => _t('Meal', 'အစားအစာ'),
        RoutineCategory.work => _t('Work', 'အလုပ်'),
        RoutineCategory.rest => _t('Rest', 'အနားယူ'),
        RoutineCategory.gym => _t('Gym', 'ဂျင်'),
        RoutineCategory.study => _t('Study', 'စာလေ့လာ'),
        RoutineCategory.gaming => _t('Gaming', 'ဂိမ်း'),
        RoutineCategory.routine => _t('Routine', 'လုပ်ငန်းစဉ်'),
      };

  // ---------------------------------------------------------------------------
  // Diet
  // ---------------------------------------------------------------------------

  String mealSlot(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => _t('Breakfast', 'နံနက်စာ'),
        MealSlot.lunch => _t('Lunch', 'နေ့လယ်စာ'),
        MealSlot.dinner => _t('Dinner', 'ညစာ'),
      };
  String slotFood(MealSlot slot) =>
      _t('${mealSlot(slot)} food', '${mealSlot(slot)} အစားအစာ');
  String get todaysMealsEyebrow => _t("TODAY'S MEALS", 'ယနေ့ အစားအစာများ');
  String get whatYouLogged => _t("What you've logged", 'မှတ်တမ်းတင်ထားသည်များ');
  String get food => _t('Food', 'အစားအစာ');
  String get qty => _t('Qty', 'အရေအတွက်');
  String get addFood => _t('Add food', 'အစားအစာ ထည့်ရန်');
  String get removeFood => _t('Remove food', 'အစားအစာ ဖယ်ရန်');
  String get enterFoodNameFirst =>
      _t('Enter a food name first', 'အစားအစာ အမည်ကို ဦးစွာ ထည့်ပါ');
  String get enterCaloriesNumber =>
      _t('Enter calories as a number', 'ကယ်လိုရီကို ဂဏန်းဖြင့် ထည့်ပါ');
  String get quantityAtLeastOne =>
      _t('Quantity must be at least 1', 'အရေအတွက် အနည်းဆုံး 1 ဖြစ်ရပါမည်');
  String kcalLeftInGoal(int kcal) => _t(
        "$kcal kcal left in today's goal.",
        'ယနေ့ ပန်းတိုင်အထိ $kcal kcal ကျန်ပါသည်။',
      );
  String kcalOverGoal(int kcal) => _t(
        "$kcal kcal over today's goal.",
        'ယနေ့ ပန်းတိုင်ထက် $kcal kcal ကျော်နေပါသည်။',
      );
  String get todaysIntake => _t("TODAY'S INTAKE", 'ယနေ့ စားသုံးမှု');

  // ---------------------------------------------------------------------------
  // Work log & evening notes
  // ---------------------------------------------------------------------------

  String get endOfDayEyebrow => _t('END OF DAY', 'နေ့ကုန်ချိန်');
  String get accomplishmentsTitle =>
      _t('Accomplishments & notes', 'ပြီးမြောက်မှုများနှင့် မှတ်စုများ');
  String get workLogPrompt => _t(
        'What did you get done today? Future you will thank you for the detail.',
        'ယနေ့ ဘာတွေ ပြီးမြောက်ခဲ့သလဲ? အသေးစိတ် ရေးထားပါက နောင်တွင် အသုံးဝင်ပါမည်။',
      );
  String get accomplishmentsField =>
      _t('Accomplishments and notes', 'ပြီးမြောက်မှုများနှင့် မှတ်စုများ');
  String get eveningEyebrow => _t('EVENING WIND-DOWN', 'ညနေ အနားယူချိန်');
  String get studyGamingNotes =>
      _t('Study & gaming notes', 'စာလေ့လာမှုနှင့် ဂိမ်း မှတ်စုများ');
  String get eveningPrompt => _t(
        'A short note is enough — just what you focused on and how it went.',
        'မှတ်စုတိုလေး ရေးရုံဖြင့် လုံလောက်ပါသည် — ဘာကို အာရုံစိုက်ခဲ့ပြီး ဘယ်လိုဖြစ်ခဲ့သလဲ။',
      );
  String get studyNotes => _t('Study notes', 'စာလေ့လာမှု မှတ်စု');
  String get gamingNotes => _t('Gaming notes', 'ဂိမ်း မှတ်စု');

  // ---------------------------------------------------------------------------
  // Module setup
  // ---------------------------------------------------------------------------

  String get whatToTrack =>
      _t('What do you want to track?', 'ဘာတွေကို ခြေရာခံချင်ပါသလဲ?');
  String get whatToTrackHint => _t(
        'Pick what matters to you. You can change this anytime in Settings, '
            "and the app stays simple around only what you've turned on.",
        'သင့်အတွက် အရေးကြီးသည်များကို ရွေးပါ။ ဆက်တင်များတွင် အချိန်မရွေး ပြောင်းနိုင်ပြီး '
            'ဖွင့်ထားသည်များကိုသာ ရိုးရှင်းစွာ ပြပါမည်။',
      );
  String get keepOneOn => _t(
        'Keep at least one on — the app needs something to show you.',
        'အနည်းဆုံး တစ်ခု ဖွင့်ထားပါ — အက်ပ်တွင် ပြစရာ တစ်ခုခု လိုအပ်ပါသည်။',
      );
  String get settingUp => _t('Setting up...', 'ပြင်ဆင်နေသည်...');
  String get continueLabel => _t('Continue', 'ဆက်လုပ်ရန်');

  // ---------------------------------------------------------------------------
  // Sync banner
  // ---------------------------------------------------------------------------

  String changesNotSaved(int count) => _t(
        count == 1 ? '1 change is not saved' : '$count changes are not saved',
        'ပြောင်းလဲမှု $count ခု မသိမ်းရသေးပါ',
      );
  String get retrying => _t('Retrying…', 'ထပ်ကြိုးစားနေသည်…');
  String get reconnectAndRetry => _t(
        'They are still here — reconnect and retry.',
        'ဒေတာများ မပျောက်ပါ — အင်တာနက် ပြန်ချိတ်ပြီး ထပ်ကြိုးစားပါ။',
      );
  String get retry => _t('Retry', 'ထပ်ကြိုးစားရန်');
  String get dismiss => _t('Dismiss', 'ပိတ်ရန်');

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  String get createYourAccount => _t('Create your account', 'အကောင့် ဖွင့်ပါ');
  String get welcome => _t('Welcome to RoutineSync', 'RoutineSync မှ ကြိုဆိုပါသည်');
  String get signUpIntro => _t(
        'Your routines, meals, and gym plan stay private to your account.',
        'သင့် လုပ်ငန်းစဉ်၊ အစားအစာနှင့် ဂျင်အစီအစဉ်များကို သင့်အကောင့်တွင်သာ သီးသန့် သိမ်းထားပါသည်။',
      );
  String get signInIntro => _t(
        'Sign in to load your daily routine, meals, and gym plan.',
        'နေ့စဉ် လုပ်ငန်းစဉ်၊ အစားအစာနှင့် ဂျင်အစီအစဉ်များကို ဖွင့်ရန် အကောင့်ဝင်ပါ။',
      );
  String get email => _t('Email', 'အီးမေးလ်');
  String get enterYourEmail => _t('Enter your email', 'အီးမေးလ် ထည့်ပါ');
  String get password => _t('Password', 'စကားဝှက်');
  String get atLeast6Chars =>
      _t('At least 6 characters', 'အနည်းဆုံး စာလုံး 6 လုံး');
  String get showPassword => _t('Show password', 'စကားဝှက် ပြရန်');
  String get hidePassword => _t('Hide password', 'စကားဝှက် ဖျောက်ရန်');
  String get confirmPassword => _t('Confirm password', 'စကားဝှက် အတည်ပြုရန်');
  String get rememberMe => _t('Remember me', 'မှတ်ထားပါ');
  String get forgot => _t('Forgot?', 'မေ့နေသလား?');
  String get signUpWithGoogle => _t('Sign up with Google', 'Google ဖြင့် အကောင့်ဖွင့်ရန်');
  String get continueWithGoogle => _t('Continue with Google', 'Google ဖြင့် ဆက်လုပ်ရန်');
  String get haveAccountSignIn => _t(
        'Already have an account? Sign in',
        'အကောင့် ရှိပြီးသားလား? အကောင့်ဝင်ရန်',
      );
  String get newHereCreate =>
      _t('New here? Create an account', 'အသစ်လား? အကောင့် ဖွင့်ရန်');
  String get creatingAccount => _t('Creating account...', 'အကောင့် ဖွင့်နေသည်...');
  String get signingIn => _t('Signing in...', 'အကောင့် ဝင်နေသည်...');
  String get createAccount => _t('Create account', 'အကောင့် ဖွင့်ရန်');
  String get enterPassword => _t('Enter a password', 'စကားဝှက် ထည့်ပါ');
  String get passwordsDontMatch =>
      _t('Passwords do not match', 'စကားဝှက်များ မတူညီပါ');
  String googleSignInFailed(Object error) =>
      _t('Google sign-in failed: $error', 'Google ဖြင့် ဝင်၍ မရပါ: $error');
  String dataNotLoaded(Object error) => _t(
        'Signed in, but your data could not be loaded: $error',
        'အကောင့်ဝင်ပြီးပါပြီ၊ သို့သော် ဒေတာ ဖွင့်၍ မရပါ: $error',
      );
  String get enterValidEmail =>
      _t('Enter a valid email', 'မှန်ကန်သော အီးမေးလ် ထည့်ပါ');
  String get emailInUse => _t(
        'That email already has an account. Sign in.',
        'ဤအီးမေးလ်ဖြင့် အကောင့် ရှိပြီးသားပါ။ အကောင့်ဝင်ပါ။',
      );
  String get noAccountForEmail =>
      _t('No account found for this email', 'ဤအီးမေးလ်ဖြင့် အကောင့် မတွေ့ပါ');
  String get useAtLeast6Chars =>
      _t('Use at least 6 characters', 'အနည်းဆုံး စာလုံး 6 လုံး သုံးပါ');
  String get incorrectPassword => _t('Incorrect password', 'စကားဝှက် မှားနေပါသည်');
  String get tooManyAttempts => _t(
        'Too many attempts. Try again later',
        'ကြိုးစားမှု များလွန်းပါသည်။ နောက်မှ ထပ်ကြိုးစားပါ',
      );
  String get linkGoogleHint => _t(
        'Sign in with your password, then link Google',
        'စကားဝှက်ဖြင့် ဝင်ပြီးမှ Google ကို ချိတ်ပါ',
      );
  String get signInMethodDisabled => _t(
        'This sign-in method is disabled in Firebase',
        'ဤ အကောင့်ဝင်နည်းကို Firebase တွင် ပိတ်ထားပါသည်',
      );
  String signInFailed(String? message) =>
      _t('Sign in failed: $message', 'အကောင့်ဝင်၍ မရပါ: $message');
  String get enterEmailToReset => _t(
        'Enter your email to reset the password',
        'စကားဝှက် ပြန်သတ်မှတ်ရန် အီးမေးလ် ထည့်ပါ',
      );
  String resetEmailSent(String email) => _t(
        'Password reset email sent to $email',
        '$email သို့ စကားဝှက် ပြန်သတ်မှတ်ရန် အီးမေးလ် ပို့ပြီးပါပြီ',
      );
  String resetEmailFailed(String? message) => _t(
        'Could not send reset email: $message',
        'ပြန်သတ်မှတ်ရန် အီးမေးလ် ပို့၍ မရပါ: $message',
      );
  String get or => _t('or', 'သို့မဟုတ်');

  // ---------------------------------------------------------------------------
  // Splash
  // ---------------------------------------------------------------------------

  String couldNotLoadData(Object error) =>
      _t('Could not load your data: $error', 'ဒေတာ ဖွင့်၍ မရပါ: $error');
  String get preparingDaySemantics => _t(
        'RoutineSync is preparing your day',
        'RoutineSync က သင့်နေ့ကို ပြင်ဆင်နေပါသည်',
      );
  String get betterDailyRhythm => _t('A BETTER DAILY RHYTHM', 'ပိုကောင်းသော နေ့စဉ် စည်းချက်');
  String get yourDayInRhythm => _t('Your day, in rhythm.', 'သင့်နေ့ကို စည်းချက်ညီညီ။');
  String get preparingYourDay => _t('Preparing your day', 'သင့်နေ့ကို ပြင်ဆင်နေသည်');

  // ---------------------------------------------------------------------------
  // Food manager
  // ---------------------------------------------------------------------------

  String get searchExistingFood =>
      _t('Search existing food', 'ရှိပြီးသား အစားအစာ ရှာရန်');
  String get existingFoods => _t('Existing foods', 'ရှိပြီးသား အစားအစာများ');
  String get noFoodsFound => _t(
        'No foods found. Create one above.',
        'အစားအစာ မတွေ့ပါ။ အပေါ်တွင် အသစ် ဖန်တီးပါ။',
      );
  String addNamed(String name) => _t('Add $name', '$name ထည့်ရန်');
  String get quantity => _t('Quantity', 'အရေအတွက်');
  String get deleteFoodTitle => _t('Delete food?', 'အစားအစာကို ဖျက်မလား?');
  String deleteFoodBody(String name) => _t(
        '"$name" will be removed from your food list.',
        '"$name" ကို အစားအစာ စာရင်းမှ ဖယ်ရှားပါမည်။',
      );
  String get createFood => _t('Create food', 'အစားအစာ ဖန်တီးရန်');
  String get editFood => _t('Edit food', 'အစားအစာ ပြင်ရန်');
  String get autoFilled => _t('Auto-filled', 'အလိုအလျောက် ဖြည့်ထားသည်');
  String get saveFood => _t('Save food', 'အစားအစာ သိမ်းရန်');
  String get addToMeal => _t('Add to meal', 'ထမင်းဝိုင်းထဲ ထည့်ရန်');
  String get deleteFood => _t('Delete food', 'အစားအစာ ဖျက်ရန်');

  // ---------------------------------------------------------------------------
  // Gym
  // ---------------------------------------------------------------------------

  String get gymTechnique => _t('Gym technique', 'ဂျင် နည်းစနစ်');
  String get manageTechniques => _t('Manage techniques', 'နည်းစနစ်များ စီမံရန်');
  String get recoveryNoSets =>
      _t('Recovery day — no sets to log.', 'အနားယူရက် — မှတ်ရန် ဆက် မရှိပါ။');
  String exercisesTickToStart(int count) => _t(
        '$count exercises · tick a set to start the day',
        'လေ့ကျင့်ခန်း $count မျိုး · စတင်ရန် ဆက်တစ်ခုကို အမှန်ခြစ်ပါ',
      );
  String setsExercisesProgress(int completed, int target, int started) => _t(
        '$completed / $target sets · $started exercises',
        'ဆက် $completed / $target · လေ့ကျင့်ခန်း $started မျိုး',
      );
  String kgMoved(String kg) => _t('$kg kg moved', '$kg kg မ ပြီး');
  String get weeklyPlan => _t('Weekly plan', 'အပတ်စဉ် အစီအစဉ်');
  String get rest => _t('Rest', 'အနားယူ');
  String get restBadge => _t('REST', 'အနားယူ');
  String exercisesCount(int count) => _t(
        '$count ${count == 1 ? 'exercise' : 'exercises'}',
        'လေ့ကျင့်ခန်း $count မျိုး',
      );
  String kgLifted(String kg) => _t('$kg kg lifted', '$kg kg မ ခဲ့သည်');
  String get noWorkoutsYet =>
      _t('No workouts logged yet', 'လေ့ကျင့်မှု မှတ်တမ်း မရှိသေးပါ');
  String get noWorkoutsYetHint => _t(
        'Tick a set or record a weight on a training day and it will show up '
            'here.',
        'လေ့ကျင့်ရက်တွင် ဆက်တစ်ခု အမှန်ခြစ်ပါ သို့မဟုတ် အလေးချိန် မှတ်ပါက '
            'ဤနေရာတွင် ပေါ်လာပါမည်။',
      );
  String get noHistoryYet => _t('No history yet', 'မှတ်တမ်း မရှိသေးပါ');
  String noHistoryYetHint(String exercise) => _t(
        'Log a set or a weight for $exercise and it will show up here.',
        '$exercise အတွက် ဆက် သို့မဟုတ် အလေးချိန် မှတ်ပါက ဤနေရာတွင် ပေါ်လာပါမည်။',
      );
  String sessionsLabel(int count) =>
      _t(count == 1 ? 'SESSION' : 'SESSIONS', 'ကြိမ်');
  String get bestLift => _t('BEST LIFT', 'အများဆုံး အလေးချိန်');
  String setsReps(int completed, int target, int reps) => _t(
        '$completed/$target sets · $reps reps',
        'ဆက် $completed/$target · $reps ကြိမ်',
      );

  String get manageGymTechniques =>
      _t('Manage gym techniques', 'ဂျင် နည်းစနစ်များ စီမံရန်');
  String get addBuiltInExercises =>
      _t('Add built-in exercises', 'မူလ လေ့ကျင့်ခန်းများ ထည့်ရန်');
  String get addTechnique => _t('Add technique', 'နည်းစနစ် ထည့်ရန်');
  String get exerciseLibraryEyebrow =>
      _t('EXERCISE LIBRARY', 'လေ့ကျင့်ခန်း စာကြည့်တိုက်');
  String get buildYourPlan => _t(
        'Build your own training plan',
        'ကိုယ်ပိုင် လေ့ကျင့်ရေး အစီအစဉ် တည်ဆောက်ပါ',
      );
  String get techniqueManagerIntro => _t(
        'Rename any training day or swap two days around, move an exercise to '
            'a different day, update its coaching cues, or remove what you no '
            'longer use.',
        'လေ့ကျင့်ရက်ကို အမည်ပြောင်းခြင်း၊ ရက်နှစ်ရက် လဲလှယ်ခြင်း၊ လေ့ကျင့်ခန်းကို '
            'အခြားရက်သို့ ရွှေ့ခြင်း၊ လမ်းညွှန်ချက်များ ပြင်ခြင်း သို့မဟုတ် '
            'မသုံးတော့သည်များကို ဖယ်ရှားခြင်း ပြုလုပ်နိုင်ပါသည်။',
      );
  String get techniqueAdded => _t('Technique added', 'နည်းစနစ် ထည့်ပြီးပါပြီ');
  String get techniqueUpdated => _t('Technique updated', 'နည်းစနစ် ပြင်ပြီးပါပြီ');
  String builtInAdded(int added) => switch (added) {
        0 => _t(
            'Your plan already has every built-in exercise',
            'သင့်အစီအစဉ်တွင် မူလ လေ့ကျင့်ခန်းအားလုံး ရှိပြီးသားပါ',
          ),
        1 => _t('Added 1 built-in exercise', 'မူလ လေ့ကျင့်ခန်း 1 မျိုး ထည့်ပြီးပါပြီ'),
        _ => _t(
            'Added $added built-in exercises',
            'မူလ လေ့ကျင့်ခန်း $added မျိုး ထည့်ပြီးပါပြီ',
          ),
      };
  String dayUpdated(String day, int added) => switch (added) {
        0 => _t('$day updated', '$day ပြင်ပြီးပါပြီ'),
        1 => _t(
            '$day updated · 1 exercise added',
            '$day ပြင်ပြီးပါပြီ · လေ့ကျင့်ခန်း 1 မျိုး ထည့်ပြီး',
          ),
        _ => _t(
            '$day updated · $added exercises added',
            '$day ပြင်ပြီးပါပြီ · လေ့ကျင့်ခန်း $added မျိုး ထည့်ပြီး',
          ),
      };
  String swapDayWith(String day) => _t('Swap $day with', '$day နှင့် လဲလှယ်မည့်ရက်');
  String get swapDayHint => _t(
        'Both days trade names and every exercise on them.',
        'ရက်နှစ်ရက်လုံး၏ အမည်နှင့် လေ့ကျင့်ခန်းအားလုံးကို လဲလှယ်ပါမည်။',
      );
  String daysSwapped(String a, String b) =>
      _t('$a and $b swapped', '$a နှင့် $b လဲလှယ်ပြီးပါပြီ');
  String moveTo(String name) => _t('Move $name to', '$name ကို ရွှေ့မည့်ရက်');
  String get moveHint => _t(
        'Its cue, steps and image move with it.',
        'လမ်းညွှန်ချက်၊ အဆင့်များနှင့် ပုံလည်း အတူ ပါသွားပါမည်။',
      );
  String alreadyOnDay(String name, String day) =>
      _t('$name is already on $day', '$name သည် $day တွင် ရှိပြီးသားပါ');
  String movedTo(String name, String day) =>
      _t('$name moved to $day', '$name ကို $day သို့ ရွှေ့ပြီးပါပြီ');
  String get deleteTechniqueTitle =>
      _t('Delete technique?', 'နည်းစနစ်ကို ဖျက်မလား?');
  String deleteTechniqueBody(String name, String day) =>
      _t('$name will be removed from $day.', '$name ကို $day မှ ဖယ်ရှားပါမည်။');
  String get techniqueDeleted => _t('Technique deleted', 'နည်းစနစ် ဖျက်ပြီးပါပြီ');
  String get dayActions => _t('Day actions', 'ရက် လုပ်ဆောင်ချက်များ');
  String get renameDay => _t('Rename this day', 'ဤရက်ကို အမည်ပြောင်းရန်');
  String get swapWithAnotherDay =>
      _t('Swap with another day', 'အခြားရက်နှင့် လဲလှယ်ရန်');
  String get noExercisesOnDay =>
      _t('No exercises on this day yet.', 'ဤရက်တွင် လေ့ကျင့်ခန်း မရှိသေးပါ။');
  String get usesBuiltInGuide => _t(
        'Uses the built-in technique guide',
        'မူလ နည်းစနစ် လမ်းညွှန်ကို အသုံးပြုသည်',
      );
  String get techniqueActions => _t('Technique actions', 'နည်းစနစ် လုပ်ဆောင်ချက်များ');
  String get moveToAnotherDay => _t('Move to another day', 'အခြားရက်သို့ ရွှေ့ရန်');
  String editDay(String day) => _t('Edit $day', '$day ကို ပြင်ရန်');
  String get editDayHint => _t(
        'The exercises already on this day stay where they are.',
        'ဤရက်တွင် ရှိပြီးသား လေ့ကျင့်ခန်းများ နေရာ မပြောင်းပါ။',
      );
  String get quickPick => _t('QUICK PICK', 'အမြန် ရွေးရန်');
  String alsoAddExercises(int count, String title) => _t(
        count == 1
            ? 'Also add 1 exercise for $title'
            : 'Also add $count exercises for $title',
        '$title အတွက် လေ့ကျင့်ခန်း $count မျိုးကိုပါ ထည့်ရန်',
      );
  String get dayName => _t('Day name', 'ရက် အမည်');
  String get dayNameHint => _t('Example: Leg day', 'ဥပမာ: Leg day');
  String get enterDayName => _t('Enter a day name.', 'ရက် အမည် ထည့်ပါ။');
  String get focus => _t('Focus', 'အဓိက ကြွက်သား');
  String get focusHint => _t(
        'Example: Quads, hamstrings, calves',
        'ဥပမာ: Quads, hamstrings, calves',
      );
  String get restDayHint => _t(
        'Hides the set progress bar on this day.',
        'ဤရက်တွင် ဆက် တိုးတက်မှု ဘားကို ဖျောက်ထားပါမည်။',
      );
  String get resetBuiltInSplit =>
      _t('Reset to the built-in split', 'မူလ အစီအစဉ်သို့ ပြန်ထားရန်');
  String get addGymTechnique => _t('Add gym technique', 'ဂျင် နည်းစနစ် ထည့်ရန်');
  String get editTechnique => _t('Edit technique', 'နည်းစနစ် ပြင်ရန်');
  String get trainingDay => _t('Training day', 'လေ့ကျင့်ရက်');
  String get exerciseName => _t('Exercise name', 'လေ့ကျင့်ခန်း အမည်');
  String get exerciseNameHint =>
      _t('Example: Dumbbell pullover', 'ဥပမာ: Dumbbell pullover');
  String get coachingCue => _t('Quick coaching cue', 'အတိုချုပ် လမ်းညွှန်ချက်');
  String get coachingCueHint => _t(
        'Example: Keep ribs down and move slowly.',
        'ဥပမာ: နံရိုးကို နှိမ့်ထားပြီး ဖြည်းဖြည်း လုပ်ပါ။',
      );
  String get techniqueSteps => _t('Technique steps', 'နည်းစနစ် အဆင့်များ');
  String get oneStepPerLine =>
      _t('Enter one step per line', 'တစ်ကြောင်းလျှင် အဆင့်တစ်ခု ရေးပါ');
  String get imageUrlOptional =>
      _t('Image URL (optional)', 'ပုံ URL (မထည့်လည်း ရပါသည်)');
  String get enterExerciseName =>
      _t('Enter an exercise name.', 'လေ့ကျင့်ခန်း အမည် ထည့်ပါ။');
  String get exerciseExistsOnDay => _t(
        'This exercise already exists on this day.',
        'ဤလေ့ကျင့်ခန်းသည် ဤရက်တွင် ရှိပြီးသားပါ။',
      );
  String get enterCompleteUrl =>
      _t('Enter a complete image URL.', 'ပြည့်စုံသော ပုံ URL ထည့်ပါ။');
  String get useHttpUrl => _t(
        'Use an http or https image URL.',
        'http သို့မဟုတ် https ပုံ URL ကို သုံးပါ။',
      );

  String dayTechnique(String title) => _t('$title technique', '$title နည်းစနစ်');
  String get kgLiftedToday => _t('kg lifted today', 'kg ယနေ့ မ ခဲ့သည်');
  String lastLoad(String kg, int sets, int reps) => _t(
        'Last $kg kg · $sets x $reps',
        'နောက်ဆုံး $kg kg · $sets x $reps',
      );
  String get clear => _t('Clear', 'ဖယ်ရှားရန်');
  String get allDone => _t('All done', 'အားလုံး ပြီးပြီ');
  String get setTarget => _t('Set target', 'ပန်းတိုင် သတ်မှတ်ရန်');
  String get sets => _t('Sets', 'ဆက်');
  String get reps => _t('Reps', 'အကြိမ်');
  String get weightKgLabel => _t('Weight (kg)', 'အလေးချိန် (kg)');
  String get leaveEmptyBodyweight => _t(
        'Leave empty for bodyweight',
        'ကိုယ်အလေးချိန်ဖြင့်သာ လုပ်ပါက ဗလာထားပါ',
      );
  String get viewHistory => _t('View history', 'မှတ်တမ်း ကြည့်ရန်');
  String get howToDoIt => _t('How to do it', 'လုပ်ဆောင်ပုံ');
  String get holdSetup => _t('Hold / setup', 'ကိုင်ပုံ / ပြင်ဆင်ပုံ');
  String get avoid => _t('Avoid', 'ရှောင်ရန်');
  String get tempo => _t('Tempo', 'အမြန်နှုန်း');
  String benchAngle(String angle) => _t('Bench angle: $angle', 'ခုံ ထောင့်: $angle');
  String get safetyNote => _t(
        'Use a weight you can control for your chosen sets and reps. Stop if '
            'pain, dizziness, numbness, or joint pinching happens. For heavy '
            'bench, squat, or overhead work, use safety pins or a spotter.',
        'ရွေးထားသော ဆက်နှင့် အကြိမ်အတွက် ထိန်းနိုင်သော အလေးချိန်ကိုသာ သုံးပါ။ '
            'နာကျင်ခြင်း၊ မူးဝေခြင်း၊ ထုံကျဉ်ခြင်း သို့မဟုတ် အဆစ်ညှပ်သလို '
            'ခံစားရပါက ချက်ချင်း ရပ်ပါ။ အလေးများသော bench၊ squat သို့မဟုတ် '
            'overhead လေ့ကျင့်ခန်းများတွင် safety pin သို့မဟုတ် အကူအညီပေးသူ ထားပါ။',
      );
}

/// Makes the active [AppStrings] available below `MaterialApp`.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      strings.language != oldWidget.strings.language;
}

/// Shorthand so widgets read `context.strings.settings`.
extension AppStringsContext on BuildContext {
  AppStrings get strings =>
      dependOnInheritedWidgetOfExactType<AppStringsScope>()?.strings ??
      const AppStrings(AppLanguage.english);
}
