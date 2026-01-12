part of 'widgets.dart';

enum SelectorType { from, to }

class _CurrencySelector extends StatelessWidget {
  final SelectorType type;

  const _CurrencySelector(this.type);

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final enabledCurrencies = controller.enabledCurrencies.watch(context);

    final currencyBeacon = type == SelectorType.from
        ? controller.fromCurrency
        : controller.toCurrency;
    final current = currencyBeacon.watch(context);

    return PopupMenuButton<String>(
      onSelected: (value) => currencyBeacon.value = value,
      itemBuilder: (BuildContext context) => enabledCurrencies
          .map(
            (currency) => PopupMenuItem(value: currency, child: Text(currency)),
          )
          .toList(),
      child: Text(
        '$current ▽',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
