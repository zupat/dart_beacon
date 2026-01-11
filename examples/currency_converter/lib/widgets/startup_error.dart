part of 'widgets.dart';

class StartupError extends StatelessWidget {
  const StartupError(this.errorText, {super.key});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        Text(
          errorText,
          textAlign: .center,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controllerRef.read(context).allRates.reset,
          child: Text('retry'),
        ),
      ],
    );
  }
}
