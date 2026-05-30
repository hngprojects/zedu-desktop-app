void main() {
  var t1 = DateTime.tryParse("2026-05-30 04:30:00")?.toLocal();
  var t2 = DateTime.tryParse("2026-05-30T04:30:00Z")?.toLocal();
  var t3 = DateTime.tryParse("2026-05-30T04:30:00+01:00")?.toLocal();
  print(t1);
  print(t2);
  print(t3);
}
