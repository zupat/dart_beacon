import 'package:currency_converter/deps.dart';
import 'package:currency_converter/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:google_fonts/google_fonts.dart';

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    final rates = controllerRef.select(context, (c) => c.allRates);
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: rates.lastData != null
                ? Column(
                    children: [
                      CommonConversions(),
                      CurrencyDisplay(),
                      Numpad(),
                    ],
                  )
                : const NoRatesAvailable(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(
        // Define the default brightness and colors.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),

        // Define the default `TextTheme`. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          displaySmall: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LiteRefScope(child: CurrencyConverterView()),
    ),
  );
}
