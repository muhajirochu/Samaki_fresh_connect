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
  String get myListings => 'Orodha Zangu';

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
    return 'Habari,\n$name';
  }

  @override
  String hello(String name) {
    return 'Habari, $name!';
  }

  @override
  String get yourStreetSellingHub => 'Kituo chako cha kuuza barabarani';

  @override
  String buyerGreeting(String name) {
    return 'Habari,\n$name';
  }

  @override
  String get quickActions => 'Vitendo vya Haraka';

  @override
  String get noImage => 'Hakuna picha';

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
  String get editProfile => 'Hariri Wasifu';

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
  String get callSeller => 'Piga muuzaji';

  @override
  String get smsSeller => 'Tuma ujumbe kwa muuzaji';

  @override
  String get callFailed => 'Simu haipatikani — nambari imenakiliwa';

  @override
  String get smsFailed => 'Ujumbe haupatikani — nambari imenakiliwa';

  @override
  String get viewDetails => 'Ona Maelezo';

  @override
  String get trackSeller => 'Fuatilia muuzaji';

  @override
  String get sellersNearYou => 'Wauzaji karibu nawe';

  @override
  String get liveFishFromThisSeller => 'Samaki hai kutoka kwa muuzaji huyu';

  @override
  String get noFishPhotos => 'Hakuna picha za samaki bado';

  @override
  String get phoneCopied => 'Nambari ya simu imenakiliwa';

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
  String get editListing => 'Hariri Orodha';

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
  String get markAsSold => 'Tia alama kuwa imeuzwa';

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
  String distanceFromYou(String distance) {
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
  String get allListings => 'Zabuni Zote';

  @override
  String get allListingsSubtitle => 'Kagua na simamia soko';

  @override
  String get transactions => 'Miamala';

  @override
  String get transactionsSubtitle => 'Ona historia ya malipo';

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
  String get listingDeleted => 'Orodha imefutwa';

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
  String get appearanceLiveHint =>
      'Uchaguzi wako unatumika papo hapo kwenye kila skrini na kuhifadhiwa kwa wakati ujao.';

  @override
  String get adminDashboardSubtitle => 'Muhtasari wa jukwaa na usimamizi';

  @override
  String get totalSellers => 'Wauzaji wa barabarani wote';

  @override
  String get totalBuyers => 'Wanunuzi wote';

  @override
  String get pendingOrders => 'Maagizo yanayosubiri';

  @override
  String get completedOrders => 'Maagizo yaliyokamilika';

  @override
  String get cancelledOrders => 'Maagizo yaliyositishwa';

  @override
  String get recentActivity => 'Shughuli za hivi karibuni';

  @override
  String get manageBuyers => 'Simamia Wanunuzi';

  @override
  String get manageBuyersSubtitle => 'Simamisha au rejesha akaunti za wanunuzi';

  @override
  String get approveSeller => 'Kubali muuzaji';

  @override
  String get revokeApproval => 'Ondoa idhini';

  @override
  String get approvedBadge => 'Hai';

  @override
  String get pendingApprovalBadge => 'Inasubiri idhini';

  @override
  String get suspendedBadge => 'Imesimamishwa';

  @override
  String get suspendDialog => 'Simamisha mtumiaji';

  @override
  String get suspendReason => 'Sababu';

  @override
  String get reactivateUser => 'Anzisha tena';

  @override
  String get searchBy => 'Tafuta kwa jina, barua pepe au simu';

  @override
  String get searchSellers => 'Tafuta wauzaji';

  @override
  String get searchBuyers => 'Tafuta wanunuzi';

  @override
  String get filterAll => 'Wote';

  @override
  String get filterActive => 'Hai';

  @override
  String get noMatchingBuyers =>
      'Hakuna wanunuzi wanaolingana na utafutaji wako';

  @override
  String get userSuspended => 'Mnunuzi amesimamishwa';

  @override
  String get userReactivated => 'Mnunuzi ameanzishwa tena';

  @override
  String get userModerationFailed =>
      'Imeshindwa kusasisha mnunuzi huyu. Tafadhali jaribu tena.';

  @override
  String get listingDetails => 'Maelezo ya Orodha';

  @override
  String get notLoggedInSimple => 'Hujaingia';

  @override
  String get loadingFreshCatch => 'Inapakia samaki fresh...';

  @override
  String get loadingYourListings => 'Inapakia orodha zako...';

  @override
  String get loadingYourOrders => 'Inapakia maagizo yako...';

  @override
  String get failedToLoadListings => 'Imeshindwa kupakia orodha';

  @override
  String get failedToLoadOrders => 'Imeshindwa kupakia maagizo';

  @override
  String get failedToLoadUserData => 'Hitilafu kupakia data ya mtumiaji';

  @override
  String get noListingsYet => 'Hakuna Orodha Bado';

  @override
  String get createListingPrompt => 'Anza orodha ili kuuza samaki!';

  @override
  String get noOrdersYet => 'Hakuna Maagizo';

  @override
  String get orderTrackingExplanation =>
      'Ufuatiliaji wa maagizo ni kwa wanunuzi na wauzaji.';

  @override
  String get noOrdersFound => 'Hakuna Maagizo Yaliyopatikana';

  @override
  String get noOrdersPrompt => 'Bado hujafanya miamala yoyote.';

  @override
  String get show => 'Onyesha';

  @override
  String get hide => 'Ficha';

  @override
  String get deleteListingTitle => 'Futa orodha?';

  @override
  String deleteListingBody(String fishType, String quantity) {
    return 'Hii itafuta kabisa orodha ya $fishType ($quantity kg). Wanunuzi hawatakuona tena sokoni.';
  }

  @override
  String get deleteFailed => 'Kufuta kumeshindwa';

  @override
  String get listingUpdated => 'Orodha imesasishwa';

  @override
  String get updateFailed => 'Kusasisha kumeshindwa';

  @override
  String get markedAsSold => 'Imeuzwa';

  @override
  String get actionFailed => 'Kitendo kimeshindwa';

  @override
  String get noFishAvailable => 'Hakuna samaki wanaopatikana.';

  @override
  String get checkBackLater => 'Rudi baadaye kwa samaki fresh!';

  @override
  String get errorLoadingListing => 'Hitilafu kupakia orodha';

  @override
  String get errorLoadingOrder => 'Hitilafu kupakia agizo';

  @override
  String get listingNotFound => 'Orodha haikupatikana';

  @override
  String get listingMayBeRemoved => 'Orodha hii inaweza kuwa imeondolewa.';

  @override
  String get orderNotFound => 'Agizo halikupatikana';

  @override
  String get orderMayBeDeleted => 'Agizo hili linaweza kuwa limefutwa.';

  @override
  String couldNotLoadListing(String error) {
    return 'Imeshindwa kupakia orodha: $error';
  }

  @override
  String get orderPlacedSuccess => 'Agizo limewekwa!';

  @override
  String get orderPlacedSellerTitle => 'Agizo jipya limewekwa';

  @override
  String orderPlacedSellerBody(String name) {
    return '$name ameweka agizo kwenye orodha yako';
  }

  @override
  String get listingAlreadySold =>
      'Orodha hii haipatikani tena — mnunuzi mwingine amenunua samaki huyu.';

  @override
  String get profileUpdatedSuccess => 'Wasifu umesasishwa';

  @override
  String errorWithMessage(String message) {
    return 'Hitilafu: $message';
  }

  @override
  String get noRatingsYet => 'Bado hakuna tathmini';

  @override
  String reviewCount(int count) {
    return 'Tathmini $count';
  }

  @override
  String get manageListingTooltip => 'Simamia orodha';

  @override
  String get switchThemeTooltip => 'Badilisha mandhari';

  @override
  String get allSettingsTooltip => 'Mipangilio yote';

  @override
  String get searchOrders => 'Tafuta maagizo';

  @override
  String get manageCategories => 'Aina za Samaki';

  @override
  String get manageCategoriesSubtitle =>
      'Ongeza, hariri au futa aina za samaki';

  @override
  String get newCategory => 'Aina mpya';

  @override
  String get categoryName => 'Jina la kuonyesha';

  @override
  String get categorySlug => 'Kitambulisho';

  @override
  String get categoryActive => 'Hai';

  @override
  String get categoryInactive => 'Isiyotumika';

  @override
  String get seedDefaults => 'Weka chaguo-msingi';

  @override
  String get seedDefaultsHint => 'Weka aina saba za msingi za samaki';

  @override
  String get reportsTab => 'Ripoti';

  @override
  String get reportsSales => 'Ripoti ya mauzo';

  @override
  String get reportsOrders => 'Ripoti ya maagizo';

  @override
  String get reportsSellers => 'Ripoti ya wauzaji wa barabarani';

  @override
  String get reportsBuyers => 'Ripoti ya wanunuzi';

  @override
  String get reportsRevenue => 'Muhtasari wa mapato';

  @override
  String get thisWeek => 'Wiki hii';

  @override
  String get thisMonth => 'Mwezi huu';

  @override
  String get topSellers => 'Wauzaji bora';

  @override
  String get topBuyers => 'Wanunuzi bora';

  @override
  String get logsTitle => 'Kumbukumbu za Shughuli';

  @override
  String get logsSubtitle =>
      'Historia ya kuingia, usajili na vitendo vya admin';

  @override
  String get loginEvents => 'Kuingia';

  @override
  String get registrationEvents => 'Usajili';

  @override
  String get adminActions => 'Vitendo vya admin';

  @override
  String get disputeEvents => 'Mizozo';

  @override
  String get listingEvents => 'Zabuni';

  @override
  String get noLogsYet => 'Bado hakuna shughuli zilizorekodiwa';

  @override
  String get adminSettingsTitle => 'Mipango ya Admin';

  @override
  String get platformMaintenance => 'Hali ya matengenezo';

  @override
  String get platformMaintenanceSubtitle =>
      'Lemaza kuingia kwa wanunuzi na wauzaji kwa muda';

  @override
  String get refreshData => 'Onyesha upya data';

  @override
  String get refreshDataSubtitle => 'Batilisha cache ya admin na upake tena';

  @override
  String get dangerZone => 'Eneo hatari';

  @override
  String get disputeResolution => 'Utatuzi wa mizozo';

  @override
  String get disputeNote => 'Ujumbe wa admin';

  @override
  String get disputeNoteHint => 'Fupi eleza utatuzi';

  @override
  String get adminActionsSection => 'Vitendo vya admin';

  @override
  String get adminOnlySection => 'Zana za admin';

  @override
  String get viewOrderDetail => 'Ona agizo';

  @override
  String get statusAll => 'Zote';

  @override
  String get statusPending => 'Inasubiri';

  @override
  String get statusCompleted => 'Imekamilika';

  @override
  String get statusCancelled => 'Imeghairiwa';

  @override
  String get suspendUserAction => 'Simamisha mtumiaji';

  @override
  String get noBuyersRegistered => 'Bado hakuna wanunuzi waliosajiliwa';

  @override
  String get fishAvailableNearbyTile => 'Samaki\nKaribu';

  @override
  String get activeRequestsTile => 'Maombi\nHai';

  @override
  String get nearestSellerTile => 'Muuzaji\nwa Karibu';

  @override
  String get fishAvailableSubtitle => 'Hai karibu nawe';

  @override
  String get activeRequestsSubtitle => 'Maombi yaliyofunguliwa';

  @override
  String get nearestSellerSubtitle => 'Samaki wa karibu';

  @override
  String get dailySales => 'Mauzo ya leo';

  @override
  String get weeklySales => 'Mauzo ya wiki';

  @override
  String get monthlySales => 'Mauzo ya mwezi';

  @override
  String get appInfoAndCredits => 'Taarifa za programu na sifa';

  @override
  String get notificationsPreferences => 'Mapendeleo ya arifa';

  @override
  String get about => 'Kuhusu';

  @override
  String get aboutTitle => 'Kuhusu';

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

  @override
  String get goOnlineFailed => 'Imeshindwa kuwa online';

  @override
  String get dashboard => 'Dashibodi';

  @override
  String get myProducts => 'Bidhaa Zangu';

  @override
  String get messages => 'Ujumbe';

  @override
  String get cart => 'Kikapu';

  @override
  String get cartTitle => 'Kikapu Changu';

  @override
  String get cartEmptyTitle => 'Kikapu chako ni kitupu';

  @override
  String get cartEmptySubtitle =>
      'Tafuta samaki na uwaongeze kwenye kikapu ili uwaagize wote kwa pamoja.';

  @override
  String get cartBrowseFish => 'Tafuta samaki';

  @override
  String get cartTotal => 'Jumla';

  @override
  String get cartCheckout => 'Agiza sasa';

  @override
  String get cartClear => 'Futa kikapu';

  @override
  String get cartClearConfirmTitle => 'Futa kikapu?';

  @override
  String get cartClearConfirmBody =>
      'Hii itaondoa kila kitu kwenye kikapu chako. Haiwezi kurudishwa.';

  @override
  String get cartItemRemoved => 'Imeondolewa kwenye kikapu';

  @override
  String get cartAddedToCart => 'Imeongezwa kwenye kikapu';

  @override
  String get cartAlreadyInCart => 'Tayari ipo kwenye kikapu chako';

  @override
  String get addToCart => 'Weka kikapuni';

  @override
  String cartCheckoutSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maagizo $count yamewekwa',
      one: 'Agizo 1 limewekwa',
    );
    return '$_temp0';
  }

  @override
  String cartCheckoutPartial(int placed, int total) {
    return 'Vitu $placed kati ya $total vimeagizwa — vingine havipatikani tena';
  }

  @override
  String get cartCheckoutFailed =>
      'Imeshindwa kuweka agizo lako. Tafadhali jaribu tena.';

  @override
  String get cartUnavailable => 'Haipatikani tena';

  @override
  String cartPricePerKg(String price) {
    return '$price/kg';
  }

  @override
  String get contactsTitle => 'Ujumbe';

  @override
  String get contactsEmptyTitle => 'Bado hakuna wanunuzi';

  @override
  String get contactsEmptySubtitle =>
      'Mtu akikuagizia, ataonekana hapa ili uweze kumpigia simu au kumtumia ujumbe.';

  @override
  String contactsOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maagizo $count',
      one: 'Agizo 1',
    );
    return '$_temp0';
  }

  @override
  String get contactsCall => 'Piga simu';

  @override
  String get contactsSms => 'Tuma SMS';

  @override
  String get contactsNoPhone => 'Hakuna namba ya simu';

  @override
  String get contactsCallFailed => 'Imeshindwa kupiga simu';

  @override
  String get contactsSmsFailed => 'Imeshindwa kufungua ujumbe';

  @override
  String get buyerGreetingSubtitle => 'Pata samaki fresh karibu nawe';

  @override
  String get mapCtaTitle => 'Fungua Ramani';

  @override
  String get mapCtaSubtitle => 'Wauzaji karibu, njia, na muda unaotarajiwa';

  @override
  String get myRequestsTitle => 'Maombi Yangu';

  @override
  String get myRequestsEmpty => 'Hakuna maombi yanayoendelea';

  @override
  String myRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maombi $count yanayoendelea',
      one: 'Ombi 1 linaloendelea',
      zero: 'Hakuna maombi yanayoendelea',
    );
    return '$_temp0';
  }

  @override
  String get recentlyBoughtTitle => 'Iliyonunuliwa Hivi Karibuni';

  @override
  String get recentlyBoughtSubtitle =>
      'Rudi kwenye ununuzi wako wa hivi karibuni';

  @override
  String get recentlyBoughtChip => 'Iliyopita';

  @override
  String get popularNearYouTitle => 'Maarufu Karibu Nawe';

  @override
  String get popularNearYouSubtitle => 'Mapendekezo kwa eneo lako';

  @override
  String get popularNearYouEmpty =>
      'Mapendekezo yatapatikana hapa baada ya wauzaji kuchapisha samaki wengi karibu nawe.';

  @override
  String popularNearYouListings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maorodha $count',
      one: 'Orodha 1',
    );
    return '$_temp0';
  }

  @override
  String popularNearYouSold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Iliyouzwa $count',
      one: 'Iliyouzwa 1',
    );
    return '$_temp0';
  }

  @override
  String get popularNearYouFrom => 'Kuanzia';

  @override
  String orderFallbackName(String id) {
    return 'Orderi #$id';
  }

  @override
  String get sellersMapTitle => 'Ramani ya Wauzaji';

  @override
  String get showAllTypes => 'Onyesha aina zote';

  @override
  String get markAllAsRead => 'Weka zote zimesomwa';

  @override
  String get distanceLabel => 'Umbali';

  @override
  String get estimatedTimeLabel => 'Muda unaotarajiwa';

  @override
  String get trackDeliveryTitle => 'Fuatilia Uwasilishaji';

  @override
  String get locationNotAvailable => 'Hakuna taarifa za eneo';

  @override
  String get appDownloadTitle => 'Pakua Programu';

  @override
  String get appDownloadScanHeader => 'Skani ili Usakinishe';

  @override
  String get appDownloadScanHint =>
      'Elekeza kamera kwenye msimbo au gusa ili kuukuza.';

  @override
  String get appDownloadDirectUrlLabel => 'URL ya Pakua Moja kwa Moja:';

  @override
  String appDownloadDetectedYou(String platform) {
    return 'Imegunduliwa: $platform';
  }

  @override
  String appDownloadDownloadApk(String size) {
    return 'Pakua APK ($size)';
  }

  @override
  String get appDownloadInstallIos => 'Sakinisha kwenye iPhone';

  @override
  String get appDownloadInstallAndroid => 'Sakinisha kwenye Android';

  @override
  String get appDownloadManualHeader => 'Au sakinisha mwenyewe';

  @override
  String get appDownloadIosComingSoon =>
      'Inakuja hivi karibuni — mwaliko wa TestFlight utatolewa wakati wa uzinduzi.';

  @override
  String get appDownloadShareLink => 'Shiriki Kiungo cha Pakua';

  @override
  String get appDownloadCopyLink => 'Nakili Kiungo cha Pakua';

  @override
  String get appDownloadCopied => 'URL ya pakua imenakiliwa kwenye clipboard!';

  @override
  String get appDownloadSharedSuccess =>
      'Kiungo cha pakua kimeshirikiwa kikamilifu!';

  @override
  String get appDownloadShareFailed =>
      'Imeshindwa kushiriki. Badala yake kiungo kimenakiliwa kwenye clipboard.';

  @override
  String get appDownloadEnlargeQr => 'Kuza QR';

  @override
  String get appDownloadQrDialogTitle => 'Skani Msimbo wa QR';

  @override
  String get appDownloadQrDialogHelp =>
      'Elekeza kamera ya simu yoyote au skana ili kupakua';

  @override
  String get appDownloadPdfCard => 'Pakua Kadi ya Usakinishaji (PDF)';

  @override
  String get appDownloadPdfShare => 'Shiriki PDF';

  @override
  String get appDownloadPdfShareFailed => 'Imeshindwa kutengeneza PDF.';

  @override
  String get appDownloadPdfGenerating => 'Inatengeneza kadi ya usakinishaji…';

  @override
  String get appDownloadSpecsHeader => 'Vipimo vya Programu';

  @override
  String get appDownloadSpecsSubtitle => 'Maelezo ya kiufundi wa toleo hili';

  @override
  String get appDownloadSpecsPlatform => 'Jukwaa';

  @override
  String get appDownloadSpecsVersion => 'Toleo';

  @override
  String get appDownloadSpecsSize => 'Saizi ya Kifurushi';

  @override
  String get appDownloadSpecsOs => 'Ulinganifu wa OS';

  @override
  String get appDownloadSpecsRelease => 'Tarehe ya Kutolewa';

  @override
  String get appDownloadSpecsStatus => 'Hali';

  @override
  String get appDownloadSpecsPlatformAndroid => 'Android APK Moja kwa Moja';

  @override
  String get appDownloadSpecsPlatformIos => 'iOS TestFlight / Duka la Programu';

  @override
  String get appDownloadInstallGuide => 'Maelekezo ya Usakinishaji';

  @override
  String get appDownloadInstallGuideSubtitle =>
      'Sakinisha kwenye simu yako — hakuna USB wahiyo kusanidi.';

  @override
  String get appDownloadScanOrTap => 'Gusa ili kukuza kwa skrini nzima';

  @override
  String get appDownloadFooter => 'Mfumo wa SamakiFresh Connect © 2026';

  @override
  String get appDownloadShareSubject => 'Pakua SamakiFresh Connect';

  @override
  String appDownloadShareBody(String appName, String version, String url) {
    return 'Sakinisha SamakiFresh Connect — $appName $version. Skani msimbo wa QR au fungua kiungo hiki: $url';
  }

  @override
  String get appDownloadAndroidStepsTitle => 'Android';

  @override
  String get appDownloadIosStepsTitle => 'iPhone';

  @override
  String get appDownloadIosComingSoonSteps =>
      'Mwaliko wa TestFlight utatolewa wakati wa uzinduzi. Skani QR au rudi tena hivi karibuni.';

  @override
  String get confirmPickupCode => 'Thibitisha Namba (Pickup Code)';

  @override
  String yourCode(String code) {
    return 'Namba Yako: $code';
  }

  @override
  String get enterPickupCode => 'Ingiza namba ya uthibitisho (Code)';

  @override
  String get preConfirmationChecklistTitle =>
      'Thibitisha Upokeaji na Weka Maoni:';

  @override
  String get checkFishArrivedWell => 'Samaki wamefika vizuri?';

  @override
  String get checkQuantityQualityRight => 'Kiasi na ubora ni sahihi?';

  @override
  String get submitProofPhoto => 'Weka Picha ya Ushahidi (Hiari):';

  @override
  String get takePhoto => 'Piga Picha';

  @override
  String get chooseGallery => 'Chagua Galari';

  @override
  String get yourComment => 'Maoni Yako';

  @override
  String get yourCommentHint => 'Andika maoni au maelezo ya samaki hapa...';

  @override
  String get sending => 'Inatuma...';

  @override
  String get confirmAndSubmit => 'Thibitisha na Tuma kwa Admin';

  @override
  String get submitToAdmin => 'Tuma kwa Admin';

  @override
  String get adminWillReview =>
      'Admin atapitia maoni na picha kabla ya kuachilia malipo kwa muuzaji.';

  @override
  String get pleaseEnterCode => 'Tafadhali ingiza namba ya uthibitisho (code).';

  @override
  String get pleaseEnterComment =>
      'Tafadhali andika maoni yako kabla ya kuthibitisha.';

  @override
  String get incorrectCodeTryAgain =>
      'Namba sio sahihi. Tafadhali jaribu tena.';

  @override
  String get proofAndCommentSubmitted =>
      '✅ Maoni na ushahidi vimewasilishwa! Admin atapitia na kuachilia malipo.';

  @override
  String get errorSubmittingProof => 'Kuna tatizo wakati wa kutuma ushahidi.';

  @override
  String get buyerProofAndComment => 'Ushahidi na Maoni ya Mnunuzi:';

  @override
  String get sellerPendingApprovalMessage =>
      'Usajili wako umepokelewa kikamilifu! Akaunti yako ya muuzaji ipo kwenye mchakato wa kuhakikiwa na Admin wa SamakiFresh.\n\nHutaweza kuingiza samaki wapya, kuanzisha uuzaji wa live, wala kupokea oda hadi akaunti yako ithibitishwe na Admin.';

  @override
  String get awaitingAdminApprovalStatus => '⏳ INASUBIRI IDHINI YA ADMIN';

  @override
  String get awaitingAdminApprovalStatusMsg =>
      'Umewasilisha ushahidi na maoni yako. Admin anapitia taarifa zako ili kuachilia malipo kwa muuzaji.';

  @override
  String yourCommentQuoted(String comment) {
    return 'Maoni Yako: \"$comment\"';
  }

  @override
  String get sellerAwaitingAdminApprovalMsg =>
      'Mnunuzi amethibitisha na kutuma ushahidi. Pesa zitafunguliwa kwako mara tu Admin atakapoidhinisha.';

  @override
  String get startPreparingFish => 'Anza Kuandaa Samaki';

  @override
  String get generatePickupCode => 'Tengeneza Kodi & Tayari';

  @override
  String get startDelivery => 'Anza Kupeleka';

  @override
  String get verifyAndComplete => 'Thibitisha & Kamilisha';

  @override
  String get orderVerifiedSuccessfully => 'Oda imethibitishwa! Pesa zimetumwa.';

  @override
  String get invalidCodeTryAgain => 'Kodi si sahihi. Jaribu tena.';

  @override
  String get shareCodeWithSeller => 'Mpe muuzaji kodi hii...';

  @override
  String get platformCommission => 'Kamisheni ya Mtandao (5%):';

  @override
  String get sellerEarnings => 'Mapato ya Muuzaji (95%):';

  @override
  String get earningsTitle => 'Mapato';

  @override
  String get pendingPayout => 'Malipo Yanasubiri';

  @override
  String get checkingAccountStatus => 'Inakagua hali ya akaunti yako...';

  @override
  String get refreshAccountStatus => 'Kagua Hali ya Akaunti (Refresh)';

  @override
  String get statusPaid => '🔒 Imelipwa';

  @override
  String get statusConfirmed => 'Imekubaliwa';

  @override
  String get statusPreparing => 'Inaandaliwa';

  @override
  String get statusOnTheWay => 'Inakuja';

  @override
  String get statusDisputed => 'Kuna Mgogoro';

  @override
  String get orderNotSentPaymentUnverified =>
      'Maagizo hayakutumwa kwa sababu malipo hayajathibitishwa.';

  @override
  String get wishlistTitle => 'Orodha ya Matakwa';

  @override
  String errorPrefix(String error) {
    return 'Hitilafu: $error';
  }

  @override
  String get confirmReceived => 'Thibitisha Kupokea';

  @override
  String get confirmReceivedTitle => 'Thibitisha Kupokea Samaki';

  @override
  String get confirmReceivedBody =>
      'Je, umepokea samaki wako na unafurahia oda yako?';

  @override
  String get confirmReceivedWarning =>
      '⚠️ Baada ya kuthibitisha, pesa zitatolewa kwa muuzaji na haiwezekani kubatilishwa.';

  @override
  String get confirmYes => 'Ndio, Nimethibitisha';

  @override
  String get confirmNo => 'Hapana, Rudi';

  @override
  String get paymentHeld => '🔒 Malipo Yameshikiliwa kwa Usalama';

  @override
  String get paymentHeldSubtitle =>
      'Pesa zitatolewa kwa muuzaji tu baada ya wewe kuthibitisha kupokea samaki.';

  @override
  String get paymentReleased => '✅ Malipo Yametolewa';

  @override
  String get paymentReleasedSubtitle => 'Muuzaji amepata pesa zake.';

  @override
  String get orderCompletedTitle => 'Oda Imekamilika! 🎉';

  @override
  String get orderTotalLabel => 'Jumla ya Oda:';

  @override
  String get platformCommissionLabel => 'Kamisheni ya Mfumo (5%):';

  @override
  String get sellerEarningsLabel => 'Muuzaji Amepata (95%):';

  @override
  String get confirmingPayment => 'Inashughulikia...';

  @override
  String get paymentConfirmedSuccess =>
      'Asante! Oda imekamilika na pesa zimetumwa kwa muuzaji.';

  @override
  String get paymentConfirmError => 'Kuna hitilafu. Tafadhali jaribu tena.';

  @override
  String get waitingBuyerConfirmation => 'Inasubiri Uthibitisho wa Mnunuzi';

  @override
  String get waitingBuyerSubtitle =>
      'Mnunuzi atathibitisha kupokea samaki, na ndipo pesa zako zitatumwa.';

  @override
  String get yourPendingPayout => 'Mapato yako ya Kusubiri:';

  @override
  String get payoutReleasedTitle => '✅ Oda Imekamilika — Pesa Zimetumwa!';

  @override
  String get adminHeldTab => '🔒 Zimeshikiliwa';

  @override
  String get adminReleasedTab => '✅ Zimetolewa';

  @override
  String get adminPendingTab => '⏳ Zinasubiri';

  @override
  String get buyerConfirmed => 'Mnunuzi Amethibitisha';

  @override
  String get buyerNotYetConfirmed => 'Mnunuzi Hajathibitisha';

  @override
  String get paymentReference => 'Kumbukumbu:';

  @override
  String get allOrders => 'Zote';

  @override
  String get cancelOrderDialogTitle => 'Ghairi Oda?';

  @override
  String get cancelOrderDialogBody =>
      'Je, una uhakika unataka kughairi oda hii?';

  @override
  String get cancelOrderBtn => 'Ghairi Oda';

  @override
  String get orderCancelledSnackbar => 'Oda imeghairiwa';

  @override
  String get orderNewPrefix => 'MPYA';

  @override
  String get testPaymentTitle => 'Malipo ya Majaribio';

  @override
  String get testPaymentSubtitle =>
      'Jaribu mfumo wa malipo bila kukatwa pesa yoyote';

  @override
  String get selectPaymentMethod => 'Chagua Njia ya Malipo:';

  @override
  String get mobileNumberLabel => 'Namba ya Simu ya Majaribio';

  @override
  String get testPinLabel => 'PIN ya Majaribio (k.m. 1234)';

  @override
  String get testCardLabel => 'Namba ya Kadi ya Majaribio (4242...)';

  @override
  String get cashOnDelivery => 'Pesa Taslimu (Cash on Delivery)';

  @override
  String get cashOnDeliverySubtitle => 'Lipa muuzaji ukipokea samaki';

  @override
  String confirmTestPayment(String amount) {
    return 'Thibitisha Malipo ya Majaribio (TZS $amount)';
  }

  @override
  String get placeOrderCash => 'Weka Agizo (Pesa Taslimu)';

  @override
  String paymentHeldMessage(String ref) {
    return 'Malipo Yameshikiliwa! Thibitisha Kupokea Samaki. Ref: $ref';
  }

  @override
  String get orderReceivedCashMessage =>
      'Agizo Limepokelewa! Lipa muuzaji ukipokea samaki.';

  @override
  String get bankCardTest => 'Kadi ya Benki / Visa / Mastercard (Majaribio)';

  @override
  String paymentErrorPrefix(String error) {
    return 'Hitilafu ya malipo: $error';
  }

  @override
  String cartOrdersName(int count) {
    return 'Oda za Kikapu ($count)';
  }

  @override
  String get heldUntilConfirmation =>
      ' — Malipo yameshikiliwa hadi mnunuzi athibitishe kupokea.';

  @override
  String get wishlistEmptyText => 'Orodha yako ni tupu';

  @override
  String get wishlistEmptyTextSubtitle =>
      'Ukiongeza samaki unayotafuta, tutakuarifu mara itakapopatikana karibu nawe.';

  @override
  String get notifyWhenFound => 'Arifu utakapopata';

  @override
  String upToPrice(String price) {
    return 'Hadi TZS $price/kg';
  }

  @override
  String get selectFishLabel => 'Chagua Samaki';

  @override
  String get quantityKgLabel => 'Kiasi (kg)';

  @override
  String get enterQuantityHint => 'Weka kiasi';

  @override
  String get totalAmountLabel => 'Jumla ya Malipo:';

  @override
  String get additionalNotesLabel => 'Maelezo mengine';

  @override
  String get notesHint => 'Mfano: nataka fresh sana, nitalipia ukileta...';

  @override
  String forSeller(String name) {
    return 'Kwa: $name';
  }

  @override
  String get loginWelcomeBack => 'Karibu Tena';

  @override
  String get loginSignInContinue =>
      'Ingia ili kuendelea kwenye dashibodi yako.';

  @override
  String get loginEmailAddress => 'Barua pepe';

  @override
  String get loginPasswordHint => 'Nenosiri';

  @override
  String get loginForgotPassword => 'Umesahau nenosiri?';

  @override
  String get loginOrContinueWith => 'au endelea na';

  @override
  String get loginTagline => 'Samaki Wazuri  ·  Maisha Bora';

  @override
  String get trackPaymentRefunded => '💸 Malipo Yamerudishwa Kwako';

  @override
  String get trackPaymentHeld => '🔒 Malipo Yanahifadhiwa Salama';

  @override
  String get trackPaymentReleased => '✅ Malipo Yametolewa — Muuzaji Amelipwa';

  @override
  String get trackCommentsOptional => '📝 Maoni (Hiari)';

  @override
  String get trackProofPhotoOptional => '📷 Picha ya Uthibitisho (Hiari)';

  @override
  String get trackUploadingPhoto => 'Inapakia picha...';

  @override
  String get trackReceivedFishCorrect => '✅ Nimepokea Samaki — Oda Sahihi';

  @override
  String get trackIncorrectOrderReport => '⚠️ Oda Sio Sahihi — Ripoti Tatizo';

  @override
  String get trackConfirmReceipt => 'Thibitisha Mapokezi';

  @override
  String get trackConfirmReceiptMsg =>
      'Umepokea samaki wako na umeridhishwa na oda yako?';

  @override
  String get trackNoGoBack => 'Hapana, Rudi';

  @override
  String get trackYesIConfirm => 'Ndio, Nathibitisha';

  @override
  String get trackOrderCompletedMsg =>
      'Asante! Oda imekamilika na malipo yametolewa kwa muuzaji.';

  @override
  String get trackErrorOccurred => 'Kuna hitilafu. Tafadhali jaribu tena.';

  @override
  String get trackProvideCommentOrPhoto =>
      'Tafadhali andika maoni au pakia picha kuelezea tatizo.';

  @override
  String get trackReportIssueTitle => 'Ripoti Tatizo';

  @override
  String get trackSureOrderIncorrect => 'Una uhakika oda sio sahihi?';

  @override
  String get trackYesReportIssue => 'Ndio, Ripoti Tatizo';

  @override
  String get trackIssueReportedMsg =>
      'Tatizo lako limeripotiwa. Admin atapitia na kuwasiliana nawe hivi karibuni.';

  @override
  String get trackOrderCompletedTitle => 'Oda Imekamilika! 🎉';

  @override
  String get trackThankYouUsing => 'Asante kwa kutumia SamakiFresh Connect.';

  @override
  String get trackIssueReportedTitle =>
      '⚠️ Tatizo Limeripotiwa — Inasubiri Uhakiki wa Admin';

  @override
  String get trackFullRefundIssued => '💸 Marejesho Kamili Yametolewa';

  @override
  String get trackETA => 'Muda wa Kufika';

  @override
  String get trackContactSeller => 'Wasiliana na Muuzaji';

  @override
  String get trackReportReceivedMsg =>
      'Ripoti yako imepokelewa. Malipo yamehifadhiwa kusubiri utatuzi wa admin.';

  @override
  String trackRefundedToAccount(String amount) {
    return 'TZS $amount zimerudishwa kwenye akaunti yako.';
  }

  @override
  String get buyerNoActiveOrders => 'Hakuna oda zinazoendelea za kufuatilia';

  @override
  String relativeMinutes(int count) {
    return '$count dk';
  }

  @override
  String relativeHours(int count) {
    return '$count saa';
  }

  @override
  String relativeDays(int count) {
    return '$count siku';
  }

  @override
  String get sellerNoActiveDeliveries =>
      'Hakuna safari za uwasilishaji zinazoendelea';

  @override
  String get tabOverview => 'Muhtasari';

  @override
  String get tabSales => 'Mauzo';

  @override
  String get tabOrders => 'Oda';

  @override
  String get tabSellers => 'Wauzaji';

  @override
  String get tabBuyers => 'Wanunuzi';

  @override
  String get tabRevenue => 'Mapato';

  @override
  String get adminToday => 'Leo';

  @override
  String adminOrderCount(int count) {
    return 'Oda $count';
  }

  @override
  String get adminTotal => 'Jumla';

  @override
  String get adminNoBuyersYet => 'Hakuna wanunuzi bado';

  @override
  String get adminTabAll => 'Zote';

  @override
  String get adminTabHeld => '🔒 Zilizoshikiliwa';

  @override
  String get adminTabReleased => '✅ Zilizotolewa';

  @override
  String get adminTabPending => '⏳ Zinasubiri';

  @override
  String get adminTabDisputed => '⚠️ Migogoro';

  @override
  String get adminNoHeldPayments => 'Hakuna malipo yaliyoshikiliwa';

  @override
  String get adminNoReleasedPayouts => 'Hakuna malipo yaliyotolewa bado';

  @override
  String get adminNoPendingPayments => 'Hakuna malipo yanayosubiri';

  @override
  String get adminNoActiveDisputes => 'Hakuna migogoro inayoendelea';

  @override
  String get adminNoTransactions => 'Hakuna miamala iliyopatikana';

  @override
  String get adminStatusPending => 'INASUBIRI';

  @override
  String get adminStatusConfirmed => 'IMETHIBITISHWA';

  @override
  String get adminStatusPreparing => 'INATAYARISHWA';

  @override
  String get adminStatusReady => 'TAYARI';

  @override
  String get adminStatusOnTheWay => 'NJIANI';

  @override
  String get adminStatusCompleted => 'IMEKAMILIKA';

  @override
  String get adminStatusCancelled => 'IMEGHAIRIWA';

  @override
  String get adminStatusDisputed => 'MIGOGORO';

  @override
  String get adminRefundedBadge => '💸 IMERUDISHWA';

  @override
  String get adminPaidBadge => '💳 IMELIPWA';

  @override
  String get adminCashBadge => '💵 TASLIMU';

  @override
  String adminPayoutBadge(String status) {
    return 'MALIPO: $status';
  }

  @override
  String get adminBuyerConfirmedBadge => '✅ MNUNUZI AMETHIBITISHA';

  @override
  String get adminDisputeReportedBadge => '⚠️ MGOGORO UMERIPOTIWA';

  @override
  String get adminAwaitingConfirmationBadge => '⏳ INASUBIRI UTHIBITISHO';

  @override
  String get adminBuyerDisputeReview => 'Mapitio ya Mgogoro wa Mnunuzi';

  @override
  String adminComplaint(String comment) {
    return 'Lalamiko: \"$comment\"';
  }

  @override
  String get adminRefundBuyerBtn => '💸 Mjeshee Mnunuzi';

  @override
  String get adminApprovePayoutBtn => '✅ Idhinisha Malipo';

  @override
  String get adminOrderTotal => 'Jumla ya Oda:';

  @override
  String get adminPlatformCommission => 'Kamisheni ya Jukwaa (5%):';

  @override
  String get adminSellerEarnings => 'Mapato ya Muuzaji (95%):';

  @override
  String get adminApproveRefundTitle => 'Idhinisha Kurejesha Pesa?';

  @override
  String adminApproveRefundMsg(String amount, String orderId) {
    return 'Una uhakika unataka kumrejeshea mnunuzi TZS $amount kwa Oda #$orderId?\n\nHii itaghairi oda na kurejesha fedha.';
  }

  @override
  String get adminCancelBtn => 'Ghairi';

  @override
  String get adminConfirmRefundBtn => 'Thibitisha Kurejesha Pesa';

  @override
  String adminRefundApprovedMsg(String amount, String orderId) {
    return 'Urejesho wa TZS $amount umeidhinishwa kwa Oda #$orderId.';
  }

  @override
  String get adminApprovePayoutTitle => 'Idhinisha Malipo ya Muuzaji?';

  @override
  String adminApprovePayoutMsg(String amount) {
    return 'Una uhakika unataka kutatua mgogoro huu kwa kumpendelea muuzaji na kutoa TZS $amount?';
  }

  @override
  String get adminApprovePayoutConfirmBtn => 'Idhinisha Malipo';

  @override
  String adminPayoutReleasedMsg(String orderId) {
    return 'Malipo yametolewa kwa muuzaji kwa Oda #$orderId.';
  }

  @override
  String get adminEditCategory => 'Hariri kategoria';

  @override
  String adminCategorySlugHint(String name) {
    return 'mfano: $name';
  }

  @override
  String adminDeleteCategoryConfirm(String name) {
    return 'Futa moja kwa moja \"$name\"?';
  }

  @override
  String get settingsFeatureComingSoon =>
      'Kipengele hiki kinakuja hivi karibuni...';

  @override
  String get settingsBuyersOnly =>
      'Kipengele hiki ni kwa ajili ya wanunuzi pekee.';

  @override
  String get settingsChangePassword => 'Badili Nenosiri';

  @override
  String settingsResetPasswordPrompt(String email) {
    return 'Tuma barua pepe ya kubadili nenosiri kwenda:\\n$email?';
  }

  @override
  String get settingsEmailSent => 'Barua pepe imetumwa kikamilifu.';

  @override
  String get settingsError => 'Kuna hitilafu. Tafadhali jaribu tena.';

  @override
  String get settingsSend => 'Tuma';

  @override
  String get settingsFaceIdEnabled => 'Face ID imewashwa kwa mafanikio.';

  @override
  String get actionEditListingDesc => 'Sasisha bei, kiasi au maelezo';

  @override
  String get alreadySold => 'Imeuzwa tayari';

  @override
  String get actionDeactivateListingDesc => 'Ficha kutoka sokoni';

  @override
  String get actionDeleteListingDesc => 'Ondoa bidhaa hii kabisa';

  @override
  String get orderNotSentPaymentFailed =>
      'Ombi halikutumwa kwa sababu malipo hayajathibitishwa.';
}
