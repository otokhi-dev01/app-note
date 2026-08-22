/// English strings — covers Splash, Onboarding, Login, Register, the
/// Language picker, and Settings (including the profile rename flow). Every
/// other screen is still hardcoded English, so this is also the fallback
/// locale (see `AppTranslations`).
const Map<String, String> enUS = {
  // Splash
  'app_tagline': 'High Fidelity Note Taking',

  // Onboarding
  'onboarding_skip': 'Skip',
  'onboarding_next': 'Next',
  'onboarding_get_started': 'Get Started',
  'onboarding_continue_guest': 'Continue without account',
  'onboarding_page1_title': 'Capture Ideas',
  'onboarding_page1_desc':
      'Quickly write down your thoughts whenever they strike.',
  'onboarding_page2_title': 'Organize Folders',
  'onboarding_page2_desc':
      'Keep your notes tidy with custom categories and colors.',
  'onboarding_page3_title': 'Sync Anywhere',
  'onboarding_page3_desc':
      'Your notes are always with you, across all your devices.',

  // Shared auth fields
  'phone_number_hint': 'Phone Number',
  'password_hint': 'Password',
  'confirm_password_hint': 'Confirm Password',
  'full_name_hint': 'Full Name',

  // Login
  'login_title': 'Login',
  'login_welcome_back': 'Welcome Back',
  'login_subtitle': 'Login to your account',
  'remember_me': 'Remember Me',
  'forgot_password': 'Forgot Password?',
  'login_button': 'LOGIN',
  'login_no_account': "Don't have an account?",
  'register_link': 'Register',
  'welcome_title': 'Welcome',
  'login_success_message': 'Login successful!',
  'login_failed_title': 'Login Failed',

  // Register
  'register_title': 'Register',
  'register_create_account': 'Create Account',
  'register_subtitle': 'Sign up to get started',
  'register_button': 'REGISTER',
  'register_have_account': 'Already have an account?',
  'login_link': 'Login',
  'success_title': 'Success',
  'register_success_message': 'Account created successfully! Please log in.',
  'register_failed_title': 'Registration Failed',

  // Forgot password sheet
  'reset_password_title': 'Reset Password',
  'reset_password_desc':
      'Enter your phone number to receive a password reset link.',
  'send_reset_link': 'SEND RESET LINK',
  'invalid_phone_title': 'Invalid phone',
  'reset_request_sent_title': 'Request Sent',
  'reset_request_sent_message':
      'If an account exists for @phone, you will receive a reset link shortly.',

  // Validators
  'validator_phone_required': 'Please enter your phone number.',
  'validator_phone_invalid': 'Please enter a valid phone number (8-15 digits).',
  'validator_password_required': 'Please enter a password.',
  'validator_password_too_short':
      'Password must be at least 6 characters long.',

  // Language picker
  'language_title': 'Language',

  // Settings
  'settings_title': 'Settings',
  'section_preferences': 'PREFERENCES',
  'section_preferences_footer': 'Choose how the app looks and how notes behave.',
  'section_support': 'SUPPORT',
  'section_support_footer': 'Get help or reach out if something isn\'t working.',
  'dark_mode': 'Dark Mode',
  'appearance_title': 'Appearance',
  'note_preferences_title': 'Note Preferences',
  'help_center_title': 'Help Center',
  'log_out': 'Log Out',
  'log_in_create_account': 'Log In or Create Account',
  'delete_account_title': 'Delete Account',
  'version_label': 'Version',

  // Profile rename
  'edit_name_title': 'Edit Name',
  'edit_name_hint': 'Enter your name',
  'saved_title': 'Saved',
  'name_updated_message': 'Name updated',
  'name_update_failed_title': 'Could not update name',
  'profile_image_updated_message': 'Profile image updated',
  'profile_image_update_failed_title': 'Could not update profile image',
  'guest_label': 'Guest',
  'default_user_name': 'User Name',
  'not_signed_in': 'Not signed in',

  // Profile View
  'profile_title': 'Profile',
  'full_name_label': 'Full Name',
  'phone_label': 'Phone Number',
  'account_status_label': 'Account Status',
  'guest_status': 'Guest Mode',
  'verified_status': 'Verified Account',
  'joined_label': 'Joined',
  'tier_label': 'Account Tier',
  'not_available': 'Not available',
};
