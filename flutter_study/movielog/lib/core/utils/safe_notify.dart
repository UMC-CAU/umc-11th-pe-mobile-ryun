import 'package:flutter/foundation.dart';

mixin SafeNotify on ChangeNotifier {
  bool isDisposed = false;
  void notifyIfAlive() {
    if (!isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
