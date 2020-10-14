import 'package:ftpconnect/ftpconnect.dart';

const _MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime _buildDateTime(String monthStr, String dayStr, String hourOrYear) {
  int year;
  int hour = 0;
  int minute = 0;

  if (hourOrYear.contains(':')) {
    var splitted = hourOrYear.trim().split(':');
    hour = int.parse(splitted[0]);
    minute = int.parse(splitted[1]);
    year = DateTime.now().year;
  } else {
    year = int.parse(hourOrYear.trim());
  }

  int month = _MONTHS.indexOf(monthStr.trim()) + 1;

  return DateTime(year, month, int.parse(dayStr.trim()), hour, minute);
}

class SimpleFtpEntry {
  static final linePattern = RegExp(r"([-dl]).* ([0-9]+) ([a-zA-Z]{3}) (.[0-9]) +(\d{2}:?\d{2}) (.*)");
  final String originalLine;
  final String name;
  final DateTime modifyTime;
  final FTPEntryType type;
  final int size;

  SimpleFtpEntry({this.originalLine, this.name, this.modifyTime, this.type, this.size});

  factory SimpleFtpEntry.parse(String line) {
    if (line == null || line.trim().isEmpty) {
      throw FTPException('Can\'t create instance from empty information');
    }
    if (!linePattern.hasMatch(line)) {
      throw ArgumentError.value(line, 'ftp list files line', "doesn't match regex: $linePattern");
    }
    var match = linePattern.firstMatch(line);
    String type = match.group(1);
    int size = int.parse(match.group(2));
    DateTime modifyTime = _buildDateTime(match.group(3), match.group(4), match.group(5));
    String filename = match.group(6);

    return SimpleFtpEntry(
        originalLine: line,
        type: type == 'd' ? FTPEntryType.DIR : FTPEntryType.FILE,
        size: size,
        modifyTime: modifyTime,
        name: filename);
  }

  @override
  String toString() {
    return "name: $name, type: $type, size: $size, modifyTime: $modifyTime";
  }

  
}

class FTPEntry extends SimpleFtpEntry {
  final String persmission;
  final String unique;
  final String group;
  final int gid;
  final String mode;
  final String owner;
  final int uid;
  final Map<String, String> additionalProperties;

  // Hide constructor
  FTPEntry._(
      String originalLine, 
      String name, 
      DateTime modifyTime, 
      this.persmission,
      FTPEntryType type, 
      int size,
      this.unique,
      this.group,
      this.gid,
      this.mode,
      this.owner,
      this.uid,
      this.additionalProperties)
      : super(
        originalLine: originalLine, 
        name: name, 
        modifyTime: modifyTime, 
        type: type, 
        size: size);

  factory FTPEntry(final String sMlsdResponseLine) {
    if (sMlsdResponseLine == null || sMlsdResponseLine.trim().isEmpty) {
      throw FTPException('Can\'t create instance from empty information');
    }

    String _name;
    DateTime _modifyTime;
    String _persmission;
    FTPEntryType _type;
    int _size = 0;
    String _unique;
    String _group;
    int _gid = -1;
    String _mode;
    String _owner;
    int _uid = -1;
    Map<String, String> _additional = {};

    // Split and trim line
    sMlsdResponseLine.trim().split(';').forEach((property) {
      final prop = property
          .split('=')
          .map((part) => part.trim())
          .toList(growable: false);

      if (prop.length == 1) {
        // Name
        _name = prop[0];
      } else {
        // Other attributes
        switch (prop[0].toLowerCase()) {
          case 'modify':
            final String date =
                prop[1].substring(0, 8) + 'T' + prop[1].substring(8);
            _modifyTime = DateTime.parse(date);
            break;
          case 'perm':
            _persmission = prop[1];
            break;
          case 'size':
            _size = int.parse(prop[1]);
            break;
          case 'type':
            _type = prop[1] == 'dir' ? FTPEntryType.DIR : FTPEntryType.FILE;
            break;
          case 'unique':
            _unique = prop[1];
            break;
          case 'unix.group':
            _group = prop[1];
            break;
          case 'unix.gid':
            _gid = int.parse(prop[1]);
            break;
          case 'unix.mode':
            _mode = prop[1];
            break;
          case 'unix.owner':
            _owner = prop[1];
            break;
          case 'unix.uid':
            _uid = int.parse(prop[1]);
            break;
          default:
            _additional.putIfAbsent(prop[0], () => prop[1]);
            break;
        }
      }
    });

    return FTPEntry._(sMlsdResponseLine, _name, _modifyTime, _persmission, _type, _size,_unique,
        _group, _gid, _mode, _owner, _uid, Map.unmodifiable(_additional));
  }

  @override
  String toString() =>
      'name=$name;modifyTime=$modifyTime;permission=$persmission;type=$type;size=$size;unique=$unique;group=$group;mode=$mode;owner=$owner';
}

enum FTPEntryType { FILE, DIR }
