// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Samaki Fresh Connect';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get logout => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get fullName => 'Full Name';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get chooseLanguageSubtitle =>
      'Switch the entire app to your preferred language.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get kiswahili => 'Kiswahili';

  @override
  String get home => 'Home';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get myListings => 'My Listings';

  @override
  String get profile => 'Profile';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchFish => 'Search Fish';

  @override
  String get searchHint => 'e.g. tuna, mackerel, fillet…';

  @override
  String get startTypingToSearch => 'Start typing to search';

  @override
  String noSellersHave(String query) {
    return 'No sellers have \"$query\" right now';
  }

  @override
  String get noSellersHaveSubtitle =>
      'No seller carries this fish at the moment. Try a different name.';

  @override
  String get loading => 'Loading…';

  @override
  String loadingError(String error) {
    return 'Error: $error';
  }

  @override
  String get searchFailed => 'Search failed';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get fishType => 'Fish Type';

  @override
  String get quantity => 'Quantity (kg)';

  @override
  String get price => 'Price per kg';

  @override
  String get description => 'Description';

  @override
  String get requiredField => 'Required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get quantityMustBePositive => 'Quantity must be greater than 0';

  @override
  String get priceMustBePositive => 'Price must be greater than 0';

  @override
  String get phoneInvalid => 'Enter Tanzanian format: +255XXXXXXXXX';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get postListing => 'Post Listing';

  @override
  String get sellStock => 'Sell Stock';

  @override
  String get buyStock => 'Buy Stock';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myOrdersSubtitle => 'Track purchases';

  @override
  String get sellStockSubtitle => 'Post a listing';

  @override
  String get myListingsSubtitle => 'Manage your stock';

  @override
  String get buyStockSubtitle => 'Browse marketplace';

  @override
  String get fishAvailableNearby => 'Fish Available Nearby';

  @override
  String get activeListings => 'Active Listings';

  @override
  String get totalStock => 'Total Stock';

  @override
  String get nearestSeller => 'Nearest Seller';

  @override
  String get activeRequests => 'Active Requests';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get starting => 'Starting…';

  @override
  String get youAreNowOnline => 'You are now online · sharing location';

  @override
  String get youAreNowOffline => 'You are now offline';

  @override
  String get photosUpTo5 => 'Photos (up to 5)';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get shopLocation => 'Shop Location';

  @override
  String get setShopLocation => 'Set shop location';

  @override
  String get shopLocationSet => 'Shop location set';

  @override
  String get shopLocationRequired =>
      'Required so buyers can find your shop on the map';

  @override
  String get readingGps => 'Reading GPS signal...';

  @override
  String shopLocationSetTo(String label) {
    return 'Shop location set to $label';
  }

  @override
  String imageUploadFailed(String error) {
    return 'Could not read photos: $error';
  }

  @override
  String cameraImageFailed(String error) {
    return 'Could not read photo from camera: $error';
  }

  @override
  String get listingCreatedSuccessfully => 'Listing created successfully! 🐟';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String habari(String name) {
    return 'Hello, $name! 🛒';
  }

  @override
  String get yourStreetSellingHub => 'Your street selling hub';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get noImage => 'No image';

  @override
  String expiresIn(String duration) {
    return 'Expires in $duration';
  }

  @override
  String get active => 'ACTIVE';

  @override
  String get sold => 'SOLD';

  @override
  String get expired => 'EXPIRED';

  @override
  String get myProfile => 'My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get noImageBroken => 'Image could not be loaded';

  @override
  String get sendFishRequest => 'Send fish request';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get callSeller => 'Call seller';

  @override
  String get smsSeller => 'Message seller';

  @override
  String get callFailed => 'Call not available — number copied';

  @override
  String get smsFailed => 'SMS not available — number copied';

  @override
  String get viewDetails => 'View Details';

  @override
  String get trackSeller => 'Track seller';

  @override
  String get sellersNearYou => 'Sellers near you';

  @override
  String get liveFishFromThisSeller => 'Live fish from this seller';

  @override
  String get noFishPhotos => 'No fish photos yet';

  @override
  String get phoneCopied => 'Phone number copied';

  @override
  String sellersNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sellers',
      one: '1 seller',
      zero: 'No sellers',
    );
    return '$_temp0 nearby';
  }

  @override
  String get live => 'Live';

  @override
  String get onlineLiveLocation => 'Online · live location';

  @override
  String get account => 'Account';

  @override
  String get search => 'Search';

  @override
  String get demoAccounts => 'Demo Accounts';

  @override
  String get tryOutApp => 'Try out the app instantly with a demo account.';

  @override
  String get myLocation => 'My Location';

  @override
  String get useGps => 'Use GPS';

  @override
  String get useSavedLocation => 'Use saved location';

  @override
  String distanceAway(String distance) {
    return '$distance km away';
  }

  @override
  String get verificationRequired => 'Account verification required';

  @override
  String get verificationMessage =>
      'Please check your email and verify your account before continuing.';

  @override
  String get verifyNow => 'Verify Now';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noNotificationsSubtitle =>
      'We\'ll let you know when something happens.';

  @override
  String get noWishlistItems => 'Your wishlist is empty';

  @override
  String get noWishlistSubtitle =>
      'Tap the heart on any fish listing to save it here.';

  @override
  String get noActiveRequests => 'No active fish requests';

  @override
  String get noActiveRequestsSubtitle =>
      'When you post a fish request, it will appear here.';

  @override
  String get noListings => 'No listings yet';

  @override
  String get noListingsSubtitle =>
      'Tap the + button to add your first listing.';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get noOrdersSubtitle =>
      'When you buy or sell fish, orders will appear here.';

  @override
  String get offlineState => 'This seller is currently offline';

  @override
  String kmAway(String km) {
    return '$km km away';
  }

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get selectLanguageDescription =>
      'The whole app will switch instantly. Your choice is saved on this device.';

  @override
  String get languageSaved => 'Language saved';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String changeFailed(String setting, String error) {
    return 'Couldn\'t change $setting: $error';
  }

  @override
  String get commonError => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get editListing => 'Edit Listing';

  @override
  String get logoutConfirmationMessage =>
      'You will be returned to the login screen.';

  @override
  String get km => 'km';

  @override
  String get reorder => 'Reorder';

  @override
  String get leaveReview => 'Leave a review';

  @override
  String get shareListing => 'Share listing';

  @override
  String get reportListing => 'Report listing';

  @override
  String get deleteListingConfirmation =>
      'Delete this listing? This cannot be undone.';

  @override
  String get markAsSold => 'Mark as sold';

  @override
  String get soldConfirmation => 'Mark this listing as sold?';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get priceLowToHigh => 'Price: Low to high';

  @override
  String get priceHighToLow => 'Price: High to low';

  @override
  String get apply => 'Apply';

  @override
  String get clearAll => 'Clear all';

  @override
  String get results => 'Results';

  @override
  String get noResults => 'No results';

  @override
  String get selectLocation => 'Select location';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get savedLocations => 'Saved locations';

  @override
  String get loadingLocation => 'Loading your location...';

  @override
  String get couldNotGetLocation => 'Could not get your location';

  @override
  String get permissionDenied => 'Location permission denied';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get seeAll => 'See all';

  @override
  String get viewMore => 'View more';

  @override
  String get filterByType => 'Filter by fish type';

  @override
  String distanceFromYou(Object distance) {
    return '$distance km from you';
  }

  @override
  String get selectRadius => 'Select search radius';

  @override
  String get showingNearest => 'Showing nearest sellers only';

  @override
  String get languagePreference => 'Language preference';

  @override
  String get themePreference => 'Theme preference';

  @override
  String get changed => 'Changed';

  @override
  String get featureComingSoon => 'Coming soon';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get refresh => 'Refresh';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get verifyAccount => 'Verify your account';

  @override
  String get resendEmail => 'Resend verification email';

  @override
  String get verificationEmailSent => 'Verification email sent';

  @override
  String get tapToUse => 'Tap to use';

  @override
  String get selectImage => 'Select image';

  @override
  String get fromCamera => 'From camera';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get reviewInformation => 'Review your information';

  @override
  String get totalListings => 'Total listings';

  @override
  String get totalOrders => 'Total orders';

  @override
  String get accountInfo => 'Account info';

  @override
  String get phone => 'Phone';

  @override
  String get street => 'Street';

  @override
  String get region => 'Region';

  @override
  String get market => 'Market';

  @override
  String get buyersAvailable => 'Buyers available';

  @override
  String sellersNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sellers nearby',
      one: '1 seller nearby',
      zero: 'No sellers nearby',
    );
    return '$_temp0';
  }

  @override
  String get receiving => 'Receiving';

  @override
  String get ready => 'Ready';

  @override
  String get inTransit => 'In transit';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get buyer => 'Buyer';

  @override
  String get seller => 'Seller';

  @override
  String get quantityKg => 'Quantity';

  @override
  String get perKg => '/ kg';

  @override
  String get noReviews => 'No reviews yet';

  @override
  String get seeAllReviews => 'See all reviews';

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String get ratings => 'Ratings';

  @override
  String get reviews => 'Reviews';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get deliveryTime => 'Delivery time';

  @override
  String get yourOrders => 'Your orders';

  @override
  String get buyerType => 'Buyer type';

  @override
  String get transport => 'Transport';

  @override
  String get individualHousehold => 'Individual/Household';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get hotel => 'Hotel';

  @override
  String get retail => 'Retail';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get anytime => 'Anytime';

  @override
  String get fullAddress => 'Full address';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get equipmentPhoto => 'Equipment photo';

  @override
  String get selectPhotos => 'Select up to 5 photos';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get enterAddress => 'Enter address';

  @override
  String get enterCity => 'Enter city';

  @override
  String get enterRegion => 'Enter region';

  @override
  String get addListing => 'Add listing';

  @override
  String get deleteListing => 'Delete listing';

  @override
  String get markSold => 'Mark as sold';

  @override
  String get shareLocation => 'Share location';

  @override
  String get goOnline => 'Go online';

  @override
  String get goOffline => 'Go offline';

  @override
  String get startingLocation => 'Starting location...';

  @override
  String get shareLocationToggle => 'Share your location';

  @override
  String get shareLocationSubtitle => 'Let buyers see you on the map';

  @override
  String get onlineStatus => 'Online status';

  @override
  String get onlineNow => 'You are online';

  @override
  String get offlineNow => 'You are offline';

  @override
  String get sellerProfile => 'Seller profile';

  @override
  String activeListingsCount(Object count) {
    return 'Active: $count';
  }

  @override
  String ratingValue(Object rating) {
    return '$rating rating';
  }

  @override
  String lastSeenMinutesAgo(Object minutes) {
    return 'Last seen ${minutes}m ago';
  }

  @override
  String lastSeenHoursAgo(Object hours) {
    return 'Last seen ${hours}h ago';
  }

  @override
  String lastSeenDaysAgo(Object days) {
    return 'Last seen ${days}d ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get directions => 'Directions';

  @override
  String get send => 'Send';

  @override
  String get messageSeller => 'Message seller';

  @override
  String get typeMessage => 'Type a message';

  @override
  String get onlineDot => 'Online';

  @override
  String get verifiedBadge => 'Verified';

  @override
  String get you => 'You';

  @override
  String get buyerName => 'Buyer name';

  @override
  String get sellerName => 'Seller name';

  @override
  String get orders => 'Orders';

  @override
  String get filters => 'Filters';

  @override
  String get allTypes => 'All types';

  @override
  String get noOrdersYetTitle => 'No orders yet';

  @override
  String get loadingOrders => 'Loading orders...';

  @override
  String orderId(String id) {
    return 'Order #$id';
  }

  @override
  String get markAsCompleted => 'Mark as completed';

  @override
  String get cancelOrderConfirmation => 'Cancel this order?';

  @override
  String get acceptOrder => 'Accept order';

  @override
  String get confirmOrder => 'Confirm order';

  @override
  String get rejectOrder => 'Reject order';

  @override
  String get trackOrder => 'Track order';

  @override
  String get orderItems => 'Order items';

  @override
  String get delivery => 'Delivery';

  @override
  String quantityShortKg(String qty) {
    return '$qty kg';
  }

  @override
  String totalKg(String qty) {
    return '$qty kg total';
  }

  @override
  String buyerOrderedItems(String buyer, String qty) {
    return '$buyer ordered $qty kg';
  }

  @override
  String pricePerKg(String price) {
    return 'TZS $price/kg';
  }

  @override
  String priceRange(String min, String max) {
    return 'TZS $min – $max / kg';
  }

  @override
  String get setMyLocation => 'Set my location';

  @override
  String get switchToLightTheme => 'Switch to light theme';

  @override
  String get switchToDarkTheme => 'Switch to dark theme';

  @override
  String get platformOverview => 'Platform Overview & Management';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get ordersToday => 'Orders Today';

  @override
  String get platformRevenue => 'Platform Revenue';

  @override
  String get management => 'Management';

  @override
  String get manageDalalis => 'Manage Dalalis';

  @override
  String get manageDalalisSubtitle => 'Register, approve or block brokers';

  @override
  String get allListings => 'All Listings';

  @override
  String get allListingsSubtitle => 'Review and moderate marketplace';

  @override
  String get transactions => 'Transactions';

  @override
  String get transactionsSubtitle => 'View payment history';

  @override
  String hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get manageStreetSellers => 'Manage Street Sellers';

  @override
  String get manageStreetSellersSubtitle =>
      'Approve, review or block sellers on the platform';

  @override
  String get noStreetSellers => 'No street sellers registered yet';

  @override
  String get noStreetSellersSubtitle =>
      'When sellers register, they\'ll appear here for review.';

  @override
  String get viewProfile => 'View profile';

  @override
  String get blockUser => 'Block';

  @override
  String get unblockUser => 'Unblock';

  @override
  String get userBlocked => 'User blocked';

  @override
  String get userUnblocked => 'User unblocked';

  @override
  String get confirmBlockUser =>
      'Block this seller? They will not be able to sign in until you unblock them.';

  @override
  String get adminAllListingsSubtitle =>
      'Review every listing across the marketplace';

  @override
  String get noListingsFound => 'No listings found';

  @override
  String get noListingsFoundSubtitle =>
      'When buyers or sellers create listings, they\'ll appear here.';

  @override
  String get deleteListingConfirmationAdmin =>
      'Permanently delete this listing? This cannot be undone.';

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String listingsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings deleted',
      one: '1 listing deleted',
      zero: 'No listings deleted',
    );
    return '$_temp0';
  }

  @override
  String get selectMode => 'Select';

  @override
  String get exitSelectMode => 'Exit selection';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String deleteListingsConfirmationAdmin(int count) {
    return 'Permanently delete $count listings? This cannot be undone.';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'None selected',
    );
    return '$_temp0';
  }

  @override
  String get appearanceLiveHint =>
      'Your selection is applied instantly across every screen and saved for next time.';

  @override
  String get adminDashboardSubtitle => 'Platform overview and management';

  @override
  String get totalSellers => 'Total street sellers';

  @override
  String get totalBuyers => 'Total buyers';

  @override
  String get pendingOrders => 'Pending orders';

  @override
  String get completedOrders => 'Completed orders';

  @override
  String get cancelledOrders => 'Cancelled orders';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get manageBuyers => 'Manage Buyers';

  @override
  String get manageBuyersSubtitle => 'Suspend or reactivate buyer accounts';

  @override
  String get approveSeller => 'Approve seller';

  @override
  String get revokeApproval => 'Revoke approval';

  @override
  String get approvedBadge => 'Active';

  @override
  String get pendingApprovalBadge => 'Pending approval';

  @override
  String get suspendedBadge => 'Suspended';

  @override
  String get suspendDialog => 'Suspend user';

  @override
  String get suspendReason => 'Reason';

  @override
  String get reactivateUser => 'Reactivate';

  @override
  String get searchBy => 'Search by name, email or phone';

  @override
  String get searchSellers => 'Search sellers';

  @override
  String get searchBuyers => 'Search buyers';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get noMatchingBuyers => 'No buyers match your search';

  @override
  String get userSuspended => 'Buyer suspended';

  @override
  String get userReactivated => 'Buyer reactivated';

  @override
  String get userModerationFailed =>
      'Couldn\'t update this buyer. Please try again.';

  @override
  String get listingDetails => 'Listing Details';

  @override
  String get notLoggedInSimple => 'Not logged in';

  @override
  String get loadingFreshCatch => 'Loading fresh catch...';

  @override
  String get loadingYourListings => 'Loading your listings...';

  @override
  String get loadingYourOrders => 'Loading your orders...';

  @override
  String get failedToLoadListings => 'Failed to load listings';

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String get failedToLoadUserData => 'Error loading user data';

  @override
  String get noListingsYet => 'No Listings Yet';

  @override
  String get createListingPrompt => 'Create a listing to start selling!';

  @override
  String get noOrdersYet => 'No Orders';

  @override
  String get orderTrackingExplanation =>
      'Order tracking is for buyers and sellers.';

  @override
  String get noOrdersFound => 'No Orders Found';

  @override
  String get noOrdersPrompt => 'You haven\'t made any transactions yet.';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get deleteListingTitle => 'Delete listing?';

  @override
  String deleteListingBody(String fishType, String quantity) {
    return 'This will permanently remove the $fishType listing ($quantity kg). Buyers will no longer see it on the marketplace.';
  }

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get listingUpdated => 'Listing updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get markedAsSold => 'Marked as sold';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get noFishAvailable => 'No Fish Available';

  @override
  String get checkBackLater => 'Check back later for fresh catch!';

  @override
  String get errorLoadingListing => 'Error loading listing';

  @override
  String get errorLoadingOrder => 'Error loading order';

  @override
  String get listingNotFound => 'Listing not found';

  @override
  String get listingMayBeRemoved => 'This listing may have been removed.';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get orderMayBeDeleted => 'This order may have been deleted.';

  @override
  String couldNotLoadListing(String error) {
    return 'Could not load listing: $error';
  }

  @override
  String get orderPlacedSuccess => 'Order placed successfully!';

  @override
  String get listingAlreadySold =>
      'This listing is no longer available — another buyer just purchased it.';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String reviewCount(int count) {
    return '$count reviews';
  }

  @override
  String get manageListingTooltip => 'Manage listing';

  @override
  String get switchThemeTooltip => 'Switch theme';

  @override
  String get allSettingsTooltip => 'All settings';

  @override
  String get searchOrders => 'Search orders';

  @override
  String get manageCategories => 'Fish Categories';

  @override
  String get manageCategoriesSubtitle => 'Add, edit or remove fish types';

  @override
  String get newCategory => 'New category';

  @override
  String get categoryName => 'Display name';

  @override
  String get categorySlug => 'Slug';

  @override
  String get categoryActive => 'Active';

  @override
  String get categoryInactive => 'Inactive';

  @override
  String get seedDefaults => 'Seed defaults';

  @override
  String get seedDefaultsHint => 'Populate the seven default fish types';

  @override
  String get reportsTab => 'Reports';

  @override
  String get reportsSales => 'Sales report';

  @override
  String get reportsOrders => 'Orders report';

  @override
  String get reportsSellers => 'Street sellers report';

  @override
  String get reportsBuyers => 'Buyers report';

  @override
  String get reportsRevenue => 'Revenue summary';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get topSellers => 'Top sellers';

  @override
  String get topBuyers => 'Top buyers';

  @override
  String get logsTitle => 'Activity Logs';

  @override
  String get logsSubtitle => 'Login history, registrations and admin actions';

  @override
  String get loginEvents => 'Logins';

  @override
  String get registrationEvents => 'Registrations';

  @override
  String get adminActions => 'Admin actions';

  @override
  String get disputeEvents => 'Disputes';

  @override
  String get listingEvents => 'Listings';

  @override
  String get noLogsYet => 'No activity recorded yet';

  @override
  String get adminSettingsTitle => 'Admin Settings';

  @override
  String get platformMaintenance => 'Maintenance mode';

  @override
  String get platformMaintenanceSubtitle =>
      'Disable buyer + seller sign-ins temporarily';

  @override
  String get refreshData => 'Refresh live data';

  @override
  String get refreshDataSubtitle => 'Invalidate every admin cache and re-fetch';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get disputeResolution => 'Dispute resolution';

  @override
  String get disputeNote => 'Admin note';

  @override
  String get disputeNoteHint => 'Briefly describe the resolution';

  @override
  String get adminActionsSection => 'Admin actions';

  @override
  String get adminOnlySection => 'Admin tools';

  @override
  String get viewOrderDetail => 'View order';

  @override
  String get statusAll => 'All';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get suspendUserAction => 'Suspend user';

  @override
  String get noBuyersRegistered => 'No buyers registered yet';

  @override
  String get fishAvailableNearbyTile => 'Fish Available\nNearby';

  @override
  String get activeRequestsTile => 'Active\nRequests';

  @override
  String get nearestSellerTile => 'Nearest\nSeller';

  @override
  String get fishAvailableSubtitle => 'Live around you';

  @override
  String get activeRequestsSubtitle => 'Open requests';

  @override
  String get nearestSellerSubtitle => 'Closest fish';

  @override
  String get dailySales => 'Daily sales';

  @override
  String get weeklySales => 'Weekly sales';

  @override
  String get monthlySales => 'Monthly sales';

  @override
  String get appInfoAndCredits => 'App info and credits';

  @override
  String get notificationsPreferences => 'Notification preferences';

  @override
  String get about => 'About';

  @override
  String get aboutTitle => 'About';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsScreenSubtitle => 'All orders placed on the platform';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsSubtitle =>
      'When buyers place orders, they\'ll appear here.';

  @override
  String revenueLabel(String amount) {
    return 'TZS $amount';
  }

  @override
  String get revenueZero => 'TZS 0';

  @override
  String kFormatter(String value) {
    return '${value}K';
  }

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String get goOnlineFailed => 'Imeshindwa kuwa online';
}
