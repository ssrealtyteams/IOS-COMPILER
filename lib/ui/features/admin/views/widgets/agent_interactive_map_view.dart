import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Standard Web Mercator Projection Utilities for Real Google Maps Slippy Tiles
/// ─────────────────────────────────────────────────────────────────────────────
class MercatorProjection {
  static const double tileSize = 256.0;

  static double lonToWorldX(double lon, double zoom) {
    return ((lon + 180.0) / 360.0) * math.pow(2.0, zoom) * tileSize;
  }

  static double latToWorldY(double lat, double zoom) {
    final sinLat = math.sin(lat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final y = 0.5 - (math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi));
    return y * math.pow(2.0, zoom) * tileSize;
  }

  static Offset latLngToScreen({
    required double lat,
    required double lon,
    required double centerLat,
    required double centerLon,
    required double zoom,
    required Size screenSize,
    required Offset panOffset,
  }) {
    final worldX = lonToWorldX(lon, zoom);
    final worldY = latToWorldY(lat, zoom);

    final centerWorldX = lonToWorldX(centerLon, zoom) - panOffset.dx;
    final centerWorldY = latToWorldY(centerLat, zoom) - panOffset.dy;

    final screenX = (worldX - centerWorldX) + screenSize.width / 2;
    final screenY = (worldY - centerWorldY) + screenSize.height / 2;

    return Offset(screenX, screenY);
  }

  static double metersToPixels(double meters, double lat, double zoom) {
    final resolution = 156543.03392 * math.cos(lat * math.pi / 180.0) / math.pow(2.0, zoom);
    return (meters / resolution).clamp(4.0, 400.0);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Authentic Google Maps Interactive Live View with Real Slippy Map Tiles
/// ─────────────────────────────────────────────────────────────────────────────
class AgentInteractiveMapView extends StatefulWidget {
  final AgentGpsRouteHistory route;
  final double height;
  final bool showControls;
  final bool isMultiAgent;
  final List<AgentRadarLocation>? allAgents;
  final ValueChanged<AgentRadarLocation>? onAgentSelected;

  const AgentInteractiveMapView({
    super.key,
    required this.route,
    this.height = 420,
    this.showControls = true,
    this.isMultiAgent = false,
    this.allAgents,
    this.onAgentSelected,
  });

  @override
  State<AgentInteractiveMapView> createState() => _AgentInteractiveMapViewState();
}

class _AgentInteractiveMapViewState extends State<AgentInteractiveMapView>
    with SingleTickerProviderStateMixin {
  // Center coordinates (Jonapur Base Office / Live Agent)
  static const double jonapurBaseLat = 28.4624272;
  static const double jonapurBaseLon = 77.1515298;

  late double _centerLat;
  late double _centerLon;

  // Zoom level: 12.0 (NCR overview) to 18.5 (detailed street / building level)
  double _zoomLevel = 14.8;
  Offset _panOffset = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  double _baseZoom = 14.8;

  // Expand / Maximize map height state
  bool _isExpanded = false;

  // Selected waypoint callout
  AgentGpsWaypoint? _selectedWaypoint;
  AgentRadarLocation? _selectedAgentPin;

  // Map type: standard roadmap ('m') or hybrid satellite ('y')
  String _mapType = 'm';

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _initCenterPosition();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  void _initCenterPosition() {
    if (widget.route.waypoints.isNotEmpty) {
      final latest = widget.route.waypoints.last;
      _centerLat = latest.latitude != 0.0 ? latest.latitude : jonapurBaseLat;
      _centerLon = latest.longitude != 0.0 ? latest.longitude : jonapurBaseLon;
    } else {
      _centerLat = jonapurBaseLat;
      _centerLon = jonapurBaseLon;
    }
  }

  @override
  void didUpdateWidget(covariant AgentInteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.agentId != widget.route.agentId) {
      _initCenterPosition();
      _panOffset = Offset.zero;
      _selectedWaypoint = null;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.8).clamp(12.0, 18.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.8).clamp(12.0, 18.5);
    });
  }

  void _resetToAgent() {
    setState(() {
      if (widget.route.waypoints.isNotEmpty) {
        final last = widget.route.waypoints.last;
        _centerLat = last.latitude;
        _centerLon = last.longitude;
      }
      _zoomLevel = 15.8;
      _panOffset = Offset.zero;
      _selectedWaypoint = null;
    });
  }

  void _resetToOffice() {
    setState(() {
      _centerLat = jonapurBaseLat;
      _centerLon = jonapurBaseLon;
      _zoomLevel = 15.2;
      _panOffset = Offset.zero;
      _selectedWaypoint = null;
    });
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == 'm' ? 'y' : 'm';
    });
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final screenH = MediaQuery.of(context).size.height;
    final effectiveHeight = _isExpanded
        ? (screenH * 0.72).clamp(520.0, 780.0)
        : widget.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECE9), // Standard Google Maps land tone
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // ── 1. Interactive Real Google Maps Slippy Tile Layer ─────────
                RawGestureDetector(
                  gestures: {
                    EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                      (EagerGestureRecognizer instance) {},
                    ),
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) {
                      _lastFocalPoint = details.focalPoint;
                      _baseZoom = _zoomLevel;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        if (details.pointerCount > 1 && details.scale != 1.0) {
                          final newZoom = _baseZoom + (math.log(details.scale) / math.ln2);
                          _zoomLevel = newZoom.clamp(12.0, 18.5);
                        }
                        final delta = details.focalPoint - _lastFocalPoint;
                        _panOffset += delta;
                        _lastFocalPoint = details.focalPoint;
                      });
                    },
                    onDoubleTap: () {
                      setState(() {
                        _zoomLevel = _zoomLevel >= 16.5 ? 14.5 : _zoomLevel + 1.2;
                      });
                    },
                    child: Stack(
                      children: [
                        // Real Google Maps Network Tiles
                        _buildGoogleMapTiles(size),

                        // Real GPS Trail & Telemetry Vector Overlay
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            return CustomPaint(
                              size: size,
                              painter: _GoogleMapOverlayPainter(
                                route: route,
                                centerLat: _centerLat,
                                centerLon: _centerLon,
                                zoomLevel: _zoomLevel,
                                panOffset: _panOffset,
                                pulseValue: _pulseCtrl.value,
                                isMultiAgent: widget.isMultiAgent,
                                allAgents: widget.allAgents,
                                selectedWaypoint: _selectedWaypoint,
                                selectedAgentPin: _selectedAgentPin,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. Top Telemetry Metrics Strip ───────────────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _buildTopTelemetryHeader(route),
                ),

                // ── 3. Google Maps Controls (Expand, Zoom +/-, Layers, Agent, Base) ──
                if (widget.showControls)
                  Positioned(
                    right: 10,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fullscreen / Maximize Map
                        _buildGoogleMapBtn(
                          icon: _isExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          tooltip: _isExpanded ? 'Collapse Map' : 'Expand Full Map',
                          onTap: _toggleExpand,
                          color: const Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 6),

                        // Zoom In (+) Button
                        _buildGoogleMapBtn(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom In',
                          onTap: _zoomIn,
                          color: const Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 6),

                        // Zoom Out (-) Button
                        _buildGoogleMapBtn(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom Out',
                          onTap: _zoomOut,
                          color: const Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 6),

                        // Map Type Toggle (Satellite / Road)
                        _buildGoogleMapBtn(
                          icon: _mapType == 'm' ? Icons.layers_rounded : Icons.map_rounded,
                          tooltip: _mapType == 'm' ? 'Satellite View' : 'Roadmap View',
                          onTap: _toggleMapType,
                          color: const Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 6),

                        // Center on Live Agent
                        _buildGoogleMapBtn(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Center on Agent',
                          onTap: _resetToAgent,
                          color: const Color(0xFF1A73E8), // Google Blue
                        ),
                        const SizedBox(height: 6),

                        // Center on Jonapur Head Office Base
                        _buildGoogleMapBtn(
                          icon: Icons.account_balance_rounded,
                          tooltip: 'Center on Jonapur Base',
                          onTap: _resetToOffice,
                          color: const Color(0xFFEA4335), // Google Red
                        ),
                      ],
                    ),
                  ),

                // ── 4. Bottom Left Waypoints Quick Selector Strip ────────────
                if (route.waypoints.isNotEmpty && !widget.isMultiAgent)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: 58,
                    child: _buildWaypointSelectorStrip(route),
                  ),

                // ── 5. Selected Waypoint / Halt Detail Card ─────────────────
                if (_selectedWaypoint != null)
                  Positioned(
                    top: 60,
                    left: 12,
                    right: 12,
                    child: _buildWaypointDetailCard(_selectedWaypoint!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// Real Google Maps Tile Grid Renderer
  /// ──────────────────────────────────────────────────────────────────────────
  Widget _buildGoogleMapTiles(Size size) {
    final intZoom = _zoomLevel.floor().clamp(12, 18);
    final scale = math.pow(2.0, _zoomLevel - intZoom).toDouble();

    final centerWorldX = MercatorProjection.lonToWorldX(_centerLon, intZoom.toDouble()) - (_panOffset.dx / scale);
    final centerWorldY = MercatorProjection.latToWorldY(_centerLat, intZoom.toDouble()) - (_panOffset.dy / scale);

    final viewWidthAtIntZoom = size.width / scale;
    final viewHeightAtIntZoom = size.height / scale;

    final minTileX = ((centerWorldX - viewWidthAtIntZoom / 2) / 256.0).floor();
    final maxTileX = ((centerWorldX + viewWidthAtIntZoom / 2) / 256.0).floor();
    final minTileY = ((centerWorldY - viewHeightAtIntZoom / 2) / 256.0).floor();
    final maxTileY = ((centerWorldY + viewHeightAtIntZoom / 2) / 256.0).floor();

    final maxTileIndex = (1 << intZoom) - 1;
    final tileWidgets = <Widget>[];

    for (int tx = minTileX; tx <= maxTileX; tx++) {
      for (int ty = minTileY; ty <= maxTileY; ty++) {
        if (ty < 0 || ty > maxTileIndex) continue;
        final wrappedTx = (tx % (maxTileIndex + 1) + (maxTileIndex + 1)) % (maxTileIndex + 1);

        final left = (tx * 256.0 - (centerWorldX - viewWidthAtIntZoom / 2)) * scale;
        final top = (ty * 256.0 - (centerWorldY - viewHeightAtIntZoom / 2)) * scale;
        final tileSizeScaled = 256.0 * scale;

        // Authentic Google Maps Tile URL
        final serverNum = (wrappedTx + ty).abs() % 4;
        final tileUrl = 'https://mt$serverNum.google.com/vt/lyrs=$_mapType&x=$wrappedTx&y=$ty&z=$intZoom';

        tileWidgets.add(
          Positioned(
            left: left,
            top: top,
            width: tileSizeScaled + 0.5,
            height: tileSizeScaled + 0.5,
            child: CachedNetworkImage(
              imageUrl: tileUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, url) => Container(
                color: _mapType == 'm' ? const Color(0xFFE8ECE9) : const Color(0xFF1E293B),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFE8ECE9),
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: Colors.black.withAlpha(20),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: tileWidgets);
  }

  Widget _buildTopTelemetryHeader(AgentGpsRouteHistory route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Distance from Jonapur Base / Off-Duty status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: !route.isOnline
                      ? const Color(0xFFFEE2E2)
                      : (route.isInOffice ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !route.isOnline
                      ? Icons.power_settings_new_rounded
                      : (route.isInOffice ? Icons.verified_rounded : Icons.near_me_rounded),
                  size: 13,
                  color: !route.isOnline
                      ? const Color(0xFFDC2626)
                      : (route.isInOffice ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    !route.isOnline
                        ? 'Off-Duty (Punched Out)'
                        : (route.isInOffice ? 'At Base Office' : '${route.distanceFormatted} from Office'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: !route.isOnline ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    !route.isOnline
                        ? 'Shift Ended • No Active Movement'
                        : 'ETA: ${route.estimatedTimeToOffice}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Battery & Total Traveled KM
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.battery_charging_full_rounded,
                      size: 11,
                      color: route.batteryPercent > 20
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${route.batteryPercent}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 11, color: Color(0xFF2563EB)),
                    const SizedBox(width: 3),
                    Text(
                      '${route.totalDistanceTravelledKm.toStringAsFixed(1)} km trail',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointSelectorStrip(AgentGpsRouteHistory route) {
    final waypoints = route.waypoints;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: waypoints.asMap().entries.map((entry) {
          final idx = entry.key;
          final wp = entry.value;
          final isSelected = _selectedWaypoint == wp;
          final isHalt = wp.isHalt;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWaypoint = isSelected ? null : wp;
                  _centerLat = wp.latitude;
                  _centerLon = wp.longitude;
                  _zoomLevel = 16.2;
                  _panOffset = Offset.zero;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : (isHalt ? const Color(0xFFFFFBEB) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : (isHalt ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),
                    width: isSelected || isHalt ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      idx == 0
                          ? Icons.flag_rounded
                          : (idx == waypoints.length - 1
                              ? Icons.my_location_rounded
                              : (isHalt ? Icons.hourglass_top_rounded : Icons.location_on_rounded)),
                      size: 11,
                      color: isSelected
                          ? Colors.white
                          : (idx == 0
                              ? const Color(0xFF16A34A)
                              : (isHalt ? const Color(0xFFD97706) : const Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stop ${idx + 1} (${wp.timeFormatted})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isHalt ? const Color(0xFF92400E) : const Color(0xFF334155)),
                      ),
                    ),
                    if (isHalt && !isSelected) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          wp.stayDurationFormatted,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaypointDetailCard(AgentGpsWaypoint wp) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: wp.isHalt ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              wp.isHalt ? Icons.timer_rounded : Icons.location_on_rounded,
              color: wp.isHalt ? const Color(0xFFD97706) : const Color(0xFF2563EB),
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wp.address,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  wp.isHalt
                      ? '⏳ Stayed: ${wp.stayDurationFormatted} (${wp.haltIntervalFormatted})'
                      : '🕒 ${wp.timeFormatted} • Speed: ${wp.speedKmh.toStringAsFixed(0)} km/h',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: wp.isHalt ? const Color(0xFFB45309) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => setState(() => _selectedWaypoint = null),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(7.5),
              child: Icon(icon, color: color, size: 17),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Authentic Google Maps Vector Overlay Painter
/// Paints: Geofence Circle, GPS Route Trail, Red Head Office Pin, Blue Agent Beacon,
/// Halt Badges & Multi-Agent Markers with accurate Web Mercator projection.
/// ─────────────────────────────────────────────────────────────────────────────
class _GoogleMapOverlayPainter extends CustomPainter {
  final AgentGpsRouteHistory route;
  final double centerLat;
  final double centerLon;
  final double zoomLevel;
  final Offset panOffset;
  final double pulseValue;
  final bool isMultiAgent;
  final List<AgentRadarLocation>? allAgents;
  final AgentGpsWaypoint? selectedWaypoint;
  final AgentRadarLocation? selectedAgentPin;

  _GoogleMapOverlayPainter({
    required this.route,
    required this.centerLat,
    required this.centerLon,
    required this.zoomLevel,
    required this.panOffset,
    required this.pulseValue,
    required this.isMultiAgent,
    this.allAgents,
    this.selectedWaypoint,
    this.selectedAgentPin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Jonapur Base Geofence Circle (200m radius accurately projected)
    _drawBaseGeofence(canvas, size);

    // 2. GPS Route Trail Path (Connecting actual waypoints)
    if (route.waypoints.isNotEmpty && !isMultiAgent) {
      _drawGpsRoutePolyline(canvas, size);
      _drawWaypointsAndHalts(canvas, size);
    }

    // 3. Jonapur Head Office Base Marker (Google Red Pin)
    _drawJonapurBaseMarker(canvas, size);

    // 4. Live Agent Pin or Multi-Agent Fleet
    if (isMultiAgent && allAgents != null) {
      _drawMultiAgentFleet(canvas, size);
    } else {
      _drawLiveAgentBeacon(canvas, size);
    }
  }

  void _drawBaseGeofence(Canvas canvas, Size size) {
    final baseOffset = MercatorProjection.latLngToScreen(
      lat: 28.4624272,
      lon: 77.1515298,
      centerLat: centerLat,
      centerLon: centerLon,
      zoom: zoomLevel,
      screenSize: size,
      panOffset: panOffset,
    );

    final pixelRadius = MercatorProjection.metersToPixels(200.0, 28.4624272, zoomLevel);

    // Geofence soft fill
    final fillPaint = Paint()
      ..color = const Color(0xFF16A34A).withAlpha(18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(baseOffset, pixelRadius, fillPaint);

    // Geofence dashed border
    final borderPaint = Paint()
      ..color = const Color(0xFF16A34A).withAlpha(140)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(baseOffset, pixelRadius, borderPaint);
  }

  void _drawGpsRoutePolyline(Canvas canvas, Size size) {
    final waypoints = route.waypoints;
    if (waypoints.length < 2) return;

    final screenPoints = waypoints.map((wp) {
      return MercatorProjection.latLngToScreen(
        lat: wp.latitude,
        lon: wp.longitude,
        centerLat: centerLat,
        centerLon: centerLon,
        zoom: zoomLevel,
        screenSize: size,
        panOffset: panOffset,
      );
    }).toList();

    // Outer Glow / Border for Google Maps trail
    final borderPath = Path()..moveTo(screenPoints.first.dx, screenPoints.first.dy);
    for (int i = 1; i < screenPoints.length; i++) {
      borderPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF1E40AF).withAlpha(40)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(borderPath, glowPaint);

    // Main Google Blue GPS Path
    final pathPaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(borderPath, pathPaint);

    // Draw direction arrows along the path
    for (int i = 0; i < screenPoints.length - 1; i++) {
      final p1 = screenPoints[i];
      final p2 = screenPoints[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);

      _drawDirectionArrow(canvas, mid, angle);
    }
  }

  void _drawDirectionArrow(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final arrowPath = Path()
      ..moveTo(-3, -3)
      ..lineTo(3, 0)
      ..lineTo(-3, 3)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.restore();
  }

  void _drawWaypointsAndHalts(Canvas canvas, Size size) {
    final waypoints = route.waypoints;

    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final offset = MercatorProjection.latLngToScreen(
        lat: wp.latitude,
        lon: wp.longitude,
        centerLat: centerLat,
        centerLon: centerLon,
        zoom: zoomLevel,
        screenSize: size,
        panOffset: panOffset,
      );

      final isSelected = selectedWaypoint == wp;
      final isFirst = i == 0;
      final isLast = i == waypoints.length - 1;

      // Draw Numbered Waypoint Disc
      final discPaint = Paint()
        ..color = isSelected
            ? const Color(0xFF1E293B)
            : (isFirst
                ? const Color(0xFF16A34A)
                : (isLast
                    ? const Color(0xFF1A73E8)
                    : (wp.isHalt ? const Color(0xFFD97706) : const Color(0xFF2563EB))));

      canvas.drawCircle(offset, isSelected ? 8.0 : 6.0, Paint()..color = Colors.white);
      canvas.drawCircle(offset, isSelected ? 6.5 : 4.5, discPaint);

      // Draw Amber Halt / Stay Badge for 5+ min stays
      if (wp.isHalt && !isLast) {
        _drawHaltBadge(canvas, offset, wp.stayDurationFormatted);
      }
    }
  }

  void _drawHaltBadge(Canvas canvas, Offset pos, String stayText) {
    final badgePos = Offset(pos.dx, pos.dy - 18);

    final textSpan = TextSpan(
      text: '⏳ Halt: $stayText',
      style: const TextStyle(
        color: Color(0xFF92400E),
        fontSize: 9.0,
        fontWeight: FontWeight.w800,
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgePos, width: tp.width + 10, height: tp.height + 6),
      const Radius.circular(5),
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.black.withAlpha(20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFFFEF3C7),
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    tp.paint(canvas, Offset(badgePos.dx - tp.width / 2, badgePos.dy - tp.height / 2));
  }

  void _drawJonapurBaseMarker(Canvas canvas, Size size) {
    final baseOffset = MercatorProjection.latLngToScreen(
      lat: 28.4624272,
      lon: 77.1515298,
      centerLat: centerLat,
      centerLon: centerLon,
      zoom: zoomLevel,
      screenSize: size,
      panOffset: panOffset,
    );

    // Google Red Teardrop Marker
    final pinPath = Path()
      ..moveTo(baseOffset.dx, baseOffset.dy)
      ..cubicTo(
        baseOffset.dx - 9,
        baseOffset.dy - 10,
        baseOffset.dx - 9,
        baseOffset.dy - 22,
        baseOffset.dx,
        baseOffset.dy - 22,
      )
      ..cubicTo(
        baseOffset.dx + 9,
        baseOffset.dy - 22,
        baseOffset.dx + 9,
        baseOffset.dy - 10,
        baseOffset.dx,
        baseOffset.dy,
      );

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black.withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(pinPath, Paint()..color = const Color(0xFFEA4335)); // Google Red
    canvas.drawCircle(Offset(baseOffset.dx, baseOffset.dy - 14), 3.5, Paint()..color = Colors.white);

    // Label: Jonapur Head Office
    _drawMarkerLabel(canvas, Offset(baseOffset.dx, baseOffset.dy + 7), 'Jonapur Head Office (Dalmia Farm)', const Color(0xFFB91C1C));
  }

  void _drawLiveAgentBeacon(Canvas canvas, Size size) {
    final agentLat = route.waypoints.isNotEmpty ? route.waypoints.last.latitude : 28.4626100;
    final agentLon = route.waypoints.isNotEmpty ? route.waypoints.last.longitude : 77.1517200;

    final agentOffset = MercatorProjection.latLngToScreen(
      lat: agentLat,
      lon: agentLon,
      centerLat: centerLat,
      centerLon: centerLon,
      zoom: zoomLevel,
      screenSize: size,
      panOffset: panOffset,
    );

    // If associate is punched out, draw stationary grey/red dot without radar waves
    if (!route.isOnline) {
      canvas.drawCircle(agentOffset, 7.5, Paint()..color = Colors.white);
      canvas.drawCircle(agentOffset, 5.5, Paint()..color = const Color(0xFF94A3B8));
      _drawAgentPill(canvas, Offset(agentOffset.dx, agentOffset.dy - 18), '${route.agentName} (Off-Duty)', false, isOffDuty: true);
      return;
    }

    // 1. Google Blue Pulsating Radar Waves (Active Punch-In only)
    final waveRadius1 = 12.0 + pulseValue * 18.0;
    final waveAlpha1 = ((1.0 - pulseValue) * 120).toInt().clamp(0, 255);
    canvas.drawCircle(
      agentOffset,
      waveRadius1,
      Paint()..color = const Color(0xFF1A73E8).withAlpha(waveAlpha1),
    );

    final waveRadius2 = 8.0 + pulseValue * 10.0;
    final waveAlpha2 = ((1.0 - pulseValue) * 80).toInt().clamp(0, 255);
    canvas.drawCircle(
      agentOffset,
      waveRadius2,
      Paint()..color = const Color(0xFF4285F4).withAlpha(waveAlpha2),
    );

    // 2. Google Blue Solid Location Disc with White Ring
    canvas.drawCircle(agentOffset, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(agentOffset, 6.5, Paint()..color = const Color(0xFF1A73E8));

    // 3. Agent Name Tag
    _drawAgentPill(canvas, Offset(agentOffset.dx, agentOffset.dy - 18), route.agentName, route.isInOffice);
  }

  void _drawAgentPill(Canvas canvas, Offset pos, String name, bool isOffice, {bool isOffDuty = false}) {
    final textSpan = TextSpan(
      text: name,
      style: TextStyle(
        color: isOffDuty ? const Color(0xFF64748B) : const Color(0xFF0F172A),
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + 16, height: tp.height + 6),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = Colors.black.withAlpha(20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRRect(
      pillRect,
      Paint()..color = Colors.white,
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = isOffDuty
            ? const Color(0xFFCBD5E1)
            : (isOffice ? const Color(0xFF86EFAC) : const Color(0xFF93C5FD))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Small status dot inside pill
    canvas.drawCircle(
      Offset(pos.dx - tp.width / 2 - 2, pos.dy),
      2.5,
      Paint()
        ..color = isOffDuty
            ? const Color(0xFF94A3B8)
            : (isOffice ? const Color(0xFF16A34A) : const Color(0xFF2563EB)),
    );

    tp.paint(canvas, Offset(pos.dx - tp.width / 2 + 4, pos.dy - tp.height / 2));
  }

  void _drawMultiAgentFleet(Canvas canvas, Size size) {
    if (allAgents == null) return;

    for (final agent in allAgents!) {
      final offset = MercatorProjection.latLngToScreen(
        lat: agent.latitude,
        lon: agent.longitude,
        centerLat: centerLat,
        centerLon: centerLon,
        zoom: zoomLevel,
        screenSize: size,
        panOffset: panOffset,
      );

      final isSelected = selectedAgentPin == agent;
      final isOffice = agent.status.toLowerCase() == 'inoffice' || agent.isInOffice;
      final pinColor = isOffice ? const Color(0xFF16A34A) : const Color(0xFFD97706);

      canvas.drawCircle(offset, isSelected ? 8.0 : 6.0, Paint()..color = Colors.white);
      canvas.drawCircle(offset, isSelected ? 6.5 : 4.5, Paint()..color = pinColor);

      _drawAgentPill(canvas, Offset(offset.dx, offset.dy - 16), agent.name, isOffice);
    }
  }

  void _drawMarkerLabel(Canvas canvas, Offset pos, String text, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        backgroundColor: Colors.white.withAlpha(220),
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _GoogleMapOverlayPainter oldDelegate) {
    return oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedWaypoint != selectedWaypoint ||
        oldDelegate.selectedAgentPin != selectedAgentPin ||
        oldDelegate.route != route;
  }
}
