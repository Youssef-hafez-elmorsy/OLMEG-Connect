import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageGrid extends StatelessWidget {
  final List<String> imageURLs;
  final void Function(int index)? onImageTap;
  final void Function(int index)? onRemove;
  final bool showRemoveButton;
  final List<double>? uploadProgress;

  const ImageGrid({
    super.key,
    required this.imageURLs,
    this.onImageTap,
    this.onRemove,
    this.showRemoveButton = false,
    this.uploadProgress,
  });

  bool _isBlobUrl(String url) {
    return url.startsWith('blob:');
  }

  bool _isBase64(String url) {
    return url.startsWith('data:image');
  }

  Uint8List _decodeBase64ToUint8List(String url) {
    final base64String = url.split(',').last;
    return Uint8List.fromList(base64Decode(base64String));
  }

  @override
  Widget build(BuildContext context) {
    if (imageURLs.isEmpty) return const SizedBox.shrink();

    if (imageURLs.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildImageTile(context, imageURLs[0], 0),
      );
    } else if (imageURLs.length == 2) {
      return Row(
        children: [
          Expanded(child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, imageURLs[0], 0))),
          const SizedBox(width: 2),
          Expanded(child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, imageURLs[1], 1))),
        ],
      );
    } else if (imageURLs.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: AspectRatio(aspectRatio: 1, child: _buildImageTile(context, imageURLs[0], 0))),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageTile(context, imageURLs[1], 1)),
                const SizedBox(height: 2),
                Expanded(child: _buildImageTile(context, imageURLs[2], 2)),
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
          itemCount: imageURLs.length > 4 ? 4 : imageURLs.length,
          itemBuilder: (context, index) {
            if (index == 3 && imageURLs.length > 4) {
              return _buildOverlayTile(context, imageURLs);
            }
            return _buildImageTile(context, imageURLs[index], index);
          },
        ),
      );
    }
  }

  Widget _buildImageTile(BuildContext context, String url, int index) {
    final progress = uploadProgress != null && uploadProgress!.length > index ? uploadProgress![index] : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => onImageTap?.call(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isBase64(url)
                ? Image.memory(
                    _decodeBase64ToUint8List(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.errorContainer,
                      child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
                    ),
                  )
                : _isBlobUrl(url)
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.errorContainer,
                          child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.errorContainer,
                          child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
                        ),
                      ),
          ),
        ),
        if (progress != null && progress < 1.0)
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(value: progress),
            ),
          ),
        if (showRemoveButton && onRemove != null)
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

  Widget _buildOverlayTile(BuildContext context, List<String> urls) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onImageTap?.call(3),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: urls[3],
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+${urls.length - 3}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}