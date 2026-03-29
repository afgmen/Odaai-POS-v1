// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show Blob, Url, AnchorElement;

/// Downloads an Excel file in the browser via a Blob URL.
void downloadExcelBytes(List<int> bytes, String fileName) {
  final blob = html.Blob(
    [bytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
