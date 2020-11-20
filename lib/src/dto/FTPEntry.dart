import 'package:ftpconnect/ftpconnect.dart';

class FTPEntry {
  final String name;
  final DateTime modifyTime;
  final String persmission;
  final FTPEntryType type;
  final int size;
  final String unique;
  final String group;
  final int gid;
  final String mode;
  final String owner;
  final int uid;
  final Map<String, String> additionalProperties;

  // Hide constructor
  FTPEntry.x(
      this.name,
      this.modifyTime,
      this.persmission,
      this.type,
      this.size,
      this.unique,
      this.group,
      this.gid,
      this.mode,
      this.owner,
      this.uid,
      this.additionalProperties);

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

    return FTPEntry.x(_name, _modifyTime, _persmission, _type, _size, _unique,
        _group, _gid, _mode, _owner, _uid, Map.unmodifiable(_additional));
  }

  @override
  String toString() =>
      'name=$name;modifyTime=$modifyTime;permission=$persmission;type=$type;size=$size;unique=$unique;group=$group;mode=$mode;owner=$owner';
}

enum FTPEntryType { FILE, DIR }
