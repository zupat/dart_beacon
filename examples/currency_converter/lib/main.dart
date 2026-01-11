import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

String formatCurrency(String value) {
  if (value.isEmpty) return '0';

  // Handle decimal numbers
  final parts = value.split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

  // Add commas to integer part
  String formattedInteger = '';
  for (int i = 0; i < integerPart.length; i++) {
    if (i > 0 && (integerPart.length - i) % 3 == 0) {
      formattedInteger += ',';
    }
    formattedInteger += integerPart[i];
  }

  return formattedInteger + decimalPart;
}

final amountRef = Ref.scoped((ctx) => Beacon.writable(''));
final fromCurrencyRef = Ref.scoped((ctx) => Beacon.writable('USD'));
final toCurrencyRef = Ref.scoped((ctx) => Beacon.writable('EUR'));

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const _CurrencyConverterContent(),
          ),
        ),
      ),
    );
  }
}

class _CurrencyConverterContent extends StatelessWidget {
  const _CurrencyConverterContent();

  @override
  Widget build(BuildContext context) {
    final amount = amountRef.watch(context);
    final fromCurrency = fromCurrencyRef.watch(context);
    final toCurrency = toCurrencyRef.watch(context);

    final rates = {'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79, 'JPY': 149.50};

    final quickAmounts = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
    final largeAmounts = [
      1000,
      2000,
      5000,
      7000,
      8000,
      9000,
      10000,
      13000,
      15000,
      17000,
    ];

    return Column(
      children: [
        // Quick conversion rates list
        Expanded(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Currency headers
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fromCurrency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        toCurrency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fromCurrency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        toCurrency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Conversion rates
                Expanded(
                  child: ListView.separated(
                    itemCount: quickAmounts.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      );
                    },
                    itemBuilder: (context, index) {
                      final amt = quickAmounts[index];
                      final converted =
                          ((amt * (rates[toCurrency]! / rates[fromCurrency]!))
                              .toStringAsFixed(2));
                      final largeAmt =
                          largeAmounts[index % largeAmounts.length];
                      final largeConverted =
                          ((largeAmt *
                                  (rates[toCurrency]! / rates[fromCurrency]!))
                              .toStringAsFixed(2));
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatCurrency('$amt'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatCurrency(converted),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatCurrency('$largeAmt'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatCurrency(largeConverted),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Currency switcher
        Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  _CurrencySelector(fromCurrencyRef, fromCurrency, 'from'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    child: Text(
                      formatCurrency(amount.isEmpty ? '0' : amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  final temp = fromCurrencyRef.of(context).value;
                  fromCurrencyRef.of(context).value = toCurrencyRef
                      .of(context)
                      .value;
                  toCurrencyRef.of(context).value = temp;
                },
                icon: Icon(Icons.swap_horiz),
              ),
              Row(
                spacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    child: Text(
                      formatCurrency(
                        ((amount.isEmpty ? 0.0 : double.parse(amount)) *
                                (rates[toCurrency]! / rates[fromCurrency]!))
                            .toStringAsFixed(2),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CurrencySelector(toCurrencyRef, toCurrency, 'to'),
                ],
              ),
            ],
          ),
        ),
        // Numpad
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.7,
            children: List.generate(12, (index) {
              if (index < 9) {
                return _NumPadButton('${index + 1}');
              } else if (index == 9) {
                return _NumPadButton('0');
              } else if (index == 10) {
                return _NumPadButton('.');
              } else {
                return _ClearButton();
              }
            }),
          ),
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final ScopedRef<WritableBeacon<String>> currencyRef;
  final String current;
  final String label;

  const _CurrencySelector(this.currencyRef, this.current, this.label);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => currencyRef.of(context).value = value,
      itemBuilder: (BuildContext context) => ['USD', 'EUR', 'GBP', 'JPY']
          .map(
            (currency) => PopupMenuItem(value: currency, child: Text(currency)),
          )
          .toList(),
      child: Text('$current ▽', style: const TextStyle(fontSize: 16)),
    );
  }
}

class _NumPadButton extends StatelessWidget {
  final String label;

  const _NumPadButton(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final current = amountRef.of(context).value;
        amountRef.of(context).value = current + label;
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => amountRef.of(context).value = '',
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.backspace, color: Colors.red)),
      ),
    );
  }
}

void main() {
  runApp(const LiteRefScope(child: MaterialApp(home: CurrencyConverterView())));
}
