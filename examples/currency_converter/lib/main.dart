import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

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

    final quickAmounts = [5, 10, 15, 20, 50, 100];

    return Column(
      children: [
        // Quick conversion rates list
        Expanded(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: quickAmounts.length,
              itemBuilder: (context, index) {
                final amt = quickAmounts[index];
                final converted =
                    ((amt * (rates[toCurrency]! / rates[fromCurrency]!))
                        .toStringAsFixed(2));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '$amt',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(fromCurrency, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text(
                        converted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(toCurrency, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Currency switcher
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      amount.isEmpty ? '0' : amount,
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
                      ((amount.isEmpty ? 0.0 : double.parse(amount)) *
                              (rates[toCurrency]! / rates[fromCurrency]!))
                          .toStringAsFixed(2),
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
