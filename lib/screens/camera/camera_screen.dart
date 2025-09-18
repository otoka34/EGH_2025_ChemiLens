import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カメラ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'カメラ画面',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}