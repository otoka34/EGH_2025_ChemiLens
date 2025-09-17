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
    print('SimpleMolecularViewerScreen: Initializing ${widget.moleculeName} (${widget.sdfData.length} chars)');
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // print('WebView page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _loadMolecule();
          },
          onWebResourceError: (WebResourceError error) {
            // Only print critical errors
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout) {
              print('WebView critical error: ${error.description}');
            }
          },
        ),
      )
      // Console logging disabled to reduce output
      // ..addJavaScriptChannel(
      //   'ConsoleLog',
      //   onMessageReceived: (JavaScriptMessage message) {
      //     print('WebView Console: ${message.message}');
      //   },
      // )
      ..loadHtmlString(_generateSimpleHTML());
  }

  Set<String> _extractAtomsFromSDF(String sdfData) {
    final atoms = <String>{};
    final lines = sdfData.split('\n');
    
    // SDFファイルの原子ブロック部分を解析
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // 原子行の形式: x y z [atom_symbol] ...
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        // 4番目の要素が原子記号の可能性が高い
        final possibleAtom = parts[3];
        if (possibleAtom.length <= 2 && possibleAtom.isNotEmpty) {
          // 一般的な原子記号は1-2文字
          final firstChar = possibleAtom[0];
          if (firstChar.toUpperCase() == firstChar && RegExp(r'[A-Z]').hasMatch(firstChar)) {
            atoms.add(possibleAtom);
          }
        }
      }
    }
    
    return atoms;
  }

  void _loadMolecule() {
    // SDFデータをJavaScriptに渡して3Dmol.jsで描画
    final escapedSdf = jsonEncode(widget.sdfData);
    
    // 分子に含まれる原子を抽出
    final presentAtoms = _extractAtomsFromSDF(widget.sdfData);
    final atomsJson = jsonEncode(presentAtoms.toList());
    
    final script = '''
      if (typeof \$3Dmol !== 'undefined' && viewer) {
        try {
          viewer.clear();
          viewer.addModel($escapedSdf, 'sdf');
          
          // 棒球モデル（stick and ball）を基本表示とする
          viewer.setStyle({}, {
            stick: { 
              colorscheme: 'default', 
              radius: 0.15 
            },
            sphere: { 
              scale: 0.2, 
              colorscheme: 'default'
            }
          });
          
          // より良い照明設定
          viewer.setBackgroundColor('#ffffff');
          
          currentZoom = 1;
          viewer.zoomTo();
          viewer.render();
          
          // 色分けレジェンドを更新
          updateAtomLegend($atomsJson);
          
          // console.log('Molecule loaded successfully');
        } catch(e) {
          // console.error('Error loading molecule:', e);
        }
      } else {
        // console.error('3Dmol.js not ready');
        setTimeout(() => {
          if (typeof \$3Dmol !== 'undefined' && viewer) {
            _loadMolecule();
          }
        }, 500);
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
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
        .zoom-controls {
          position: absolute;
          top: 15px;
          right: 15px;
          display: flex;
          flex-direction: column;
          gap: 10px;
          z-index: 100;
        }
        .zoom-btn {
          width: 44px;
          height: 44px;
          border-radius: 22px;
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #ddd;
          box-shadow: 0 2px 8px rgba(0,0,0,0.15);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 20px;
          font-weight: bold;
          color: #333;
          cursor: pointer;
          user-select: none;
          transition: all 0.2s ease;
        }
        .zoom-btn:active {
          transform: scale(0.95);
          background: rgba(240, 240, 240, 0.9);
        }
        .controls { 
          text-align: center; 
          padding: 12px; 
          background: white; 
          margin: 0 10px 10px; 
          border-radius: 8px; 
          box-shadow: 0 1px 3px rgba(0,0,0,0.1); 
          font-size: 14px; 
          color: #666; 
        }
        .control-buttons {
          display: flex;
          justify-content: center;
          gap: 15px;
          margin-top: 8px;
        }
        .control-btn {
          padding: 8px 16px;
          border: 1px solid #ddd;
          border-radius: 6px;
          background: #f8f9fa;
          color: #333;
          font-size: 12px;
          cursor: pointer;
          transition: all 0.2s ease;
        }
        .control-btn:active {
          background: #e9ecef;
          transform: scale(0.95);
        }
        .atom-legend {
          background: white;
          margin: 10px;
          padding: 12px;
          border-radius: 8px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .legend-title {
          font-weight: bold;
          margin-bottom: 8px;
          color: #333;
          font-size: 14px;
        }
        .legend-items {
          display: flex;
          flex-wrap: wrap;
          gap: 12px;
        }
        .legend-item {
          display: flex;
          align-items: center;
          font-size: 12px;
          color: #555;
        }
        .legend-color {
          width: 12px;
          height: 12px;
          border-radius: 50%;
          margin-right: 4px;
          border: 1px solid rgba(0,0,0,0.2);
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
                <div class="zoom-controls">
                    <div class="zoom-btn" onclick="zoomIn()">+</div>
                    <div class="zoom-btn" onclick="zoomOut()">−</div>
                    <div class="zoom-btn" onclick="resetView()">⌂</div>
                </div>
            </div>
        </div>
        
        <div class="atom-legend">
            <div class="legend-title">原子の色分け</div>
            <div class="legend-items" id="legend-items">
                <!-- 動的に生成される -->
            </div>
        </div>
        
        <div class="controls">
            <div class="control-buttons">
                <div class="control-btn" onclick="changeStyle('stick')">棒球モデル</div>
                <div class="control-btn" onclick="changeStyle('sphere')">空間充填</div>
                <div class="control-btn" onclick="changeStyle('cartoon')">リボン</div>
            </div>
        </div>
    </div>

    <script>
        let viewer;
        let currentZoom = 1;
        
        // Console logging disabled to reduce output
        // Uncomment below lines if debugging is needed
        /*
        const originalLog = console.log;
        const originalError = console.error;
        console.log = function(...args) {
          originalLog.apply(console, args);
          if (window.ConsoleLog) {
            window.ConsoleLog.postMessage(args.join(' '));
          }
        };
        console.error = function(...args) {
          originalError.apply(console, args);
          if (window.ConsoleLog) {
            window.ConsoleLog.postMessage('ERROR: ' + args.join(' '));
          }
        };
        */
        
        function initializeViewer() {
          try {
            const element = document.getElementById('viewer');
            const config = { 
              backgroundColor: 'white',
              enableMouse: true,
              enableTouch: true
            };
            
            if (typeof \$3Dmol !== 'undefined') {
              viewer = \$3Dmol.createViewer(element, config);
              viewer.setBackgroundColor('white');
              
              // Enable mouse and touch interactions
              viewer.enableMouse();
              viewer.enableTouch();
              
              // console.log('3Dmol.js viewer initialized successfully');
            } else {
              // console.error('3Dmol.js not loaded');
              setTimeout(initializeViewer, 100);
            }
          } catch(e) {
            // console.error('Error initializing viewer:', e);
          }
        }
        
        let isZooming = false;
        let zoomTimeout;
        
        function zoomIn() {
          if (viewer && !isZooming) {
            isZooming = true;
            clearTimeout(zoomTimeout);
            
            currentZoom *= 1.3;
            viewer.zoom(currentZoom);
            viewer.render();
            
            zoomTimeout = setTimeout(() => {
              isZooming = false;
            }, 100);
          }
        }
        
        function zoomOut() {
          if (viewer && !isZooming) {
            isZooming = true;
            clearTimeout(zoomTimeout);
            
            currentZoom /= 1.3;
            viewer.zoom(currentZoom);
            viewer.render();
            
            zoomTimeout = setTimeout(() => {
              isZooming = false;
            }, 100);
          }
        }
        
        function resetView() {
          if (viewer && !isZooming) {
            isZooming = true;
            clearTimeout(zoomTimeout);
            
            currentZoom = 1;
            viewer.zoomTo();
            viewer.render();
            
            zoomTimeout = setTimeout(() => {
              isZooming = false;
            }, 100);
          }
        }
        
        function updateAtomLegend(presentAtoms) {
          const atomColors = {
            'H': { color: '#FFFFFF', borderColor: '#CCCCCC', name: '水素' },
            'C': { color: '#909090', borderColor: '#909090', name: '炭素' },
            'N': { color: '#3050F8', borderColor: '#3050F8', name: '窒素' },
            'O': { color: '#FF0D0D', borderColor: '#FF0D0D', name: '酸素' },
            'S': { color: '#FFFF30', borderColor: '#FFFF30', name: '硫黄' },
            'Cl': { color: '#1FF01F', borderColor: '#1FF01F', name: '塩素' },
            'F': { color: '#80D1E3', borderColor: '#80D1E3', name: 'フッ素' },
            'P': { color: '#A020F0', borderColor: '#A020F0', name: 'リン' },
            'B': { color: '#FFC0CB', borderColor: '#FFC0CB', name: 'ホウ素' },
            'Br': { color: '#B87333', borderColor: '#B87333', name: '臭素' },
            'I': { color: '#9400D3', borderColor: '#9400D3', name: 'ヨウ素' },
            'Mg': { color: '#8AFF00', borderColor: '#8AFF00', name: 'マグネシウム' },
            'Ca': { color: '#3DFF00', borderColor: '#3DFF00', name: 'カルシウム' },
            'Fe': { color: '#E06633', borderColor: '#E06633', name: '鉄' },
            'Zn': { color: '#7D80B0', borderColor: '#7D80B0', name: '亜鉛' },
            'Na': { color: '#AB5CF2', borderColor: '#AB5CF2', name: 'ナトリウム' },
            'K': { color: '#8F40D4', borderColor: '#8F40D4', name: 'カリウム' }
          };
          
          const legendContainer = document.getElementById('legend-items');
          if (!legendContainer) return;
          
          legendContainer.innerHTML = '';
          
          presentAtoms.forEach(atom => {
            const atomInfo = atomColors[atom];
            if (atomInfo) {
              const legendItem = document.createElement('div');
              legendItem.className = 'legend-item';
              
              const colorDiv = document.createElement('div');
              colorDiv.className = 'legend-color';
              colorDiv.style.backgroundColor = atomInfo.color;
              colorDiv.style.borderColor = atomInfo.borderColor;
              
              const labelSpan = document.createElement('span');
              labelSpan.textContent = atom + '（' + atomInfo.name + '）';
              
              legendItem.appendChild(colorDiv);
              legendItem.appendChild(labelSpan);
              legendContainer.appendChild(legendItem);
            }
          });
        }

        function changeStyle(styleType) {
          if (viewer) {
            viewer.removeAllModels();
            // Re-add the model with new style
            setTimeout(() => {
              window.webkit.messageHandlers.reloadMolecule.postMessage('reload');
            }, 100);
          }
        }
        
        // Touch gesture handling for better mobile experience
        let lastTouchDistance = 0;
        let initialTouchDistance = 0;
        
        document.getElementById('viewer').addEventListener('touchstart', function(e) {
          if (e.touches.length === 2) {
            const touch1 = e.touches[0];
            const touch2 = e.touches[1];
            initialTouchDistance = Math.hypot(
              touch1.clientX - touch2.clientX,
              touch1.clientY - touch2.clientY
            );
            lastTouchDistance = initialTouchDistance;
          }
        }, { passive: true });
        
        document.getElementById('viewer').addEventListener('touchmove', function(e) {
          if (e.touches.length === 2 && !isZooming) {
            const touch1 = e.touches[0];
            const touch2 = e.touches[1];
            const currentDistance = Math.hypot(
              touch1.clientX - touch2.clientX,
              touch1.clientY - touch2.clientY
            );
            
            if (lastTouchDistance > 0) {
              const zoomFactor = currentDistance / lastTouchDistance;
              currentZoom *= zoomFactor;
              if (viewer) {
                viewer.zoom(currentZoom);
                viewer.render();
              }
            }
            lastTouchDistance = currentDistance;
          }
        }, { passive: true });
        
        document.addEventListener('DOMContentLoaded', initializeViewer);
        
        // Error logging disabled to reduce output
        // window.addEventListener('error', function(e) {
        //     console.error('JavaScript error:', e.error);
        // });
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