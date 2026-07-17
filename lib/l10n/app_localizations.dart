import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Samaki Fresh Connect'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch the entire app to your preferred language.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kiswahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get kiswahili;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @searchFish.
  ///
  /// In en, this message translates to:
  /// **'Search Fish'**
  String get searchFish;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. tuna, mackerel, fillet…'**
  String get searchHint;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get startTypingToSearch;

  /// No description provided for @noSellersHave.
  ///
  /// In en, this message translates to:
  /// **'No sellers have \"{query}\" right now'**
  String noSellersHave(String query);

  /// No description provided for @noSellersHaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No seller carries this fish at the moment. Try a different name.'**
  String get noSellersHaveSubtitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String loadingError(String error);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @fishType.
  ///
  /// In en, this message translates to:
  /// **'Fish Type'**
  String get fishType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get price;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @quantityMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get quantityMustBePositive;

  /// No description provided for @priceMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get priceMustBePositive;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter Tanzanian format: +255XXXXXXXXX'**
  String get phoneInvalid;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get postListing;

  /// No description provided for @sellStock.
  ///
  /// In en, this message translates to:
  /// **'Sell Stock'**
  String get sellStock;

  /// No description provided for @buyStock.
  ///
  /// In en, this message translates to:
  /// **'Buy Stock'**
  String get buyStock;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track purchases'**
  String get myOrdersSubtitle;

  /// No description provided for @sellStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a listing'**
  String get sellStockSubtitle;

  /// No description provided for @myListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your stock'**
  String get myListingsSubtitle;

  /// No description provided for @buyStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse marketplace'**
  String get buyStockSubtitle;

  /// No description provided for @fishAvailableNearby.
  ///
  /// In en, this message translates to:
  /// **'Fish Available Nearby'**
  String get fishAvailableNearby;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @totalStock.
  ///
  /// In en, this message translates to:
  /// **'Total Stock'**
  String get totalStock;

  /// No description provided for @nearestSeller.
  ///
  /// In en, this message translates to:
  /// **'Nearest Seller'**
  String get nearestSeller;

  /// No description provided for @activeRequests.
  ///
  /// In en, this message translates to:
  /// **'Active Requests'**
  String get activeRequests;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get starting;

  /// No description provided for @youAreNowOnline.
  ///
  /// In en, this message translates to:
  /// **'You are now online · sharing location'**
  String get youAreNowOnline;

  /// No description provided for @youAreNowOffline.
  ///
  /// In en, this message translates to:
  /// **'You are now offline'**
  String get youAreNowOffline;

  /// No description provided for @photosUpTo5.
  ///
  /// In en, this message translates to:
  /// **'Photos (up to 5)'**
  String get photosUpTo5;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @shopLocation.
  ///
  /// In en, this message translates to:
  /// **'Shop Location'**
  String get shopLocation;

  /// No description provided for @setShopLocation.
  ///
  /// In en, this message translates to:
  /// **'Set shop location'**
  String get setShopLocation;

  /// No description provided for @shopLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Shop location set'**
  String get shopLocationSet;

  /// No description provided for @shopLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required so buyers can find your shop on the map'**
  String get shopLocationRequired;

  /// No description provided for @readingGps.
  ///
  /// In en, this message translates to:
  /// **'Reading GPS signal...'**
  String get readingGps;

  /// No description provided for @shopLocationSetTo.
  ///
  /// In en, this message translates to:
  /// **'Shop location set to {label}'**
  String shopLocationSetTo(String label);

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read photos: {error}'**
  String imageUploadFailed(String error);

  /// No description provided for @cameraImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read photo from camera: {error}'**
  String cameraImageFailed(String error);

  /// No description provided for @listingCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing created successfully! 🐟'**
  String get listingCreatedSuccessfully;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @habari.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}! 🛒'**
  String habari(String name);

  /// No description provided for @yourStreetSellingHub.
  ///
  /// In en, this message translates to:
  /// **'Your street selling hub'**
  String get yourStreetSellingHub;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noImage;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {duration}'**
  String expiresIn(String duration);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get sold;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expired;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @noImageBroken.
  ///
  /// In en, this message translates to:
  /// **'Image could not be loaded'**
  String get noImageBroken;

  /// No description provided for @sendFishRequest.
  ///
  /// In en, this message translates to:
  /// **'Send fish request'**
  String get sendFishRequest;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @callSeller.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callSeller;

  /// No description provided for @smsSeller.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smsSeller;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @sellersNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sellers} =1{1 seller} other{{count} sellers}} nearby'**
  String sellersNearby(int count);

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @onlineLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Online · live location'**
  String get onlineLiveLocation;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo Accounts'**
  String get demoAccounts;

  /// No description provided for @tryOutApp.
  ///
  /// In en, this message translates to:
  /// **'Try out the app instantly with a demo account.'**
  String get tryOutApp;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @useGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS'**
  String get useGps;

  /// No description provided for @useSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Use saved location'**
  String get useSavedLocation;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceAway(String distance);

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Account verification required'**
  String get verificationRequired;

  /// No description provided for @verificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and verify your account before continuing.'**
  String get verificationMessage;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when something happens.'**
  String get noNotificationsSubtitle;

  /// No description provided for @noWishlistItems.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get noWishlistItems;

  /// No description provided for @noWishlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any fish listing to save it here.'**
  String get noWishlistSubtitle;

  /// No description provided for @noActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'No active fish requests'**
  String get noActiveRequests;

  /// No description provided for @noActiveRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you post a fish request, it will appear here.'**
  String get noActiveRequestsSubtitle;

  /// No description provided for @noListings.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListings;

  /// No description provided for @noListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first listing.'**
  String get noListingsSubtitle;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @noOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you buy or sell fish, orders will appear here.'**
  String get noOrdersSubtitle;

  /// No description provided for @offlineState.
  ///
  /// In en, this message translates to:
  /// **'This seller is currently offline'**
  String get offlineState;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(String km);

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @selectLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'The whole app will switch instantly. Your choice is saved on this device.'**
  String get selectLanguageDescription;

  /// No description provided for @languageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageSaved;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @changeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change {setting}: {error}'**
  String changeFailed(String setting, String error);

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get editListing;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get logoutConfirmationMessage;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get leaveReview;

  /// No description provided for @shareListing.
  ///
  /// In en, this message translates to:
  /// **'Share listing'**
  String get shareListing;

  /// No description provided for @reportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListing;

  /// No description provided for @deleteListingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this listing? This cannot be undone.'**
  String get deleteListingConfirmation;

  /// No description provided for @markAsSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get markAsSold;

  /// No description provided for @soldConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Mark this listing as sold?'**
  String get soldConfirmation;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to high'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to low'**
  String get priceHighToLow;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @savedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved locations'**
  String get savedLocations;

  /// No description provided for @loadingLocation.
  ///
  /// In en, this message translates to:
  /// **'Loading your location...'**
  String get loadingLocation;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get couldNotGetLocation;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get permissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get viewMore;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by fish type'**
  String get filterByType;

  /// No description provided for @distanceFromYou.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from you'**
  String distanceFromYou(Object distance);

  /// No description provided for @selectRadius.
  ///
  /// In en, this message translates to:
  /// **'Select search radius'**
  String get selectRadius;

  /// No description provided for @showingNearest.
  ///
  /// In en, this message translates to:
  /// **'Showing nearest sellers only'**
  String get showingNearest;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language preference'**
  String get languagePreference;

  /// No description provided for @themePreference.
  ///
  /// In en, this message translates to:
  /// **'Theme preference'**
  String get themePreference;

  /// No description provided for @changed.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changed;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get featureComingSoon;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your account'**
  String get verifyAccount;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @tapToUse.
  ///
  /// In en, this message translates to:
  /// **'Tap to use'**
  String get tapToUse;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// No description provided for @fromCamera.
  ///
  /// In en, this message translates to:
  /// **'From camera'**
  String get fromCamera;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @reviewInformation.
  ///
  /// In en, this message translates to:
  /// **'Review your information'**
  String get reviewInformation;

  /// No description provided for @totalListings.
  ///
  /// In en, this message translates to:
  /// **'Total listings'**
  String get totalListings;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get totalOrders;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account info'**
  String get accountInfo;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @buyersAvailable.
  ///
  /// In en, this message translates to:
  /// **'Buyers available'**
  String get buyersAvailable;

  /// No description provided for @sellersNearbyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sellers nearby} =1{1 seller nearby} other{{count} sellers nearby}}'**
  String sellersNearbyCount(int count);

  /// No description provided for @receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get receiving;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get inTransit;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @quantityKg.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityKg;

  /// No description provided for @perKg.
  ///
  /// In en, this message translates to:
  /// **'/ kg'**
  String get perKg;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @seeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'See all reviews'**
  String get seeAllReviews;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery time'**
  String get deliveryTime;

  /// No description provided for @yourOrders.
  ///
  /// In en, this message translates to:
  /// **'Your orders'**
  String get yourOrders;

  /// No description provided for @buyerType.
  ///
  /// In en, this message translates to:
  /// **'Buyer type'**
  String get buyerType;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @individualHousehold.
  ///
  /// In en, this message translates to:
  /// **'Individual/Household'**
  String get individualHousehold;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @hotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get hotel;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get fullAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @equipmentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Equipment photo'**
  String get equipmentPhoto;

  /// No description provided for @selectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5 photos'**
  String get selectPhotos;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get enterAddress;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @enterRegion.
  ///
  /// In en, this message translates to:
  /// **'Enter region'**
  String get enterRegion;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add listing'**
  String get addListing;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get deleteListing;

  /// No description provided for @markSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get markSold;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get goOffline;

  /// No description provided for @startingLocation.
  ///
  /// In en, this message translates to:
  /// **'Starting location...'**
  String get startingLocation;

  /// No description provided for @shareLocationToggle.
  ///
  /// In en, this message translates to:
  /// **'Share your location'**
  String get shareLocationToggle;

  /// No description provided for @shareLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let buyers see you on the map'**
  String get shareLocationSubtitle;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online status'**
  String get onlineStatus;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'You are online'**
  String get onlineNow;

  /// No description provided for @offlineNow.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineNow;

  /// No description provided for @sellerProfile.
  ///
  /// In en, this message translates to:
  /// **'Seller profile'**
  String get sellerProfile;

  /// No description provided for @activeListingsCount.
  ///
  /// In en, this message translates to:
  /// **'Active: {count}'**
  String activeListingsCount(Object count);

  /// No description provided for @ratingValue.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String ratingValue(Object rating);

  /// No description provided for @lastSeenMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes}m ago'**
  String lastSeenMinutesAgo(Object minutes);

  /// No description provided for @lastSeenHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Last seen {hours}h ago'**
  String lastSeenHoursAgo(Object hours);

  /// No description provided for @lastSeenDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last seen {days}d ago'**
  String lastSeenDaysAgo(Object days);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message seller'**
  String get messageSeller;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessage;

  /// No description provided for @onlineDot.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineDot;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @buyerName.
  ///
  /// In en, this message translates to:
  /// **'Buyer name'**
  String get buyerName;

  /// No description provided for @sellerName.
  ///
  /// In en, this message translates to:
  /// **'Seller name'**
  String get sellerName;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypes;

  /// No description provided for @noOrdersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYetTitle;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get loadingOrders;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderId(String id);

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markAsCompleted;

  /// No description provided for @cancelOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderConfirmation;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept order'**
  String get acceptOrder;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get confirmOrder;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject order'**
  String get rejectOrder;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order items'**
  String get orderItems;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @quantityShortKg.
  ///
  /// In en, this message translates to:
  /// **'{qty} kg'**
  String quantityShortKg(String qty);

  /// No description provided for @totalKg.
  ///
  /// In en, this message translates to:
  /// **'{qty} kg total'**
  String totalKg(String qty);

  /// No description provided for @buyerOrderedItems.
  ///
  /// In en, this message translates to:
  /// **'{buyer} ordered {qty} kg'**
  String buyerOrderedItems(String buyer, String qty);

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'TZS {price}/kg'**
  String pricePerKg(String price);

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'TZS {min} – {max} / kg'**
  String priceRange(String min, String max);

  /// No description provided for @setMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Set my location'**
  String get setMyLocation;

  /// No description provided for @switchToLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to light theme'**
  String get switchToLightTheme;

  /// No description provided for @switchToDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get switchToDarkTheme;

  /// No description provided for @platformOverview.
  ///
  /// In en, this message translates to:
  /// **'Platform Overview & Management'**
  String get platformOverview;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @ordersToday.
  ///
  /// In en, this message translates to:
  /// **'Orders Today'**
  String get ordersToday;

  /// No description provided for @platformRevenue.
  ///
  /// In en, this message translates to:
  /// **'Platform Revenue'**
  String get platformRevenue;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @manageDalalis.
  ///
  /// In en, this message translates to:
  /// **'Manage Dalalis'**
  String get manageDalalis;

  /// No description provided for @manageDalalisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register, approve or block brokers'**
  String get manageDalalisSubtitle;

  /// No description provided for @allListings.
  ///
  /// In en, this message translates to:
  /// **'All Listings'**
  String get allListings;

  /// No description provided for @allListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and moderate marketplace'**
  String get allListingsSubtitle;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View payment history'**
  String get transactionsSubtitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String hello(String name);

  /// No description provided for @manageStreetSellers.
  ///
  /// In en, this message translates to:
  /// **'Manage Street Sellers'**
  String get manageStreetSellers;

  /// No description provided for @manageStreetSellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approve, review or block sellers on the platform'**
  String get manageStreetSellersSubtitle;

  /// No description provided for @noStreetSellers.
  ///
  /// In en, this message translates to:
  /// **'No street sellers registered yet'**
  String get noStreetSellers;

  /// No description provided for @noStreetSellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When sellers register, they\'ll appear here for review.'**
  String get noStreetSellersSubtitle;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get userUnblocked;

  /// No description provided for @confirmBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block this seller? They will not be able to sign in until you unblock them.'**
  String get confirmBlockUser;

  /// No description provided for @adminAllListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review every listing across the marketplace'**
  String get adminAllListingsSubtitle;

  /// No description provided for @noListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get noListingsFound;

  /// No description provided for @noListingsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When buyers or sellers create listings, they\'ll appear here.'**
  String get noListingsFoundSubtitle;

  /// No description provided for @deleteListingConfirmationAdmin.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this listing? This cannot be undone.'**
  String get deleteListingConfirmationAdmin;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @listingsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No listings deleted} =1{1 listing deleted} other{{count} listings deleted}}'**
  String listingsDeleted(int count);

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectMode;

  /// No description provided for @exitSelectMode.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get exitSelectMode;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @deleteListingsConfirmationAdmin.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {count} listings? This cannot be undone.'**
  String deleteListingsConfirmationAdmin(int count);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None selected} =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @appearanceLiveHint.
  ///
  /// In en, this message translates to:
  /// **'Your selection is applied instantly across every screen and saved for next time.'**
  String get appearanceLiveHint;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform overview and management'**
  String get adminDashboardSubtitle;

  /// No description provided for @totalSellers.
  ///
  /// In en, this message translates to:
  /// **'Total street sellers'**
  String get totalSellers;

  /// No description provided for @totalBuyers.
  ///
  /// In en, this message translates to:
  /// **'Total buyers'**
  String get totalBuyers;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending orders'**
  String get pendingOrders;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed orders'**
  String get completedOrders;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled orders'**
  String get cancelledOrders;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @manageBuyers.
  ///
  /// In en, this message translates to:
  /// **'Manage Buyers'**
  String get manageBuyers;

  /// No description provided for @manageBuyersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend or reactivate buyer accounts'**
  String get manageBuyersSubtitle;

  /// No description provided for @approveSeller.
  ///
  /// In en, this message translates to:
  /// **'Approve seller'**
  String get approveSeller;

  /// No description provided for @revokeApproval.
  ///
  /// In en, this message translates to:
  /// **'Revoke approval'**
  String get revokeApproval;

  /// No description provided for @approvedBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get approvedBadge;

  /// No description provided for @pendingApprovalBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApprovalBadge;

  /// No description provided for @suspendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspendedBadge;

  /// No description provided for @suspendDialog.
  ///
  /// In en, this message translates to:
  /// **'Suspend user'**
  String get suspendDialog;

  /// No description provided for @suspendReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get suspendReason;

  /// No description provided for @reactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateUser;

  /// No description provided for @searchBy.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone'**
  String get searchBy;

  /// No description provided for @searchSellers.
  ///
  /// In en, this message translates to:
  /// **'Search sellers'**
  String get searchSellers;

  /// No description provided for @searchBuyers.
  ///
  /// In en, this message translates to:
  /// **'Search buyers'**
  String get searchBuyers;

  /// No description provided for @searchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders'**
  String get searchOrders;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Fish Categories'**
  String get manageCategories;

  /// No description provided for @manageCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit or remove fish types'**
  String get manageCategoriesSubtitle;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get categoryName;

  /// No description provided for @categorySlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get categorySlug;

  /// No description provided for @categoryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get categoryActive;

  /// No description provided for @categoryInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get categoryInactive;

  /// No description provided for @seedDefaults.
  ///
  /// In en, this message translates to:
  /// **'Seed defaults'**
  String get seedDefaults;

  /// No description provided for @seedDefaultsHint.
  ///
  /// In en, this message translates to:
  /// **'Populate the seven default fish types'**
  String get seedDefaultsHint;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @reportsSales.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get reportsSales;

  /// No description provided for @reportsOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders report'**
  String get reportsOrders;

  /// No description provided for @reportsSellers.
  ///
  /// In en, this message translates to:
  /// **'Street sellers report'**
  String get reportsSellers;

  /// No description provided for @reportsBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers report'**
  String get reportsBuyers;

  /// No description provided for @reportsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue summary'**
  String get reportsRevenue;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @topSellers.
  ///
  /// In en, this message translates to:
  /// **'Top sellers'**
  String get topSellers;

  /// No description provided for @topBuyers.
  ///
  /// In en, this message translates to:
  /// **'Top buyers'**
  String get topBuyers;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get logsTitle;

  /// No description provided for @logsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login history, registrations and admin actions'**
  String get logsSubtitle;

  /// No description provided for @loginEvents.
  ///
  /// In en, this message translates to:
  /// **'Logins'**
  String get loginEvents;

  /// No description provided for @registrationEvents.
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get registrationEvents;

  /// No description provided for @adminActions.
  ///
  /// In en, this message translates to:
  /// **'Admin actions'**
  String get adminActions;

  /// No description provided for @disputeEvents.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputeEvents;

  /// No description provided for @listingEvents.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listingEvents;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get noLogsYet;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettingsTitle;

  /// No description provided for @platformMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get platformMaintenance;

  /// No description provided for @platformMaintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable buyer + seller sign-ins temporarily'**
  String get platformMaintenanceSubtitle;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh live data'**
  String get refreshData;

  /// No description provided for @refreshDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invalidate every admin cache and re-fetch'**
  String get refreshDataSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @disputeResolution.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolution'**
  String get disputeResolution;

  /// No description provided for @disputeNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note'**
  String get disputeNote;

  /// No description provided for @disputeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the resolution'**
  String get disputeNoteHint;

  /// No description provided for @adminActionsSection.
  ///
  /// In en, this message translates to:
  /// **'Admin actions'**
  String get adminActionsSection;

  /// No description provided for @adminOnlySection.
  ///
  /// In en, this message translates to:
  /// **'Admin tools'**
  String get adminOnlySection;

  /// No description provided for @viewOrderDetail.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get viewOrderDetail;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @suspendUserAction.
  ///
  /// In en, this message translates to:
  /// **'Suspend user'**
  String get suspendUserAction;

  /// No description provided for @dailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily sales'**
  String get dailySales;

  /// No description provided for @weeklySales.
  ///
  /// In en, this message translates to:
  /// **'Weekly sales'**
  String get weeklySales;

  /// No description provided for @monthlySales.
  ///
  /// In en, this message translates to:
  /// **'Monthly sales'**
  String get monthlySales;

  /// No description provided for @appInfoAndCredits.
  ///
  /// In en, this message translates to:
  /// **'App info and credits'**
  String get appInfoAndCredits;

  /// No description provided for @notificationsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationsPreferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All orders placed on the platform'**
  String get transactionsScreenSubtitle;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When buyers place orders, they\'ll appear here.'**
  String get noTransactionsSubtitle;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'TZS {amount}'**
  String revenueLabel(String amount);

  /// No description provided for @revenueZero.
  ///
  /// In en, this message translates to:
  /// **'TZS 0'**
  String get revenueZero;

  /// No description provided for @kFormatter.
  ///
  /// In en, this message translates to:
  /// **'{value}K'**
  String kFormatter(String value);

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No orders} =1{1 order} other{{count} orders}}'**
  String ordersCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
