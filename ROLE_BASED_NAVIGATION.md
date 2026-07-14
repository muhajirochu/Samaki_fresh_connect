# Role-Based Navigation Guide

## Overview

The Samaki Fresh Connect app now implements role-based navigation that automatically routes users to their appropriate dashboard after login. Each user role has a custom dashboard with role-specific features and information.

## Supported Roles

1. **Buyer** → `/dashboard/buyer`
   - Browse and purchase fresh fish
   - View orders and favorites
   - Manage profile and preferences

2. **Fisherman** → `/dashboard/fisherman`
   - Create and manage fish listings
   - Track active listings and sales
   - Receive orders from buyers

3. **Street Seller (Dalali)** → `/dashboard/street_seller`
   - Manage daily sales inventory
   - Track sales reports and payments
   - Sell stock to customers

4. **Fish Broker (Dalali)** → `/dashboard/dalali`
   - Connect fishermen with buyers
   - Match deals and manage market rates
   - Build contacts and relationships

5. **Admin** → `/dashboard/buyer` (default for now)
   - Administrative dashboard (to be customized)

## Flow Diagram

```
App Launch
    ↓
Splash Screen
    ├─ Check Firebase Auth (currentUser)
    │
    ├─ User Logged In? 
    │  ├─ Yes → Fetch User Role from Firestore
    │  │         ↓
    │  │         Display appropriate dashboard
    │  │
    │  └─ No → Go to Welcome Screen
    │          ↓
    │          User navigates to Login
    │          ↓
    │          Enter credentials
    │          ↓
    │          Firebase Authentication
    │          ↓
    │          Fetch User Role from Firestore
    │          ↓
    │          Navigate to dashboard
```

## Implementation Details

### 1. Database Structure

User documents in Firestore (`users/{userId}`):

```json
{
  "userId": "user123",
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+255123456789",
  "role": "buyer",
  "profilePictureUrl": "https://...",
  "location": {
    "latitude": -6.1699,
    "longitude": 39.2025
  },
  "isActive": true,
  "registeredBy": "admin_id",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 2. Key Services

#### UserService (`lib/services/user_service.dart`)

- `fetchUserById(userId)` - Fetch user data with role from Firestore
- `saveUser(user)` - Save user data to Firestore
- `userStream(userId)` - Real-time user data updates
- `updateUserRole(userId, newRole)` - Change user role

#### AuthService (existing)

- `signIn(email, password)` - Firebase authentication
- `signUp(email, password, fullName)` - Create new account
- `signOut()` - Logout user
- `currentUser` - Get currently logged-in user

### 3. Riverpod Providers (`lib/providers/auth_provider.dart`)

```dart
// Get current Firebase user
final currentUserProvider = Provider<User?>((ref) { ... });

// Get current user's Firestore data with role
final currentUserDataProvider = FutureProvider<UserModel?>((ref) { ... });

// Get current user's role
final currentUserRoleProvider = FutureProvider<UserRole?>((ref) { ... });

// Watch real-time changes to current user
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) { ... });
```

### 4. Updated Components

#### Splash Screen (`lib/screens/auth/splash_screen.dart`)

- Checks if user is already authenticated
- Fetches user role from Firestore
- Routes to appropriate dashboard or welcome screen

#### Login Screen (`lib/screens/auth/login_screen.dart`)

- Now uses `AuthService` for Firebase authentication
- Fetches user role after successful login
- Routes to role-based dashboard

#### Routes (`lib/config/routes.dart`)

New dashboard routes:
- `/dashboard/buyer`
- `/dashboard/fisherman`
- `/dashboard/street_seller`
- `/dashboard/dalali`

### 5. Dashboard Screens

Each dashboard is in its own directory with role-specific UI:

```
lib/screens/
├── buyer/
│   └── buyer_dashboard_screen.dart
├── fisherman/
│   └── fisherman_dashboard_screen.dart
├── street_seller/
│   └── street_seller_dashboard_screen.dart
└── dalali/
    └── dalali_dashboard_screen.dart
```

## Usage Examples

### Navigate Based on Role (in Login)

```dart
// After successful login
final user = await authService.signIn(...);
if (user != null) {
  final userData = await userService.fetchUserById(user.uid);
  if (userData != null) {
    context.go(_getRouteForRole(userData.role));
  }
}
```

### Access Current User Role

```dart
// Using Riverpod Provider
final role = await ref.watch(currentUserRoleProvider.future);
```

### Stream User Data Changes

```dart
// Watch for real-time changes
ref.watch(currentUserStreamProvider).whenData((user) {
  if (user?.role != previousRole) {
    // Role changed, trigger navigation update
  }
});
```

### Fetch User Data in Splash

```dart
@override
void initState() {
  super.initState();
  _checkAuthAndNavigate();
}

Future<void> _checkAuthAndNavigate() async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser != null) {
    final userData = await ref.read(currentUserDataProvider.future);
    if (userData != null) {
      _navigateToDashboard(userData.role);
    }
  }
}
```

## Extending with New Roles

To add a new role:

1. **Update UserRole enum** (`lib/models/enums/user_role.dart`):
   ```dart
   enum UserRole { ..., newRole }
   ```

2. **Create dashboard screen** (`lib/screens/newrole/newrole_dashboard_screen.dart`)

3. **Update routes** (`lib/config/routes.dart`):
   ```dart
   GoRoute(
     path: '/dashboard/newrole',
     builder: (context, state) => const NewRoleDashboardScreen(),
   ),
   ```

4. **Update route mapping** in Login and Splash screens:
   ```dart
   case UserRole.newRole:
     return '/dashboard/newrole';
   ```

## Error Handling

The implementation includes error handling for:
- Missing user data in Firestore
- Failed authentication attempts
- Network errors during role fetch
- User role changes during session

## Future Enhancements

1. **Permission-based access** - Restrict dashboard access based on permissions
2. **Role switching** - Allow users to switch roles if multiple roles are assigned
3. **Custom dashboard layouts** - Different layouts for different screen sizes per role
4. **Role-specific features** - Dynamic feature toggles based on role
5. **Audit logging** - Track role changes and dashboard access

## Testing

To test role-based navigation:

1. Create test users with different roles in Firebase Console
2. Log in with each user role
3. Verify redirection to correct dashboard
4. Check Firestore data structure
5. Test role changes and real-time updates

## Support

For issues or questions about role-based navigation:
1. Check Firestore document structure
2. Verify user role value in database
3. Check provider state in DevTools
4. Review logs in Dart console
