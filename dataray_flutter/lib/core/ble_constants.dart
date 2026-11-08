import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConstants {
  static final serviceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final rxUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
  static final txUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');
  static final statusUuid = Guid('6e400004-b5a3-f393-e0a9-e50e24dcca9e');
  static final infoUuid = Guid('6e400005-b5a3-f393-e0a9-e50e24dcca9e');

  static const stationPrefix = 'DATARAY_';
}
