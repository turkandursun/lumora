import 'package:drift/wasm.dart';

// Compiled with `dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart`.
// Defines the dedicated/shared web worker drift uses to host the database
// off the main thread. See https://drift.simonbinder.eu/platforms/web/.
void main() => WasmDatabase.workerMainForOpen();
