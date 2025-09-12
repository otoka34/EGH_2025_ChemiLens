import 'dart:io';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart';

class ARViewerScreen extends StatefulWidget {
  final Uint8List glbData;
  final String moleculeName;

  const ARViewerScreen({
    super.key,
    required this.glbData,
    required this.moleculeName,
  });

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen> {
  String? _glbFilePath;
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARNode? _modelNode;

  @override
  void initState() {
    super.initState();
    _saveGlbToFileAndInitAR();
  }

  Future<void> _saveGlbToFileAndInitAR() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/molecule.glb');
      await file.writeAsBytes(widget.glbData);
      if (mounted) {
        setState(() {
          _glbFilePath = file.path;
        });
      }
    } catch (e) {
      print("Error saving GLB file: $e");
      // TODO: Show an error message to the user
    }
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    if (_glbFilePath != null) {
      final file = File(_glbFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.moleculeName)),
      body: _glbFilePath == null
          ? const Center(child: CircularProgressIndicator())
          : ARView(
              onARViewCreated: _onARViewCreated,
            ),
    );
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;

    _arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      handleTaps: true,
    );
    _arObjectManager?.onInitialize();

    // Add the node to the scene as soon as the view is created
    _addNode();
  }

  Future<void> _addNode() async {
    if (_glbFilePath != null && _arObjectManager != null) {
      if (_modelNode != null) {
        _arObjectManager?.removeNode(_modelNode!);
      }
      final newNode = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: _glbFilePath!,
        scale: Vector3(0.2, 0.2, 0.2),
        position: Vector3(0.0, -0.5, -1.5), // Position it in front of the camera
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );
      _modelNode = newNode;
      await _arObjectManager?.addNode(newNode);
    }
  }
}
