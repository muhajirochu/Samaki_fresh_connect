// User data flow test — verifies that the user data stream
// updates when the signed-in user changes. This is the test we
// run when the user reports "I can't fetch user data" or
// "the dashboard shows the wrong user".

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/services/user_service.dart';

UserModel _makeUser({
  required String id,
  required String email,
  required String name,
  required UserRole role,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    userId: id,
    email: email,
    fullName: name,
    phoneNumber: '+255700000000',
    role: role,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeUserService extends UserService {
  @override
  Stream<UserModel?> userStream(String uid) {
    return Stream.value(mockUser);
  }
}

void main() {
  // Reset the global mock user before AND after each test so the
  // suite is fully isolated.
  tearDown(() => setMockUser(null));

  test(
    'currentUserStreamProvider — reads from mockUser when set',
    () async {
      setMockUser(_makeUser(
        id: 'admin-1',
        email: 'admin@samakifresh.com',
        name: 'Admin User',
        role: UserRole.admin,
      ));

      final container = ProviderContainer(
        overrides: [
          userServiceProvider.overrideWith(
            (ref) => _FakeUserService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(currentUserStreamProvider.future);
      expect(user, isNotNull);
      expect(user!.userId, 'admin-1');
      expect(user.role, UserRole.admin);
    },
  );

  test(
    'currentUserStreamProvider — flips when mockUser changes',
    () async {
      setMockUser(_makeUser(
        id: 'admin-1',
        email: 'admin@samakifresh.com',
        name: 'Admin User',
        role: UserRole.admin,
      ));
      final container = ProviderContainer(
        overrides: [
          userServiceProvider.overrideWith(
            (ref) => _FakeUserService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final first = await container.read(currentUserStreamProvider.future);
      expect(first!.userId, 'admin-1');

      // Switch mockUser to a buyer.
      setMockUser(_makeUser(
        id: 'buyer-1',
        email: 'buyer@samakifresh.com',
        name: 'Buyer User',
        role: UserRole.buyer,
      ));
      // Invalidate the cached stream so the next read returns the
      // freshly-built stream with the new mockUser.
      container.invalidate(currentUserStreamProvider);
      // Reading the provider again should give us the new user.
      final second = await container.read(currentUserStreamProvider.future);
      expect(second!.userId, 'buyer-1');
      expect(second.role, UserRole.buyer);
    },
  );
}