import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class MathElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Math.tex(
      element.textContent,
      textStyle: preferredStyle?.copyWith(color: Colors.white, fontSize: preferredStyle.fontSize ?? 18),
      onErrorFallback: (error) => Text(
        element.textContent,
        style: preferredStyle?.copyWith(color: Colors.red),
      ),
    );
  }
}

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$([^\$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final mathContent = match.groupCount >= 1 ? match[1] : null;
    if (mathContent != null) {
      parser.addNode(md.Element.text('math', mathContent));
      return true;
    }
    return false;
  }
}

class BlockMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$([^\$]+)\$\$$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    parser.advance();
    final mathContent = (match != null && match.groupCount >= 1) ? match[1] : null;
    if (mathContent != null) {
      return md.Element.text('math', mathContent);
    }
    return md.Element.text('p', '');
  }
}
