import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/providers/listing_provider.dart';
import 'package:samakifresh_connect/screens/buyer/buyer_seller_tracking_screen.dart';

void main() {
  testWidgets('renders seller name and at least one fish photo card',
      (tester) async {
    const sellerId = 'seller-001';
    final seller = UserModel(
      userId: sellerId,
      email: 'fatma@example.com',
      fullName: 'Fatma Tuna Specialist',
      phoneNumber: '+255770000001',
      role: UserRole.streetSeller,
      location: const {
        'regionName': 'Mjini Magharibi',
        'marketName': 'Stone Town',
      },
      isActive: true,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );
    final listing = FishListingModel(
      listingId: 'listing-1',
      sellerId: sellerId,
      fishType: 'Tuna',
      quantityKg: 5,
      pricePerKg: 12000,
      totalPrice: 60000,
      imageUrls: const ['https://example.com/tuna.jpg'],
      status: 'active',
      createdAt: DateTime(2026, 7, 1),
      expiresAt: DateTime(2026, 7, 2),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userModelStreamProvider(sellerId)
              .overrideWith((ref) => Stream.value(seller)),
          sellerListingsProvider(sellerId)
              .overrideWith((ref) => Stream.value([listing])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: BuyerSellerTrackingScreen(sellerId: 'seller-001'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Fatma Tuna Specialist'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('listing-1-https://example.com/tuna.jpg'),
      ),
      findsOneWidget,
    );
    expect(find.text('Tuna'), findsOneWidget);
  });
}
