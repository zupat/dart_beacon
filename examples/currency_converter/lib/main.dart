import 'package:currency_converter/deps.dart';
import 'package:currency_converter/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    final rates = controllerRef.select(context, (c) => c.allRates);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const SettingsPanel(),
              );
            },
          ),
        ],
      ),
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
    LiteRefScope(
      child: MaterialApp(
        title: 'Currency Converter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Define the default brightness and colors.
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const CurrencyConverterView(),
      ),
    ),
  );
}
