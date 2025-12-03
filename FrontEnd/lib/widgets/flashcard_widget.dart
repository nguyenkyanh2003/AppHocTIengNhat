import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Flashcard widget với flip animation
class FlashcardWidget extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? frontSubtext;
  final String? backSubtext;
  final VoidCallback? onFlip;
  final bool showBack;
  final Color frontColor;
  final Color backColor;

  const FlashcardWidget({
    Key? key,
    required this.frontText,
    required this.backText,
    this.frontSubtext,
    this.backSubtext,
    this.onFlip,
    this.showBack = false,
    this.frontColor = const Color(0xFF2196F3),
    this.backColor = const Color(0xFF4CAF50),
  }) : super(key: key);

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _showBack = widget.showBack;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;

    setState(() {
      _showBack = !_showBack;
    });

    if (_showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isBack = angle > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackCard(),
                  )
                : _buildFrontCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.frontColor,
            widget.frontColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.frontColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 24),
          Text(
            widget.frontText,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.frontSubtext != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.frontSubtext!,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Chạm để lật',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.backColor,
            widget.backColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.backColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.backText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.backSubtext != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.backSubtext!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
