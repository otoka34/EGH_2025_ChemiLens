import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MoleculeViewerScreen extends StatefulWidget {
  final String sdfData;
  final String moleculeName;

  const MoleculeViewerScreen({
    super.key,
    required this.sdfData,
    required this.moleculeName,
  });

  @override
  State<MoleculeViewerScreen> createState() => _MoleculeViewerScreenState();
}

class _MoleculeViewerScreenState extends State<MoleculeViewerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final htmlContent = _createHtml(widget.sdfData);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moleculeName),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  String _createHtml(String sdf) {
    // SDFデータ内の改行や特殊文字をJavaScript文字列リテラルとして扱えるようにエスケープする
    final escapedSdf = sdf
        .replaceAll(r'\', r'\\') // Backslash
        .replaceAll(r'`', r'\`')      // Backtick
        .replaceAll(r'$', r'\$');   // Dollar sign

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; }
        #container { width: 100%; height: 100%; }
      </style>
    </head>
    <body>
      <div id="container"></div>
      <script src="https://3dmol.org/build/3Dmol-min.js"></script>
      <script>
        (function() {
          const sdfData = `${escapedSdf}`;
          const element = document.getElementById('container');
          const config = { backgroundColor: 'white' };
          const viewer = \$3Dmol.createViewer(element, config);
          
          viewer.addModel(sdfData, 'sdf');
          viewer.setStyle({}, {stick: {}});
          viewer.zoomTo();
          viewer.render();
        })();
      </script>
    </body>
    </html>
    ''';
  }
}