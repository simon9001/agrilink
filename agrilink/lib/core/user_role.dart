enum UserRole {
  FARMER('Farmer'),
  BUYER('Buyer'),
  SUPPLIER('Supplier'),
  EXPERT('Expert'),
  ADMIN('Admin');

  const UserRole(this.displayName);

  final String displayName;

  // Convert from old roles to new roles (migration mapping)
  static UserRole fromLegacyRole(String legacyRole) {
    switch (legacyRole.toLowerCase()) {
      case 'farmer':
        return UserRole.FARMER;
      case 'veterinarian':
        return UserRole.EXPERT;
      case 'company':
        return UserRole.SUPPLIER;
      case 'buyer/trader':
      case 'buyer':
        return UserRole.BUYER;
      default:
        return UserRole.FARMER; // Default fallback
    }
  }

  // Get route for dashboard based on role
  String get dashboardRoute() {
    switch (this) {
      case UserRole.FARMER:
        return '/dashboard/farmer';
      case UserRole.BUYER:
        return '/dashboard/buyer';
      case UserRole.SUPPLIER:
        return '/dashboard/supplier';
      case UserRole.EXPERT:
        return '/dashboard/expert';
      case UserRole.ADMIN:
        return '/dashboard/admin';
    }
  }
}

class UserData {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? profilePicture;
  final bool isVerified;
  final Map<String, dynamic>? profileData;

  UserData({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePicture,
    this.isVerified = false,
    this.profileData,
  });

  String get fullName => '$firstName $lastName';

  factory UserData.fromMap(Map<String, dynamic> map) {
    // Handle role mapping from legacy system
    String roleString = map['role'] ?? 'FARMER';
    UserRole role = UserRole.fromLegacyRole(roleString);

    return UserData(
      id: map['id']?.toString() ?? '',
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      role: role,
      profilePicture: map['profile_picture'],
      isVerified: map['is_verified'] ?? false,
      profileData: map['profile_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.displayName,
      'profile_picture': profilePicture,
      'is_verified': isVerified,
      'profile_data': profileData,
    };
  }
}