class RefreshNotifier {
  static final RefreshNotifier _instance = RefreshNotifier._internal();
  factory RefreshNotifier() => _instance;
  RefreshNotifier._internal();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  void notifyDataChanged() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

typedef VoidCallback = void Function();