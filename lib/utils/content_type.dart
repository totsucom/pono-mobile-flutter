class ContentType {
  static const Jpeg = 'image/jpeg';
  static const Png = 'image/png';
  static const Gif = 'image/gif';
  static const Bmp = 'image/bmp';

  static String fromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return null;
    final ext = path.substring(i + 1).toUpperCase();
    switch (ext) {
      case 'JPG':
        return ContentType.Jpeg;
      case 'JPEG':
        return ContentType.Jpeg;
      case 'PNG':
        return ContentType.Png;
      case 'GIF':
        return ContentType.Gif;
      case 'BMP':
        return ContentType.Bmp;
      default:
        return null;
    }
  }
}
