import 'dart:html' as html;

void installWebProtectionImpl() {
  html.document.onContextMenu.listen((event) {
    event.preventDefault();
  });

  html.window.onKeyDown.listen((event) {
    final key = event.key?.toLowerCase();
    final ctrl = event.ctrlKey || event.metaKey;
    if (ctrl && (key == 'u' || key == 's' || key == 'i' || key == 'j')) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (event.keyCode == 123) {
      event.preventDefault();
      event.stopPropagation();
    }
  });
}
