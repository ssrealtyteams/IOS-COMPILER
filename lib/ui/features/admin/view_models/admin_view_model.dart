import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/data/repositories/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository;

  AdminViewModel({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  AdminOverviewStats _stats = const AdminOverviewStats();
  AdminOverviewStats get stats => _stats;

  List<TelecallerOverview> _telecallers = [];
  List<TelecallerOverview> get telecallers {
    if (_searchQuery.trim().isEmpty) return _telecallers;
    final q = _searchQuery.trim().toLowerCase();
    return _telecallers.where((t) =>
        t.name.toLowerCase().contains(q) ||
        t.employeeId.toLowerCase().contains(q) ||
        t.phone.contains(q)).toList();
  }

  List<AgentRadarLocation> _radarLocations = [];
  List<AgentRadarLocation> get radarLocations {
    if (_searchQuery.trim().isEmpty) return _radarLocations;
    final q = _searchQuery.trim().toLowerCase();
    return _radarLocations.where((r) =>
        r.name.toLowerCase().contains(q) ||
        r.employeeId.toLowerCase().contains(q) ||
        r.address.toLowerCase().contains(q)).toList();
  }

  String _selectedPeriod = 'today';
  String get selectedPeriod => _selectedPeriod;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAutoDistributionActive = true;
  bool get isAutoDistributionActive => _isAutoDistributionActive;

  Timer? _refreshTimer;

  void init() {
    loadData();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadData(silent: true);
    });
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
    loadData();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _repository.fetchOverviewStats(period: _selectedPeriod),
        _repository.fetchTelecallers(period: _selectedPeriod),
        _repository.fetchLiveRadar(),
      ]);

      _stats = results[0] as AdminOverviewStats;
      _telecallers = results[1] as List<TelecallerOverview>;
      _radarLocations = results[2] as List<AgentRadarLocation>;
      _isAutoDistributionActive = _stats.isAutoDistributionActive;
    } catch (e) {
      debugPrint('⚠️ [AdminViewModel] loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleMasterAutoDistribution(bool enabled) async {
    _isAutoDistributionActive = enabled;
    _stats = _stats.copyWith(isAutoDistributionActive: enabled);
    notifyListeners();

    try {
      await _repository.toggleMasterAutoDistribution(enabled);
    } catch (e) {
      debugPrint('⚠️ [AdminViewModel] toggle error: $e');
    }
  }

  Future<void> toggleTelecallerQueue(String agentId, bool isActive) async {
    final idx = _telecallers.indexWhere((t) => t.id == agentId);
    if (idx != -1) {
      _telecallers[idx] = _telecallers[idx].copyWith(isQueueActive: isActive);
      notifyListeners();
    }

    try {
      await _repository.toggleTelecallerQueue(agentId, isActive);
    } catch (e) {
      debugPrint('⚠️ [AdminViewModel] toggle queue error: $e');
    }
  }

  Future<AgentDrilldownData> fetchAgentDrilldown(TelecallerOverview agent) async {
    return await _repository.fetchAgentDrilldown(agent);
  }

  Future<AgentCustomerBreakdown> fetchAgentCustomerBreakdown(TelecallerOverview agent) async {
    return await _repository.fetchAgentCustomerBreakdown(agent);
  }

  Future<AgentGpsRouteHistory> fetchAgentRouteHistory(String agentId, {String? agentName, String? employeeId}) async {
    return await _repository.fetchAgentRouteHistory(agentId, agentName: agentName, employeeId: employeeId);
  }

  Future<List<AgentDailyWorkReport>> fetchAgentDailyWorkReports(String agentId, {DateTime? month}) async {
    return await _repository.fetchAgentDailyWorkReports(agentId, month: month);
  }

  Future<bool> reassignLead(String leadId, String targetAgentId, String targetAgentName) async {
    final success = await _repository.reassignLead(leadId, targetAgentId, targetAgentName);
    if (success) {
      loadData(silent: true);
    }
    return success;
  }

  Future<({bool success, String message})> changePassword({
    required String oldPassword,
    required String newPassword,
    String? email,
    String? employeeId,
  }) async {
    return await _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      email: email,
      employeeId: employeeId,
    );
  }
}
