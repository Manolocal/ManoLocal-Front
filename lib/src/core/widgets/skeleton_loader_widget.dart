import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class _ShimmerScope extends InheritedNotifier<Animation<double>> {
  const _ShimmerScope({
    required Animation<double> animation,
    required super.child,
  }) : super(notifier: animation);

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
        ?.notifier;
  }
}

/// Bloque rectangular o circular con soporte para efecto Shimmer dentro de [SkeletonLoaderWidget].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.graySurface : AppColors.silverLight;
    final highlightColor = isDark ? AppColors.grayElevated : AppColors.silver;
    final animation = _ShimmerScope.maybeOf(context);

    Widget buildContainer(double? progress) {
      final double slide = progress != null ? (progress * 2 - 1) : 0.0;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
          gradient: progress != null
              ? LinearGradient(
                  begin: Alignment(-1.5 + slide, -0.2),
                  end: Alignment(1.5 + slide, 0.2),
                  colors: [baseColor, highlightColor, baseColor],
                  stops: const [0.1, 0.5, 0.9],
                )
              : null,
          color: progress == null ? baseColor : null,
        ),
      );
    }

    if (animation == null) {
      return buildContainer(null);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => buildContainer(animation.value),
    );
  }
}

/// Cargador esqueleto animado (efecto Shimmer) para listas de resultados de búsqueda.
class SkeletonLoaderWidget extends StatefulWidget {
  final int itemCount;

  const SkeletonLoaderWidget.specialistList({
    super.key,
    this.itemCount = 3,
  });

  @override
  State<SkeletonLoaderWidget> createState() => _SkeletonLoaderWidgetState();
}

class _SkeletonLoaderWidgetState extends State<SkeletonLoaderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      animation: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          widget.itemCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SpecialistCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _SpecialistCardSkeleton extends StatelessWidget {
  const _SpecialistCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 48, height: 48, shape: BoxShape.circle),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 170, height: 16),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          SkeletonBox(width: 78, height: 22, borderRadius: 20),
                          SkeletonBox(width: 96, height: 22, borderRadius: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(width: 140, height: 12),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                SkeletonBox(width: 92, height: 28, borderRadius: 16),
                SkeletonBox(width: 108, height: 28, borderRadius: 16),
                SkeletonBox(width: 78, height: 28, borderRadius: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 40, borderRadius: 12)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 40, borderRadius: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
