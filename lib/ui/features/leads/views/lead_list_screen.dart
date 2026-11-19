import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/lead.dart';
import '../view_models/lead_list_view_model.dart';
import 'widgets/lead_card.dart';
import 'widgets/call_history_sheet.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/loading_overlay.dart';
import '../../common/widgets/primary_button.dart';

class LeadListScreen extends StatefulWidget {
  const LeadListScreen({
    super.key,
    required this.viewModel,
    required this.onLeadTap,
    required this.onCall,
    required this.onWhatsApp,
    required this.onShare,
  });

  final LeadListViewModel viewModel;
  final void Function(Lead) onLeadTap;
  final void Function(Lead) onCall;
  final void Function(Lead) onWhatsApp;
  final void Function(Lead) onShare;

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final _scrollController = ScrollController();

  LeadListViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.init();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _vm.loadLeads();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Column(
          children: [
            OfflineBanner(isVisible: _vm.isOffline),
            _buildSearchBar(),
            _buildStatusChips(),
            _buildFilterRow(),
            Expanded(child: _buildLeadList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: ListenableBuilder(
        listenable: _vm,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Leads'),
            if (_vm.leads.isNotEmpty)
              Text(
                '${_vm.leads.length} leads',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
              ),
          ],
        ),
      ),
      actions: [
        ListenableBuilder(
          listenable: _vm,
          builder: (_, __) => Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showFilterSheet(context),
              ),
              if (_vm.filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _vm.loadLeads(refresh: true),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: AppSearchBar(
        onChanged: _vm.onSearchChanged,
        hint: 'Search by name, phone, project...',
      ),
    );
  }

  Widget _buildStatusChips() {
    return ListenableBuilder(
      listenable: _vm,
      builder: (_, __) {
        final currentStatus = _vm.filter.status;
        final filters = [
          (null, 'All'),
          (LeadStatus.missedCall, 'Missed Call'),
          (LeadStatus.notConnected, 'Not Connect'),
          (LeadStatus.visitScheduled, 'Visit Set'),
          (LeadStatus.visitDone, 'Visit Done'),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: filters.map((filterItem) {
              final status = filterItem.$1;
              final label = filterItem.$2;
              final isSelected = currentStatus == status;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: -3),
                  onSelected: (selected) {
                    _vm.applyFilter(
                      _vm.filter.copyWith(
                        status: selected ? status : null,
                        clearStatus: status == null && selected,
                      ),
                    );
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return ListenableBuilder(
      listenable: _vm,
      builder: (_, __) {
        if (!_vm.filter.hasActiveFilters) return const SizedBox.shrink();
        return Container(
          height: 40,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                '${_vm.filter.activeFilterCount} filter(s) active',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _vm.clearFilters,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadList() {
    return ListenableBuilder(
      listenable: _vm,
      builder: (_, __) {
        if (_vm.state.isLoading && _vm.leads.isEmpty) {
          return _buildShimmer();
        }

        if (_vm.state.isError && _vm.leads.isEmpty) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load leads',
            subtitle: _vm.state.errorMessage,
            action: () => _vm.loadLeads(refresh: true),
            actionLabel: 'Retry',
          );
        }

        if (_vm.leads.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No leads found',
            subtitle: 'Try adjusting your filters or search term.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => _vm.loadLeads(refresh: true),
          color: AppColors.primary,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 100),
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            cacheExtent: 600,
            itemCount: _vm.leads.length + (_vm.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _vm.leads.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Center(
                    child: _vm.state.isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ssGoldDark)
                        : OutlinedButton.icon(
                            onPressed: () => _vm.loadLeads(),
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.ssGoldDark),
                            label: const Text(
                              'Load More Leads',
                              style: TextStyle(
                                color: AppColors.ssGoldDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC9A227), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: const Color(0xFFFDFBF7),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                  ),
                );
              }

              final lead = _vm.leads[index];
              return LeadCard(
                lead: lead,
                animationDelay: (index * 50).clamp(0, 400),
                onTap: () => widget.onLeadTap(lead),
                onCall: () => widget.onCall(lead),
                onWhatsApp: () => widget.onWhatsApp(lead),
                onShare: () => widget.onShare(lead),
                onTimeline: () async {
                  final activities = await _vm.getTimeline(lead.id);
                  if (context.mounted) {
                    showCallHistorySheet(context, lead, activities);
                  }
                },
                onLeadUpdated: (updated) => _vm.updateLead(updated),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 140, height: 16),
                ShimmerBox(width: 60, height: 20, borderRadius: 10),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(width: 180, height: 14),
            SizedBox(height: 8),
            ShimmerBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        currentFilter: _vm.filter,
        onApply: _vm.applyFilter,
      ),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.currentFilter, required this.onApply});
  final LeadFilter currentFilter;
  final void Function(LeadFilter) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late LeadFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () {
                    setState(() => _filter = const LeadFilter());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Status', _buildStatusFilters()),
                  const SizedBox(height: 16),
                  _buildSection('Priority', _buildPriorityFilters()),
                  const SizedBox(height: 16),
                  _buildSection('Sort By', _buildSortFilters()),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: PrimaryButton(
              label: 'Apply Filters',
              onPressed: () {
                widget.onApply(_filter);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleSmall),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatusFilters() {
    final statuses = [
      LeadStatus.newLead,
      LeadStatus.interested,
      LeadStatus.hot,
      LeadStatus.warm,
      LeadStatus.cold,
      LeadStatus.visitScheduled,
      LeadStatus.closedWon,
      LeadStatus.closedLost,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final isSelected = _filter.status == s;
        return FilterChipButton(
          label: s.displayName,
          isSelected: isSelected,
          onSelected: () {
            setState(() {
              _filter = _filter.copyWith(status: isSelected ? null : s);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriorityFilters() {
    return Wrap(
      spacing: 8,
      children: LeadPriority.values.map((p) {
        final isSelected = _filter.priority == p;
        return FilterChipButton(
          label: p.displayName,
          isSelected: isSelected,
          onSelected: () {
            setState(() {
              _filter = _filter.copyWith(priority: isSelected ? null : p);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortFilters() {
    final options = [
      ('last_activity_at', 'Last Activity'),
      ('created_at', 'Date Added'),
      ('full_name', 'Name A-Z'),
      ('priority', 'Priority'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final isSelected = _filter.sortBy == o.$1;
        return FilterChipButton(
          label: o.$2,
          isSelected: isSelected,
          onSelected: () {
            setState(() => _filter = _filter.copyWith(sortBy: o.$1));
          },
        );
      }).toList(),
    );
  }
}
