import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/reader/presentation/widgets/reader_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReaderContent notifica la palabra real sin puntuación', (
    tester,
  ) async {
    String? selectedWord;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContent(
            content: 'Hello, careful reader.',
            onWordTap: (word) => selectedWord = word,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(AppKeys.readerWordToken('Hello', 0)));

    expect(selectedWord, 'Hello');
  });

  testWidgets('ReaderContent expone palabras tocables a lectores de pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContent(content: 'Hello reader.', onWordTap: (_) {}),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Consultar palabra Hello'), findsOneWidget);
  });

  testWidgets('ReaderContent aplica tamaño e interlineado configurados', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContent(
            content: 'Hello reader.',
            fontScale: 1.2,
            lineHeight: 1.7,
            onWordTap: (_) {},
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Hello'));

    expect(text.style?.fontSize, closeTo(25.2, 0.001));
    expect(text.style?.height, 1.7);
  });
}
