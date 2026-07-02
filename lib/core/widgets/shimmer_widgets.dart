import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CoachCardShimmer extends StatelessWidget {
  const CoachCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          _ShimmerBox(width: 52, height: 52, borderRadius: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                _ShimmerBox(width: 80, height: 12, borderRadius: 6),
                SizedBox(height: 8),
                _ShimmerBox(width: 100, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachListShimmer extends StatelessWidget {
  const CoachListShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const CoachCardShimmer(),
      ),
    );
  }
}

class StatsShimmer extends StatelessWidget {
  const StatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(child: _ShimmerBox(width: double.infinity, height: 72, borderRadius: 14)),
          SizedBox(width: 10),
          Expanded(child: _ShimmerBox(width: double.infinity, height: 72, borderRadius: 14)),
          SizedBox(width: 10),
          Expanded(child: _ShimmerBox(width: double.infinity, height: 72, borderRadius: 14)),
        ],
      ),
    );
  }
}

class ScannedProfileShimmer extends StatelessWidget {
  const ScannedProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerBox(width: 180, height: 24, borderRadius: 8),
          SizedBox(height: 16),
          Row(
            children: [
              _ShimmerBox(width: 56, height: 56, borderRadius: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: double.infinity, height: 14, borderRadius: 6),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 120, height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _ShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
          SizedBox(height: 16),
          CoachCardShimmer(),
          CoachCardShimmer(),
        ],
      ),
    );
  }
}
