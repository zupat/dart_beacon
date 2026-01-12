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
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: .1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _CurrencyValue(SelectorType.from)),
                Container(
                  height: 20,
                  width: .5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _CurrencyValue(SelectorType.to),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _CurrencySelector(SelectorType.from)),
              IconButton(
                onPressed: () {
                  controllerRef.read(context).swapCurrencies();
                  _startAnimation();
                },
                icon: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(child: _CurrencySelector(SelectorType.to)),
            ],
          ),
        ],
      ),
    );
  }
}
