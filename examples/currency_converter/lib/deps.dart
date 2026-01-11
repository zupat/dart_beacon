import 'package:currency_converter/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_beacon/state_beacon.dart';

late final ScopedRef<CurrencyController> controllerRef;
late final SingletonRef<SharedPreferences> sharedPrefRef;

final startUpBeacon = Ref.scoped((_) => Beacon.future(startUp));

Future<void> startUp() async {
  final sharedPref = await SharedPreferences.getInstance();
  final controller = CurrencyController(sharedPref);

  // await initial data load
  await controller.allRates.toFuture();

  sharedPrefRef = Ref.singleton<SharedPreferences>(() => sharedPref);
  controllerRef = Ref.scoped<CurrencyController>((_) => controller);
}
