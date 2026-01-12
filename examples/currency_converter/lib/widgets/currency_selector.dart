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

    final animationOffsets = _slideOffsets.watch(context);
    final offset = type == SelectorType.from
        ? animationOffsets.$1
        : animationOffsets.$2;

    return PopupMenuButton<String>(
      onSelected: (value) => currencyBeacon.value = value,
      itemBuilder: (BuildContext context) => enabledCurrencies
          .map(
            (currency) => PopupMenuItem(value: currency, child: Text(currency)),
          )
          .toList(),
      child: AnimatedSlide(
        offset: Offset(offset, 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: Text(
          '$current ▽',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: type == SelectorType.to ? TextAlign.right : null,
        ),
      ),
    );
  }
}
