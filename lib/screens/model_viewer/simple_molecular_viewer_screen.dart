import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SimpleMolecularViewerScreen extends StatefulWidget {
  final String sdfData;
  final String moleculeName;
  final String? formula;

  const SimpleMolecularViewerScreen({
    super.key,
    required this.sdfData,
    required this.moleculeName,
    this.formula,
  });

  @override
  State<SimpleMolecularViewerScreen> createState() => _SimpleMolecularViewerScreenState();
}

class _SimpleMolecularViewerScreenState extends State<SimpleMolecularViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _loadMolecule();
          },
        ),
      )
      ..loadHtmlString(_generateSimpleHTML());
  }

  void _loadMolecule() {
    // SDFデータをJavaScriptに渡して3Dmol.jsで描画
    final escapedSdf = jsonEncode(widget.sdfData);
    final script = '''
      if (typeof \$3Dmol !== 'undefined' && viewer) {
        try {
          viewer.clear();
          viewer.addModel($escapedSdf, 'sdf');
          viewer.setStyle({}, {
            stick: { colorscheme: 'default', radius: 0.15 },
            sphere: { scale: 0.25, colorscheme: 'default' }
          });
          viewer.zoomTo();
          viewer.render();
          console.log('Molecule loaded successfully');
        } catch(e) {
          console.error('Error loading molecule:', e);
        }
      } else {
        console.error('3Dmol.js not ready');
      }
    ''';
    _controller.runJavaScript(script);
  }

  String _generateSimpleHTML() {
    final escapedFormula = widget.formula?.replaceAll('<', '&lt;').replaceAll('>', '&gt;') ?? '';
    final escapedMoleculeName = widget.moleculeName.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    
    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Molecular Viewer</title>
    <script src="https://cdn.jsdelivr.net/npm/3dmol@1.8.0/build/3Dmol-min.js"></script>
    <style>
        body { 
          margin: 0; 
          padding: 0; 
          font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
          background: #f5f5f5; 
        }
        .container { 
          width: 100%; 
          height: 100vh; 
          display: flex; 
          flex-direction: column; 
        }
        .info-panel { 
          background: white; 
          padding: 15px; 
          margin: 10px; 
          border-radius: 10px; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        .molecule-name { 
          font-size: 18px; 
          font-weight: bold; 
          margin-bottom: 8px; 
          color: #333; 
        }
        .formula { 
          background: #e3f2fd; 
          color: #1976d2; 
          padding: 8px 12px; 
          border-radius: 6px; 
          font-family: monospace; 
          font-weight: 600; 
          margin-bottom: 12px; 
          display: inline-block; 
          border: 1px solid #bbdefb; 
        }
        .viewer-container { 
          flex: 1; 
          position: relative; 
          background: #ffffff; 
          border-radius: 10px; 
          margin: 10px; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
          overflow: hidden; 
        }
        #viewer { 
          width: 100%; 
          height: 100%; 
          position: relative; 
        }
        .loading { 
          position: absolute; 
          top: 50%; 
          left: 50%; 
          transform: translate(-50%, -50%); 
          color: #666; 
          text-align: center;
        }
        .controls { 
          text-align: center; 
          padding: 10px; 
          background: white; 
          margin: 0 10px 10px; 
          border-radius: 8px; 
          box-shadow: 0 1px 3px rgba(0,0,0,0.1); 
          font-size: 14px; 
          color: #666; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="info-panel">
            <div class="molecule-name">$escapedMoleculeName</div>
            ${escapedFormula.isNotEmpty ? '<div class="formula">$escapedFormula</div>' : ''}
        </div>
        
        <div class="viewer-container">
            <div id="viewer">
                <div class="loading">Loading 3D molecular model...</div>
            </div>
        </div>
        
        <div class="controls">
            Controls: Drag to rotate • Pinch to zoom
        </div>
    </div>

    <script>
        let viewer;
        
        function initializeViewer() {
          try {
            const element = document.getElementById('viewer');
            const config = { backgroundColor: 'white' };
            
            if (typeof \$3Dmol !== 'undefined') {
              viewer = \$3Dmol.createViewer(element, config);
              viewer.setBackgroundColor('white');
              console.log('3Dmol.js viewer initialized successfully');
            } else {
              console.error('3Dmol.js not loaded');
              setTimeout(initializeViewer, 100);
            }
          } catch(e) {
            console.error('Error initializing viewer:', e);
          }
        }
        
        document.addEventListener('DOMContentLoaded', initializeViewer);
        
        window.addEventListener('error', function(e) {
            console.error('JavaScript error:', e.error);
        });
    </script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moleculeName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMolecule,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading 3D molecular viewer...'),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.close),
      ),
    );
  }
}