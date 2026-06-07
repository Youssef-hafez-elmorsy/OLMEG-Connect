// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

bool openExternalLink(String url) {
  html.window.open(url, '_blank', 'noopener,noreferrer');
  return true;
}
