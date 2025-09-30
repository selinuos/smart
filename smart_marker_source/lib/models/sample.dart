class Sample {
  final DateTime ts;
  final double ax, ay, az;
  final double gx, gy, gz;
  final String raw;

  Sample({
    required this.ts,
    required this.ax, required this.ay, required this.az,
    required this.gx, required this.gy, required this.gz,
    required this.raw,
  });

  String toCsvRow() {
    return "\${ts.toUtc().toIso8601String()},\$ax,\$ay,\$az,\$gx,\$gy,\$gz,"\${raw.replaceAll('"','\'')}"";
  }
}