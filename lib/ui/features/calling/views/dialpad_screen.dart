import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../view_models/call_view_model.dart';
import '../widgets/save_contact_before_call_sheet.dart';

class CustomDialpad extends StatefulWidget {
  const CustomDialpad({
    super.key,
    required this.callViewModel,
    this.initialNumber,
  });

  final CallViewModel callViewModel;
  final String? initialNumber;

  @override
  State<CustomDialpad> createState() => _CustomDialpadState();
}

class _CustomDialpadState extends State<CustomDialpad>
    with SingleTickerProviderStateMixin {
  String _number = '';
  late TabController _tabController;

  // Contacts state
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _contactsLoading = false;
  bool _contactsPermissionDenied = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _number = widget.initialNumber ?? '';
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((c) {
          final name = (c.displayName ?? '').toLowerCase();
          final phone = c.phones.isNotEmpty
              ? c.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '')
              : '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadContacts() async {
    setState(() {
      _contactsLoading = true;
      _contactsPermissionDenied = false;
    });

    try {
      final success = await ContactService.loadContacts(forceReload: true);
      if (success) {
        setState(() {
          _allContacts = ContactService.cachedContacts;
          _filteredContacts = _allContacts;
          _contactsLoading = false;
        });
      } else {
        setState(() {
          _contactsLoading = false;
          _contactsPermissionDenied = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load contacts: $e');
      setState(() {
        _contactsLoading = false;
        _contactsPermissionDenied = true;
      });
    }
  }

  void _onKey(String key) {
    setState(() => _number += key);
    _searchController.text = _number;
  }

  void _onDelete() {
    if (_number.isNotEmpty) {
      setState(() {
        _number = _number.substring(0, _number.length - 1);
        _searchController.text = _number;
      });
    }
  }

  Future<void> _onCall() async {
    if (_number.isNotEmpty) {
      final matchedName = ContactService.lookupContactName(_number);
      showSaveContactBeforeCallSheet(
        context,
        phoneNumber: _number,
        initialName: matchedName,
        onCallInitiate: (lead) {
          widget.callViewModel.initiateCall(lead: lead);
        },
      );
    }
  }

  void _callContact(Contact contact) {
    if (contact.phones.isNotEmpty) {
      final number = contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
      setState(() => _number = number);
      showSaveContactBeforeCallSheet(
        context,
        phoneNumber: number,
        initialName: contact.displayName,
        onCallInitiate: (lead) {
          widget.callViewModel.initiateCall(lead: lead);
        },
      );
    }
  }

  void _selectContact(Contact contact) {
    if (contact.phones.isNotEmpty) {
      final number = contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
      setState(() => _number = number);
      _tabController.animateTo(0); // Switch to dialpad tab
    }
  }

  String _formatNumber(String number) {
    if (number.length <= 5) return number;
    if (number.length <= 10) {
      return '${number.substring(0, 5)} ${number.substring(5)}';
    }
    return '${number.substring(0, 5)} ${number.substring(5, 10)} ${number.substring(10)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dialpad'),
        backgroundColor: AppColors.ssGoldDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.ssGoldLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dialpad_rounded), text: 'Keypad'),
            Tab(icon: Icon(Icons.contacts_rounded), text: 'Contacts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDialpadTab(),
          _buildContactsTab(),
        ],
      ),
    );
  }

  Widget _buildDialpadTab() {
    return Column(
      children: [
        // Number display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            children: [
              Text(
                _number.isEmpty ? 'Enter Number' : _formatNumber(_number),
                style: _number.isEmpty
                    ? AppTypography.headlineMedium.copyWith(
                        color: AppColors.textTertiary,
                      )
                    : AppTypography.headlineLarge.copyWith(
                        letterSpacing: 2,
                      ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (_number.isNotEmpty)
                Text('Tap call to dial', style: AppTypography.bodySmall),
              // Show matched contacts while typing
              if (_number.isNotEmpty && _filteredContacts.isNotEmpty)
                _buildInlineContactSuggestion(),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildKeypad()),
        _buildBottomActions(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInlineContactSuggestion() {
    final top3 = _filteredContacts.take(3).toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.ssGold.withAlpha(60)),
      ),
      child: Column(
        children: top3.map((c) {
          final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
          return InkWell(
            onTap: () => _selectContact(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _ContactAvatar(name: c.displayName ?? '', size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.displayName ?? '',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                        Text(phone,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.call_rounded,
                      size: 16, color: AppColors.ssGoldDark),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '', '2', 'ABC', '3', 'DEF'],
      ['4', 'GHI', '5', 'JKL', '6', 'MNO'],
      ['7', 'PQRS', '8', 'TUV', '9', 'WXYZ'],
      ['*', '', '0', '+', '#', ''],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        children: keys
            .expand((row) => [
                  _DialKey(digit: row[0], letters: row[1], onTap: () => _onKey(row[0])),
                  _DialKey(digit: row[2], letters: row[3], onTap: () => _onKey(row[2])),
                  _DialKey(digit: row[4], letters: row[5], onTap: () => _onKey(row[4])),
                ])
            .toList(),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Contacts shortcut
          _CircleActionButton(
            icon: Icons.contacts_outlined,
            color: AppColors.ssGoldDark,
            backgroundColor: const Color(0xFFFFF8E1),
            onTap: () => _tabController.animateTo(1),
          ),
          // Call button
          GestureDetector(
            onTap: _onCall,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _number.isEmpty ? AppColors.border : AppColors.success,
                shape: BoxShape.circle,
                boxShadow: _number.isEmpty
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.success.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
            )
                .animate(target: _number.isEmpty ? 0 : 1)
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0)),
          ),
          // Backspace
          _CircleActionButton(
            icon: Icons.backspace_outlined,
            color: AppColors.error,
            backgroundColor: const Color(0xFFFFEBEE),
            onTap: _onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or number...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.ssGoldDark),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: AppColors.ssGold, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        // Body
        Expanded(child: _buildContactsBody()),
      ],
    );
  }

  Widget _buildContactsBody() {
    if (_contactsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (_contactsPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.contacts_outlined,
                    size: 48, color: AppColors.ssGoldDark),
              ),
              const SizedBox(height: 20),
              Text(
                'Contacts Permission Required',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Allow access to your phone contacts to quickly dial saved numbers.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                  await _loadContacts();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ssGoldDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadContacts,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No contacts found for "${_searchController.text}"'
                  : 'No contacts with phone numbers',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : 'No number';
        return _ContactListTile(
          contact: contact,
          phone: phone,
          onCall: () => _callContact(contact),
          onSelect: () => _selectContact(contact),
        ).animate(delay: Duration(milliseconds: index * 30)).fadeIn().slideX(begin: 0.05);
      },
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ContactListTile extends StatelessWidget {
  const _ContactListTile({
    required this.contact,
    required this.phone,
    required this.onCall,
    required this.onSelect,
  });

  final Contact contact;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _ContactAvatar(name: contact.displayName ?? '', size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName ?? '',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF3E2723),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Call button
            GestureDetector(
              onTap: onCall,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  size: 18,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.name, this.size = 44});
  final String name;
  final double size;

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF8B6914),
      const Color(0xFF2E7D32),
      const Color(0xFF00838F),
      const Color(0xFF6A1B9A),
      const Color(0xFFBF360C),
      const Color(0xFF1565C0),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final clean = name.trim();
    String initials = '?';
    if (clean.isNotEmpty) {
      final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length >= 2) {
        final w1 = words[0].characters.firstOrNull;
        final w2 = words[1].characters.firstOrNull;
        if (w1 != null && w2 != null) {
          initials = '$w1$w2'.toUpperCase();
        } else {
          initials = clean.characters.first.toUpperCase();
        }
      } else {
        initials = clean.characters.first.toUpperCase();
      }
    }
    final color = _avatarColor(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(60), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class _DialKey extends StatelessWidget {
  const _DialKey({
    required this.digit,
    required this.letters,
    required this.onTap,
  });

  final String digit;
  final String letters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusFull,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                digit,
                style: AppTypography.headlineSmall.copyWith(fontSize: 26),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: AppTypography.labelSmall.copyWith(fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
