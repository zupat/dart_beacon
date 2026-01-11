part of 'widgets.dart';

class _CurrencySelector extends StatelessWidget {
  final WritableBeacon<String> currencyBeacon;
  final String current;
  final String label;

  const _CurrencySelector(this.currencyBeacon, this.current, this.label);

  @override
  Widget build(BuildContext context) {
    final enabledCurrencies = controllerRef.select(
      context,
      (c) => c.enabledCurrencies,
    );
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
