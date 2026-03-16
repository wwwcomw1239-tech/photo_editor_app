import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PhotoEditorApp());
}

class PhotoEditorApp extends StatelessWidget {
  const PhotoEditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PhotoEditorHome(),
    );
  }
}

class PhotoEditorHome extends StatefulWidget {
  const PhotoEditorHome({super.key});
  @override
  State<PhotoEditorHome> createState() => _PhotoEditorHomeState();
}

class _PhotoEditorHomeState extends State<PhotoEditorHome> {
  Uint8List? _imageBytes;
  ColorFilter? _currentFilter;
  String _filterName = 'Original';

  static const ColorFilter _bwFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  static const ColorFilter _sepiaFilter = ColorFilter.matrix(<double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0,     0,     0,     1, 0,
  ]);

  static const ColorFilter _warmFilter = ColorFilter.matrix(<double>[
    1.2, 0,   0,   0, 20,
    0,   1.0, 0,   0, 10,
    0,   0,   0.8, 0, 0,
    0,   0,   0,   1, 0,
  ]);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _currentFilter = null;
        _filterName = 'Original';
      });
    }
  }

  void _applyFilter(ColorFilter? filter, String name) {
    setState(() {
      _currentFilter = filter;
      _filterName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 100, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No image selected',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade500)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_filterName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.deepPurple)),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ColorFiltered(
                            colorFilter: _currentFilter ??
                                const ColorFilter.mode(
                                    Colors.transparent, BlendMode.multiply),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Image'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
          if (_imageBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterButton('Original', null, 'Original'),
                  _filterButton('B&W', _bwFilter, 'Black & White'),
                  _filterButton('Sepia', _sepiaFilter, 'Sepia'),
                  _filterButton('Warm', _warmFilter, 'Warm'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, ColorFilter? filter, String name) {
    final isActive = _filterName == name;
    return ElevatedButton(
      onPressed: () => _applyFilter(filter, name),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.deepPurple : null,
        foregroundColor: isActive ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
