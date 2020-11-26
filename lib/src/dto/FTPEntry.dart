import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';
import 'package:ftpconnect/src/util/extenstion.dart';
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

  static final RegExp regexpLIST = RegExp(r"^([\-ld])" // Directory flag [1]
      r"([\-rwxs]{9})\s+" // Permissions [2]
      r"(\d+)\s+" // Number of items [3]
      r"(\w+)\s+" // File owner [4]
      r"(\w+)\s+" // File group [5]
      r"(\d+)\s+" // File size in bytes [6]
      r"(\w{3}\s+\d{1,2}\s+(?:\d{1,2}:\d{1,2}|\d{4}))\s+" // date[7]
      r"(.+)$" //file/dir name[8]
      );

  static final regexpLISTSiiServers = RegExp(r"^(.{8}\s+.{7})\s+" //date[1]
      r"(.{0,5})\s+" //type file or dir [2]
      r"(\d{0,24})\s+" //size [3]
      r"(.+)$" //file/ dir name [4]
      );

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

  factory FTPEntry.parse(String responseLine, DIR_LIST_COMMAND cmd) {
    if (cmd == DIR_LIST_COMMAND.LIST)
      return FTPEntry._parseListCommand(responseLine);
    else if (cmd == DIR_LIST_COMMAND.NLST)
      return FTPEntry._(responseLine, null, null, null, null, null, null, null,
          null, null, null, null);
    else
      return FTPEntry._parseMLSDCommand(responseLine);
  }

  factory FTPEntry._parseMLSDCommand(final String responseLine) {
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
            _modifyTime = DateTime.tryParse(prop[1]) ?? DateTime.tryParse(date);
            break;
          case 'perm':
            _persmission = prop[1];
            break;
          case 'size':
            _size = int.parse(prop[1]);
            break;
          case 'type':
            if (prop[1] == 'dir')
              _type = FTPEntryType.DIR;
            else if (prop[1] == 'file')
              _type = FTPEntryType.FILE;
            else
              _type = FTPEntryType.LINK;
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

    return FTPEntry._(_name, _modifyTime, _persmission, _type, _size, _unique,
        _group, _gid, _mode, _owner, _uid, Map.unmodifiable(_additional));
  }

  ///reference http://cr.yp.to/ftp/list/binls.html
  ///-rw-r--r-- 1 owner group           213 Aug 26 16:31 FileName.txt
  ///d for Dir
  ///- for file
  ///
  /// SII servers format:
  /// 02-11-15  03:05PM      <DIR>     1410887680 directory
  /// 02-11-15  03:05PM               1410887680 file.avi
  factory FTPEntry._parseListCommand(final String responseLine) {
    if (responseLine == null || responseLine.trim().isEmpty) {
      throw FTPException('Can\'t create instance from empty information');
    }

    if (regexpLIST.hasMatch(responseLine))
      return FTPEntry._parseLIST(responseLine);
    else
      return FTPEntry._parseLISTiis(responseLine);
  }

  factory FTPEntry._parseLIST(final String responseLine) {
    if (responseLine == null || responseLine.trim().isEmpty)
      throw FTPException('Can\'t create instance from empty information');
    if (!regexpLIST.hasMatch(responseLine))
      throw FTPException('Invalid format for LIST command response !');
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

    Iterable<Match> matches = regexpLIST.allMatches(responseLine);
    for (Match match in matches) {
      if (match.group(1) == "-")
        _type = FTPEntryType.FILE;
      else if (match.group(1) == "d")
        _type = FTPEntryType.DIR;
      else
        _type = FTPEntryType.LINK;

      //permission
      _persmission = match.group(2);
      //nb files
      //var nbFiles = match.group(3);
      //owner
      _owner = match.group(4);
      //group
      _group = match.group(5);
      //size
      _size = int.tryParse(match.group(6)) ?? 0;
      //date
      String date = (match.group(7).split(" ")..removeWhere((i) => i.isEmpty))
          .join(" "); //keep only one space
      //insert year
      if (date.contains(':')) date = '$date ${DateTime.now().year}';
      var format = date.contains(':') ? 'MMM dd hh:mm yyyy' : 'MMM dd yyyy';
      _modifyTime = DateFormat(format).parse(date);
      //file/dir name
      _name = match.group(8);
    }
    return FTPEntry._(_name, _modifyTime, _persmission, _type, _size, _unique,
        _group, _gid, _mode, _owner, _uid, {});
  }

  factory FTPEntry._parseLISTiis(final String responseLine) {
    if (responseLine == null || responseLine.trim().isEmpty) {
      throw FTPException('Can\'t create instance from empty information');
    }
    if (!regexpLISTSiiServers.hasMatch(responseLine))
      throw FTPException('Invalid format for LIST command response !');

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
    Iterable<Match> matches = regexpLISTSiiServers.allMatches(responseLine);
    for (Match match in matches) {
      //date
      String date = (match.group(1).split(" ")..removeWhere((i) => i.isEmpty))
          .join(" "); //keep only one space
      _modifyTime = DateFormat('MM-dd-yyyy hh:mma').parse(date);

      //type
      if (match.group(2).trim().isEmpty)
        _type = FTPEntryType.FILE;
      else if (match.group(2).toLowerCase().contains("dir"))
        _type = FTPEntryType.DIR;
      else
        _type = FTPEntryType.LINK;

      //size
      _size = int.tryParse(match.group(3)) ?? 0;

      //file/dir name
      _name = match.group(4);
    }
    return FTPEntry._(_name, _modifyTime, _persmission, _type, _size, _unique,
        _group, _gid, _mode, _owner, _uid, {});
  }

  @override
  String toString() =>
      'name=$name;modify=$modifyTime;perm=$persmission;type=${type.describeEnum.toLowerCase()};size=$size;unique=$unique;unix.group=$group;unix.mode=$mode;unix.owner=$owner;unix.uid=$uid;unix.gid=$gid';
}

enum FTPEntryType { FILE, DIR, LINK }
