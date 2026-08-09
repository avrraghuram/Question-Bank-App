import 'web_protection_stub.dart'
    if (dart.library.html) 'web_protection_html.dart';

void installWebProtection() => installWebProtectionImpl();
