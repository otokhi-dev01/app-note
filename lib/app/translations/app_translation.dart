import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    return <String, Map<String, String>>{
      'en_US': <String, String>{
        // Navigation
        'folders': 'Folders',
        'notes': 'Notes',
        'settings': 'Settings',
        'profile': 'Profile',

        // Settings
        'app_settings': 'Application settings',
        'appearance': 'Appearance',
        'appearance_description':
        'Choose how Piisiit Note looks on your device.',
        'system_default': 'System default',
        'system_default_description':
        'Follow your device appearance setting.',
        'light_mode': 'Light mode',
        'light_mode_description':
        'Always use the light appearance.',
        'dark_mode': 'Dark mode',
        'dark_mode_description':
        'Always use the dark appearance.',

        'language': 'Language',
        'language_description':
        'Choose the application language and font.',
        'english': 'English',
        'english_description':
        'English with the system font.',
        'khmer': 'Khmer',
        'khmer_description':
        'ភាសាខ្មែរជាមួយពុម្ពអក្សរខ្មែរ',

        'theme_saved':
        'Your appearance preference is saved.',
        'language_saved':
        'Your language preference is saved.',

        // Authentication
        'piisiit_note': 'Piisiit Note',
        'welcome_back': 'Welcome back',
        'sign_in_description':
        'Sign in to access and manage your notes.',
        'phone_number': 'Phone number',
        'enter_phone_number':
        'Enter your phone number',
        'password': 'Password',
        'enter_password': 'Enter your password',
        'sign_in': 'Sign In',
        'create_account': 'Create Account',
        'full_name': 'Full name',
        'confirm_password': 'Confirm password',
        'already_have_account':
        'Already have an account?',
        'dont_have_account':
        'Don’t have an account?',

        // General
        'refresh': 'Refresh',
        'try_again': 'Try Again',
        'sign_out': 'Sign Out',
        'cancel': 'Cancel',
        'done': 'Done',
      },

      'km_KH': <String, String>{
        // Navigation
        'folders': 'ថត',
        'notes': 'កំណត់ត្រា',
        'settings': 'ការកំណត់',
        'profile': 'ប្រវត្តិរូប',

        // Settings
        'app_settings': 'ការកំណត់កម្មវិធី',
        'appearance': 'រូបរាង',
        'appearance_description':
        'ជ្រើសរើសរូបរាងរបស់កម្មវិធី Piisiit Note។',
        'system_default': 'តាមប្រព័ន្ធ',
        'system_default_description':
        'ប្រើរូបរាងតាមការកំណត់របស់ឧបករណ៍។',
        'light_mode': 'របៀបភ្លឺ',
        'light_mode_description':
        'ប្រើរូបរាងភ្លឺជានិច្ច។',
        'dark_mode': 'របៀបងងឹត',
        'dark_mode_description':
        'ប្រើរូបរាងងងឹតជានិច្ច។',

        'language': 'ភាសា',
        'language_description':
        'ជ្រើសរើសភាសា និងពុម្ពអក្សររបស់កម្មវិធី។',
        'english': 'អង់គ្លេស',
        'english_description':
        'ភាសាអង់គ្លេសជាមួយពុម្ពអក្សរប្រព័ន្ធ។',
        'khmer': 'ខ្មែរ',
        'khmer_description':
        'ភាសាខ្មែរជាមួយពុម្ពអក្សរខ្មែរ។',

        'theme_saved':
        'ការកំណត់រូបរាងត្រូវបានរក្សាទុក។',
        'language_saved':
        'ការកំណត់ភាសាត្រូវបានរក្សាទុក។',

        // Authentication
        'piisiit_note': 'Piisiit Note',
        'welcome_back': 'សូមស្វាគមន៍មកវិញ',
        'sign_in_description':
        'ចូលគណនីដើម្បីគ្រប់គ្រងកំណត់ត្រារបស់អ្នក។',
        'phone_number': 'លេខទូរស័ព្ទ',
        'enter_phone_number':
        'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
        'password': 'ពាក្យសម្ងាត់',
        'enter_password':
        'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក',
        'sign_in': 'ចូលគណនី',
        'create_account': 'បង្កើតគណនី',
        'full_name': 'ឈ្មោះពេញ',
        'confirm_password':
        'បញ្ជាក់ពាក្យសម្ងាត់',
        'already_have_account':
        'មានគណនីរួចហើយ?',
        'dont_have_account':
        'មិនទាន់មានគណនី?',

        // General
        'refresh': 'ផ្ទុកឡើងវិញ',
        'try_again': 'ព្យាយាមម្តងទៀត',
        'sign_out': 'ចាកចេញ',
        'cancel': 'បោះបង់',
        'done': 'រួចរាល់',
      },
    };
  }
}