import 'package:flutter/material.dart';

class PranthoraLoader extends StatelessWidget {
  final double size;
  final bool showLabel;

  // Default to a smaller size (reduced from 32 to 20)
  const PranthoraLoader({super.key, this.size = 20, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final double loaderSize = size;
    // Thinner stroke for smaller loader
    final double stroke = (loaderSize * 0.12).clamp(1.4, 2.2); // slightly thinner
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: loaderSize,
          height: loaderSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 5,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: CircularProgressIndicator(
              strokeWidth: stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
