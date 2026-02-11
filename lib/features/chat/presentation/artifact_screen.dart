import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArtifactScreen extends StatefulWidget {
  const ArtifactScreen({super.key, required this.title, required this.html});

  final String title;
  final String html;

  @override
  State<ArtifactScreen> createState() => _ArtifactScreenState();
}

class _ArtifactScreenState extends State<ArtifactScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
