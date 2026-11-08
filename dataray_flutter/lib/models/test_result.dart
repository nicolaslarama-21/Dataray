class TestResult {
  const TestResult(
      {required this.id,
      required this.time,
      required this.distance,
      required this.bits,
      required this.errors,
      required this.crcOk,
      required this.stationId});
  final int id;
  final DateTime time;
  final double distance;
  final int bits;
  final int errors;
  final bool crcOk;
  final String stationId;
  double? get ber => bits > 0 ? errors / bits : null;
  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'distance': distance,
        'bits': bits,
        'errors': errors,
        'crcOk': crcOk,
        'stationId': stationId
      };
  factory TestResult.fromJson(Map<String, dynamic> j) => TestResult(
      id: j['id'] as int,
      time: DateTime.parse(j['time'] as String),
      distance: (j['distance'] as num).toDouble(),
      bits: j['bits'] as int,
      errors: j['errors'] as int,
      crcOk: j['crcOk'] as bool,
      stationId: j['stationId'] as String);
}
