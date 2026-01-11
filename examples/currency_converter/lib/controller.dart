import 'dart:convert';

import 'package:currency_converter/utils.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

const apiURL = 'https://latest.currency-api.pages.dev/v1/currencies/usd.json';

class CurrencyController with BeaconController {
  CurrencyController() {
    allRates.subscribe((newVal) {
      if (newVal.isData) {
        lastUpdate.value = timeago.format(DateTime.now());
      }
    });
  }

  // the app won't load if no rates are fetched
  late final lastUpdate = B.lazyWritable<String>();
  late final amount = B.writable('');
  late final amountFormatted = B.derived(() {
    return formatCurrency(amount.value);
  });
  late final convertedAmount = B.derived(() {
    final amountValue = double.tryParse(amount.value) ?? 0.0;
    final fromRate = filteredRates.value[fromCurrency.value] ?? 1.0;
    final toRate = filteredRates.value[toCurrency.value] ?? 1.0;
    final converted = amountValue / fromRate * toRate;
    return converted.toStringAsFixed(2);
  });
  late final fromCurrency = B.writable('USD');
  late final toCurrency = B.writable('EUR');
  late final enabledCurrencies = B.hashSet({'USD', 'EUR', 'GBP', 'JPY', 'CNY'});

  late final allRates = B.future(() async {
    final resp = await http.get(Uri.parse(apiURL));
    if (resp.statusCode == 200) {
      final data = Map<String, dynamic>.from(
        (jsonDecode(resp.body) as Map<String, dynamic>)['usd'],
      );
      final result = <String, double>{};
      for (final MapEntry(key: name, value: rate) in data.entries) {
        result[name.toUpperCase()] = (rate as num).toDouble();
      }
      return result;
    } else {
      throw Exception('Failed to load currency data');
    }
  });

  late final filteredRates = B.derived(() {
    final rates = allRates.value.lastData ?? {};
    final enabled = enabledCurrencies.value;
    final result = <String, double>{};
    for (final currency in enabled) {
      if (rates.containsKey(currency)) {
        result[currency] = rates[currency]!;
      }
    }
    return result;
  });

  late final commonAmounts = B.derived(() {
    final rates = filteredRates.value;
    final fromRate = rates[fromCurrency.value] ?? 1.0;
    final toRate = rates[toCurrency.value] ?? 1.0;
    final smallAmounts = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
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

    List<(String, String)> formatAmounts(List<int> amounts) {
      return amounts.map((amount) {
        final converted = amount / fromRate * toRate;
        return (
          formatCurrency(amount.toString()),
          formatCurrency(converted.toStringAsFixed(2)),
        );
      }).toList();
    }

    return (
      small: formatAmounts(smallAmounts),
      large: formatAmounts(largeAmounts),
    );
  });

  Future<void> refreshRates() async {
    allRates.reset();
    await allRates.nextOrNull(filter: (data) => !data.isLoading);
  }

  void swapCurrencies() {
    final from = fromCurrency.value;
    final to = toCurrency.value;
    fromCurrency.value = to;
    toCurrency.value = from;
  }

  void addDigit(String digit) {
    amount.value += digit;
  }

  void clearAmount() {
    amount.value = '';
  }

  void enableCurrency(String currency) {
    enabledCurrencies.add(currency);
  }
}
