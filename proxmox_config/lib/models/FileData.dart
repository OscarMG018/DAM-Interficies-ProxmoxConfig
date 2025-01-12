class FileData {
  final String name;
  final String extension;
  final bool isFolder;

  FileData({
    required this.name,
    required this.extension,
    required this.isFolder,
  });

  String getImagePath() {
    if (isFolder) {
      return 'assets/images/folder.png';
    } else {
      if (extension == 'txt') {
        return 'assets/images/txt.png';
      } else if (extension == 'png') {
        return 'assets/images/png.png';
      } else {
        return 'assets/images/file.png';
      }
    }
  }
}