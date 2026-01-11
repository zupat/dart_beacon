part of 'widgets.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final (ratesByQuery, enabledCurrencies, lastUpdate) = controller.select3(
      context,
      (c) => (c.ratesByQuery, c.enabledCurrencies, c.lastUpdate),
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
            TextField(
              controller: controller.query.controller,
              decoration: const InputDecoration(
                labelText: 'Search Currency',
                border: OutlineInputBorder(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ratesByQuery.keys.length,
                itemBuilder: (context, index) {
                  final allCurrencies = ratesByQuery.keys.toList();
                  final currency = allCurrencies[index];
                  final isEnabled = enabledCurrencies.contains(currency);
                  final rate = ratesByQuery[currency] ?? 0.0;

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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
