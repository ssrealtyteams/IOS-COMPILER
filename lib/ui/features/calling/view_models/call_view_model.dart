import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../data/repositories/remote_lead_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/platform/call_channel.dart';
import '../../../../core/services/aws_s3_service.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../domain/entities/call.dart';
import '../../../../domain/entities/lead.dart';
import 'package:permission_handler/permission_handler.dart';

enum CallViewState {
  idle,
  requestingPermission,
  initiating,
  dialing,
  connected,
  ended,
  error,
}

@injectable
class CallViewModel extends ChangeNotifier {
  CallViewModel();

  // ── State ──────────────────────────────────────────
  CallViewState _state = CallViewState.idle;
  CallViewState get state => _state;

  Lead? _activeLead;
  Lead? get activeLead => _activeLead;

  String? _activePhoneNumber;
  String? get activePhoneNumber => _activePhoneNumber;

  DateTime? _callStartTime;
  DateTime? _connectedTime;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  CallType? _callType;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _showDisposition = false;
  bool get showDisposition => _showDisposition;

  // ── In-Call Controls & State ───────────────────────
  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _showKeypad = false;
  bool get showKeypad => _showKeypad;

  bool _showNotesSheet = false;
  bool get showNotesSheet => _showNotesSheet;

  String _liveNotes = '';
  String get liveNotes => _liveNotes;

  bool _isMinimized = false;
  bool get isMinimized => _isMinimized;

  String _dtmfDigits = '';
  String get dtmfDigits => _dtmfDigits;

  bool get isCallActive =>
      _state == CallViewState.dialing ||
      _state == CallViewState.connected ||
      _state == CallViewState.initiating;

  // ── Voice Recording & AWS S3 ───────────────────────
  String? _recordingPath;
  String? get recordingPath => _recordingPath;

  String? _recordingUrl;
  String? get recordingUrl => _recordingUrl;

  bool _isUploadingRecording = false;
  bool get isUploadingRecording => _isUploadingRecording;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  bool _isDefaultDialer = false;
  bool get isDefaultDialer => _isDefaultDialer;

  StreamSubscription? _callEventSub;
  Timer? _durationTimer;
  Call? _lastCall;
  Call? get lastCall => _lastCall;

  // ── Lifecycle ─────────────────────────────────────
  void initialize() {
    _callEventSub = CallChannel.callEvents.listen(
      _onCallEvent,
      onError: (e) => debugPrint('CallChannel error: $e'),
    );
    checkDefaultDialer();
  }

  Future<void> checkDefaultDialer() async {
    _isDefaultDialer = await CallChannel.isDefaultDialer();
    notifyListeners();
  }

  Future<bool> requestDefaultDialer() async {
    final granted = await CallChannel.requestDefaultDialer();
    _isDefaultDialer = await CallChannel.isDefaultDialer();
    notifyListeners();
    return granted;
  }

  /// Called when user returns to app after a call
  Future<void> onAppResumed() async {
    // Keep active call state intact while call is alive.
    // The native CallStateReceiver will post CALL_ENDED when the call physically finishes.
  }

  bool get isIncoming => _callType == CallType.incoming;

  /// Answer / Accept incoming call
  Future<void> answerCall() async {
    try {
      await CallChannel.answerCall();
    } catch (_) {}
    _state = CallViewState.connected;
    _connectedTime = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  /// Reject / Decline incoming call
  Future<void> rejectCall() async {
    try {
      await CallChannel.rejectCall();
    } catch (_) {}
    _stopTimer();
    await _onCallEnded(CallEventTypes.rejected);
    notifyListeners();
  }

  /// Explicitly cut / hang up active call from app UI
  Future<void> hangUpCall() async {
    try {
      await CallChannel.endCall();
    } catch (_) {}
    _stopTimer();
    await _onCallEnded(CallEventTypes.ended);
    notifyListeners();
  }

  void _onCallEvent(CallEvent event) {
    debugPrint('🔔 [CallViewModel] Received Native Event: ${event.type}, Data: ${event.data}, Duration: ${event.durationSeconds}, Audio: ${event.recordingPath}');
    switch (event.type) {
      case CallEventTypes.dialing:
        _state = CallViewState.dialing;
        _callType = CallType.outgoing;
        _callStartTime = DateTime.now();
        _elapsedSeconds = 0;
        if ((_activePhoneNumber == null || _activePhoneNumber!.isEmpty) && event.data != null && event.data!.isNotEmpty) {
          _activePhoneNumber = event.data;
          RemoteLeadRepository.findOrCreateLead(event.data!).then((lead) {
            _activeLead = lead;
            notifyListeners();
          });
        }
      case CallEventTypes.ringing:
        _state = CallViewState.dialing;
        _callType = CallType.incoming;
        _callStartTime = DateTime.now();
        _elapsedSeconds = 0;
        if ((_activePhoneNumber == null || _activePhoneNumber!.isEmpty) && event.data != null && event.data!.isNotEmpty) {
          _activePhoneNumber = event.data;
          RemoteLeadRepository.findOrCreateLead(event.data!).then((lead) {
            _activeLead = lead;
            notifyListeners();
          });
        }
      case CallEventTypes.started:
      case CallEventTypes.connected:
        _state = CallViewState.connected;
        _connectedTime ??= DateTime.now();
        _startTimer();
      case CallEventTypes.ended:
      case CallEventTypes.missed:
      case CallEventTypes.rejected:
        if (_state == CallViewState.ended && _lastCall != null) {
          debugPrint('⏱️ [CallViewModel] Call already ended, updating duration if higher: ${event.durationSeconds}s');
          final lateDuration = event.durationSeconds;
          if (lateDuration != null && lateDuration > _lastCall!.durationSeconds) {
            _elapsedSeconds = lateDuration;
            _lastCall = _lastCall!.copyWith(
              durationSeconds: lateDuration,
              recordingPath: event.recordingPath ?? _lastCall!.recordingPath,
            );
          }
          break;
        }
        _onCallEnded(
          event.type,
          nativeDuration: event.durationSeconds,
          recordingPath: event.recordingPath,
        );
      default:
        break;
    }
    notifyListeners();
  }

  Future<void> _onCallEnded(
    String eventType, {
    int? nativeDuration,
    String? recordingPath,
  }) async {
    _stopTimer();
    _state = CallViewState.ended;

    int duration = nativeDuration ?? 0;
    if (duration == 0 && _elapsedSeconds > 0) {
      duration = _elapsedSeconds;
    }

    // 1. Attempt to read official call log duration from Android system with short delay
    if (duration == 0 && _activePhoneNumber != null) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final log = await CallChannel.getLastCallLog(_activePhoneNumber);
        final logDur = (log['durationSeconds'] as num?)?.toInt() ?? 0;
        if (logDur > 0) duration = logDur;
      } catch (_) {}
    }

    // 2. Fallback to start/connected time difference if still 0
    if (duration == 0) {
      if (_connectedTime != null) {
        duration = DateTime.now().difference(_connectedTime!).inSeconds;
      } else if (_callStartTime != null) {
        duration = DateTime.now().difference(_callStartTime!).inSeconds;
      }
    }

    // Fallback to query native recorder if recordingPath was not passed in event
    String? finalRecordingPath = recordingPath;
    if (finalRecordingPath == null || finalRecordingPath.isEmpty) {
      try {
        finalRecordingPath = await CallChannel.getRecordingPath() ?? await CallChannel.stopVoiceRecording();
      } catch (_) {}
    }

    _elapsedSeconds = duration;
    _recordingPath = finalRecordingPath;
    _recordingUrl = null;

    _lastCall = Call(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _callType ?? CallType.outgoing,
      status: _mapEventToStatus(eventType),
      phoneNumber: _activePhoneNumber ?? '',
      durationSeconds: duration,
      startedAt: _callStartTime ?? DateTime.now(),
      leadId: _activeLead?.id,
      leadName: _activeLead?.fullName,
      connectedAt: _connectedTime,
      endedAt: DateTime.now(),
      recordingPath: finalRecordingPath,
      recordingUrl: _recordingUrl,
    );

    // Auto-upload recording to AWS S3 in background if available
    if (finalRecordingPath != null && finalRecordingPath.isNotEmpty) {
      debugPrint('🎙️ [CallViewModel] Starting S3 upload for audio: $finalRecordingPath');
      _uploadRecordingToS3(finalRecordingPath, _activePhoneNumber ?? 'call');
    }

    // Auto-show disposition popup
    Future.delayed(
      Duration(seconds: AppConstants.callDispositionDelaySeconds),
      () {
        if (_state == CallViewState.ended) {
          _showDisposition = true;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _uploadRecordingToS3(String filePath, String phoneNumber) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      _isUploadingRecording = true;
      _uploadProgress = 0.0;
      notifyListeners();

      final s3Url = await AwsS3Service.uploadCallRecording(
        file: file,
        phoneNumber: phoneNumber,
        onProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      if (s3Url != null) {
        _recordingUrl = s3Url;
        if (_lastCall != null) {
          _lastCall = Call(
            id: _lastCall!.id,
            type: _lastCall!.type,
            status: _lastCall!.status,
            phoneNumber: _lastCall!.phoneNumber,
            durationSeconds: _lastCall!.durationSeconds,
            startedAt: _lastCall!.startedAt,
            leadId: _lastCall!.leadId,
            leadName: _lastCall!.leadName,
            agentId: _lastCall!.agentId,
            connectedAt: _lastCall!.connectedAt,
            endedAt: _lastCall!.endedAt,
            disposition: _lastCall!.disposition,
            remarks: _lastCall!.remarks,
            recordingPath: _lastCall!.recordingPath,
            recordingUrl: s3Url,
            isSynced: _lastCall!.isSynced,
          );
        }
        debugPrint('✅ [CallViewModel] Call recording uploaded to S3: $s3Url');
      }
    } catch (e) {
      debugPrint('❌ [CallViewModel] Failed to upload recording to AWS S3: $e');
    } finally {
      _isUploadingRecording = false;
      notifyListeners();
    }
  }

  CallStatus _mapEventToStatus(String eventType) => switch (eventType) {
        CallEventTypes.started => CallStatus.connected,
        CallEventTypes.connected => CallStatus.connected,
        CallEventTypes.ended => CallStatus.ended,
        CallEventTypes.missed => CallStatus.missed,
        CallEventTypes.rejected => CallStatus.rejected,
        _ => CallStatus.ended,
      };

  // ── Commands ───────────────────────────────────────
  Future<void> initiateCall({Lead? lead, String? phoneNumber}) async {
    final phone = lead?.phone ?? phoneNumber;
    if (phone == null || phone.isEmpty) return;

    Lead activeLead;
    if (lead != null) {
      String resolvedName = lead.fullName;
      if (resolvedName.startsWith('Lead ') || resolvedName == 'Unknown Contact' || resolvedName == phone) {
        final contactName = await ContactService.lookupContactNameAsync(phone);
        if (contactName != null && contactName.isNotEmpty) {
          resolvedName = contactName;
        }
      }
      activeLead = lead.copyWith(
        fullName: resolvedName,
        status: lead.status == LeadStatus.newLead ? LeadStatus.contacted : lead.status,
        lastActivityAt: DateTime.now(),
      );
      await RemoteLeadRepository.updateLeadInRepo(activeLead);
    } else {
      activeLead = await RemoteLeadRepository.findOrCreateLead(phone);
    }

    _activeLead = activeLead;
    _activePhoneNumber = phone;
    _callStartTime = DateTime.now();
    _connectedTime = null;
    _elapsedSeconds = 0;
    _state = CallViewState.requestingPermission;
    notifyListeners();

    // Request permissions
    final statuses = await [
      Permission.phone,
      Permission.microphone,
      Permission.contacts,
    ].request();

    if (statuses[Permission.phone] != PermissionStatus.granted) {
      _errorMessage = 'Call permission denied. Please enable in settings.';
      _state = CallViewState.error;
      notifyListeners();
      return;
    }

    _state = CallViewState.initiating;
    notifyListeners();

    // Start background monitoring service
    try {
      await CallChannel.startCallMonitoring();
    } catch (e) {
      debugPrint('Call monitoring service skipped: $e');
    }

    final result = await CallChannel.initiateCall(phone);
    result.fold(
      onSuccess: (_) {
        _state = CallViewState.dialing;
        _elapsedSeconds = 0;
      },
      onFailure: (e) {
        _errorMessage = e.message;
        _state = CallViewState.error;
      },
    );
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await CallChannel.setSpeakerphoneOn(_isSpeakerOn);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await CallChannel.setMicrophoneMute(_isMuted);
    notifyListeners();
  }

  void toggleKeypad() {
    _showKeypad = !_showKeypad;
    notifyListeners();
  }

  void appendDtmf(String digit) {
    _dtmfDigits += digit;
    CallChannel.sendDtmf(digit);
    notifyListeners();
  }

  void clearDtmf() {
    _dtmfDigits = '';
    notifyListeners();
  }

  void toggleNotesSheet() {
    _showNotesSheet = !_showNotesSheet;
    notifyListeners();
  }

  void updateLiveNotes(String text) {
    _liveNotes = text;
    notifyListeners();
  }

  void toggleMinimized() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }

  void dismissDisposition() {
    _showDisposition = false;
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _state = CallViewState.idle;
    _activeLead = null;
    _activePhoneNumber = null;
    _callStartTime = null;
    _connectedTime = null;
    _elapsedSeconds = 0;
    _lastCall = null;
    _showDisposition = false;
    _isSpeakerOn = false;
    _isMuted = false;
    _showKeypad = false;
    _showNotesSheet = false;
    _isMinimized = false;
    _dtmfDigits = '';
    _liveNotes = '';
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String get durationDisplay {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _callEventSub?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
