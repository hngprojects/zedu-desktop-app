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
    );
  }
}

class OrgBuzzNotifier extends ChangeNotifier {
  final Ref _ref;
  OrgBuzzState _state = const OrgBuzzState();

  OrgBuzzNotifier(this._ref);

  OrgBuzzState get state => _state;

  OrgBuzzRepository get _repo => _ref.read(orgBuzzRepositoryProvider);
  ActiveCallNotifier get _callNotifier => _ref.read(activeCallProvider);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Creates a buzz and immediately activates the Agora session.
  Future<void> startInstantMeeting() async {
    _state = _state.copyWith(status: OrgBuzzStatus.creating, errorMessage: null);
    notifyListeners();

    try {
      final data = await _repo.createOrgBuzz();
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

  /// Creates a buzz and shows the "ready" card without joining Agora yet.
  Future<void> createForLater() async {
    _state = _state.copyWith(status: OrgBuzzStatus.creating, errorMessage: null);
    notifyListeners();

    try {
      final data = await _repo.createOrgBuzz();
      _applyBuzzData(data);
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

    final results = await _repo.searchChannelMembers(
      channelId: _state.channelId ?? '',
      buzzId: _state.buzzId ?? '',
      query: query.trim(),
    );
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
