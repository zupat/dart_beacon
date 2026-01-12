import 'package:fast_currency_converter/deps.dart';
import 'package:fast_currency_converter/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final screenHeight = MediaQuery.sizeOf(context).height;
                  return Wrap(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.80,
                        child: const SettingsPanel(),
                      ),
                    ],
                  );
                },
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
            child: switch (startUpBeacon.watch(context)) {
              AsyncData() => Column(
                children: [CommonConversions(), CurrencyDisplay(), Numpad()],
              ),
              AsyncError e => StartupError(e.error.toString()),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  // BeaconObserver.useLogging();
  runApp(
    LiteRefScope(
      child: MaterialApp(
        title: 'Fast Currency Converter',
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
