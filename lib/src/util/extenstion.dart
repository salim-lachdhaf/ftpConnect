import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';

extension CommandListTypeEnum on DIR_LIST_COMMAND {
  String get describeEnum =>
      this.toString().substring(this.toString().indexOf('.') + 1);
}

extension FtpEntryTypeEnum on FTPEntryType {
  String get describeEnum =>
      this.toString().substring(this.toString().indexOf('.') + 1);
}
