import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/domain/app_settings.dart';

class ArtifactScreen extends StatefulWidget {
  const ArtifactScreen({
    super.key,
    required this.title,
    required this.html,
    required this.safetyMode,
  });

  final String title;
  final String html;
  final ArtifactSafetyMode safetyMode;

  @override
  State<ArtifactScreen> createState() => _ArtifactScreenState();
}

class _ArtifactScreenState extends State<ArtifactScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final sanitizedHtml = _buildHtmlByMode(widget.html, widget.safetyMode);
    final allowExternal = widget.safetyMode == ArtifactSafetyMode.trusted;
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.safetyMode == ArtifactSafetyMode.safe
            ? JavaScriptMode.disabled
            : JavaScriptMode.unrestricted,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (allowExternal) {
              return NavigationDecision.navigate;
            }
            if (request.url.startsWith('about:blank')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(sanitizedHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}

String _buildHtmlByMode(String source, ArtifactSafetyMode mode) {
  var html = source.trim();
  if (mode == ArtifactSafetyMode.safe) {
    html = _stripScriptsAndDangerousAttrs(html);
  }
  if (mode != ArtifactSafetyMode.trusted) {
    html = _stripRemoteLoads(html);
  }
  final csp = switch (mode) {
    ArtifactSafetyMode.safe =>
      "default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none';",
    ArtifactSafetyMode.interactive =>
      "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; font-src data:; connect-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none';",
    ArtifactSafetyMode.trusted =>
      "default-src * data: blob: 'unsafe-inline' 'unsafe-eval';",
  };

  final hasHead = RegExp(r'<head[^>]*>', caseSensitive: false).hasMatch(html);
  final meta = '<meta http-equiv="Content-Security-Policy" content="$csp">';
  if (hasHead) {
    final reg = RegExp(r'<head[^>]*>', caseSensitive: false);
    final match = reg.firstMatch(html);
    if (match != null) {
      final headTag = match.group(0) ?? '<head>';
      return html.replaceFirst(reg, '$headTag$meta');
    }
  }
  return '<!doctype html><html><head>$meta</head><body>$html</body></html>';
}

String _stripScriptsAndDangerousAttrs(String html) {
  var out = html;
  out = out.replaceAll(
    RegExp(r'<script[\s\S]*?>[\s\S]*?</script>', caseSensitive: false),
    '',
  );
  out = out.replaceAll(
    RegExp("\\son\\w+\\s*=\\s*(\".*?\"|'.*?'|[^\\s>]+)", caseSensitive: false),
    '',
  );
  out = out.replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), '');
  out = out.replaceAll(
    RegExp(r'<iframe[\s\S]*?>[\s\S]*?</iframe>', caseSensitive: false),
    '',
  );
  return out;
}

String _stripRemoteLoads(String html) {
  var out = html;
  out = out.replaceAll(
    RegExp(r'\s(src|href)\s*=\s*"(https?:)?//[^"]*"', caseSensitive: false),
    '',
  );
  out = out.replaceAll(
    RegExp(r"\s(src|href)\s*=\s*'(https?:)?//[^']*'", caseSensitive: false),
    '',
  );
  return out;
}
