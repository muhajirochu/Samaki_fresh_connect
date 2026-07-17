// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Samaki Fresh Connect';

  @override
  String get welcome => 'Karibu';

  @override
  String get login => 'Ingia';

  @override
  String get signup => 'Jisajili';

  @override
  String get logout => 'Toka';

  @override
  String get email => 'Barua pepe';

  @override
  String get password => 'Neno la siri';

  @override
  String get confirmPassword => 'Thibitisha neno la siri';

  @override
  String get phoneNumber => 'Nambari ya simu';

  @override
  String get fullName => 'Jina kamili';

  @override
  String get forgotPassword => 'Umesahau neno la siri?';

  @override
  String get rememberMe => 'Nikumbuke';

  @override
  String get orContinueWith => 'Au endelea na';

  @override
  String get alreadyHaveAccount => 'Una akaunti tayari?';

  @override
  String get dontHaveAccount => 'Huna akaunti?';

  @override
  String get submit => 'Wasilisha';

  @override
  String get save => 'Hifadhi';

  @override
  String get cancel => 'Ghairi';

  @override
  String get delete => 'Futa';

  @override
  String get edit => 'Hariri';

  @override
  String get retry => 'Jaribu tena';

  @override
  String get back => 'Rudi';

  @override
  String get close => 'Funga';

  @override
  String get confirm => 'Thibitisha';

  @override
  String get yes => 'Ndiyo';

  @override
  String get no => 'Hapana';

  @override
  String get ok => 'Sawa';

  @override
  String get settings => 'Mipango';

  @override
  String get appearance => 'Muonekano';

  @override
  String get language => 'Lugha';

  @override
  String get chooseLanguage => 'Chagua Lugha';

  @override
  String get chooseLanguageSubtitle => 'Badilisha lugha ya programu nzima.';

  @override
  String get selectLanguage => 'Chagua Lugha';

  @override
  String get english => 'English';

  @override
  String get kiswahili => 'Kiswahili';

  @override
  String get home => 'Mwanzo';

  @override
  String get marketplace => 'Soko';

  @override
  String get myListings => 'Zabuni zangu';

  @override
  String get profile => 'Wasifu';

  @override
  String get wishlist => 'Orodha ya matumaini';

  @override
  String get notifications => 'Arifa';

  @override
  String get searchFish => 'Tafuta samaki';

  @override
  String get searchHint => 'k.m. tuna, mackerel, fillet…';

  @override
  String get startTypingToSearch => 'Anza kuandika kutafuta';

  @override
  String noSellersHave(String query) {
    return 'Hakuna muuzaji wa \"$query\" kwa sasa';
  }

  @override
  String get noSellersHaveSubtitle =>
      'Hakuna muuzaji anayebeba samaki wa aina hii kwa sasa. Jaribu jina lingine.';

  @override
  String get loading => 'Inapakia…';

  @override
  String loadingError(String error) {
    return 'Hitilafu: $error';
  }

  @override
  String get searchFailed => 'Utafutaji umeshindwa';

  @override
  String get notLoggedIn => 'Hujaingia';

  @override
  String get fishType => 'Aina ya samaki';

  @override
  String get quantity => 'Kiasi (kg)';

  @override
  String get price => 'Bei kwa kilo';

  @override
  String get description => 'Maelezo';

  @override
  String get requiredField => 'Inahitajika';

  @override
  String get enterValidNumber => 'Weka nambari sahihi';

  @override
  String get quantityMustBePositive => 'Kiasi lazima kiwe zaidi ya 0';

  @override
  String get priceMustBePositive => 'Bei lazima iwe zaidi ya 0';

  @override
  String get phoneInvalid => 'Weka muundo wa Tanzania: +255XXXXXXXXX';

  @override
  String get passwordsDoNotMatch => 'Maneno ya siri hayafanani';

  @override
  String get emailInvalid => 'Weka anwani sahihi ya barua pepe';

  @override
  String get passwordTooShort => 'Neno la siri lazima liwe angalau herufi 6';

  @override
  String get postListing => 'Tuma Zabuni';

  @override
  String get sellStock => 'Uza Samaki';

  @override
  String get buyStock => 'Nunua Samaki';

  @override
  String get myOrders => 'Maagizo Yangu';

  @override
  String get myOrdersSubtitle => 'Fuatilia manunuzi';

  @override
  String get sellStockSubtitle => 'Tuma zabuni';

  @override
  String get myListingsSubtitle => 'Simamia samaki wako';

  @override
  String get buyStockSubtitle => 'Vinjari soko';

  @override
  String get fishAvailableNearby => 'Samaki Waliopo Karibu';

  @override
  String get activeListings => 'Zabuni Hai';

  @override
  String get totalStock => 'Jumla ya Samaki';

  @override
  String get nearestSeller => 'Muuzaji wa Karibu';

  @override
  String get activeRequests => 'Maombi Hai';

  @override
  String get online => 'Mtandaoni';

  @override
  String get offline => 'Nje ya Mtandao';

  @override
  String get starting => 'Inaanza…';

  @override
  String get youAreNowOnline => 'Upo mtandaoni · unashiriki eneo';

  @override
  String get youAreNowOffline => 'Umetoka mtandaoni';

  @override
  String get photosUpTo5 => 'Picha (hadi 5)';

  @override
  String get addPhoto => 'Ongeza Picha';

  @override
  String get gallery => 'Mkusanyiko';

  @override
  String get camera => 'Kamera';

  @override
  String get shopLocation => 'Eneo la Duka';

  @override
  String get setShopLocation => 'Weka eneo la duka';

  @override
  String get shopLocationSet => 'Eneo la duka limewekwa';

  @override
  String get shopLocationRequired => 'Inahitajika ili wanunuzi waweze kukupata';

  @override
  String get readingGps => 'Inasoma ishara ya GPS...';

  @override
  String shopLocationSetTo(String label) {
    return 'Eneo la duka limewekwa $label';
  }

  @override
  String imageUploadFailed(String error) {
    return 'Imeshindwa kusoma picha: $error';
  }

  @override
  String cameraImageFailed(String error) {
    return 'Imeshindwa kusoma picha kutoka kamerasi: $error';
  }

  @override
  String get listingCreatedSuccessfully => 'Zabuni imeundwa kwa mafanikio! 🐟';

  @override
  String errorGeneric(String error) {
    return 'Hitilafu: $error';
  }

  @override
  String habari(String name) {
    return 'Habari, $name! 🛒';
  }

  @override
  String get yourStreetSellingHub => 'Kituo chako cha kuuza barabarani';

  @override
  String get quickActions => 'Vitendo vya Haraka';

  @override
  String get noImage => 'Hakuna Picha';

  @override
  String expiresIn(String duration) {
    return 'Inaisha baada ya $duration';
  }

  @override
  String get active => 'HAI';

  @override
  String get sold => 'IMEUZWA';

  @override
  String get expired => 'IMEPITA';

  @override
  String get myProfile => 'Wasifu Wangu';

  @override
  String get editProfile => 'Hariri wasifu';

  @override
  String get accountInformation => 'Maelezo ya Akaunti';

  @override
  String get signOut => 'Toka';

  @override
  String get signOutConfirmation => 'Una uhakika unataka kutoka?';

  @override
  String get noImageBroken => 'Picha haikuweza kupakuliwa';

  @override
  String get sendFishRequest => 'Tuma ombi la samaki';

  @override
  String get sendRequest => 'Tuma Ombi';

  @override
  String get callSeller => 'Piga simu';

  @override
  String get smsSeller => 'Tuma Ujumbe';

  @override
  String get viewDetails => 'Ona Maelezo';

  @override
  String sellersNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wauzaji $count',
      one: 'Muuzaji 1',
      zero: 'Hakuna wauzaji',
    );
    return '$_temp0 karibu';
  }

  @override
  String get live => 'Moja kwa moja';

  @override
  String get onlineLiveLocation => 'Mtandaoni · eneo la moja kwa moja';

  @override
  String get account => 'Akaunti';

  @override
  String get search => 'Tafuta';

  @override
  String get demoAccounts => 'Akaunti za Onyesho';

  @override
  String get tryOutApp =>
      'Jaribu programu mara moja kwa kutumia akaunti ya onyesho.';

  @override
  String get myLocation => 'Eneo Langu';

  @override
  String get useGps => 'Tumia GPS';

  @override
  String get useSavedLocation => 'Tumia eneo lililohifadhiwa';

  @override
  String distanceAway(String distance) {
    return '$distance km mbali';
  }

  @override
  String get verificationRequired => 'Uthibitisho wa akaunti unahitajika';

  @override
  String get verificationMessage =>
      'Tafadhali angalia barua pepe yako na uthibitishe akaunti yako kabla ya kuendelea.';

  @override
  String get verifyNow => 'Thibitisha Sasa';

  @override
  String get noNotificationsYet => 'Bado hakuna arifa';

  @override
  String get noNotificationsSubtitle => 'Tutakujulisha kitu kitakachotokea.';

  @override
  String get noWishlistItems => 'Orodha yako ya matumaini ni tupu';

  @override
  String get noWishlistSubtitle =>
      'Gusa moyo kwenye zabuni yoyote ya samaki kuihifadhi hapa.';

  @override
  String get noActiveRequests => 'Hakuna maombi hai ya samaki';

  @override
  String get noActiveRequestsSubtitle =>
      'Utapoweka ombi la samaki, litaonekana hapa.';

  @override
  String get noListings => 'Bado hakuna zabuni';

  @override
  String get noListingsSubtitle =>
      'Gusa kitufe cha + kuongeza zabuni yako ya kwanza.';

  @override
  String get noOrders => 'Bado hakuna maagizo';

  @override
  String get noOrdersSubtitle =>
      'Utakaponunua au kuuza samaki, maagizo yataonekana hapa.';

  @override
  String get offlineState => 'Muuzaji huyu kwa sasa yuko nje ya mtandao';

  @override
  String kmAway(String km) {
    return '$km km mbali';
  }

  @override
  String get selectLanguageTitle => 'Chagua Lugha';

  @override
  String get selectLanguageDescription =>
      'Programu nzima itabadilika mara moja. Chaguo lako linawekwa kwenye kifaa hiki.';

  @override
  String get languageSaved => 'Lugha imehifadhiwa';

  @override
  String get settingsSaved => 'Mipango imehifadhiwa';

  @override
  String changeFailed(String setting, String error) {
    return 'Imeshindwa kubadilisha $setting: $error';
  }

  @override
  String get commonError => 'Kitu kilienda vibaya';

  @override
  String get tryAgain => 'Jaribu tena';

  @override
  String get personalInformation => 'Maelezo ya Kibinafsi';

  @override
  String get editListing => 'Hariri Zabuni';

  @override
  String get logoutConfirmationMessage =>
      'Utarudishwa kwenye skrini ya kuingia.';

  @override
  String get km => 'km';

  @override
  String get reorder => 'Agiza tena';

  @override
  String get leaveReview => 'Toa tathmini';

  @override
  String get shareListing => 'Shiriki zabuni';

  @override
  String get reportListing => 'Ripoti zabuni';

  @override
  String get deleteListingConfirmation =>
      'Futa zabuni hii? Hii haiwezi kubatilishwa.';

  @override
  String get markAsSold => 'Weka alama ya kuuza';

  @override
  String get soldConfirmation => 'Weka alama ya kuuza kwenye zabuni hii?';

  @override
  String get filter => 'Chuja';

  @override
  String get sortBy => 'Panga kwa';

  @override
  String get newestFirst => 'Mpya kwanza';

  @override
  String get priceLowToHigh => 'Bei: Chini hadi juu';

  @override
  String get priceHighToLow => 'Bei: Juu hadi chini';

  @override
  String get apply => 'Tumia';

  @override
  String get clearAll => 'Futa yote';

  @override
  String get results => 'Matokeo';

  @override
  String get noResults => 'Hakuna matokeo';

  @override
  String get selectLocation => 'Chagua eneo';

  @override
  String get useMyLocation => 'Tumia eneo langu';

  @override
  String get savedLocations => 'Maeneo yaliyohifadhiwa';

  @override
  String get loadingLocation => 'Inapakia eneo lako...';

  @override
  String get couldNotGetLocation => 'Imeshindwa kupata eneo lako';

  @override
  String get permissionDenied => 'Ruhusa ya eneo imekataliwa';

  @override
  String get openSettings => 'Fungua Mipango';

  @override
  String get loadingMore => 'Inapakia zaidi...';

  @override
  String get seeAll => 'Ona zote';

  @override
  String get viewMore => 'Ona zaidi';

  @override
  String get filterByType => 'Chuja kwa aina ya samaki';

  @override
  String distanceFromYou(Object distance) {
    return '$distance km kutoka kwako';
  }

  @override
  String get selectRadius => 'Chagua eneo la utafutaji';

  @override
  String get showingNearest => 'Inaonyesha wauzaji wa karibu tu';

  @override
  String get languagePreference => 'Lugha unayopendelea';

  @override
  String get themePreference => 'Muonekano unaoupendelea';

  @override
  String get changed => 'Imebadilishwa';

  @override
  String get featureComingSoon => 'Inakuja hivi karibuni';

  @override
  String get noDataYet => 'Hakuna data bado';

  @override
  String get refresh => 'Onyesha upya';

  @override
  String get pullToRefresh => 'Vuta chini kuonyesha upya';

  @override
  String get verifyAccount => 'Thibitisha akaunti yako';

  @override
  String get resendEmail => 'Tuma tena barua ya uthibitisho';

  @override
  String get verificationEmailSent => 'Barua ya uthibitisho imetumwa';

  @override
  String get tapToUse => 'Gusa kutumia';

  @override
  String get selectImage => 'Chagua picha';

  @override
  String get fromCamera => 'Kutoka kamerasi';

  @override
  String get fromGallery => 'Kutoka kwenye mkusanyiko';

  @override
  String get changePhoto => 'Badilisha picha';

  @override
  String get reviewInformation => 'Kagua maelezo yako';

  @override
  String get totalListings => 'Zabuni zote';

  @override
  String get totalOrders => 'Maagizo yote';

  @override
  String get accountInfo => 'Maelezo ya akaunti';

  @override
  String get phone => 'Simu';

  @override
  String get street => 'Mtaa';

  @override
  String get region => 'Mkoa';

  @override
  String get market => 'Soko';

  @override
  String get buyersAvailable => 'Wanunuzi waliopo';

  @override
  String sellersNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wauzaji $count karibu',
      one: 'Muuzaji 1 karibu',
      zero: 'Hakuna wauzaji karibu',
    );
    return '$_temp0';
  }

  @override
  String get receiving => 'Inapokea';

  @override
  String get ready => 'Tayari';

  @override
  String get inTransit => 'Njiani';

  @override
  String get delivered => 'Imefika';

  @override
  String get cancelled => 'Imeghairiwa';

  @override
  String get pending => 'Inasubiri';

  @override
  String get completed => 'Imekamilika';

  @override
  String get buyer => 'Mnunuzi';

  @override
  String get seller => 'Muuzaji';

  @override
  String get quantityKg => 'Kiasi';

  @override
  String get perKg => '/ kg';

  @override
  String get noReviews => 'Hakuna tathmini bado';

  @override
  String get seeAllReviews => 'Ona tathmini zote';

  @override
  String get verified => 'Imethibitishwa';

  @override
  String get notVerified => 'Haijathibitishwa';

  @override
  String get ratings => 'Alama';

  @override
  String get reviews => 'Tathmini';

  @override
  String get orderDetails => 'Maelezo ya Agizo';

  @override
  String get deliveryAddress => 'Anwani ya uwasilishaji';

  @override
  String get deliveryTime => 'Wakati wa uwasilishaji';

  @override
  String get yourOrders => 'Maagizo yako';

  @override
  String get buyerType => 'Aina ya mnunuzi';

  @override
  String get transport => 'Usafirishaji';

  @override
  String get individualHousehold => 'Mtu binafsi/Kaya';

  @override
  String get restaurant => 'Mgahawa';

  @override
  String get hotel => 'Hoteli';

  @override
  String get retail => 'Duka';

  @override
  String get morning => 'Asubuhi';

  @override
  String get afternoon => 'Mchana';

  @override
  String get evening => 'Jioni';

  @override
  String get anytime => 'Wakati wowote';

  @override
  String get fullAddress => 'Anwani kamili';

  @override
  String get city => 'Jiji';

  @override
  String get country => 'Nchi';

  @override
  String get profilePhoto => 'Picha ya wasifu';

  @override
  String get equipmentPhoto => 'Picha ya vifaa';

  @override
  String get selectPhotos => 'Chagua hadi picha 5';

  @override
  String get tapToAdd => 'Gusa kuongeza';

  @override
  String get enterAddress => 'Weka anwani';

  @override
  String get enterCity => 'Weka jiji';

  @override
  String get enterRegion => 'Weka mkoa';

  @override
  String get addListing => 'Ongeza zabuni';

  @override
  String get deleteListing => 'Futa zabuni';

  @override
  String get markSold => 'Weka alama ya kuuza';

  @override
  String get shareLocation => 'Shiriki eneo';

  @override
  String get goOnline => 'Nenda mtandaoni';

  @override
  String get goOffline => 'Toka mtandaoni';

  @override
  String get startingLocation => 'Inaanza eneo...';

  @override
  String get shareLocationToggle => 'Shiriki eneo lako';

  @override
  String get shareLocationSubtitle => 'Wanunuzi wakaona kwenye ramani';

  @override
  String get onlineStatus => 'Hali ya mtandao';

  @override
  String get onlineNow => 'Uko mtandaoni';

  @override
  String get offlineNow => 'Uko nje ya mtandao';

  @override
  String get sellerProfile => 'Wasifu wa muuzaji';

  @override
  String activeListingsCount(Object count) {
    return 'Hai: $count';
  }

  @override
  String ratingValue(Object rating) {
    return 'Alama $rating';
  }

  @override
  String lastSeenMinutesAgo(Object minutes) {
    return 'Alionekana dakika $minutes zilizopita';
  }

  @override
  String lastSeenHoursAgo(Object hours) {
    return 'Alionekana masaa $hours yaliyopita';
  }

  @override
  String lastSeenDaysAgo(Object days) {
    return 'Alionekana siku $days zilizopita';
  }

  @override
  String get justNow => 'Sasa hivi';

  @override
  String get call => 'Piga simu';

  @override
  String get message => 'Ujumbe';

  @override
  String get directions => 'Maelekezo';

  @override
  String get send => 'Tuma';

  @override
  String get messageSeller => 'Tuma ujumbe kwa muuzaji';

  @override
  String get typeMessage => 'Andika ujumbe';

  @override
  String get onlineDot => 'Mtandaoni';

  @override
  String get verifiedBadge => 'Imethibitishwa';

  @override
  String get you => 'Wewe';

  @override
  String get buyerName => 'Jina la mnunuzi';

  @override
  String get sellerName => 'Jina la muuzaji';

  @override
  String get orders => 'Maagizo';

  @override
  String get filters => 'Vichujio';

  @override
  String get allTypes => 'Aina zote';

  @override
  String get noOrdersYetTitle => 'Bado hakuna maagizo';

  @override
  String get loadingOrders => 'Inapakia maagizo...';

  @override
  String orderId(String id) {
    return 'Agizo #$id';
  }

  @override
  String get markAsCompleted => 'Weka alama ya kukamilika';

  @override
  String get cancelOrderConfirmation => 'Ghairi agizi hili?';

  @override
  String get acceptOrder => 'Kubali agizo';

  @override
  String get confirmOrder => 'Thibitisha agizo';

  @override
  String get rejectOrder => 'Kataa agizo';

  @override
  String get trackOrder => 'Fuatilia agizo';

  @override
  String get orderItems => 'Vitu vya agizo';

  @override
  String get delivery => 'Uwasilishaji';

  @override
  String quantityShortKg(String qty) {
    return '$qty kg';
  }

  @override
  String totalKg(String qty) {
    return '$qty kg jumla';
  }

  @override
  String buyerOrderedItems(String buyer, String qty) {
    return '$buyer aliagiza $qty kg';
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
  String get setMyLocation => 'Weka eneo langu';

  @override
  String get switchToLightTheme => 'Badilisha kwenye mwanga';

  @override
  String get switchToDarkTheme => 'Badilisha kwenye giza';

  @override
  String get platformOverview => 'Muhtasari wa Jukwaa & Usimamizi';

  @override
  String get totalUsers => 'Watumiaji Wote';

  @override
  String get ordersToday => 'Maagizo ya Leo';

  @override
  String get platformRevenue => 'Mapato ya Jukwaa';

  @override
  String get management => 'Usimamizi';

  @override
  String get manageDalalis => 'Simamia Dalalis';

  @override
  String get manageDalalisSubtitle => 'Sajili, kubali au zuia mabrokeri';

  @override
  String get allListings => 'Zabuni Zote';

  @override
  String get allListingsSubtitle => 'Kagua na simamia soko';

  @override
  String get transactions => 'Miamala';

  @override
  String get transactionsSubtitle => 'Ona historia ya malipo';

  @override
  String hello(String name) {
    return 'Habari, $name!';
  }

  @override
  String get manageStreetSellers => 'Simamia Wauzaji wa Barabarani';

  @override
  String get manageStreetSellersSubtitle =>
      'Kubali, kagua au zuia wauzaji kwenye jukwaa';

  @override
  String get noStreetSellers =>
      'Bado hakuna wauzaji wa barabarani waliosajiliwa';

  @override
  String get noStreetSellersSubtitle =>
      'Wauzaji wanaposajili, wataonekana hapa kwa ukaguzi.';

  @override
  String get viewProfile => 'Ona wasifu';

  @override
  String get blockUser => 'Zuia';

  @override
  String get unblockUser => 'Ondolea kuzuia';

  @override
  String get userBlocked => 'Mtumiaji amezuiwa';

  @override
  String get userUnblocked => 'Kuzuia kumeondolewa';

  @override
  String get confirmBlockUser =>
      'Zuia muuzaji huyu? Hataweza kuingia hadi uondoe kizuizi.';

  @override
  String get adminAllListingsSubtitle => 'Kagua zabuni zote kwenye soko';

  @override
  String get noListingsFound => 'Hakuna zabuni zilizopatikana';

  @override
  String get noListingsFoundSubtitle =>
      'Wanunuzi au wauzaji wanapounda zabuni, zitaonekana hapa.';

  @override
  String get deleteListingConfirmationAdmin =>
      'Futa kabisa zabuni hii? Hii haiwezi kubatilishwa.';

  @override
  String get listingDeleted => 'Zabuni imefutwa';

  @override
  String listingsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zabuni $count zimefutwa',
      one: 'Zabuni 1 imefutwa',
      zero: 'Hakuna zabuni zilizofutwa',
    );
    return '$_temp0';
  }

  @override
  String get selectMode => 'Chagua';

  @override
  String get exitSelectMode => 'Toka kwenye uteuzi';

  @override
  String get selectAll => 'Chagua zote';

  @override
  String get deselectAll => 'Ondoa uteuzi wote';

  @override
  String get deleteSelected => 'Futa zilizochaguliwa';

  @override
  String deleteListingsConfirmationAdmin(int count) {
    return 'Futa kabisa zabuni $count? Hii haiwezi kubatilishwa.';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zimechaguliwa $count',
      one: '1 imechaguliwa',
      zero: 'Hakuna iliyochaguliwa',
    );
    return '$_temp0';
  }

  @override
  String get notificationsSection => 'Arifa';

  @override
  String get notificationsSubtitle => 'Chagua arifa zipi unazipokea';

  @override
  String get notificationsPush => 'Arifa za papo hapo';

  @override
  String get notificationsPushSubtitle => 'Onyesha arifa kwenye kifaa hiki';

  @override
  String get notificationsEmail => 'Arifa za barua pepe';

  @override
  String get notificationsEmailSubtitle => 'Pokea masasisho kwa barua pepe';

  @override
  String get notificationsOrderUpdates => 'Masasisho ya maagizo';

  @override
  String get notificationsOrderUpdatesSubtitle =>
      'Mabadiliko ya hali ya maagizo yako';

  @override
  String get notificationsPromotions => 'Matangazo na vidokezo';

  @override
  String get notificationsPromotionsSubtitle => 'Mara kwa mara, habari za soko';

  @override
  String get privacySection => 'Faragha';

  @override
  String get privacySubtitle => 'Dhibiti watumiaji wengine wanaona nini';

  @override
  String get privacyShowOnlineStatus => 'Onyesha hali yangu ya mtandaoni';

  @override
  String get privacyShowOnlineStatusSubtitle =>
      'Wanunuzi na wauzaji wanaona unapokuwa live';

  @override
  String get privacyShowLocation => 'Shiriki eneo langu';

  @override
  String get privacyShowLocationSubtitle =>
      'Inasaidia wanunuzi kukupata kwenye ramani';

  @override
  String get aboutSection => 'Kuhusu';

  @override
  String get aboutSubtitle => 'Taarifa za programu na sifa';

  @override
  String get aboutAppVersion => 'Toleo';

  @override
  String get aboutViewLicenses => 'Leseni za chanzo wazi';

  @override
  String get aboutViewLicensesSubtitle =>
      'Ona matangazo ya maktaba za wahusika wengine';

  @override
  String get aboutPrivacyPolicy => 'Sera ya faragha';

  @override
  String get aboutPrivacyPolicySubtitle => 'Jinsi tunavyoshughulikia data yako';

  @override
  String get aboutTermsOfService => 'Masharti ya huduma';

  @override
  String get aboutTermsOfServiceSubtitle =>
      'Kanuni za kutumia Samaki Fresh Connect';

  @override
  String get comingSoon => 'Inakuja hivi karibuni';

  @override
  String get appearanceLiveHint =>
      'Uchaguzi wako unatumika papo hapo kwenye kila skrini na kuhifadhiwa kwa wakati ujao.';

  @override
  String get transactionsTitle => 'Miamala';

  @override
  String get transactionsScreenSubtitle =>
      'Maagizo yote yaliyowekwa kwenye jukwaa';

  @override
  String get noTransactions => 'Bado hakuna miamala';

  @override
  String get noTransactionsSubtitle =>
      'Wanunuzi wanapoagiza, yataonekana hapa.';

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
      other: 'Maagizo $count',
      one: 'Agizo 1',
      zero: 'Hakuna maagizo',
    );
    return '$_temp0';
  }
}
