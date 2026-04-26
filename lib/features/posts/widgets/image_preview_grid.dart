import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePreviewGrid extends StatelessWidget {
  final List<XFile> images;
  final void Function(int index)? onRemove;
  final List<double>? uploadProgress;

  const ImagePreviewGrid({
    super.key,
    required this.images,
    this.onRemove,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    if (images.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildImageTile(context, images[0], 0, colorScheme),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, images[0], 0, colorScheme))),
          const SizedBox(width: 2),
          Expanded(child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, images[1], 1, colorScheme))),
        ],
      );
    } else if (images.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, images[0], 0, colorScheme))),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageTile(context, images[1], 1, colorScheme)),
                const SizedBox(height: 2),
                Expanded(child: _buildImageTile(context, images[2], 2, colorScheme)),
              ],
            ),
          ),
        ],
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: images.length > 4 ? 4 : images.length,
          itemBuilder: (context, index) {
            if (index == 3 && images.length > 4) {
              return _buildOverlayTile(context, images, colorScheme);
            }
            return _buildImageTile(context, images[index], index, colorScheme);
          },
        ),
      );
    }
  }

  Widget _buildImageTile(BuildContext context, XFile file, int index, ColorScheme colorScheme) {
    final progress = uploadProgress != null && uploadProgress!.length > index ? uploadProgress![index] : null;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            file.path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colorScheme.errorContainer,
              child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
            ),
          ),
        ),
        if (progress != null && progress < 1.0)
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: CircularProgressIndicator(value: progress)),
          ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onRemove?.call(index),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlayTile(BuildContext context, List<XFile> files, ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(files[3].path, fit: BoxFit.cover),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '+${files.length - 3}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}