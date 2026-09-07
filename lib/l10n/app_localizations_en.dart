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
    return 'Hello,\n$name';
  }

  @override
  String hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get yourStreetSellingHub => 'Your street selling hub';

  @override
  String buyerGreeting(String name) {
    return 'Hello,\n$name';
  }

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
  String distanceFromYou(String distance) {
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
  String get allListings => 'All Listings';

  @override
  String get allListingsSubtitle => 'Review and moderate marketplace';

  @override
  String get transactions => 'Transactions';

  @override
  String get transactionsSubtitle => 'View payment history';

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
  String get noFishAvailable => 'No fish available.';

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
  String get orderPlacedSellerTitle => 'New order placed';

  @override
  String orderPlacedSellerBody(String name) {
    return '$name just placed an order on one of your listings';
  }

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

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myProducts => 'My Products';

  @override
  String get messages => 'Messages';

  @override
  String get cart => 'Cart';

  @override
  String get cartTitle => 'My Cart';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptySubtitle =>
      'Browse fish and add them to your cart to order them all at once.';

  @override
  String get cartBrowseFish => 'Browse fish';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Place order';

  @override
  String get cartClear => 'Clear cart';

  @override
  String get cartClearConfirmTitle => 'Clear cart?';

  @override
  String get cartClearConfirmBody =>
      'This removes every item from your cart. It cannot be undone.';

  @override
  String get cartItemRemoved => 'Removed from cart';

  @override
  String get cartAddedToCart => 'Added to cart';

  @override
  String get cartAlreadyInCart => 'Already in your cart';

  @override
  String get addToCart => 'Add to cart';

  @override
  String cartCheckoutSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders placed',
      one: '1 order placed',
    );
    return '$_temp0';
  }

  @override
  String cartCheckoutPartial(int placed, int total) {
    return '$placed of $total items ordered — the rest are no longer available';
  }

  @override
  String get cartCheckoutFailed =>
      'Could not place your order. Please try again.';

  @override
  String get cartUnavailable => 'No longer available';

  @override
  String cartPricePerKg(String price) {
    return '$price/kg';
  }

  @override
  String get contactsTitle => 'Messages';

  @override
  String get contactsEmptyTitle => 'No buyers yet';

  @override
  String get contactsEmptySubtitle =>
      'When someone orders from you, they will show up here so you can call or text them.';

  @override
  String contactsOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get contactsCall => 'Call';

  @override
  String get contactsSms => 'SMS';

  @override
  String get contactsNoPhone => 'No phone number on file';

  @override
  String get contactsCallFailed => 'Could not start the call';

  @override
  String get contactsSmsFailed => 'Could not open messages';

  @override
  String get buyerGreetingSubtitle => 'Find fresh fish near you';

  @override
  String get mapCtaTitle => 'Open the Map';

  @override
  String get mapCtaSubtitle =>
      'Sellers nearby, routes, and the time you\'ll wait';

  @override
  String get myRequestsTitle => 'My Requests';

  @override
  String get myRequestsEmpty => 'No active requests';

  @override
  String myRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active requests',
      one: '1 active request',
      zero: 'No active requests',
    );
    return '$_temp0';
  }

  @override
  String get recentlyBoughtTitle => 'Recently Bought';

  @override
  String get recentlyBoughtSubtitle => 'Pick up where you left off';

  @override
  String get recentlyBoughtChip => 'Recent';

  @override
  String get popularNearYouTitle => 'Popular Near You';

  @override
  String get popularNearYouSubtitle => 'Recommendations for your area';

  @override
  String get popularNearYouEmpty =>
      'Recommendations will appear here once sellers list more fish near you.';

  @override
  String popularNearYouListings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
    );
    return '$_temp0';
  }

  @override
  String popularNearYouSold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sold',
      one: '1 sold',
    );
    return '$_temp0';
  }

  @override
  String get popularNearYouFrom => 'From';

  @override
  String orderFallbackName(String id) {
    return 'Order #$id';
  }

  @override
  String get sellersMapTitle => 'Sellers Map';

  @override
  String get showAllTypes => 'Show all types';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get estimatedTimeLabel => 'Estimated time';

  @override
  String get trackDeliveryTitle => 'Track Delivery';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get appDownloadTitle => 'Download App';

  @override
  String get appDownloadScanHeader => 'Scan to Install';

  @override
  String get appDownloadScanHint =>
      'Point your camera at the code or tap to enlarge.';

  @override
  String get appDownloadDirectUrlLabel => 'Direct Download URL:';

  @override
  String appDownloadDetectedYou(String platform) {
    return 'Detected: $platform';
  }

  @override
  String appDownloadDownloadApk(String size) {
    return 'Download APK ($size)';
  }

  @override
  String get appDownloadInstallIos => 'Install on iPhone';

  @override
  String get appDownloadInstallAndroid => 'Install on Android';

  @override
  String get appDownloadManualHeader => 'Or install manually';

  @override
  String get appDownloadIosComingSoon =>
      'Coming soon — TestFlight invite will be provided at release.';

  @override
  String get appDownloadShareLink => 'Share Download Link';

  @override
  String get appDownloadCopyLink => 'Copy Download Link';

  @override
  String get appDownloadCopied => 'Download URL copied to clipboard!';

  @override
  String get appDownloadSharedSuccess => 'Download link shared successfully!';

  @override
  String get appDownloadShareFailed =>
      'Could not share. Link copied to clipboard instead.';

  @override
  String get appDownloadEnlargeQr => 'Enlarge QR';

  @override
  String get appDownloadQrDialogTitle => 'Scan QR Code';

  @override
  String get appDownloadQrDialogHelp =>
      'Point camera from any phone or scanner to download';

  @override
  String get appDownloadPdfCard => 'Download Installation Card (PDF)';

  @override
  String get appDownloadPdfShare => 'Share PDF';

  @override
  String get appDownloadPdfShareFailed => 'Could not generate PDF.';

  @override
  String get appDownloadPdfGenerating => 'Generating installation card…';

  @override
  String get appDownloadSpecsHeader => 'App Specifications';

  @override
  String get appDownloadSpecsSubtitle => 'Technical details for this release';

  @override
  String get appDownloadSpecsPlatform => 'Platform';

  @override
  String get appDownloadSpecsVersion => 'Version';

  @override
  String get appDownloadSpecsSize => 'Package Size';

  @override
  String get appDownloadSpecsOs => 'OS Compatibility';

  @override
  String get appDownloadSpecsRelease => 'Release Date';

  @override
  String get appDownloadSpecsStatus => 'Status';

  @override
  String get appDownloadSpecsPlatformAndroid => 'Android APK Direct';

  @override
  String get appDownloadSpecsPlatformIos => 'iOS TestFlight / App Store';

  @override
  String get appDownloadInstallGuide => 'Installation Instructions';

  @override
  String get appDownloadInstallGuideSubtitle =>
      'Install on your phone — no USB or wireless debugging needed.';

  @override
  String get appDownloadScanOrTap => 'Tap to expand for full screen';

  @override
  String get appDownloadFooter => 'SamakiFresh Connect Ecosystem © 2026';

  @override
  String get appDownloadShareSubject => 'Download SamakiFresh Connect';

  @override
  String appDownloadShareBody(String appName, String version, String url) {
    return 'Install SamakiFresh Connect — $appName $version. Scan the QR code or open this link: $url';
  }

  @override
  String get appDownloadAndroidStepsTitle => 'Android';

  @override
  String get appDownloadIosStepsTitle => 'iPhone';

  @override
  String get appDownloadIosComingSoonSteps =>
      'TestFlight invite will be provided at release. Scan the QR or check back soon.';

  @override
  String get confirmPickupCode => 'Confirm Number (Pickup Code)';

  @override
  String yourCode(String code) {
    return 'Your Code: $code';
  }

  @override
  String get enterPickupCode => 'Enter confirmation number (Code)';

  @override
  String get preConfirmationChecklistTitle => 'Confirm Receipt & Add Comment:';

  @override
  String get checkFishArrivedWell => 'Did the fish arrive well?';

  @override
  String get checkQuantityQualityRight =>
      'Is the quantity and quality correct?';

  @override
  String get submitProofPhoto => 'Add Proof Photo (Optional):';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseGallery => 'Choose Gallery';

  @override
  String get yourComment => 'Your Comment';

  @override
  String get yourCommentHint => 'Write your comment or description here...';

  @override
  String get sending => 'Sending...';

  @override
  String get confirmAndSubmit => 'Confirm and Submit to Admin';

  @override
  String get submitToAdmin => 'Submit to Admin';

  @override
  String get adminWillReview =>
      'Admin will review your comment and photo before releasing payment to the seller.';

  @override
  String get pleaseEnterCode => 'Please enter the confirmation number (code).';

  @override
  String get pleaseEnterComment =>
      'Please write your comment before confirming.';

  @override
  String get incorrectCodeTryAgain => 'Incorrect code. Please try again.';

  @override
  String get proofAndCommentSubmitted =>
      '✅ Comment and proof submitted! Admin will review and release payment.';

  @override
  String get errorSubmittingProof =>
      'There was a problem submitting your proof.';

  @override
  String get buyerProofAndComment => 'Buyer\'s Proof and Comment:';

  @override
  String get sellerPendingApprovalMessage =>
      'Your registration has been received successfully! Your seller account is currently being reviewed by a SamakiFresh Admin.\n\nYou will not be able to add new fish, start live selling, or receive orders until your account is verified by an Admin.';

  @override
  String get awaitingAdminApprovalStatus => '⏳ AWAITING ADMIN APPROVAL';

  @override
  String get awaitingAdminApprovalStatusMsg =>
      'You have submitted your proof and comment. The Admin is reviewing your details to release the payment to the seller.';

  @override
  String yourCommentQuoted(String comment) {
    return 'Your Comment: \"$comment\"';
  }

  @override
  String get sellerAwaitingAdminApprovalMsg =>
      'Buyer has confirmed and submitted proof. Payment will be released to you once Admin approves.';

  @override
  String get startPreparingFish => 'Start Preparing Fish';

  @override
  String get generatePickupCode => 'Generate Pickup Code & Ready';

  @override
  String get startDelivery => 'Start Delivery';

  @override
  String get verifyAndComplete => 'Verify & Complete';

  @override
  String get orderVerifiedSuccessfully =>
      'Order verified successfully! Payment released.';

  @override
  String get invalidCodeTryAgain => 'Invalid code. Please try again.';

  @override
  String get shareCodeWithSeller => 'Share this code with the seller...';

  @override
  String get platformCommission => 'Platform Commission (5%):';

  @override
  String get sellerEarnings => 'Seller Earnings (95%):';

  @override
  String get earningsTitle => 'Earnings';

  @override
  String get pendingPayout => 'Pending Payout';

  @override
  String get checkingAccountStatus => 'Checking account status...';

  @override
  String get refreshAccountStatus => 'Refresh Account Status';

  @override
  String get statusPaid => '🔒 Paid';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusOnTheWay => 'On the Way';

  @override
  String get statusDisputed => 'Disputed';

  @override
  String get orderNotSentPaymentUnverified =>
      'Order not sent because payment was not verified.';

  @override
  String get wishlistTitle => 'Wishlist';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get confirmReceived => 'Confirm Received';

  @override
  String get confirmReceivedTitle => 'Confirm Fish Received';

  @override
  String get confirmReceivedBody =>
      'Have you received your fish and are satisfied with the order?';

  @override
  String get confirmReceivedWarning =>
      '⚠️ After confirming, payment will be released to the seller and cannot be reversed.';

  @override
  String get confirmYes => 'Yes, I Confirm';

  @override
  String get confirmNo => 'No, Go Back';

  @override
  String get paymentHeld => '🔒 Payment Held for Safety';

  @override
  String get paymentHeldSubtitle =>
      'Payment will be released to the seller only after you confirm receipt.';

  @override
  String get paymentReleased => '✅ Payment Released';

  @override
  String get paymentReleasedSubtitle => 'Seller has received their payment.';

  @override
  String get orderCompletedTitle => 'Order Completed! 🎉';

  @override
  String get orderTotalLabel => 'Order Total:';

  @override
  String get platformCommissionLabel => 'Platform Commission (5%):';

  @override
  String get sellerEarningsLabel => 'Seller Received (95%):';

  @override
  String get confirmingPayment => 'Processing...';

  @override
  String get paymentConfirmedSuccess =>
      'Thank you! Order completed and payment released to seller.';

  @override
  String get paymentConfirmError => 'An error occurred. Please try again.';

  @override
  String get waitingBuyerConfirmation => 'Waiting for Buyer Confirmation';

  @override
  String get waitingBuyerSubtitle =>
      'The buyer will confirm receipt, then your payout will be released.';

  @override
  String get yourPendingPayout => 'Your Pending Payout:';

  @override
  String get payoutReleasedTitle => '✅ Order Complete — Payment Sent!';

  @override
  String get adminHeldTab => '🔒 Held';

  @override
  String get adminReleasedTab => '✅ Released';

  @override
  String get adminPendingTab => '⏳ Pending';

  @override
  String get buyerConfirmed => 'Buyer Confirmed';

  @override
  String get buyerNotYetConfirmed => 'Buyer Not Yet Confirmed';

  @override
  String get paymentReference => 'Reference:';

  @override
  String get allOrders => 'All';

  @override
  String get cancelOrderDialogTitle => 'Cancel Order?';

  @override
  String get cancelOrderDialogBody =>
      'Are you sure you want to cancel this order?';

  @override
  String get cancelOrderBtn => 'Cancel Order';

  @override
  String get orderCancelledSnackbar => 'Order cancelled';

  @override
  String get orderNewPrefix => 'NEW';

  @override
  String get testPaymentTitle => 'Test Payment Sandbox';

  @override
  String get testPaymentSubtitle =>
      'Test the payment system without any real money deduction';

  @override
  String get selectPaymentMethod => 'Select Payment Method:';

  @override
  String get mobileNumberLabel => 'Test Phone Number';

  @override
  String get testPinLabel => 'Test PIN (e.g. 1234)';

  @override
  String get testCardLabel => 'Test Card Number (4242...)';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get cashOnDeliverySubtitle =>
      'Pay the seller upon receiving your fish';

  @override
  String confirmTestPayment(String amount) {
    return 'Confirm Test Payment (TZS $amount)';
  }

  @override
  String get placeOrderCash => 'Place Order (Cash on Delivery)';

  @override
  String paymentHeldMessage(String ref) {
    return 'Payment Held! Confirm fish receipt to release funds. Ref: $ref';
  }

  @override
  String get orderReceivedCashMessage =>
      'Order Received! Pay the seller upon receiving your fish.';

  @override
  String get bankCardTest => 'Bank Card / Visa / Mastercard (Test)';

  @override
  String paymentErrorPrefix(String error) {
    return 'Payment error: $error';
  }

  @override
  String cartOrdersName(int count) {
    return 'Cart Orders ($count)';
  }

  @override
  String get heldUntilConfirmation =>
      ' — Payment held until buyer confirms receipt.';

  @override
  String get wishlistEmptyText => 'Your wishlist is empty';

  @override
  String get wishlistEmptyTextSubtitle =>
      'When you add fish you\'re looking for, we\'ll notify you when available near you.';

  @override
  String get notifyWhenFound => 'Notify when found';

  @override
  String upToPrice(String price) {
    return 'Up to TZS $price/kg';
  }

  @override
  String get selectFishLabel => 'Select Fish';

  @override
  String get quantityKgLabel => 'Quantity (kg)';

  @override
  String get enterQuantityHint => 'Enter quantity';

  @override
  String get totalAmountLabel => 'Total Amount:';

  @override
  String get additionalNotesLabel => 'Additional notes';

  @override
  String get notesHint =>
      'E.g., I want very fresh fish, will pay on delivery...';

  @override
  String forSeller(String name) {
    return 'To: $name';
  }

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginSignInContinue => 'Sign in to continue to your dashboard.';

  @override
  String get loginEmailAddress => 'Email address';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginTagline => 'Fresh Fish  ·  Better Lives';

  @override
  String get trackPaymentRefunded => '💸 Payment Refunded to You';

  @override
  String get trackPaymentHeld => '🔒 Payment Held Securely';

  @override
  String get trackPaymentReleased =>
      '✅ Payment Released — Seller Received Payout';

  @override
  String get trackCommentsOptional => '📝 Comments (Optional)';

  @override
  String get trackProofPhotoOptional => '📷 Proof Photo (Optional)';

  @override
  String get trackUploadingPhoto => 'Uploading photo...';

  @override
  String get trackReceivedFishCorrect => '✅ Received Fish — Order Correct';

  @override
  String get trackIncorrectOrderReport => '⚠️ Incorrect Order — Report Issue';

  @override
  String get trackConfirmReceipt => 'Confirm Receipt';

  @override
  String get trackConfirmReceiptMsg =>
      'Have you received your fish and are satisfied with your order?';

  @override
  String get trackNoGoBack => 'No, Go Back';

  @override
  String get trackYesIConfirm => 'Yes, I Confirm';

  @override
  String get trackOrderCompletedMsg =>
      'Thank you! Order completed and payment released to seller.';

  @override
  String get trackErrorOccurred => 'An error occurred. Please try again.';

  @override
  String get trackProvideCommentOrPhoto =>
      'Please write a comment or upload a photo to explain the issue.';

  @override
  String get trackReportIssueTitle => 'Report Issue';

  @override
  String get trackSureOrderIncorrect => 'Are you sure the order is incorrect?';

  @override
  String get trackYesReportIssue => 'Yes, Report Issue';

  @override
  String get trackIssueReportedMsg =>
      'Your issue has been reported. Admin will review and contact you shortly.';

  @override
  String get trackOrderCompletedTitle => 'Order Completed! 🎉';

  @override
  String get trackThankYouUsing => 'Thank you for using SamakiFresh Connect.';

  @override
  String get trackIssueReportedTitle =>
      '⚠️ Issue Reported — Awaiting Admin Review';

  @override
  String get trackFullRefundIssued => '💸 Full Refund Issued';

  @override
  String get trackETA => 'ETA';

  @override
  String get trackContactSeller => 'Contact Seller';

  @override
  String get trackReportReceivedMsg =>
      'Your report was received. Payment is held pending administrator resolution.';

  @override
  String trackRefundedToAccount(String amount) {
    return 'TZS $amount has been refunded back to your account.';
  }

  @override
  String get buyerNoActiveOrders => 'No active orders to track';

  @override
  String relativeMinutes(int count) {
    return '${count}m';
  }

  @override
  String relativeHours(int count) {
    return '${count}h';
  }

  @override
  String relativeDays(int count) {
    return '${count}d';
  }

  @override
  String get sellerNoActiveDeliveries => 'No active deliveries to track';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabSales => 'Sales';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabSellers => 'Sellers';

  @override
  String get tabBuyers => 'Buyers';

  @override
  String get tabRevenue => 'Revenue';

  @override
  String get adminToday => 'Today';

  @override
  String adminOrderCount(int count) {
    return '$count orders';
  }

  @override
  String get adminTotal => 'Total';

  @override
  String get adminNoBuyersYet => 'No buyers yet';

  @override
  String get adminTabAll => 'All';

  @override
  String get adminTabHeld => '🔒 Held';

  @override
  String get adminTabReleased => '✅ Released';

  @override
  String get adminTabPending => '⏳ Pending';

  @override
  String get adminTabDisputed => '⚠️ Disputed';

  @override
  String get adminNoHeldPayments => 'No held payments';

  @override
  String get adminNoReleasedPayouts => 'No released payouts yet';

  @override
  String get adminNoPendingPayments => 'No pending payments';

  @override
  String get adminNoActiveDisputes => 'No active disputes';

  @override
  String get adminNoTransactions => 'No transactions found';

  @override
  String get adminStatusPending => 'PENDING';

  @override
  String get adminStatusConfirmed => 'CONFIRMED';

  @override
  String get adminStatusPreparing => 'PREPARING';

  @override
  String get adminStatusReady => 'READY';

  @override
  String get adminStatusOnTheWay => 'ON THE WAY';

  @override
  String get adminStatusCompleted => 'COMPLETED';

  @override
  String get adminStatusCancelled => 'CANCELLED';

  @override
  String get adminStatusDisputed => 'DISPUTED';

  @override
  String get adminRefundedBadge => '💸 REFUNDED';

  @override
  String get adminPaidBadge => '💳 PAID';

  @override
  String get adminCashBadge => '💵 CASH';

  @override
  String adminPayoutBadge(String status) {
    return 'PAYOUT: $status';
  }

  @override
  String get adminBuyerConfirmedBadge => '✅ BUYER CONFIRMED';

  @override
  String get adminDisputeReportedBadge => '⚠️ DISPUTE REPORTED';

  @override
  String get adminAwaitingConfirmationBadge => '⏳ AWAITING BUYER CONFIRMATION';

  @override
  String get adminBuyerDisputeReview => 'Buyer Dispute Review';

  @override
  String adminComplaint(String comment) {
    return 'Complaint: \"$comment\"';
  }

  @override
  String get adminRefundBuyerBtn => '💸 Refund Buyer';

  @override
  String get adminApprovePayoutBtn => '✅ Approve Payout';

  @override
  String get adminOrderTotal => 'Order Total:';

  @override
  String get adminPlatformCommission => 'Platform Commission (5%):';

  @override
  String get adminSellerEarnings => 'Seller Earnings (95%):';

  @override
  String get adminApproveRefundTitle => 'Approve Full Refund?';

  @override
  String adminApproveRefundMsg(String amount, String orderId) {
    return 'Are you sure you want to refund TZS $amount to the buyer for Order #$orderId?\n\nThis will cancel the order and return the funds.';
  }

  @override
  String get adminCancelBtn => 'Cancel';

  @override
  String get adminConfirmRefundBtn => 'Confirm Refund';

  @override
  String adminRefundApprovedMsg(String amount, String orderId) {
    return 'Refund of TZS $amount approved for Order #$orderId.';
  }

  @override
  String get adminApprovePayoutTitle => 'Approve Seller Payout?';

  @override
  String adminApprovePayoutMsg(String amount) {
    return 'Are you sure you want to resolve this dispute in favor of the seller and release TZS $amount?';
  }

  @override
  String get adminApprovePayoutConfirmBtn => 'Approve Payout';

  @override
  String adminPayoutReleasedMsg(String orderId) {
    return 'Payout released to seller for Order #$orderId.';
  }

  @override
  String get adminEditCategory => 'Edit category';

  @override
  String adminCategorySlugHint(String name) {
    return 'e.g. $name';
  }

  @override
  String adminDeleteCategoryConfirm(String name) {
    return 'Permanently delete \"$name\"?';
  }

  @override
  String get settingsFeatureComingSoon => 'This feature is coming soon...';

  @override
  String get settingsBuyersOnly => 'This feature is for buyers only.';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String settingsResetPasswordPrompt(String email) {
    return 'Send password reset email to:\\n$email?';
  }

  @override
  String get settingsEmailSent => 'Email sent successfully.';

  @override
  String get settingsError => 'An error occurred. Please try again.';

  @override
  String get settingsSend => 'Send';

  @override
  String get settingsFaceIdEnabled => 'Face ID enabled successfully.';

  @override
  String get actionEditListingDesc => 'Update price, quantity or description';

  @override
  String get alreadySold => 'Already sold';

  @override
  String get actionDeactivateListingDesc => 'Hide from marketplace';

  @override
  String get actionDeleteListingDesc => 'Remove this listing permanently';

  @override
  String get orderNotSentPaymentFailed =>
      'Order not sent because payment is not confirmed.';
}
