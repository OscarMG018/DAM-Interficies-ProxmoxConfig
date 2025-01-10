class ServerConfiguration {
  String name;
  String host;
  String username;
  int port;
  String idRsaPath;
  bool favorite;

  ServerConfiguration({
    this.name = "",
    this.host = "",
    this.username = "",
    this.port = 0,
    this.idRsaPath = "",
    this.favorite = false,
  });

  @override
  String toString() {
    return 'ServerConfiguration(nom: $name, server: $host, username: $username, port: $port, idRsaPath: $idRsaPath, favorite: $favorite)';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'host': host,
    'username' : username,
    'port': port,
    'idRsaPath': idRsaPath,
    'favorite': favorite,
  };

  ServerConfiguration.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        host = json['host'],
        port = json['port'],
        username = json['username'],
        idRsaPath = json['idRsaPath'],
        favorite = json['favorite'];
}
