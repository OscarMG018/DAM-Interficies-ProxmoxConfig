class RedirectionData {
  int? dport;
  int? tport;

  RedirectionData({
    required this.dport,
    required this.tport,
  });

  @override
  String toString() {
    return 'RedirectionData{dport: $dport, tport: $tport}';
  }
}