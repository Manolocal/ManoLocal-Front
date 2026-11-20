import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Envoltorio global de imágenes remotas con caché local persistente en disco/memoria
/// para evitar descargas repetitivas en catálogo y perfiles públicos.
class CustomImageCache extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;

  const CustomImageCache({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
  });

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? AppColors.graySurface : AppColors.silverLight,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.grayMuted,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? AppColors.graySurface : AppColors.silverLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.grayMuted,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    final Widget imageContent;

    if (cleanUrl.isEmpty) {
      imageContent = errorWidget ?? _buildDefaultError(context);
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (ctx, _) => placeholder ?? _buildDefaultPlaceholder(ctx),
        errorWidget: (ctx, _, _) => errorWidget ?? _buildDefaultError(ctx),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }
    return imageContent;
  }
}
