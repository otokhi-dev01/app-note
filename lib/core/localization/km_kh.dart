/// Khmer strings — mirrors the key set in `en_us.dart` (Splash, Onboarding,
/// Login, Register, Language picker, Settings, profile rename). Any screen
/// not covered here falls back to English via `AppTranslations.fallbackLocale`.
const Map<String, String> kmKH = {
  // Splash
  'app_tagline': 'ការកត់ត្រាគុណភាពខ្ពស់',

  // Onboarding
  'onboarding_skip': 'រំលង',
  'onboarding_next': 'បន្ទាប់',
  'onboarding_get_started': 'ចាប់ផ្តើម',
  'onboarding_continue_guest': 'បន្តដោយមិនប្រើគណនី',
  'onboarding_page1_title': 'កត់ត្រាគំនិត',
  'onboarding_page1_desc': 'កត់ត្រាគំនិតរបស់អ្នកយ៉ាងរហ័ស នៅពេលណាដែលវាកើតឡើង។',
  'onboarding_page2_title': 'រៀបចំថតឯកសារ',
  'onboarding_page2_desc':
      'រក្សាកំណត់ត្រារបស់អ្នកឱ្យមានសណ្តាប់ធ្នាប់ ជាមួយប្រភេទ និងពណ៌ផ្ទាល់ខ្លួន។',
  'onboarding_page3_title': 'ធ្វើសមកាលកម្មគ្រប់ទីកន្លែង',
  'onboarding_page3_desc':
      'កំណត់ត្រារបស់អ្នកនៅជាមួយអ្នកជានិច្ច នៅលើគ្រប់ឧបករណ៍។',

  // Shared auth fields
  'phone_number_hint': 'លេខទូរស័ព្ទ',
  'password_hint': 'ពាក្យសម្ងាត់',
  'confirm_password_hint': 'បញ្ជាក់ពាក្យសម្ងាត់',
  'full_name_hint': 'ឈ្មោះពេញ',

  // Login
  'login_title': 'ចូល',
  'login_welcome_back': 'សូមស្វាគមន៍មកវិញ',
  'login_subtitle': 'ចូលទៅកាន់គណនីរបស់អ្នក',
  'remember_me': 'ចងចាំខ្ញុំ',
  'forgot_password': 'ភ្លេចពាក្យសម្ងាត់?',
  'login_button': 'ចូល',
  'login_no_account': 'មិនទាន់មានគណនីមែនទេ?',
  'register_link': 'ចុះឈ្មោះ',
  'welcome_title': 'សូមស្វាគមន៍',
  'login_success_message': 'ចូលដោយជោគជ័យ!',
  'login_failed_title': 'ការចូលបានបរាជ័យ',

  // Register
  'register_title': 'ចុះឈ្មោះ',
  'register_create_account': 'បង្កើតគណនី',
  'register_subtitle': 'ចុះឈ្មោះដើម្បីចាប់ផ្តើម',
  'register_button': 'ចុះឈ្មោះ',
  'register_have_account': 'មានគណនីរួចហើយមែនទេ?',
  'login_link': 'ចូល',
  'success_title': 'ជោគជ័យ',
  'register_success_message': 'បង្កើតគណនីដោយជោគជ័យ! សូមចូល។',
  'register_failed_title': 'ការចុះឈ្មោះបានបរាជ័យ',

  // Forgot password sheet
  'reset_password_title': 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ',
  'reset_password_desc':
      'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក ដើម្បីទទួលបានតំណកំណត់ពាក្យសម្ងាត់ឡើងវិញ។',
  'send_reset_link': 'ផ្ញើតំណកំណត់ឡើងវិញ',
  'invalid_phone_title': 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ',
  'reset_request_sent_title': 'បានផ្ញើសំណើ',
  'reset_request_sent_message':
      'ប្រសិនបើមានគណនីសម្រាប់ @phone អ្នកនឹងទទួលបានតំណកំណត់ឡើងវិញឆាប់ៗនេះ។',

  // Validators
  'validator_phone_required': 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក។',
  'validator_phone_invalid': 'សូមបញ្ចូលលេខទូរស័ព្ទត្រឹមត្រូវ (8-15 ខ្ទង់)។',
  'validator_password_required': 'សូមបញ្ចូលពាក្យសម្ងាត់។',
  'validator_password_too_short': 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច 6 តួអក្សរ។',

  // Language picker
  'language_title': 'ភាសា',

  // Settings
  'settings_title': 'ការកំណត់',
  'section_preferences': 'ចំណូលចិត្ត',
  'section_support': 'ជំនួយ',
  'dark_mode': 'របៀបងងឹត',
  'appearance_title': 'រូបរាង',
  'note_preferences_title': 'ចំណូលចិត្តកំណត់ត្រា',
  'help_center_title': 'មជ្ឈមណ្ឌលជំនួយ',
  'log_out': 'ចាកចេញ',
  'log_in_create_account': 'ចូល ឬបង្កើតគណនី',

  // Profile rename
  'edit_name_title': 'កែឈ្មោះ',
  'edit_name_hint': 'បញ្ចូលឈ្មោះរបស់អ្នក',
  'saved_title': 'បានរក្សាទុក',
  'name_updated_message': 'ឈ្មោះត្រូវបានធ្វើបច្ចុប្បន្នភាព',
  'name_update_failed_title': 'មិនអាចធ្វើបច្ចុប្បន្នភាពឈ្មោះបានទេ',
  'profile_image_updated_message':
      'រូបភាពប្រវត្តិរូបត្រូវបានធ្វើបច្ចុប្បន្នភាព',
  'profile_image_update_failed_title':
      'មិនអាចធ្វើបច្ចុប្បន្នភាពរូបភាពប្រវត្តិរូបបានទេ',
  'guest_label': 'ភ្ញៀវ',
  'default_user_name': 'ឈ្មោះអ្នកប្រើប្រាស់',
  'not_signed_in': 'មិនទាន់ចូលគណនី',
};
