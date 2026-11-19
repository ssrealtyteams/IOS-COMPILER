import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/core/services/contact_service.dart';
import 'package:sales_crm_dialer/ui/features/calling/view_models/call_view_model.dart';
import '../widgets/save_contact_before_call_sheet.dart';

Future<void> showCustomDialpadSheet(BuildContext context, CallViewModel callViewModel) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CustomDialpadSheet(callViewModel: callViewModel),
  );
}

class _CustomDialpadSheet extends StatefulWidget {
  const _CustomDialpadSheet({required this.callViewModel});
  final CallViewModel callViewModel;

  @override
  State<_CustomDialpadSheet> createState() => _CustomDialpadSheetState();
}

class _CustomDialpadSheetState extends State<_CustomDialpadSheet> {
  String _phoneNumber = '';
  String? _matchedContactName;

  @override
  void initState() {
    super.initState();
    ContactService.loadContacts().then((_) {
      if (mounted) _updateMatchedContact();
    });
  }

  Future<void> _updateMatchedContact() async {
    final phone = _phoneNumber.trim();
    if (phone.isEmpty) {
      if (mounted) setState(() => _matchedContactName = null);
      return;
    }

    // 1. Sync lookup
    final syncName = ContactService.lookupContactName(phone);
    if (syncName != null && syncName.isNotEmpty) {
      if (mounted) setState(() => _matchedContactName = syncName);
      return;
    }

    // 2. Async Native PhoneLookup
    final asyncName = await ContactService.lookupContactNameAsync(phone);
    if (mounted && _phoneNumber.trim() == phone) {
      setState(() => _matchedContactName = asyncName);
    }
  }

  void _onKeyPress(String key) {
    if (_phoneNumber.length < 15) {
      setState(() {
        _phoneNumber += key;
      });
      _updateMatchedContact();
    }
  }

  void _onDelete() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
      _updateMatchedContact();
    }
  }

  Future<void> _onCall() async {
    if (_phoneNumber.isEmpty) return;
    
    final phone = _phoneNumber;
    String? contactName = _matchedContactName;
    final nav = Navigator.of(context);
    final parentContext = nav.context;

    if (contactName == null || contactName.isEmpty) {
      contactName = await ContactService.lookupContactNameAsync(phone);
    }
    nav.pop(); // Close the dialpad sheet
    
    if (parentContext.mounted) {
      showSaveContactBeforeCallSheet(
        parentContext,
        phoneNumber: phone,
        initialName: contactName,
        onCallInitiate: (lead) {
          widget.callViewModel.initiateCall(lead: lead);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0D5C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Matched Contact Name Banner
          if (_matchedContactName != null && _matchedContactName!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6914).withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B6914).withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_rounded, size: 15, color: Color(0xFF8B6914)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _matchedContactName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8B6914),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.2),
          
          // Number Display Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _phoneNumber.isEmpty ? 'Enter Number' : _phoneNumber,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: _phoneNumber.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Dialpad Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                _buildRow(['4', '5', '6']),
                _buildRow(['7', '8', '9']),
                _buildRow(['*', '0', '#']),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Call Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () async {
                    final selectedPhone = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _ContactPickerSheet(),
                    );
                    if (selectedPhone != null && mounted) {
                      setState(() {
                        _phoneNumber = selectedPhone;
                        _updateMatchedContact();
                      });
                    }
                  },
                  icon: const Icon(Icons.contacts_rounded, size: 28),
                  color: const Color(0xFF8B6914),
                ),
                GestureDetector(
                  onTap: _onCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
                  ),
                ),
                IconButton(
                  onPressed: _phoneNumber.isEmpty ? null : _onDelete,
                  icon: const Icon(Icons.backspace_outlined),
                  color: AppColors.textSecondary,
                  iconSize: 28,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) => _buildKey(k)).toList(),
      ),
    );
  }

  Widget _buildKey(String keyStr) {
    return InkWell(
      onTap: () => _onKeyPress(keyStr),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            keyStr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet();

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    await ContactService.loadContacts(forceReload: true);
    if (mounted) {
      setState(() {
        _contacts = ContactService.cachedContacts;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _contacts = ContactService.searchContacts(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0D5C0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.contacts_rounded, color: Color(0xFF8B6914), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Device Contacts',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B6914).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_contacts.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search contact by name or number...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF8B6914)),
                    )
                  : _contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No contacts found on device'
                                    : 'No contacts match "$_searchQuery"',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _fetchContacts,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Refresh Contacts'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8B6914),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _contacts.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.borderLight, height: 1),
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final name = contact.displayName?.trim() ?? '';
                            final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                            final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF8B6914).withAlpha(25),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF8B6914),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                phone,
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                              onTap: () {
                                final clean = ContactService.cleanPhone(phone);
                                Navigator.pop(context, clean.isNotEmpty ? clean : phone);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
