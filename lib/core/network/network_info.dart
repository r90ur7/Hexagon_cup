/// Interface to check network connectivity
/// This abstraction allows easy mocking in tests
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo
/// In a real app, you would use connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: Implement with connectivity_plus package
    return true;
  }
}
