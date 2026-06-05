import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum OrgBuzzStatus { idle, creating, readyForLater, joining, error }

class OrgBuzzState {
  final OrgBuzzStatus status;
  final String? buzzId;
  final String? channelId;
  final String? buzzCode;
  final String? meetingLink;
  final String? errorMessage;
  final List<BuzzMember> searchResults;
  final Set<String> selectedMemberIds;
  final bool isInviting;
  final bool isSearching;
  final List<BuzzInvitation> pendingInvitations;

  const OrgBuzzState({
    this.status = OrgBuzzStatus.idle,
    this.buzzId,
    this.channelId,
    this.buzzCode,
    this.meetingLink,
    this.errorMessage,
    this.searchResults = const [],
    this.selectedMemberIds = const {},
    this.isInviting = false,
    this.isSearching = false,
    this.pendingInvitations = const [],
  });

  OrgBuzzState copyWith({
    OrgBuzzStatus? status,
    String? buzzId,
    String? channelId,
    String? buzzCode,
    String? meetingLink,
    String? errorMessage,
    List<BuzzMember>? searchResults,
    Set<String>? selectedMemberIds,
    bool? isInviting,
    bool? isSearching,
    List<BuzzInvitation>? pendingInvitations,
  }) {
    return OrgBuzzState(
      status: status ?? this.status,
      buzzId: buzzId ?? this.buzzId,
      channelId: channelId ?? this.channelId,
      buzzCode: buzzCode ?? this.buzzCode,
      meetingLink: meetingLink ?? this.meetingLink,
      errorMessage: errorMessage ?? this.errorMessage,
      searchResults: searchResults ?? this.searchResults,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      isInviting: isInviting ?? this.isInviting,
      isSearching: isSearching ?? this.isSearching,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    );
  }
}

class OrgBuzzNotifier extends ChangeNotifier {
  final Ref _ref;
  OrgBuzzState _state = const OrgBuzzState();

  OrgBuzzNotifier(this._ref);

  OrgBuzzState get state => _state;

  // ── Delegation getters — lets UI do ref.watch(orgBuzzProvider).status etc. ──
  OrgBuzzStatus get status => _state.status;
  String? get buzzId => _state.buzzId;
  String? get channelId => _state.channelId;
  String? get buzzCode => _state.buzzCode;
  String? get meetingLink => _state.meetingLink;
  String? get errorMessage => _state.errorMessage;
  List<BuzzMember> get searchResults => _state.searchResults;
  Set<String> get selectedMemberIds => _state.selectedMemberIds;
  bool get isInviting => _state.isInviting;
  bool get isSearching => _state.isSearching;
  List<BuzzInvitation> get pendingInvitations => _state.pendingInvitations;

  OrgBuzzRepository get _repo => _ref.read(orgBuzzRepositoryProvider);
  ActiveCallNotifier get _callNotifier => _ref.read(activeCallProvider);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Creates a buzz and immediately activates the Agora session.
  Future<void> startInstantMeeting() async {
    _state = _state.copyWith(status: OrgBuzzStatus.creating, errorMessage: null);
    notifyListeners();

    try {
      final orgId = _ref.read(authNotifierProvider).user?.currentOrg ?? '';
      final data = await _repo.createOrgBuzz(orgId: orgId);
      _applyBuzzData(data);
      _callNotifier.activateOrgBuzz(
        buzzId: data['buzz_id'] as String,
        channelId: data['channel_id'] as String,
        token: data['token'] as String,
        appId: data['app_id'] as String,
        channelName: data['channel_name'] as String,
        buzzCode: data['buzz_code'] as String?,
      );
      _state = _state.copyWith(status: OrgBuzzStatus.idle);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: OrgBuzzStatus.error,
        errorMessage: 'Failed to start meeting. Please try again.',
      );
      notifyListeners();
    }
  }

  /// Creates a buzz, immediately joins the Agora session, and sets status
  /// to [readyForLater] so the UI can show the shareable link overlay.
  Future<void> createForLater() async {
    _state = _state.copyWith(status: OrgBuzzStatus.creating, errorMessage: null);
    notifyListeners();

    try {
      final orgId = _ref.read(authNotifierProvider).user?.currentOrg ?? '';
      final data = await _repo.createOrgBuzz(orgId: orgId);
      _applyBuzzData(data);
      // Join Agora immediately — same as startInstantMeeting.
      // BuzzMeetingView will render, and the ready card overlays on top.
      _callNotifier.activateOrgBuzz(
        buzzId: data['buzz_id'] as String,
        channelId: data['channel_id'] as String,
        token: data['token'] as String,
        appId: data['app_id'] as String,
        channelName: data['channel_name'] as String,
        buzzCode: data['buzz_code'] as String?,
      );
      // readyForLater signals home_view to overlay the BuzzReadyCard
      _state = _state.copyWith(status: OrgBuzzStatus.readyForLater);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: OrgBuzzStatus.error,
        errorMessage: 'Failed to create meeting. Please try again.',
      );
      notifyListeners();
    }
  }

  /// Joins an existing buzz by code or link (strips URL prefix if needed).
  Future<void> joinByCodeOrLink(String input) async {
    final code = _extractCode(input);
    if (code.isEmpty) {
      _state = _state.copyWith(
        status: OrgBuzzStatus.error,
        errorMessage: 'Please enter a valid meeting code or link.',
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(status: OrgBuzzStatus.joining, errorMessage: null);
    notifyListeners();

    try {
      final data = await _repo.joinBuzzByCode(code);
      _applyBuzzData(data);
      _callNotifier.activateOrgBuzz(
        buzzId: data['buzz_id'] as String,
        channelId: data['channel_id'] as String,
        token: data['token'] as String,
        appId: data['app_id'] as String,
        channelName: data['channel_name'] as String,
        buzzCode: code,
      );
      _state = _state.copyWith(status: OrgBuzzStatus.idle);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: OrgBuzzStatus.error,
        errorMessage: 'Could not join meeting. Check the code and try again.',
      );
      notifyListeners();
    }
  }

  /// Joins the "ready" buzz created with [createForLater].
  Future<void> joinReadyBuzz() async {
    final code = _state.buzzCode ?? _state.buzzId ?? '';
    if (code.isEmpty) return;
    await joinByCodeOrLink(code);
  }

  /// Searches org members for invitation.
  Future<void> searchMembers(String query) async {
    if (query.trim().isEmpty) {
      _state = _state.copyWith(searchResults: [], isSearching: false);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isSearching: true);
    notifyListeners();

    final orgId = _ref.read(authNotifierProvider).user?.currentOrg ?? '';
    final channelId = _state.channelId ?? '';
    
    List<BuzzMember> results;
    if (channelId.isEmpty && orgId.isNotEmpty) {
      results = await _repo.searchOrgMembers(
        orgId: orgId,
        query: query.trim(),
      );
    } else {
      results = await _repo.searchChannelMembers(
        channelId: channelId,
        buzzId: _state.buzzId ?? '',
        query: query.trim(),
      );
    }

    _state = _state.copyWith(searchResults: results, isSearching: false);
    notifyListeners();
  }

  void toggleMemberSelection(String memberId) {
    final selected = Set<String>.from(_state.selectedMemberIds);
    if (selected.contains(memberId)) {
      selected.remove(memberId);
    } else {
      selected.add(memberId);
    }
    _state = _state.copyWith(selectedMemberIds: selected);
    notifyListeners();
  }

  void clearSelection() {
    _state = _state.copyWith(
      selectedMemberIds: {},
      searchResults: [],
    );
    notifyListeners();
  }

  Future<bool> sendInvitations() async {
    if (_state.selectedMemberIds.isEmpty || _state.buzzId == null) return false;
    _state = _state.copyWith(isInviting: true);
    notifyListeners();

    final ok = await _repo.inviteUsersToBuzz(
      _state.buzzId!,
      _state.selectedMemberIds.toList(),
    );
    _state = _state.copyWith(
      isInviting: false,
      selectedMemberIds: {},
      searchResults: [],
    );
    notifyListeners();
    return ok;
  }

  void dismissError() {
    _state = _state.copyWith(status: OrgBuzzStatus.idle, errorMessage: null);
    notifyListeners();
  }

  void reset() {
    _state = const OrgBuzzState();
    notifyListeners();
  }

  /// Clears the readyForLater overlay without leaving the meeting.
  void dismissReadyCard() {
    _state = _state.copyWith(status: OrgBuzzStatus.idle);
    notifyListeners();
  }

  /// Fetches pending buzz invitations from the server.
  Future<void> fetchPendingInvitations() async {
    try {
      final invitations = await _repo.getPendingInvitations();
      _state = _state.copyWith(pendingInvitations: invitations);
      notifyListeners();
    } catch (e) {
      AppLogger.e('fetchPendingInvitations failed', tag: 'OrgBuzzNotifier', error: e);
    }
  }

  /// Ends the current buzz via the API and tears down the Agora session.
  Future<void> endCurrentBuzz() async {
    final currentBuzzId = _state.buzzId;
    if (currentBuzzId != null) {
      try {
        await _repo.endBuzz(currentBuzzId);
      } catch (e) {
        AppLogger.e('endBuzz failed', tag: 'OrgBuzzNotifier', error: e);
      }
    }
    await _callNotifier.leaveCall();
    _state = const OrgBuzzState();
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _applyBuzzData(Map<String, dynamic> data) {
    final code = (data['buzz_code'] ?? '').toString();
    final link = code.isNotEmpty ? 'buzz.zedu.chat/$code' : '';
    _state = _state.copyWith(
      buzzId: data['buzz_id']?.toString(),
      channelId: data['channel_id']?.toString(),
      buzzCode: code.isNotEmpty ? code : null,
      meetingLink: link.isNotEmpty ? link : null,
    );
  }

  String _extractCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    // Strip common URL prefixes to get just the code segment.
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : '';
    }
    // If it contains a slash without a scheme, treat part after last slash as code.
    if (trimmed.contains('/')) {
      return trimmed.split('/').last;
    }
    return trimmed;
  }
}

final orgBuzzProvider = ChangeNotifierProvider<OrgBuzzNotifier>((ref) {
  return OrgBuzzNotifier(ref);
});
