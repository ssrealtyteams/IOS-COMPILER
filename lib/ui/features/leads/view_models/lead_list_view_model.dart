import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/lead.dart';

class LeadFilter {
  const LeadFilter({
    this.search,
    this.status,
    this.priority,
    this.source,
    this.projectId,
    this.sortBy = 'last_activity_at',
    this.sortOrder = 'desc',
  });

  final String? search;
  final LeadStatus? status;
  final LeadPriority? priority;
  final String? source;
  final String? projectId;
  final String sortBy;
  final String sortOrder;

  static const empty = LeadFilter();

  LeadFilter copyWith({
    String? search,
    LeadStatus? status,
    LeadPriority? priority,
    String? source,
    String? projectId,
    String? sortBy,
    String? sortOrder,
    bool clearStatus = false,
  }) =>
      LeadFilter(
        search: search ?? this.search,
        status: clearStatus ? null : (status ?? this.status),
        priority: priority ?? this.priority,
        source: source ?? this.source,
        projectId: projectId ?? this.projectId,
        sortBy: sortBy ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toQueryMap() => {
        if (search != null) 'search': search,
        if (status != null) 'status': status!.apiValue,
        if (priority != null) 'priority': priority!.name,
        if (source != null) 'source': source,
        if (projectId != null) 'projectId': projectId,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

  bool get hasActiveFilters =>
      status != null || priority != null || source != null || projectId != null;

  int get activeFilterCount =>
      [status, priority, source, projectId]
          .where((e) => e != null)
          .length;
}

@injectable
class LeadListViewModel extends ChangeNotifier {
  LeadListViewModel({required LeadRepository leadRepository})
      : _repo = leadRepository;

  final LeadRepository _repo;

  // ── State ──────────────────────────────────────────
  ViewState _state = const ViewState.initial();
  ViewState get state => _state;

  List<Lead> _leads = [];
  List<Lead> get leads => List.unmodifiable(_leads);

  LeadFilter _filter = const LeadFilter();
  LeadFilter get filter => _filter;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Timer? _searchDebounce;

  // ── Commands ───────────────────────────────────────
  Future<void> init() async {
    debugPrint('LeadListViewModel.init() called');
    await loadLeads(refresh: true);
  }

  Future<void> loadLeads({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    debugPrint('loadLeads: _hasMore=$_hasMore, _state.isLoading=${_state.isLoading}');
    if (!_hasMore || _state.isLoading) return;

    _setState(const ViewState.loading());

    final result = await _repo.getLeads(
      filter: _filter,
      page: _currentPage,
      limit: 15,
    );

    result.fold(
      onSuccess: (paginatedLeads) {
        debugPrint('Loaded ${paginatedLeads.items.length} leads');
        if (refresh) {
          _leads = paginatedLeads.items;
        } else {
          _leads = [..._leads, ...paginatedLeads.items];
        }
        _hasMore = paginatedLeads.hasNextPage;
        _currentPage++;
        _setState(const ViewState.success());
      },
      onFailure: (error) {
        if (error.type == AppErrorType.network) {
          _isOffline = true;
          _setState(const ViewState.success()); // serve local data
        } else {
          _setState(ViewState.error(error.message));
        }
      },
    );
  }

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () {
        _filter = _filter.copyWith(search: query.isEmpty ? null : query);
        loadLeads(refresh: true);
      },
    );
  }

  void applyFilter(LeadFilter newFilter) {
    _filter = newFilter;
    loadLeads(refresh: true);
  }

  void clearFilters() {
    _filter = const LeadFilter();
    loadLeads(refresh: true);
  }

  Future<void> updateLead(Lead updatedLead) async {
    final idx = _leads.indexWhere((l) => l.id == updatedLead.id);
    if (idx != -1) {
      _leads = List.from(_leads)..[idx] = updatedLead;
      notifyListeners();
      await _repo.updateLead(updatedLead);
    }
  }

  Future<List<Activity>> getTimeline(String leadId) async {
    final result = await _repo.getLeadTimeline(leadId);
    return result.fold(
      onSuccess: (activities) => activities,
      onFailure: (err) => [],
    );
  }

  void _setState(ViewState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

// ─── Repository Interface ────────────────────────────────────────────────────
abstract class LeadRepository {
  Future<Result<PaginatedList<Lead>, AppError>> getLeads({
    required LeadFilter filter,
    required int page,
    required int limit,
  });

  Future<Result<Lead, AppError>> getLeadById(String id);
  Future<Result<List<Activity>, AppError>> getLeadTimeline(String leadId);
  Future<Result<void, AppError>> addNote(String leadId, String content);
  Future<Result<void, AppError>> updateStatus(String leadId, LeadStatus status);
  Future<Result<void, AppError>> updateLead(Lead updatedLead);
  Future<Result<void, AppError>> addActivity(String leadId, Activity activity);
}

class Activity {
  const Activity({
    required this.id,
    required this.date,
    required this.outcome,
    required this.duration,
    required this.agentName,
    this.notes,
    this.recordingUrl,
    this.recordingPath,
  });

  final String id;
  final DateTime date;
  final String outcome;
  final String duration;
  final String agentName;
  final String? notes;
  final String? recordingUrl;
  final String? recordingPath;

  Activity copyWith({
    String? id,
    DateTime? date,
    String? outcome,
    String? duration,
    String? agentName,
    String? notes,
    String? recordingUrl,
    String? recordingPath,
  }) {
    return Activity(
      id: id ?? this.id,
      date: date ?? this.date,
      outcome: outcome ?? this.outcome,
      duration: duration ?? this.duration,
      agentName: agentName ?? this.agentName,
      notes: notes ?? this.notes,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }
}
