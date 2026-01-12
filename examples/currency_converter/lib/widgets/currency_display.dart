part of 'widgets.dart';

class _CurrencyValue extends StatelessWidget {
  final SelectorType type;
  const _CurrencyValue(this.type);

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final value = type == SelectorType.from
        ? controller.amountFormatted.watch(context)
        : controller.convertedAmount.watch(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: type == SelectorType.from
            ? Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              )
            : Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class CurrencyDisplay extends StatelessWidget {
  const CurrencyDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 10,
            children: [
              _CurrencySelector(SelectorType.from),
              _CurrencyValue(SelectorType.from),
            ],
          ),
          IconButton(
            onPressed: controllerRef.read(context).swapCurrencies,
            icon: Icon(
              Icons.swap_horiz,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Row(
            spacing: 10,
            children: [
              _CurrencyValue(SelectorType.to),
              _CurrencySelector(SelectorType.to),
            ],
          ),
        ],
      ),
    );
  }
}
