import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PhotoEditorHome(),
    );
  }
}

enum FilterType { original, blackAndWhite, sepia, cool }

class PhotoEditorHome extends StatefulWidget {
  const PhotoEditorHome({super.key});

  @override
  State<PhotoEditorHome> createState() => _PhotoEditorHomeState();
}

class _PhotoEditorHomeState extends State<PhotoEditorHome> {
  Uint8List? _imageBytes;
  FilterType _selectedFilter = FilterType.original;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedFilter = FilterType.original;
      });
    }
  }

  ColorFilter _getColorFilter(FilterType filter) {
    switch (filter) {
      case FilterType.blackAndWhite:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case FilterType.sepia:
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
      case FilterType.cool:
        return const ColorFilter.matrix([
          0.8, 0,   0,   0, 0,
          0,   0.9, 0,   0, 0,
          0,   0,   1.2, 0, 0,
          0,   0,   0,   1, 0,
        ]);
      case FilterType.original:
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  Widget _buildFilterButton(
      FilterType filter, String label, IconData icon) {
    final bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 8)]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('✨ Photo Editor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Image preview area
          Expanded(
            child: Center(
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('Select an image to get started',
                            style: TextStyle(color: Colors.white38, fontSize: 16)),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColorFiltered(
                          colorFilter: _getColorFilter(_selectedFilter),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Filter buttons
          if (_imageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              color: const Color(0xFF16213E),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton(
                        FilterType.original, 'Original', Icons.image),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                        FilterType.blackAndWhite, 'B&W', Icons.contrast),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                        FilterType.sepia, 'Warm', Icons.wb_sunny_outlined),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                        FilterType.cool, 'Cool', Icons.ac_unit),
                  ],
                ),
              ),
            ),

          // Pick image button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F3460),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick Image from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
