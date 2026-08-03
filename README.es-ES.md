<p align="center">
  <img width="650" src="https://github.com/zupat/dart_beacon/blob/main/assets/state_beacon_banner.jpeg?raw=true">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-purple"> 
  <a href="https://app.codecov.io/github/zupat/dart_beacon"><img src="https://img.shields.io/codecov/c/github/zupat/dart_beacon"></a>
  <a href="https://pub.dev/packages/state_beacon"><img src="https://img.shields.io/pub/points/state_beacon?color=blue"></a>
   <img alt="estrellas" src="https://img.shields.io/github/stars/zupat/dart_beacon?style=social"/>
</p>

## Descripción general

Un Beacon es un primitivo reactivo (`signal`) y una solución simple de gestión de estado para Dart y Flutter; `state_beacon` aprovecha la [técnica de coloreado de nodos](https://milomg.dev/2022-12-01/reactivity) creada por [Milo Mighdoll](https://x.com/milomg__) y utilizada en las versiones más recientes de [SolidJS](https://www.youtube.com/watch?v=jHDzGYHY2ew&t=5291s) y [reactively](https://github.com/modderme123/reactively).

Demostración web de Flutter([código fuente](https://github.com/zupat/dart_beacon/tree/main/examples/flutter_main/lib)): https://flutter-beacon.surge.sh/
<br>Todos los ejemplos: https://github.com/zupat/dart_beacon/tree/main/examples

<p align="center">
  <img src="https://github.com/zupat/dart_beacon/blob/main/assets/state_beacon_demo.jpg?raw=true">
</p>

## Instalación

```bash
dart pub add state_beacon
```

## Uso

```dart
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

final name = Beacon.writable("Bob");

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // se reconstruye cuando el nombre cambia
    return Text(name.watch(context));
  }
}
```

#### Usando una función asíncrona

```dart
final counter = Beacon.writable(0);

// La futura se recalculará cada vez que el contador cambie
final futureCounter = Beacon.future(() async {
  final count = counter.value;
  return await fetchData(count);
});

Future<String> fetchData(int count) async {
  await Future.delayed(Duration(seconds: count));
  return '$count second has passed.';
}

class FutureCounter extends StatelessWidget {
  const FutureCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (futureCounter.watch(context)) {
      AsyncData<String>(value: final v) => Text(v),
      AsyncError(error: final e) => Text('$e'),
      _ => const CircularProgressIndicator(),
    };
  }
}
```

## Características

-   [Beacon.writable](#beaconwritable): Beacon mutable que permite lectura y escritura.
-   [Beacon.readable](#beaconreadable): Beacon inmutable que solo emite valores, ideal para datos de solo lectura.
-   [Beacon.derived](#beaconderived): Derivar valores de otros beacons, manteniéndolos sincronizados de forma reactiva.
-   [Beacon.effect](#beaconeffect): Reaccionar a cambios en los valores de los beacons.
-   [Beacon.future](#beaconfuture): Derivar valores de operaciones asíncronas, gestionando el estado durante el cálculo.
    -   [Propiedades](#properties)
    -   [Métodos](#methods)
-   [BeaconGroup](#beacongroup): Crear, restablecer y eliminar un grupo de beacons.
-   [BeaconController](#beaconcontroller)
-   [Inyección de dependencias](#dependency-injection)
-   [Beacon.stream](#beaconstream): Crear beacons derivados a partir de streams de Dart. Los valores se envuelven en un `AsyncValue`.
-   [Beacon.streamRaw](#beaconstreamraw): Como `Beacon.stream`, pero no envuelve el valor en un `AsyncValue`.
-   [Beacon.debounced](#beacondebounced): Retrasar las actualizaciones de valores hasta que haya transcurrido un tiempo especificado, evitando actualizaciones rápidas o no deseadas.
-   [Beacon.throttled](#beaconthrottled): Limitar la frecuencia de actualizaciones de valores, ideal para gestionar eventos frecuentes o la entrada del usuario.
-   [Beacon.filtered](#beaconfiltered): Actualizar valores según criterios de filtro.
-   [Beacon.timestamped](#beacontimestamped): Adjuntar marcas de tiempo a cada actualización de valor.
-   [Beacon.undoRedo](#beaconundoredo): Proporciona la capacidad de deshacer y rehacer cambios de valores.
-   [Beacon.progress](#beaconprogress): Emite valores periódicamente según el progreso.
-   [Beacon.bufferedCount](#beaconbufferedcount): Crear un búfer/lista de valores basada en un límite `int`.
-   [Beacon.bufferedTime](#beaconbufferedtime): Crear un búfer/lista de valores basada en un límite de tiempo.
-   [Beacon.list](#beaconlist): Gestionar listas reactivas que actualizan automáticamente los beacons dependientes ante cambios.
    -   [Beacon.hashSet](#beaconhashset)
    -   [Beacon.hashMap](#beaconhashmap)
-   [AsyncValue](#asyncvalue): Un envoltorio alrededor de un valor que puede estar en uno de cuatro estados: `idle`, `loading`, `data` o `error`.
    -   [unwrap](#asyncvalueunwrap): Convierte este [AsyncValue] a [AsyncData] y devuelve su valor.
    -   [lastData](#asyncvaluelastdata): Devuelve el último valor de datos válido o nulo.
    -   [tryCatch](#asyncvaluetrycatch): Ejecuta un future y devuelve [AsyncData] o [AsyncError].
    -   [actualizaciones optimistas](#asyncvaluetrycatch): Actualizar el valor de forma optimista al usar tryCatch.
-   [Beacon.family](#beaconfamily): Crear y gestionar una familia de beacons relacionados.
-   [Métodos](#properties-and-methods): Métodos adicionales para beacons que se pueden encadenar.
    -   [subscribe()](#mybeaconsubscribe)
    -   [stream](#mybeaconstream)
    -   [wrap()](#mywritablewrapanybeacon)
    -   [ingest()](#mywritableingestanystream)
    -   [next()](#mybeaconnext)
    -   [toListenable()](#mybeacontolistenable)
    -   [toValueNotifier()](#mybeacontovaluenotifier)
    -   [dispose()](#mybeacondispose)
    -   [onDispose()](#mybeaconondispose)
-   [Encadenamiento de Beacons](#chaining-methods): Encadena beacons sin problemas para crear pipelines reactivos sofisticados, combinando múltiples funcionalidades para manipulación y control avanzado de valores.
    -   [buffer](#mybeaconbuffer)
    -   [bufferTime](#mybeaconbuffertime)
    -   [throttle](#mybeaconthrottle)
    -   [filter](#mybeaconfilter)
    -   [map](#mybeaconmap)
    -   [debounce](#mybeacondebounce)
-   [Depuración](#debugging)
-   [Eliminación](#disposal)
-   [BeaconScheduler](#beaconscheduler): Configurar el programador para todos los beacons.
-   [Pruebas](#testing)

[Pitfalls](#pitfalls)

### Beacon.writable:

Un `WritableBeacon` es un valor reactivo mutable que notifica a los oyentes cuando su valor cambia. Podrías pensar que es solo un `ValueNotifier`, pero el poder de los beacons/signals radica en su componibilidad.

```dart
final counter = Beacon.writable(0);
counter.value = 10;
print(counter.value); // 10
```

### Beacon.lazyWritable:

Igual que `Beacon.writable` pero se comporta como una variable `late`. Debe establecerse antes de leerlo.

#### NB: Todos los beacons escribibles tienen un equivalente perezoso.

```dart
final counter = Beacon.lazyWritable();

print(counter.value); // lanza UninitializeLazyReadException()

counter.value = 10;
print(counter.value); // 10
```

### Beacon.readable:

Esto es útil para exponer el valor de un `WritableBeacon` a los consumidores sin permitirles modificarlo. Esta es la superclase de todos los beacons.

```dart
final _internalCounter = Beacon.writable(10);

// Exponer el valor del beacon sin permitir que sea modificado
ReadableBeacon<int> get counter => _internalCounter;
```

### Beacon.derived:

Un `DerivedBeacon` está compuesto por otros beacons. Realiza un seguimiento automáticamente de cualquier beacon accedido dentro de su cierre y recalculará su valor cuando uno de ellos cambie.

Estos beacons son perezosos y solo calcularán su valor cuando se acceda a ellos, se suscriban a ellos o sean observados por un widget o un [effect](#beaconeffect).

Ejemplo:

```dart
final age = Beacon.writable(18);
final canDrink = Beacon.derived(() => age.value >= 21);

canDrink.subscribe((value) {
  print(value); // Salida: false
});

// Salida: false

age.value = 22;
// el beacon derivado se actualizará y se notificará a los suscriptores

// Salida: true
```

### Beacon.effect:

Un effect es simplemente una función que se volverá a ejecutar cada vez que cambie una de sus dependencias.

Cualquier beacon accedido dentro del effect se rastreará como una dependencia. Un cambio en el valor de cualquiera de los beacons rastreados desencadenará la ejecución del effect.

Un effect se programa para ejecutarse inmediatamente después de su creación.

```dart
final age = Beacon.writable(15);

// este effect se ejecuta inmediatamente y siempre que age cambie
Beacon.effect(() {
    if (age.value >= 18) {
      print("You can vote!");
    } else {
       print("You can't vote yet");
    }
 });

// Salida: "You can't vote yet"

age.value = 20; // Salida: "You can vote!"
```

### Beacon.future:

Crea un `FutureBeacon` cuyo valor se deriva de un cálculo asíncrono.
Este beacon recalculará su valor cada vez que cambie una de sus dependencias.
El resultado se envuelve en un `AsyncValue`, que puede estar en uno de cuatro estados: `idle`, `loading`, `data` o `error`.

Si `manualStart` es `true` (valor predeterminado: false), el beacon estará en el estado `idle` y la futura no se ejecutará hasta que se llame a `start()`. Llamar a `start()` en un beacon que ya ha sido iniciado no tendrá efecto.

Si `shouldSleep` es `true` (valor predeterminado), el callback no se ejecutará si el beacon ya no está siendo observado.
Reanudará la ejecución una vez que se agregue un oyente o se acceda a su valor.
Esto significa que entrará en el estado `loading` al despertarse.

NB: Puedes acceder al último dato exitoso mientras el beacon está en el estado `loading` o `error` usando `myFutureBeacon.lastData`. Llamar a `lastdata` estando en el estado `data` devolverá el valor actual.

> [!IMPORTANT]
> Solo los beacons accedidos antes de la brecha asíncrona se rastrearán como dependencias. Consulta [pitfalls](#pitfalls) para obtener más detalles.

Ejemplo:

```dart
final pageNum = Beacon.writable(1);

// La futura se recalculará cada vez que el contador cambie
final pageArticles = Beacon.future(() async {
  final currentPage = pageNum.value;
  final articles = await articleService.getByPage(currentPage)
  return articles;
});

class ArticlesPage extends StatelessWidget {
const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (pageArticles.watch(context)) {
      AsyncData data => ArticleList(data.value),
      AsyncError(error: final e) => Text('$e'),
      AsyncLoading() || AsyncIdle() => const CircularProgressIndicator(),
    };
  }
}
```

Se puede transformar en una futura con `myFutureBeacon.toFuture()`
Esto es útil cuando un FutureBeacon depende de otro FutureBeacon.
Esta funcionalidad también está disponible para StreamBeacons.

```dart
final isAdminBeacon  = Beacon.writable(false);

var firstName = Beacon.future(() async {
  await Future.delayed(k10ms);
  return 'Sally';
});

var lastName = Beacon.future(() async {
  await Future.delayed(k10ms);
  return 'Smith';
});

var fullName = Beacon.future(() async {
  // esperar a que la futura se complete
  // no tenemos que manejar manualmente todos los estados
  final [fname, lname] = await Future.wait(
    [
      firstName.toFuture(),
      lastName.toFuture(),
    ],
  );

  return '$fname $lname';
});
```

#### FutureBeacon.overrideWith:

Reemplaza el callback actual y restablece el beacon ejecutando el nuevo callback.

```dart
var futureBeacon = Beacon.future(() async => 1);

await Future.delayed(k1ms);

expect(futureBeacon.unwrapValue(), 1);

futureBeacon.overrideWith(() async => throw Exception('error'));

await Future.delayed(k1ms);

expect(futureBeacon.isError, true);
```

#### FutureBeacon.updateWith:

El método `updateWith` te permite actualizar el valor de un FutureBeacon con el callback proporcionado. Esto difiere de `overrideWith` porque actualiza el valor solo una vez, mientras que `overrideWith` reemplaza el callback original suministrado al beacon.

```dart
Future<List<Todo>> loadTodos() async { ... }

Future<List<Todo>> addTodo(Todo newTodo) async {
  await todoService.addTodo(newTodo);
  final currentTodos = todosBeacon.lastData ?? [];
  return [newTodo, ...currentTodos];
}

final todosBeacon = Beacon.future(() => loadTodos());

// Más tarde, agregar un nuevo todo sin volver a obtener todos los todos
await todosBeacon.updateWith(() => addTodo(newTodo));

// También puedes proporcionar un resultado optimista
// que se establecerá inmediatamente mientras la futura se está resolviendo.
final optimisticTodos = [newTodo, ...todosBeacon.lastData ?? []];
await todosBeacon.updateWith(
  () => addTodo(newTodo),
  optimisticResult: optimisticTodos,
);
```

#### Propiedades:

Todos estos métodos también están disponibles para `StreamBeacons`.

-   `isIdle`
-   `isLoading`
-   `isIdleOrLoading`
-   `isData`
-   `isError`
-   `lastData`: Devuelve el último valor de datos exitoso o nulo. Esto es útil cuando deseas mostrar el último valor válido mientras se actualizan los datos.

#### Métodos:

Todos estos métodos con la excepción de `reset()` y `overrideWith()` también están disponibles para `StreamBeacons`.

-   `start()`: Inicia la futura si está en el estado `idle`.
-   `reset()`: Restablece el beacon ejecutando el callback nuevamente. Esto entrará en el estado `loading` inmediatamente.
-   `unwrapValue()`: Devuelve el valor si el beacon está en el estado `data`. Esto lanzará un error si el beacon no está en el estado `data`.
-   `unwrapValueOrNull()`: Esto es como `unwrapValue()` pero devuelve nulo si el beacon no está en el estado `data`.
-   `toFuture()`: Devuelve una futura que se completa con el valor cuando el beacon está en el estado `data`. Esto lanzará un error si el beacon no está en el estado `data`.
-   `overrideWith()`: Reemplaza el callback actual y restablece el beacon ejecutando el nuevo callback.
-   `updateWith()`: Actualiza el beacon con el resultado del callback futuro proporcionado.


## BeaconGroup:

Una alternativa al creador global de beacons es decir: `Beacon.writable(0)`; que realiza un seguimiento de todos los beacons y effects creados para que puedan eliminarse/restablecerse juntos.
Esto es útil cuando estás creando múltiples beacons en un widget stateful o una clase de controlador y deseas eliminarlos juntos. Consulta [BeaconController](#beaconcontroller).

```dart
 final myGroup = BeaconGroup();

 final name = myGroup.writable('Bob');
 final age = myGroup.writable(20);

 myGroup.effect(() {
   print(name.value); // Salida: Bob
 });

 age.value = 21;
 name.value = 'Alice';

 myGroup.resetAll(); // restablece los beacons pero no hace nada con el effect

 print(name.value); // Bob
 print(age.value); // 20

 myGroup.disposeAll();

 print(name.isDisposed); // true
 print(age.isDisposed); // true
 // Todos los beacons y effects son eliminados
```

## BeaconController

Una clase de mezcla abstracta que elimina automáticamente todos los beacons y effects creados dentro de ella. Esto se puede utilizar para crear un controlador que gestione un grupo de beacons. usa el [BeaconGroup](#beacongroup) (`B.writable()`) incluido en lugar de `Beacon.writable()` para crear beacons y effects.

NB: Todos los beacons deben crearse como una variable `late`.

```dart
class CountController extends BeaconController {
  late final count = B.writable(0);
  late final doubledCount = B.derived(() => count.value * 2);
}
```

## Inyección de dependencias

La inyección de dependencias se refiere al proceso de proporcionar una instancia de un Beacon o BeaconController a tus widgets. `state_beacon` incluye una biblioteca ligera de inyección de dependencias llamada [lite_ref](https://pub.dev/packages/lite_ref) que facilita y hace ergonómico hacer esto mientras también gestiona la eliminación de ambos.

NB: Puedes usar otra biblioteca de inyección de dependencias como `Provider`.

En el siguiente ejemplo, el controlador se eliminará cuando se desmonte `CounterText`:

```dart
class CountController extends BeaconController {
  late final count = B.writable(0);
  late final doubledCount = B.derived(() => count.value * 2);
}

final countControllerRef = Ref.scoped((ctx) => CountController());

class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    // observar el beacon de conteo y devolver su valor
    final count = countControllerRef.select(context, (c) => c.count);
    return Text('$count');
  }
}
```

```dart
final count = countControllerRef.select(context, (c) => c.count);

// es equivalente a
final controller = countControllerRef.of(context);
final count = controller.count.watch(context);
```

También puedes usar `select2` y `select3` para observar múltiples beacons a la vez.

```dart
final (count, doubledCount) = countControllerRef.select2(context, (c) => (c.count, c.doubledCount));

// es equivalente a
final controller = countControllerRef.of(context);
final count = controller.count.watch(context);
final doubledCount = controller.doubledCount.watch(context);
```

Consulta el ejemplo completo con pruebas [aquí](https://github.com/zupat/dart_beacon/blob/main/examples/counter/lib/main.dart).

También puedes usar `Ref.scoped` si deseas proporcionar un beacon de nivel superior sin ponerlo en un controlador. El beacon se eliminará correctamente cuando se desmonten todos los widgets que lo utilizan.

```dart
final countRef = Ref.scoped((ctx) => Beacon.writable(0));
final doubledCountRef = Ref.scoped((ctx) => Beacon.derived(() => countRef(ctx).value * 2));

class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    final count = countRef.watch(context);
    final doubledCount = doubledCountRef.watch(context);
    return Text('$count x 2 = $doubledCount');
  }
}
```

> [!NOTE]
> Aunque esto es posible, se recomienda usar `BeaconController`s siempre que sea posible. En casos donde solo necesitas un único beacon, esta puede ser una forma conveniente de proporcionarlo a un widget.


## Otros Beacons

### Beacon.stream:

Crea un `StreamBeacon` a partir de un stream dado.
Cuando una dependencia cambia, el beacon se cancelará la suscripción del stream antiguo y se suscribirá al nuevo.
Este beacon actualiza su valor según los valores emitidos por el stream.
Los valores emitidos se envuelven en un `AsyncValue`, que puede estar en uno de 4 estados:`idle`, `loading`, `data` o `error`.

Si `shouldSleep` es `true` (valor predeterminado), se cancelará la suscripción al stream si ya no está siendo observado.
Se volverá a suscribir una vez que se agregue un oyente o se acceda a su valor.
Esto significa que entrará en el estado `loading` al despertarse.

Se puede transformar en una futura con `mystreamBeacon.toFuture()`:

```dart
var myStream = Stream.periodic(Duration(seconds: 1), (i) => i);

var myBeacon = Beacon.stream(() => myStream);

myBeacon.subscribe((value) {
  print(value); // Salida AsyncLoading(),AsyncData(0),AsyncData(1),AsyncData(2),...
});
```

### Beacon.streamRaw:

Igual que `Beacon.stream`, pero no envuelve el valor en un `AsyncValue`.
Cuando una dependencia cambia, el beacon se cancelará la suscripción del stream antiguo y se suscribirá al nuevo.

Una de las siguientes condiciones debe ser `true` si no se proporciona un valor inicial:

1. El tipo es anulable
2. `isLazy` es true (el beacon debe establecerse antes de leerlo)

```dart
var myStream = Stream.periodic(Duration(seconds: 1), (i) => i);

var myBeacon = Beacon.streamRaw(() => myStream, initialValue: 0);

myBeacon.subscribe((value) {
  print(value); // Salida 0,1,2,3,...
});
```

### Beacon.debounced:

Crea un `DebouncedBeacon` que retrasará las actualizaciones de su valor según la duración. Esto es útil cuando deseas esperar a que el usuario haya terminado de escribir antes de realizar una acción.

```dart
var query = Beacon.debounced('', duration: Duration(seconds: 1));

query.subscribe((value) {
  print(value); // Salida: 'apple' después de 1 segundo
});

// simular escritura del usuario
query.value = 'a';
query.value = 'ap';
query.value = 'app';
query.value = 'appl';
query.value = 'apple';

// después de 1 segundo, el valor se actualizará a 'apple'
```

### Beacon.throttled:

Crea un `ThrottledBeacon` que limitará la frecuencia de actualizaciones de su valor según la duración.

Si `dropBlocked` es `true` (valor predeterminado), los valores se descartarán mientras el beacon está bloqueado; de lo contrario, los valores se almacenarán en búfer y se emitirán uno por uno cuando el beacon se desbloquee.

```dart
const k10ms = Duration(milliseconds: 10);
var beacon = Beacon.throttled(10, duration: k10ms);

beacon.set(20);
expect(beacon.value, equals(20)); // primera actualización permitida

beacon.set(30);
expect(beacon.value, equals(20)); // demasiado rápido, actualización ignorada

await Future.delayed(k10ms * 1.1);

beacon.set(30);
expect(beacon.value, equals(30)); // tiempo de limitación transcurrido, actualización permitida
```

### Beacon.filtered:

Crea un `FilteredBeacon` que solo actualizará su valor si pasa los criterios de filtro.
La función de filtro recibe los valores anterior y nuevo como argumentos.
La función de filtro también se puede cambiar usando el método `setFilter`.

#### Ejemplo simple:

```dart
// solo se permiten valores positivos
var pageNum = Beacon.filtered(10, filter: (prev, next) => next > 0);
pageNum.value = 20; // la actualización está permitida
pageNum.value = -5; // la actualización se ignora
```

#### Ejemplo cuando la función de filtro depende de otro beacon:

En este ejemplo, `posts` es un beacon futuro derivado que obtendrá las publicaciones cada vez que cambie `pageNum`.
Queremos evitar que el usuario cambie `pageNum` mientras `posts` está cargando.

```dart
var pageNum = Beacon.filtered(1); // estableceremos la función de filtro más tarde

final posts = Beacon.future(() => Repository.getPosts(pageNum.value));

// no se puede cambiar pageNum mientras se carga
pageNum.setFilter((prev, next) => !posts.isLoading);
```

Extraído del [ejemplo de lista infinita](https://github.com/zupat/dart_beacon/tree/main/examples/flutter_main/lib/infinite_list)

### Beacon.timestamped:

Crea un `TimestampBeacon` que adjunta una marca de tiempo a cada actualización de valor.

```dart
var myBeacon = Beacon.timestamped(10);
print(myBeacon.value); // Salida: (value: 10, timestamp: __CURRENT_TIME__)
```

### Beacon.undoRedo:

Crea un `UndoRedoBeacon` que permite deshacer y rehacer cambios en su valor.

```dart
var age = Beacon.undoRedo(0, historyLimit: 10);

age.value = 10;
age.value = 20;

age.undo(); // Revierte a 10
age.redo(); // Vuelve a 20
```

### Beacon.progress:

Crea un `ProgressBeacon` que emite valores periódicamente según el progreso (0.0 a 1.0).
Este beacon es útil para crear barras de progreso, temporizadores o animaciones.

El callback `onProgress` recibe el progreso actual (0.0 a 1.0) y devuelve el valor a emitir.
Si `loop` es verdadero, el progreso se restablecerá a 0.0 después de alcanzar 1.0 y continuará.

```dart
final progressBar = Beacon.progress(
  interval: Duration(milliseconds: 100),
  totalDuration: Duration(seconds: 5),
  onProgress: (p) => p,
);

progressBar.subscribe((val) {
  print('${val * 100}%');
});
```

Puedes controlar la ejecución con `start()`, `pause()`, `resume()` y `stop()`.

```dart
progressBar.pause();
// ...
progressBar.resume();
// ...
progressBar.start(); // reinicia el progreso desde 0.0
// ...
progressBar.stop(); // detiene el progreso y restablece el tiempo transcurrido
```

### Beacon.bufferedCount:

Crea un `BufferedCountBeacon` que recopila y almacena en búfer un número especificado de valores. Una vez que se alcanza el umbral de conteo, el valor del beacon se actualiza con la lista de valores recopilados y el búfer se restablece.

Este beacon es útil en escenarios donde necesitas agregar una cierta cantidad de valores antes de procesarlos juntos.

```dart
var countBeacon = Beacon.bufferedCount<int>(3);

countBeacon.subscribe((values) {
  print(values);
});

countBeacon.add(1);
countBeacon.add(2);
countBeacon.add(3); // Desencadena la actualización e imprime [1, 2, 3]
```

También puedes acceder al `currentBuffer` como un beacon de solo lectura.
Véalo en uso en el [ejemplo konami](https://github.com/zupat/dart_beacon/tree/main/examples/flutter_main/lib/konami);

### Beacon.bufferedTime:

Crea un `BufferedTimeBeacon` que recopila valores durante una duración de tiempo especificada.
Una vez que expira la duración de tiempo, el valor del beacon se actualiza con la lista de valores recopilados y el búfer se restablece.

```dart
var timeBeacon = Beacon.bufferedTime<int>(duration: Duration(seconds: 5));

timeBeacon.subscribe((values) {
  print(values);
});

timeBeacon.add(1);
timeBeacon.add(2);
// Después de 5 segundos, mostrará [1, 2]
```

### Beacon.list:

El `ListBeacon` proporciona métodos para agregar, eliminar y actualizar elementos en la lista y notifica a los oyentes sin necesidad de hacer una copia.

_NB_: El `previousValue` y el valor actual siempre serán los mismos porque se está mutando la misma lista. Si necesitas acceso a previousValue, usa Beacon.writable<List>([]) en su lugar.

#### Beacon.hashSet:

Similar a Beacon.list(), pero para Conjuntos (Sets).

```dart
var uniqueNumbers = Beacon.hashSet<int>({1, 2, 3});

Beacon.effect(() {
  print(uniqueNumbers.value); // Salida: {1, 2, 3}
});

uniqueNumbers.add(4); // Salida: {1, 2, 3, 4}

uniqueNumbers.remove(2); // Salida: {1, 3, 4}
```

#### Beacon.hashMap:

Similar a Beacon.list(), pero para Mapas.

```dart
var userMap = Beacon.hashMap<String, int>({});

Beacon.effect(() {
  print(userMap.value); // Salida: {}
});

userMap['Alice'] = 25; // Salida: {Alice: 25}

userMap['Bob'] = 30; // Salida: {Alice: 25, Bob: 30}

userMap.remove('Alice'); // Salida: {Bob: 30}
```

### AsyncValue:

Un `AsyncValue` es un envoltorio alrededor de un valor que puede estar en uno de cuatro estados:`idle`, `loading`, `data` o `error`.
Este es el tipo de valor de [FutureBeacons](#beaconfuture),[FutureBeacons](#beaconfuture) y [StreamBeacons](#beaconstream).

```dart
var myBeacon = Beacon.future(() async {
  return await Future.delayed(Duration(seconds: 1), () => 'Hello');
});

print(myBeacon.value); // Salida AsyncLoading inmediatamente

await Future.delayed(Duration(seconds: 1));

print(myBeacon.value); // Salida AsyncData('Hello')
```

#### AsyncValue.unwrap():

Convierte este [AsyncValue] a [AsyncData] y devuelve su valor. Esto lanzará un error si el valor no es un [AsyncData].

```dart
var name = AsyncData('Bob');
print(name.unwrap()); // Salida: Bob

name = AsyncLoading();
print(name.unwrap()); // Lanza error
```

#### AsyncValue.lastData:

Devuelve el último valor de datos válido o nulo. Esto es útil cuando deseas mostrar el último valor válido mientras se cargan nuevos datos.

```dart
var myBeacon = Beacon.future(() async {
  return await Future.delayed(Duration(seconds: 1), () => 'Hello');
});

print(myBeacon.value); // Salida AsyncLoading inmediatamente

print(myBeacon.value.lastData); // Salida null ya que no hay datos válidos todavía

await Future.delayed(Duration(seconds: 1));

print(myBeacon.value.lastData); // Salida 'Hello'

myBeacon.reset();

print(myBeacon.value); // Salida AsyncLoading

print(myBeacon.value.lastData); // Salida 'Hello' como el último dato válido cuando está en estado de carga
```

#### AsyncValue.tryCatch:

Ejecuta la futura proporcionada y devuelve [AsyncData] con el resultado
si es exitoso o [AsyncError] si se lanza una excepción.

Proporciona un [WritableBeacon] opcional que se establecerá a lo largo de los diversos estados.

Proporciona un [optimisticResult] opcional que se establecerá mientras se carga, en lugar de [AsyncLoading].

```dart
Future<String> fetchUserData() {
  // Imagina que esto es una solicitud de red que podría lanzar un error
  return Future.delayed(Duration(seconds: 1), () => 'User data');
}
  beacon.value = AsyncLoading();
  beacon.value = await AsyncValue.tryCatch(fetchUserData);
```

También puedes pasar el beacon como parámetro.
Los estados `loading`,`data` y `error`,
así como el último dato exitoso se establecerán automáticamente.

```dart
await AsyncValue.tryCatch(fetchUserData, beacon: beacon);

// o usar el método de extensión.

await beacon.tryCatch(fetchUserData);
```

Véalo en uso en el [ejemplo del carrito de compras](https://github.com/zupat/dart_beacon/tree/main/examples/shopping_cart/lib/src/cart).

Si deseas hacer actualizaciones optimistas, puedes proporcionar un parámetro `optimisticResult` opcional.

```dart
await beacon.tryCatch(mutateUserData, optimisticResult: 'User data');
```

Sin `tryCatch`, manejar el posible error requiere más
código repetitivo:

```dart
  beacon.value = AsyncLoading();
  try {
    beacon.value = AsyncData(await fetchUserData());
  } catch (err,stacktrace) {
    beacon.value = AsyncError(err, stacktrace);
  }
```

## Beacon.family:

Crea y gestiona una familia de `Beacon`s relacionados basados en una única función de creación.

Esta clase proporciona una forma conveniente de manejar beacons
relacionados que comparten la misma lógica de creación pero tienen diferentes argumentos.

### Parámetros de tipo:

-   `T`: El tipo del valor emitido por los beacons en la familia.
-   `Arg`: El tipo del argumento utilizado para identificar los beacons individuales dentro de la familia.
-   `BeaconType`: El tipo del beacon en la familia.

Si `cache` es `true`, los beacons creados se almacenan en caché. El valor predeterminado es `false`.

Ejemplo:

```dart
final postContentFamily = Beacon.family(
 (String id) {
   return Beacon.future(() async {
     return await Repository.getPostContent(id);
   });
 },
);


final postContent = postContentFamily('post-1');
final postContent = postContentFamily('post-2');

postContent.subscribe((value) {
  print(value); // Salida: post content
});
```

## Propiedades y Métodos:

### myBeacon.value:

El valor actual del beacon. Este beacon se registrará como una dependencia si se accede a él dentro de un beacon derivado o un effect. Alias: `myBeacon()`, `myBeacon.call()`.

### myBeacon.peek():

Devuelve el valor actual del beacon sin registrarlo como una dependencia.

### myBeacon.watch(context):

Devuelve el valor actual del beacon y reconstruye los widgets cada vez que el beacon se actualiza.

```dart
final name = Beacon.writable("Bob");

class ProfileCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // se reconstruye cuando el nombre cambia
    return Text(name.watch(context));
  }
}
```

### myBeacon.observe(context,callback):

Ejecuta el callback (efecto secundario) cada vez que el beacon se actualiza. ej: Mostrar un snackbar cuando el valor cambia.

```dart
final name = Beacon.writable("Bob");

class ProfileCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    name.observe(context, (prev, next) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('name changed from $prev to $next')),
      );
    });

    return Text(name.watch(context));
  }
}
```

### myBeacon.subscribe():

Se suscribe al beacon y escucha los cambios en su valor.

```dart

final age = Beacon.writable(20);

age.subscribe((value) {
  print(value); // Salida: 21, 22, 23
});

age.value = 21;
age.value = 22;
age.value = 23;
```

### myBeacon.stream:

Esto devuelve un stream que emite el valor del beacon cada vez que cambia.

### myWritable.wrap(anyBeacon):

Envuelve un beacon existente y consume sus valores

Proporciona una función (`then`) para personalizar cómo se procesan los valores emitidos.

```dart
var bufferBeacon = Beacon.bufferedCount<String>(10);
var count = Beacon.writable(5);

// Envuelve el bufferBeacon con el readableBeacon y proporciona una transformación personalizada.
bufferBeacon.wrap(count, then: (value) {
  // Transformación personalizada: Convertir el valor a cadena y agregarlo al búfer.
  bufferBeacon.add(value.toString());
});

print(bufferBeacon.buffer); // Salida: ['5']
count.value = 10;
print(bufferBeacon.buffer); // Salida: ['5', '10']
```

Este método está disponible en todos los beacons escribibles, incluidos los BufferedBeacons; y puede envolver cualquier beacon ya que todos los beacons son de solo lectura.

### myWritable.ingest(anyStream):

Esta funciona como `.wrap()` pero es específicamente para streams. Escucha el stream y actualiza el valor del beacon con los valores emitidos.

```dart
final beacon = Beacon.writable(0);
final myStream = Stream.fromIterable([1, 2, 3]);

beacon.ingest(myStream);

beacon.subscribe((value) {
  print(value); // Salida: 1, 2, 3
});
```

### mybeacon.next():

Escucha el próximo valor emitido por este Beacon y lo devuelve como una Future.

Este método se suscribe a este Beacon y espera el próximo valor
que coincida con la función [filter] opcional. Si se proporciona [filter] y
devuelve `false` para un valor emitido, el método continúa esperando el
próximo valor que coincida con el filtro. Si no se proporciona ningún [filter],
el método se completa con el primer valor recibido.

Si este es un beacon perezoso y se elimina antes de que se emita un valor,
la futura se completará con un error si no se proporciona un valor [fallback].

```dart
final age = Beacon.writable(20);

Timer(Duration(seconds: 1), () => age.value = 21;);

final nextAge = await age.next(); // devuelve 21 después de 1 segundo
```

### mybeacon.toListenable():

Devuelve un `ValueListenable` que emite el valor del beacon cada vez que cambia.

### mybeacon.toValueNotifier():

Devuelve un `ValueNotifier` que emite el valor del beacon cada vez que cambia. Cualquier mutación en el `ValueNotifier` se reflejará en el beacon. El `ValueNotifier` se eliminará cuando se elimine el beacon.

### mybeacon.dispose():

Elimina el beacon y libera todos los recursos.

### mybeacon.onDispose():

Registra un callback que se llamará cuando se elimine el beacon. Retorna una función que se puede llamar para anular el registro del callback.

## Métodos de encadenamiento:

Encadena beacons sin problemas para crear pipelines reactivos sofisticados, combinando múltiples funcionalidades para manipulación y control avanzado de valores.

```dart
// cada escritura en este beacon será filtrada y luego se aplicará debounce.
final searchQueryText = Beacon.writable('');
final searchQuery = searchQueryText.filter((prev, next) => next.length > 2).debounce(duration: k500ms);
```

> [!WARNING]  
> `buffer` y `bufferTime` no pueden estar en medio de la cadena. Si se utilizan, **DEBEN** ser los últimos en la cadena.

```dart
// BIEN
someBeacon.filter().buffer(10);

// MAL
someBeacon.buffer(10).filter();
```

### mybeacon.buffer():

Devuelve un [Beacon.bufferedCount](#beaconbufferedcount) que envuelve este beacon.

NB: El beacon devuelto se eliminará cuando se elimine el beacon envuelto.

```dart
final age = Beacon.writable(20);

final bufferedAge = age.buffer(10);

bufferedAge.subscribe((value) {
  print(value); // Salida: [20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
});

for (var i = 0; i < 10; i++) {
  age.value++;
}
```

### mybeacon.bufferTime():

Devuelve un [Beacon.bufferedTime](#beaconbufferedtime) que envuelve este beacon.

### mybeacon.throttle():

Devuelve un [Beacon.throttled](#beaconthrottled) que envuelve este beacon.

### mybeacon.filter():

Devuelve un [Beacon.filtered](#beaconfiltered) que envuelve este beacon.

### mybeacon.map():

Devuelve un [ReadableBeacon] que envuelve un Beacon y transforma sus valores.

```dart
final stream = Stream.periodic(k1ms, (i) => i).take(5);
final beacon = stream
    .toRawBeacon(isLazy: true)
    .map((v) => v.toString());

await expectLater(beacon.stream, emitsInOrder(['0', '1', '2', '3', '4']));
```

> [!NOTE]
> Cuando `map` devuelve un tipo diferente, las escrituras en el beacon devuelto no se volverán a enrutar al beacon original. En el ejemplo a continuación, las escrituras en `filteredBeacon` NO se volverán a enrutar a `count` porque `map` devuelve un `String`; lo que significa que el tipo del beacon devuelto es `FilteredBeacon<String>` y `count` contiene un `int`.

```dart
final count = Beacon.writable(0);
final filteredBeacon = count.map((v) => '$v').filter((_, n) => n.length > 1);
```

### mybeacon.debounce():

Devuelve un [Beacon.debounced](#beacondebounced) que envuelve este beacon.

```dart
final query = Beacon.writable('');

const k500ms = Duration(milliseconds: 500);

final debouncedQuery = query
        .filter((prev, next) => next.length > 2)
        .debounce(duration: k500ms);
```

## Depuración:

Establece la instancia global `BeaconObserver` para recibir notificaciones de toda la creación, actualización y eliminación de beacons. También puedes ver cuándo un beacon derivado o effect comienza/deja de observar un beacon.

Puedes crear tu propio observador implementando `BeaconObserver` o usar el observador de registro proporcionado, que registra en la consola. Proporciona un `name` a tus beacons para facilitar su identificación en los registros.

```dart
BeaconObserver.instance = LoggingObserver(); // o BeaconObserver.useLogging()

var a = Beacon.writable(10, name: 'a');
var b = Beacon.writable(20, name: 'b');
var c = Beacon.derived(() => a() * b(), name: 'c');

Beacon.effect(
  () {
    print('c: ${c.value}');
  },
  name: 'printEffect',
);
```

Esto registrará:

```
Beacon created: a
Beacon created: b
Beacon created: c

"printEffect" is watching "c"

"c" is watching "a"
"c" is watching "b"

"c" was updated:
  old: null
  new: 200
```

Actualizando un beacon:

```dart
a.value = 15;
```

Esto registrará:

```
"a" was updated:
  old: 10
  new: 15

"c" was updated:
  old: 200
  new: 300
```

Eliminando un beacon

```dart
c.dispose();
```

Esto registrará:

```
"c" stopped watching "a"
"c" stopped watching "b"

"c" was disposed
"printEffect" stopped watching c
```

## Eliminación (Disposal)

Cuando se elimina un beacon, todos los beacons derivados downstream y los effects también se eliminarán.
Un beacon no puede actualizarse después de ser eliminado. Se lanzará un error de aserción si intentas actualizar un beacon eliminado.
Se registrará una advertencia en modo de depuración si intentas acceder al valor de un beacon eliminado.
Un beacon debe eliminarse cuando ya no sea necesario para liberar recursos.

En el siguiente ejemplo, cuando se elimina `a`, `c` y `effect` también se eliminarán.

```
  a      b
   \    /
    \  /
     c
     |
     |
   effect
```

```dart
final a = Beacon.writable(10);
final b = Beacon.writable(10);
final c = Beacon.derived(() => a.value * b.value);

Beacon.effect(() => print(c.value));

//...//

a.dispose();

expect(a.isDisposed, true);
expect(c.isDisposed, true);
// effect también es eliminado
```

### BeaconScheduler:

Los `Effects` y las `Subscriptions` no son síncronos; su ejecución está controlada por un programador (scheduler). Cuando una dependencia de un `effect` cambia, se agrega a una cola y el programador decide cuál es el mejor momento para vaciar la cola. De forma predeterminada, la cola se vacía con una microtarea de DARTVM que se ejecuta en el siguiente bucle; esto puede cambiarse estableciendo un programador personalizado.

Se incluye un programador de 60fps, que limita el procesamiento de effects a 60 veces por segundo. Esto se puede hacer llamando a `BeaconScheduler.use60FpsScheduler();` en la función `main`. También puedes crear tu propio programador personalizado para casos de uso más avanzados. ej: `Gaming`: Sincronizar el vaciado con tu bucle de juego.

Cuando se prueba código **sincrónico**, es necesario vaciar la cola manualmente. Esto se puede hacer llamando a `BeaconScheduler.flush();` en tu prueba.

> [!NOTE]
> Al escribir pruebas de widgets, no es necesario vaciar manualmente. La cola se vacía automáticamente cuando llamas a `tester.pumpAndSettle()`.

```dart
final a = Beacon.writable(10);
var called = 0;

// effect se pone en cola para su ejecución. El programador decide cuándo ejecutar el effect
Beacon.effect(() {
      print("current value: ${a.value}");
      called++;
});

// vaciar manualmente la cola para ejecutar todos los effects inmediatamente
BeaconScheduler.flush();

expect(called, 1);

a.value = 20; // effect se pondrá en cola nuevamente.

BeaconScheduler.flush();

expect(called, 2);
```

## Pruebas

Los beacons pueden exponer un `Stream` con el método `.stream`. Esto se puede utilizar para probar el estado de un beacon a lo largo del tiempo con los `StreamMatcher`s existentes.

```dart
final count = Beacon.writable(10);

final stream = count.stream;

Future.delayed(Duration(milliseconds: 1), () {
  count.value = 20;
  BeaconScheduler.flush();
});

Future.delayed(Duration(milliseconds: 1), () => count.value = 30);

expect(stream, emitsInOrder([10, 20, 30]));
```

o

```dart
final count = Beacon.writable(10);

expect(count.stream, emitsInOrder([10, 20, 30]));

BeaconScheduler.flush(); // permitir que el stream capture el 10

count.value = 20;
BeaconScheduler.flush();

count.value = 30;
BeaconScheduler.flush();
```

o

```dart
final count = Beacon.writable(10);

final stream = count.stream;

await expectLater(stream, emits(10));

count.value = 20;

await expectLater(stream, emits(20));

count.value = 30;

await expectLater(stream, emits(30));
```

### Probando beacons con métodos de encadenamiento

[Los métodos de encadenamiento](#chaining-methods) (`buffer`, `bufferTime`, `next`) se pueden utilizar para facilitar las pruebas.

##### anyBeacon.buffer()

```dart
final count = Beacon.writable(10);

final buff = count.buffer(3);

BeaconScheduler.flush(); // permitir que el búfer lea el primer valor

count.value = 20;
BeaconScheduler.flush();

count.value = 30;
BeaconScheduler.flush();

expect(buff.value, equals([10, 20, 30]));
```

o

```dart
final count = Beacon.writable(10);

final buff = count.buffer(3);

await Future.delayed(Duration(milliseconds: 1)); // permitir que el búfer lea el primer valor

count.value = 20;
await Future.delayed(Duration(milliseconds: 1));

count.value = 30;

expect(await buff.next(), equals([10, 20, 30]));
```

o

```dart
final count = Beacon.writable(10);

final buff = count.buffer(3);

await Future.delayed(Duration(milliseconds: 1)); // permitir que el búfer lea el primer valor

count.value = 20;
await Future.delayed(Duration(milliseconds: 1));

count.value = 30;
await Future.delayed(Duration(milliseconds: 1));

expect(buff.value, equals([10, 20, 30]));
```

##### anyBeacon.next()

```dart
final count = Beacon.writable(10);

expectLater(count.next(), completion(30));

count.value = 30;
```

##### anyBeacon.bufferTime().next()

```dart
final count = Beacon.writable(10);

final buffTime = count.bufferTime(duration: Duration(milliseconds: 10));

expectLater(buffTime.next(), completion([10, 20, 30, 40]));

count.value = 20;
count.value = 30;
count.value = 40;
```

### BeaconControllerMixin

Una mezcla para la clase `State` de `StatefulWidget` que elimina automáticamente todos los beacons y effects creados dentro de ella.

```dart
class MyController extends StatefulWidget {
  const MyController({super.key});

  @override
  State<MyController> createState() => _MyControllerState();
}

class _MyControllerState extends State<MyController>
    with BeaconControllerMixin {
  // NO es necesario eliminar estos manualmente
  late final count = B.writable(0);
  late final doubledCount = B.derived(() => count.value * 2);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## TextEditingBeacon

Un beacon que envuelve un `TextEditingController`. Todos los cambios en el controlador se reflejan en el beacon y viceversa.

```dart
final beacon = TextEditingBeacon();
final controller = beacon.controller;

controller.text = 'Hello World';
print(beacon.value.text); // Salida: Hello World
```

## Pitfalls

Cuando usas `Beacon.future`, solo los beacons accedidos antes de la brecha asíncrona (`await`) se rastrearán como dependencias.

```dart
final counter = Beacon.writable(0);
final doubledCounter = Beacon.derived(() => counter.value * 2);

final futureCounter = Beacon.future(() async {
  // Esto se rastreará como una dependencia porque se accede antes de la brecha asíncrona
  final count = counter.value;

  await Future.delayed(Duration(seconds: count));

  // Esto NO se rastreará como una dependencia porque se accede después de `await`
  final doubled = doubledCounter.value;

  return '$count x 2 =  $doubled';
});
```

Cuando una futura depende de múltiples beacons futuros/stream

-   NO HAGAS:

```dart
final futureCounter = Beacon.future(() async {
  // en este caso lastNameStreamBeacon no se rastreará como una dependencia
  // porque se accede después de la brecha asíncrona
  final firstName = await firstNameFutureBeacon.toFuture();
  final lastName = await lastNameStreamBeacon.toFuture();

  return 'Fullname is $firstName $lastName';
});
```

-   HAZLO:

```dart
final futureCounter = Beacon.future(() async {
  // almacena las futuras antes de la brecha asíncrona, es decir, no uses await
  final firstNameFuture = firstNameFutureBeacon.toFuture();
  final lastNameFuture = lastNameStreamBeacon.toFuture();

  // espera a que las futuras se completen
  final (String firstName, String lastName) = await (firstNameFuture, lastNameFuture).wait;

  return 'Fullname is $firstName $lastName';
});
```
