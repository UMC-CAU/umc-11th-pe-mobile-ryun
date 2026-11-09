import 'package:flutter/foundation.dart';

// Learning identifier only. Intentionally never persisted; this is not login.
class LearningMemberSession extends ChangeNotifier {
  int? _memberId;
  int? get memberId => _memberId;
  void setMemberId(int id) {
    if (id < 1) throw ArgumentError('회원 ID가 올바르지 않습니다.');
    _memberId = id;
    notifyListeners();
  }

  void clear() {
    _memberId = null;
    notifyListeners();
  }
}
