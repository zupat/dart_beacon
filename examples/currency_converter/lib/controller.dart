import 'dart:convert';

import 'package:currency_converter/const.dart';
import 'package:currency_converter/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:http/http.dart' as http;

class CurrencyController with BeaconController {
  final SharedPreferences sharedPref;

  CurrencyController(this.sharedPref) {
    // Load saved preferences
    final savedEnabled = sharedPref.getStringList(prefEnabledCurrenciesKey);
    if (savedEnabled != null) {
      enabledCurrencies.value = savedEnabled.toSet();
    }

    final savedFrom = sharedPref.getString(prefFromCurrencyKey);
    if (savedFrom != null) {
      fromCurrency.value = savedFrom;
    }

    final savedTo = sharedPref.getString(prefToCurrencyKey);
    if (savedTo != null) {
      toCurrency.value = savedTo;
    }
    // Save preferences on change
    enabledCurrencies.subscribe((newVal) {
      sharedPref.setStringList(prefEnabledCurrenciesKey, newVal.toList());
    }, startNow: false);

    fromCurrency.subscribe((newVal) {
      sharedPref.setString(prefFromCurrencyKey, newVal);
    }, startNow: false);

    toCurrency.subscribe((newVal) {
      sharedPref.setString(prefToCurrencyKey, newVal);
    }, startNow: false);

    // Update last update time when rates are fetched
    allRates.subscribe((newVal) {
      if (newVal.isData) {
        lastUpdate.value = DateTime.now();
      }
    });

    convertedAmount.subscribe((_) {
      // refresh rates if last update was more than 12 hours ago
      if (DateTime.now().difference(lastUpdate.value).inHours > 12) {
        refreshRates();
      }
    });
  }

  // the app won't load if no rates are fetched
  late final lastUpdate = B.lazyWritable<DateTime>();
  late final amount = B.writable('');
  late final amountFormatted = B.derived(() {
    return formatCurrency(amount.value);
  });

  late final convertedAmount = B.derived(() {
    final amountValue = double.tryParse(amount.value) ?? 0.0;
    final fromRate = enabledRates.value[fromCurrency.value] ?? 1.0;
    final toRate = enabledRates.value[toCurrency.value] ?? 1.0;
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

  late final enabledRates = B.derived(() {
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

  late final query = B.textEditing();

  late final ratesByQuery = B.derived(() {
    final rates = allRates.value.lastData ?? {};
    final q = query.value.text.trim().toUpperCase();
    if (q.isEmpty) {
      return rates;
    } else {
      final result = <String, double>{};
      for (final entry in rates.entries) {
        if (entry.key.contains(q)) {
          result[entry.key] = entry.value;
        }
      }
      return result;
    }
  });

  late final commonAmounts = B.derived(() {
    final rates = enabledRates.value;
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
