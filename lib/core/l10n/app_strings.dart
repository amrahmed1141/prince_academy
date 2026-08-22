import 'package:flutter/widgets.dart';

/// Lightweight EN/AR strings for admin chrome + profile.
/// Expand maps as more screens are localized.
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return AppStrings(locale);
  }

  String t(String key) {
    final table = isArabic ? _ar : _en;
    return table[key] ?? _en[key] ?? key;
  }

  // —— Common ——
  String get cancel => t('cancel');
  String get save => t('save');
  String get retry => t('retry');
  String get logout => t('logout');
  String get notSet => t('notSet');
  String get language => t('language');
  String get languageEnglish => t('languageEnglish');
  String get languageArabic => t('languageArabic');
  String get currentLanguageLabel =>
      isArabic ? languageArabic : languageEnglish;

  // —— Admin chrome ——
  String get admin => t('admin');
  String get managementPortal => t('managementPortal');
  String get home => t('home');
  String get create => t('create');
  String get tracking => t('tracking');
  String get finance => t('finance');
  String get goodMorning => t('goodMorning');
  String get goodAfternoon => t('goodAfternoon');
  String get goodEvening => t('goodEvening');

  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }

  String greetingWithName(String name) => '${greeting()}, $name';

  // —— Dashboard ——
  String get quickActions => t('quickActions');
  String get scan => t('scan');
  String get addCoach => t('addCoach');
  String get addSession => t('addSession');
  String get pending => t('pending');
  String get todayRevenue => t('todayRevenue');
  String get activeMembers => t('activeMembers');
  String get todaysSessions => t('todaysSessions');
  String get coaches => t('coaches');
  String get members => t('members');
  String get freeze => t('freeze');
  String get pendingPayments => t('pendingPayments');
  String get needsAttention => t('needsAttention');
  String get viewAll => t('viewAll');
  String get seeAll => t('seeAll');
  String get allSchedules => t('allSchedules');
  String get allClear => t('allClear');
  String get currentSession => t('currentSession');
  String get upcomingSession => t('upcomingSession');
  String get noSessionsToday => t('noSessionsToday');
  String get allSessionsFinished => t('allSessionsFinished');

  // —— Profile ——
  String get adminProfile => t('adminProfile');
  String get princeMmaAcademy => t('princeMmaAcademy');
  String get emailAddress => t('emailAddress');
  String get editProfile => t('editProfile');
  String get updateDisplayName => t('updateDisplayName');
  String get notifications => t('notifications');
  String get adminAlertsUpdates => t('adminAlertsUpdates');
  String get exitAdministration => t('exitAdministration');
  String get confirmLogout => t('confirmLogout');
  String get signOutConfirm => t('signOutConfirm');
  String get fullName => t('fullName');
  String get pleaseEnterName => t('pleaseEnterName');
  String get nameUpdated => t('nameUpdated');
  String get couldNotUpdateName => t('couldNotUpdateName');
  String get chooseLanguage => t('chooseLanguage');

  // —— Search ——
  String get search => t('search');
  String get searchHintPrefix => t('searchHintPrefix');
  String get searchAdmin => t('searchAdmin');
  String get pages => t('pages');
  String get classes => t('classes');
  String get noMatches => t('noMatches');
  String get dashboard => t('dashboard');
  String get allMembers => t('allMembers');
  String get allCoaches => t('allCoaches');
  String get todaysAttendance => t('todaysAttendance');
  String get freezeRequests => t('freezeRequests');
  String get scanQr => t('scanQr');
  String get allTransactions => t('allTransactions');

  List<String> get searchHintPages => [
        t('hintMembers'),
        t('hintCoaches'),
        t('hintClasses'),
        t('hintPendingPayments'),
        t('hintAttendance'),
        t('hintFreezeRequests'),
      ];

  List<String> get searchHintTracking => [
        t('hintMemberName'),
        t('hintPhone'),
        t('hintCoachName'),
        t('hintBranch'),
        t('hintPendingPayments'),
      ];

  List<String> get searchHintAttendance => [
        t('hintMemberName'),
        t('hintCoachName'),
        t('hintSessionType'),
        t('hintBranch'),
        t('hintAttendanceStatus'),
      ];

  List<String> get searchHintSessions => [
        t('hintCoachName'),
        t('hintClassType'),
        t('hintBranch'),
        t('hintDay'),
        t('hintTimeSlot'),
      ];

  List<String> get searchHintCoaches => [
        t('hintCoachName'),
        t('hintSpecialty'),
        t('hintActiveMembers'),
        t('hintTodaySessions'),
      ];

  List<String> get searchHintMembers => [
        t('hintMemberName'),
        t('hintPhone'),
        t('hintActiveBookings'),
        t('hintPendingPayment'),
      ];

  List<String> get searchHintTransactions => [
        t('hintMemberName'),
        t('hintCoachName'),
        t('hintBookingTime'),
        t('hintConfirmed'),
        t('hintPending'),
      ];
}

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

const _en = <String, String>{
  'cancel': 'Cancel',
  'save': 'Save',
  'retry': 'Retry',
  'logout': 'Logout',
  'notSet': 'Not set',
  'language': 'Language',
  'languageEnglish': 'English',
  'languageArabic': 'Arabic',
  'chooseLanguage': 'Choose language',
  'admin': 'Admin',
  'managementPortal': 'Management Portal',
  'home': 'Home',
  'create': 'Create',
  'tracking': 'Tracking',
  'finance': 'Finance',
  'goodMorning': 'Good morning',
  'goodAfternoon': 'Good afternoon',
  'goodEvening': 'Good evening',
  'quickActions': 'Quick actions',
  'scan': 'Scan',
  'addCoach': 'Add Coach',
  'addSession': 'Add Session',
  'pending': 'Pending',
  'todayRevenue': 'Today revenue',
  'activeMembers': 'Active members',
  'todaysSessions': "Today's sessions",
  'coaches': 'Coaches',
  'members': 'Members',
  'freeze': 'Freeze',
  'pendingPayments': 'Pending payments',
  'needsAttention': 'Needs attention',
  'viewAll': 'View all',
  'seeAll': 'See all',
  'allSchedules': 'All Schedules',
  'allClear': 'All clear',
  'currentSession': 'Current session',
  'upcomingSession': 'Upcoming session',
  'noSessionsToday': 'No sessions today',
  'allSessionsFinished': 'All sessions finished',
  'adminProfile': 'Admin Profile',
  'princeMmaAcademy': 'Prince MMA Academy',
  'emailAddress': 'Email Address',
  'editProfile': 'Edit Profile',
  'updateDisplayName': 'Update your display name',
  'notifications': 'Notifications',
  'adminAlertsUpdates': 'Admin alerts & updates',
  'exitAdministration': 'Exit administration',
  'confirmLogout': 'Confirm Logout',
  'signOutConfirm': 'Are you sure you want to sign out?',
  'fullName': 'Full name',
  'pleaseEnterName': 'Please enter your name',
  'nameUpdated': 'Name updated',
  'couldNotUpdateName': 'Could not update name',
  'search': 'Search...',
  'searchHintPrefix': 'Search ',
  'searchAdmin': 'Search admin',
  'pages': 'Pages',
  'classes': 'Classes',
  'noMatches': 'No matches',
  'dashboard': 'Dashboard',
  'allMembers': 'All Members',
  'allCoaches': 'All Coaches',
  'todaysAttendance': "Today's Attendance",
  'freezeRequests': 'Freeze Requests',
  'scanQr': 'Scan QR',
  'allTransactions': 'All Transactions',
  'hintMembers': 'members',
  'hintCoaches': 'coaches',
  'hintClasses': 'classes',
  'hintPendingPayments': 'pending payments',
  'hintAttendance': 'attendance',
  'hintFreezeRequests': 'freeze requests',
  'hintMemberName': 'member name',
  'hintPhone': 'phone number',
  'hintCoachName': 'coach name',
  'hintBranch': 'branch',
  'hintSessionType': 'session type',
  'hintAttendanceStatus': 'attendance status',
  'hintClassType': 'class type',
  'hintDay': 'day',
  'hintTimeSlot': 'time slot',
  'hintSpecialty': 'specialty',
  'hintActiveMembers': 'active members',
  'hintTodaySessions': 'today sessions',
  'hintActiveBookings': 'active bookings',
  'hintPendingPayment': 'pending payment',
  'hintBookingTime': 'booking time',
  'hintConfirmed': 'confirmed',
  'hintPending': 'pending',
  'destDashboardSub': 'KPIs, today, and quick actions',
  'destCreateSub': 'Add coaches and sessions',
  'destAddCoachSub': 'Create a coach profile',
  'destAddSessionSub': 'Schedule a class',
  'destTrackingSub': 'Members and coaches overview',
  'destAllMembersSub': 'Search and open member profiles',
  'destAllCoachesSub': 'Coach directory and stats',
  'destFinanceSub': 'Revenue, coaches, and payouts',
  'destPendingPaymentsSub': 'Verify or reject screenshots',
  'destTodaySessionsSub': 'Classes running today',
  'destTodayAttendanceSub': 'Who checked in today',
  'destAllSchedulesSub': 'Full session timetable',
  'destFreezeRequestsSub': 'Approve or review freezes',
  'destScanQrSub': 'Check in a member',
  'destNotificationsSub': 'Admin alerts and updates',
  'destProfileSub': 'Name, notifications and sign out',
  'destTransactionsSub': 'Full payment history',
};

const _ar = <String, String>{
  'cancel': 'إلغاء',
  'save': 'حفظ',
  'retry': 'إعادة المحاولة',
  'logout': 'تسجيل الخروج',
  'notSet': 'غير محدد',
  'language': 'اللغة',
  'languageEnglish': 'الإنجليزية',
  'languageArabic': 'العربية',
  'chooseLanguage': 'اختر اللغة',
  'admin': 'المسؤول',
  'managementPortal': 'بوابة الإدارة',
  'home': 'الرئيسية',
  'create': 'إنشاء',
  'tracking': 'المتابعة',
  'finance': 'المالية',
  'goodMorning': 'صباح الخير',
  'goodAfternoon': 'طاب يومك',
  'goodEvening': 'مساء الخير',
  'quickActions': 'إجراءات سريعة',
  'scan': 'مسح',
  'addCoach': 'إضافة مدرب',
  'addSession': 'إضافة حصة',
  'pending': 'معلق',
  'todayRevenue': 'إيراد اليوم',
  'activeMembers': 'أعضاء نشطون',
  'todaysSessions': 'حصص اليوم',
  'coaches': 'المدربون',
  'members': 'الأعضاء',
  'freeze': 'تجميد',
  'pendingPayments': 'مدفوعات معلقة',
  'needsAttention': 'يحتاج انتباهاً',
  'viewAll': 'عرض الكل',
  'seeAll': 'عرض الكل',
  'allSchedules': 'كل الجداول',
  'allClear': 'لا يوجد شيء',
  'currentSession': 'الحصة الحالية',
  'upcomingSession': 'الحصة القادمة',
  'noSessionsToday': 'لا حصص اليوم',
  'allSessionsFinished': 'انتهت كل الحصص',
  'adminProfile': 'ملف المسؤول',
  'princeMmaAcademy': 'أكاديمية برنس للفنون القتالية',
  'emailAddress': 'البريد الإلكتروني',
  'editProfile': 'تعديل الملف',
  'updateDisplayName': 'تحديث الاسم الظاهر',
  'notifications': 'الإشعارات',
  'adminAlertsUpdates': 'تنبيهات وتحديثات المسؤول',
  'exitAdministration': 'الخروج من الإدارة',
  'confirmLogout': 'تأكيد تسجيل الخروج',
  'signOutConfirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
  'fullName': 'الاسم الكامل',
  'pleaseEnterName': 'يرجى إدخال اسمك',
  'nameUpdated': 'تم تحديث الاسم',
  'couldNotUpdateName': 'تعذر تحديث الاسم',
  'search': 'بحث...',
  'searchHintPrefix': 'بحث عن ',
  'searchAdmin': 'بحث الإدارة',
  'pages': 'الصفحات',
  'classes': 'الحصص',
  'noMatches': 'لا نتائج',
  'dashboard': 'لوحة التحكم',
  'allMembers': 'كل الأعضاء',
  'allCoaches': 'كل المدربين',
  'todaysAttendance': 'حضور اليوم',
  'freezeRequests': 'طلبات التجميد',
  'scanQr': 'مسح QR',
  'allTransactions': 'كل المعاملات',
  'hintMembers': 'الأعضاء',
  'hintCoaches': 'المدربين',
  'hintClasses': 'الحصص',
  'hintPendingPayments': 'المدفوعات المعلقة',
  'hintAttendance': 'الحضور',
  'hintFreezeRequests': 'طلبات التجميد',
  'hintMemberName': 'اسم العضو',
  'hintPhone': 'رقم الهاتف',
  'hintCoachName': 'اسم المدرب',
  'hintBranch': 'الفرع',
  'hintSessionType': 'نوع الحصة',
  'hintAttendanceStatus': 'حالة الحضور',
  'hintClassType': 'نوع الحصة',
  'hintDay': 'اليوم',
  'hintTimeSlot': 'الوقت',
  'hintSpecialty': 'التخصص',
  'hintActiveMembers': 'أعضاء نشطون',
  'hintTodaySessions': 'حصص اليوم',
  'hintActiveBookings': 'اشتراكات نشطة',
  'hintPendingPayment': 'دفع معلق',
  'hintBookingTime': 'وقت الحجز',
  'hintConfirmed': 'مؤكد',
  'hintPending': 'معلق',
  'destDashboardSub': 'المؤشرات واليوم والإجراءات السريعة',
  'destCreateSub': 'إضافة مدربين وحصص',
  'destAddCoachSub': 'إنشاء ملف مدرب',
  'destAddSessionSub': 'جدولة حصة',
  'destTrackingSub': 'نظرة عامة على الأعضاء والمدربين',
  'destAllMembersSub': 'البحث وفتح ملفات الأعضاء',
  'destAllCoachesSub': 'دليل المدربين والإحصائيات',
  'destFinanceSub': 'الإيرادات والمدربين والمدفوعات',
  'destPendingPaymentsSub': 'التحقق من الإيصالات أو رفضها',
  'destTodayAttendanceSub': 'من سجل حضوره اليوم',
  'destTodaySessionsSub': 'الحصص الجارية اليوم',
  'destAllSchedulesSub': 'جدول الحصص الكامل',
  'destFreezeRequestsSub': 'الموافقة على التجميد أو مراجعته',
  'destScanQrSub': 'تسجيل حضور عضو',
  'destNotificationsSub': 'تنبيهات وتحديثات المسؤول',
  'destProfileSub': 'الاسم والإشعارات وتسجيل الخروج',
  'destTransactionsSub': 'سجل المدفوعات الكامل',
};
