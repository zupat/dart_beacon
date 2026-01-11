part of 'widgets.dart';

class CurrencyDisplay extends StatelessWidget {
  const CurrencyDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final formattedAmount = controller.amountFormatted.watch(context);
    final convertedAmount = controller.convertedAmount.watch(context);
    final fromCurrency = controller.fromCurrency.watch(context);
    final toCurrency = controller.toCurrency.watch(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 10,
            children: [
              _CurrencySelector(controller.fromCurrency, fromCurrency, 'from'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: controller.swapCurrencies,
            icon: Icon(
              Icons.swap_horiz,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  convertedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _CurrencySelector(controller.toCurrency, toCurrency, 'to'),
            ],
          ),
        ],
      ),
    );
  }
}
