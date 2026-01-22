import 'package:web/web.dart' as web;

class WebHelper {
  static String get currentUrl => web.window.location.href;
  static String get currentPath => web.window.location.pathname;
  static String get currentOrigin => web.window.location.origin;
  
  static void replaceState(String? url) {
    web.window.history.replaceState(null, '', url ?? web.window.location.pathname);
  }
  
  static void reload() {
    web.window.location.reload();
  }
  
  static void assign(String url) {
    web.window.location.assign(url);
  }
}
