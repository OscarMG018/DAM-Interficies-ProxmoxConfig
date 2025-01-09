class ServerConfiguration {
  String name;
  String host;
  int port;
  String idRsaPath;
  bool favorite;


  ServerConfiguration({
    this.name = "",
    this.host = "",
    this.port = 0,
    this.idRsaPath = "",
    this.favorite = false,
  });

  @override
  String toString() {
    return 'ServerConfiguration(nom: $name, server: $host, port: $port, idRsaPath: $idRsaPath, favorite: $favorite)';
  }
}
