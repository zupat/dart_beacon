part of 'widgets.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final (allRates, enabledCurrencies, lastUpdate) = controller.select3(
      context,
      (c) => (c.allRates, c.enabledCurrencies, c.lastUpdate),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Currency Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Last Updated: ${timeago.format(lastUpdate)}'),
                IconButton(
                  onPressed: controller.refreshRates,
                  icon: Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Available Currencies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: allRates.lastData != null
                  ? ListView.builder(
                      itemCount: allRates.lastData!.keys.length,
                      itemBuilder: (context, index) {
                        final allCurrencies = allRates.lastData!.keys.toList();
                        final currency = allCurrencies[index];
                        final isEnabled = enabledCurrencies.contains(currency);
                        final rate = allRates.lastData![currency] ?? 0.0;

                        return ListTile(
                          title: Text(
                            currency,
                            style: TextStyle(
                              fontWeight: isEnabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Rate: ${rate.toStringAsFixed(4)}'),
                          trailing: Checkbox(
                            value: isEnabled,
                            onChanged: (bool? value) {
                              if (value == true) {
                                controller.enableCurrency(currency);
                              } else {
                                controller.enabledCurrencies.remove(currency);
                              }
                            },
                          ),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
