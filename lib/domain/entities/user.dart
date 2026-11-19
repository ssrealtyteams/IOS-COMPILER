import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.orgId,
    required this.role,
    this.email,
    this.avatarUrl,
    this.employeeId,
    this.isActive = true,
    this.isRemoteAllowed = false,
    this.isExecutive = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final String orgId;
  final UserRole role;
  final String? email;
  final String? avatarUrl;
  final String? employeeId;
  final bool isActive;
  final bool isRemoteAllowed;
  final bool isExecutive;

  String get initials {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'U';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      final w1 = words[0].characters.firstOrNull;
      final w2 = words[1].characters.firstOrNull;
      if (w1 != null && w2 != null) {
        return '$w1$w2'.toUpperCase();
      }
    }
    return clean.characters.first.toUpperCase();
  }

  bool get isAdmin => role == UserRole.admin || isExecutive;
  bool get isDirector => isExecutive || (email?.toLowerCase() == 'info@ssrealty.org') || (employeeId?.toUpperCase() == 'SSR000');
  bool get isManager => role == UserRole.manager || isAdmin;

  @override
  List<Object?> get props => [id, fullName, phone, role, isActive, isRemoteAllowed, isExecutive];

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'orgId': orgId,
        'role': role.toJson(),
        'email': email,
        'avatarUrl': avatarUrl,
        'employeeId': employeeId,
        'isActive': isActive,
        'isRemoteAllowed': isRemoteAllowed,
        'isExecutive': isExecutive,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.agent;
    final rStr = (json['role'] is String ? (json['role'] as String) : (json['role'] is Map ? (json['role']['slug'] ?? '') : '')).toLowerCase();
    
    if (rStr == 'admin' || rStr == 'super_admin' || rStr == 'director') {
      parsedRole = UserRole.admin;
    } else if (rStr == 'manager') {
      parsedRole = UserRole.manager;
    } else if (json['role'] is Map) {
      parsedRole = UserRole.fromJson(json['role'] as Map<String, dynamic>);
    } else {
      parsedRole = UserRole.agent;
    }

    final emailVal = json['email'] as String?;
    final empIdVal = json['employeeId'] as String? ?? json['employee_id'] as String?;

    final executiveAllowed = json['isExecutive'] == true ||
        json['isDirector'] == true ||
        rStr == 'director' ||
        rStr == 'super_admin' ||
        (emailVal?.toLowerCase() == 'info@ssrealty.org') ||
        (empIdVal?.toUpperCase() == 'SSR000');

    final remoteAllowed = executiveAllowed ||
        json['isRemoteAllowed'] == true ||
        json['allowRemotePunchIn'] == true ||
        json['remotePunchInAllowed'] == true ||
        json['isAgentRemoteExempted'] == true ||
        json['allowRemote'] == true ||
        json['isRemote'] == true;

    return User(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      orgId: json['orgId'] as String? ?? 'SSRealty',
      role: parsedRole,
      email: emailVal,
      avatarUrl: json['avatarUrl'] as String?,
      employeeId: empIdVal,
      isActive: json['isActive'] as bool? ?? true,
      isRemoteAllowed: remoteAllowed,
      isExecutive: executiveAllowed,
    );
  }
}

class UserRole {
  const UserRole({required this.name, required this.slug, required this.permissions});
  final String name;
  final String slug;
  final Map<String, bool> permissions;

  bool hasPermission(String permission) => permissions[permission] == true;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'permissions': permissions,
      };

  static const admin = UserRole(
    name: 'Admin',
    slug: 'admin',
    permissions: {'*': true},
  );

  static const manager = UserRole(
    name: 'Manager',
    slug: 'manager',
    permissions: {
      'leads.view.all': true,
      'leads.create': true,
      'leads.assign': true,
      'reports.all': true,
    },
  );

  static const agent = UserRole(
    name: 'Agent',
    slug: 'agent',
    permissions: {
      'leads.view.assigned': true,
      'calls.log': true,
      'reports.self': true,
    },
  );

  factory UserRole.fromJson(Map<String, dynamic> json) => UserRole(
        name: json['name'] as String,
        slug: json['slug'] as String,
        permissions: Map<String, bool>.from(json['permissions'] as Map? ?? {}),
      );
}
