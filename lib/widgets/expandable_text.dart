import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.trimLines = 1, // Default to 1 line
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: Theme.of(context).textTheme.bodyMedium, // Use default text style
      ),
      maxLines: widget.trimLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width); // Layout with available width

    if (!textPainter.didExceedMaxLines) { // Show expander only if text exceeds trimLines
      return Text(
        widget.text,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF718096), // Slightly lighter color
          ),
          maxLines: _isExpanded ? null : widget.trimLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis, // Change overflow based on expansion
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                _isExpanded ? Icons.remove : Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}