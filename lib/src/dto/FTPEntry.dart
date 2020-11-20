import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';
import 'package:intl/intl.dart';

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
  FTPEntry._(
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

  factory FTPEntry(String responseLine, DIR_LIST_COMMAND cmd) {
    return (cmd ?? DIR_LIST_COMMAND.MLSD) == DIR_LIST_COMMAND.LIST
        ? _parseListCommand(responseLine)
        : _parseMLSDCommand(responseLine);
  }

  FTPEntry _parseMLSDCommand(final String responseLine) {
    if (responseLine == null || responseLine.trim().isEmpty) {
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
    responseLine.trim().split(';').forEach((property) {
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

    return FTPEntry(
        _name,
        _modifyTime,
        _persmission,
        _type,
        _size,
        _unique,
        _group,
        _gid,
        _mode,
        _owner,
        _uid,
        Map.unmodifiable(_additional));
  }

  FTPEntry _parseListCommand(final String responseLine) {
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

    var data = responseLine.split(" ")
      ..removeWhere((i) =>
      i
          .trim()
          .isEmpty);
    if (data.length < 9)
      return FTPEntry._(
          _name,
          _modifyTime,
          _persmission,
          _type,
          _size,
          _unique,
          _group,
          _gid,
          _mode,
          _owner,
          _uid,
          Map.unmodifiable({}));

    //permission and type in first
    _type = data.first[0] == "-" ? FTPEntryType.FILE : FTPEntryType.DIR;
    _persmission = data.first.substring(1);

    //owner in third place
    _owner = data[2];

    //group in forth place
    _group = data[3];

    //size in fifth place
    _size = int.tryParse(data[4]) ?? 0;
    //date in six, seven and eight place
    String date = '${data[5]}${data[6]}_${data[7]}_${DateTime
        .now()
        .year}';
    //if the file is modified in last six/year , it return only the time
    //other wises it returns the years instead
    String time = data[7].contains(':') ? data[7] : null;
    String formatDate = time == null ? 'MMMdd_yyyy_yyyy' : 'MMMdd_hh:mm_yyyy';
    _modifyTime = DateFormat(formatDate).parse(date);

    //file name in the last
    _name = data.last;

    return FTPEntry._(
        _name,
        _modifyTime,
        _persmission,
        _type,
        _size,
        _unique,
        _group,
        _gid,
        _mode,
        _owner,
        _uid,
        {});
  }

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
