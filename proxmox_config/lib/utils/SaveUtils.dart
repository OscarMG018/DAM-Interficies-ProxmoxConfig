import 'dart:convert';
import 'dart:io';

class SaveUtils {

  static void save(String fileName, Object object) {
    File file = File(fileName);
    file.writeAsStringSync(json.encode(object));
  }

  static List<dynamic> load(String fileName) {
    File file = File(fileName);
    return json.decode(file.readAsStringSync());
  }

  static Future<void> saveAsync(String fileName, Object object) async {
    File file = File(fileName);
    await file.writeAsString(json.encode(object));
  }

  static Future<List<dynamic>> loadAsync(String fileName) async {
    File file = File(fileName);
    return json.decode(await file.readAsString());
  }
}