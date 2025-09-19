import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '/theme/app_colors.dart';

class ARViewerScreen extends StatefulWidget {
  final String glbModelUrl;

  const ARViewerScreen({super.key, required this.glbModelUrl});

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARNode? arObjectNode;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AR Viewer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath:
          "assets/triangle.png", // You might need to add a placeholder image here
      showWorldOrigin: true,
      handlePans: true,
      handleRotation: true,
    );
    this.arObjectManager?.onInitialize();

    _addGLBObject();
  }

  Future<void> _addGLBObject() async {
    if (arObjectNode != null) {
      arObjectManager?.removeNode(arObjectNode!);
      arObjectNode = null;
    }

    arObjectNode = ARNode(
      type: NodeType.webGLB,
      uri: widget.glbModelUrl,
      scale: vector.Vector3(0.2, 0.2, 0.2), // Adjust scale as needed
      position: vector.Vector3(0.0, -0.5, -1.0), // Adjust position as needed
      rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0), // Adjust rotation as needed
    );
    arObjectManager?.addNode(arObjectNode!);
  }
}
