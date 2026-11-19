import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class ContactService {
  static const MethodChannel _channel = MethodChannel('com.salescrm.dialer/contacts');
  static List<Contact> _cachedContacts = [];
  static final Map<String, String> _phoneToNameMap = {};
  static bool _isLoading = false;
  static bool _hasPermission = false;

  static List<Contact> get cachedContacts => List.unmodifiable(_cachedContacts);
  static bool get hasPermission => _hasPermission;
  static bool get isLoading => _isLoading;

  /// Requests permission and pre-loads contacts into memory
  static Future<bool> init() async {
    return await loadContacts();
  }

  /// Request contacts permission with dual-check (permission_handler + flutter_contacts)
  static Future<bool> requestPermission() async {
    try {
      var status = await ph.Permission.contacts.status;
      if (!status.isGranted) {
        status = await ph.Permission.contacts.request();
      }

      if (status.isGranted) {
        _hasPermission = true;
        return true;
      }

      // Secondary check with flutter_contacts internal permission handler
      final fcGranted = await FlutterContacts.permissions.request(PermissionType.read);
      _hasPermission = fcGranted == PermissionStatus.granted;
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Loads all contacts from device and populates fast lookup index
  static Future<bool> loadContacts({bool forceReload = false}) async {
    if (_isLoading) return _hasPermission;
    if (_cachedContacts.isNotEmpty && !forceReload) return true;

    _isLoading = true;
    try {
      final granted = await requestPermission();
      if (!granted) {
        _isLoading = false;
        return false;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      _cachedContacts = contacts.where((c) => c.phones.isNotEmpty).toList();
      _phoneToNameMap.clear();

      for (final contact in _cachedContacts) {
        final name = contact.displayName?.trim() ?? '';
        if (name.isEmpty) continue;

        for (final p in contact.phones) {
          final rawNumber = p.number;
          final cleanNumber = cleanPhone(rawNumber);
          if (cleanNumber.isNotEmpty) {
            _phoneToNameMap[cleanNumber] = name;
            // Also index last 10 digits for Indian standard numbers
            if (cleanNumber.length >= 10) {
              final last10 = cleanNumber.substring(cleanNumber.length - 10);
              _phoneToNameMap[last10] = name;
            }
          }
        }
      }

      debugPrint('✅ [ContactService] Loaded ${_cachedContacts.length} contacts (${_phoneToNameMap.length} indexed numbers)');
      _isLoading = false;
      return true;
    } catch (e) {
      debugPrint('❌ [ContactService] Error loading contacts: $e');
      _isLoading = false;
      return false;
    }
  }

  /// Strip special characters, spaces, hyphens from phone number
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Synchronous fast lookup of contact name by phone number
  static String? lookupContactName(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return null;
    final clean = cleanPhone(phoneNumber);
    if (clean.isEmpty) return null;

    // 1. Direct match
    if (_phoneToNameMap.containsKey(clean)) {
      return _phoneToNameMap[clean];
    }

    // 2. Last 10 digits match
    if (clean.length >= 10) {
      final last10 = clean.substring(clean.length - 10);
      if (_phoneToNameMap.containsKey(last10)) {
        return _phoneToNameMap[last10];
      }
    }

    // 3. Prefix/Suffix match
    for (final entry in _phoneToNameMap.entries) {
      if (entry.key.endsWith(clean) || clean.endsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Asynchronous lookup with Native Android PhoneLookup fallback
  static Future<String?> lookupContactNameAsync(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return null;

    // 1. Memory check
    final memoryName = lookupContactName(phoneNumber);
    if (memoryName != null && memoryName.isNotEmpty) {
      return memoryName;
    }

    // 2. Query Native Android PhoneLookup via ContactsContract
    try {
      final nativeName = await _channel.invokeMethod<String>('lookupContact', {
        'phoneNumber': phoneNumber,
      });

      if (nativeName != null && nativeName.trim().isNotEmpty) {
        final clean = cleanPhone(phoneNumber);
        _phoneToNameMap[clean] = nativeName.trim();
        if (clean.length >= 10) {
          _phoneToNameMap[clean.substring(clean.length - 10)] = nativeName.trim();
        }
        debugPrint('📞 [ContactService] Native PhoneLookup resolved $phoneNumber -> $nativeName');
        return nativeName.trim();
      }
    } catch (e) {
      debugPrint('Error in native contact lookup: $e');
    }

    return null;
  }

  /// Search contacts by query (name or phone number)
  static List<Contact> searchContacts(String query) {
    if (query.trim().isEmpty) return _cachedContacts;
    final qLower = query.toLowerCase().trim();
    final qClean = cleanPhone(query);

    return _cachedContacts.where((c) {
      final nameMatches = (c.displayName ?? '').toLowerCase().contains(qLower);
      if (nameMatches) return true;

      if (qClean.isNotEmpty) {
        for (final p in c.phones) {
          final pClean = cleanPhone(p.number);
          if (pClean.contains(qClean)) return true;
        }
      }
      return false;
    }).toList();
  }

  /// Save or update contact directly to device Phone Contacts book
  static Future<bool> saveOrUpdateContact(String name, String phoneNumber) async {
    final clean = cleanPhone(phoneNumber);
    final trimmedName = name.trim();
    if (clean.isEmpty || trimmedName.isEmpty) return false;

    // 1. Invoke Native Android ContactsPlugin
    try {
      final saved = await _channel.invokeMethod<bool>('saveContact', {
        'name': trimmedName,
        'phoneNumber': phoneNumber,
      });

      if (saved == true) {
        _phoneToNameMap[clean] = trimmedName;
        if (clean.length >= 10) {
          _phoneToNameMap[clean.substring(clean.length - 10)] = trimmedName;
        }
        debugPrint('✅ [ContactService] Saved contact to phonebook via Native: $trimmedName ($phoneNumber)');
        loadContacts(forceReload: true);
        return true;
      }
    } catch (e) {
      debugPrint('Native contact save error: $e');
    }

    // Fallback: update in-memory index
    _phoneToNameMap[clean] = trimmedName;
    if (clean.length >= 10) {
      _phoneToNameMap[clean.substring(clean.length - 10)] = trimmedName;
    }
    return true;
  }
}
