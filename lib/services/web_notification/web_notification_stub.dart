class WebNotificationService {
  static final WebNotificationService instance = WebNotificationService._();
  
  WebNotificationService._();

  void initialize() {
    // Stub for non-web platforms. Does nothing.
  }

  Future<void> requestPermissionManually() async {
    // Stub
  }

  void dispose() {
    // Stub
  }
}
