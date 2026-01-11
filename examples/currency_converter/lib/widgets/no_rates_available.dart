part of 'widgets.dart';

class NoRatesAvailable extends StatelessWidget {
  const NoRatesAvailable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final rates = controller.allRates;
    return Center(
      child: rates.isError
          ? Center(
              child: Column(
                children: [
                  Text(
                    'Error loading currency rates.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: rates.reset, child: Text('retry')),
                ],
              ),
            )
          : const CircularProgressIndicator(),
    );
  }
}
