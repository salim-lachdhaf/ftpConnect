import 'package:flutter_test/flutter_test.dart';
import 'package:ftpconnect/ftpconnect.dart';

int currentYear = DateTime.now().year;

void main() {
  var correctLinesToTest = [
    SimpleFtpEntry(
        originalLine: '-rw-r--r--    1 dlptest9   dlptest9           17 Oct 13 05:34 file1.txt',
        modifyTime: DateTime(currentYear, DateTime.october, 13, 5, 34),
        size: 17,
        name: 'file1.txt',
        type: FTPEntryType.FILE),
    SimpleFtpEntry(
        originalLine: '-rwx--x--x    2 3312038  3312038         2 Apr 26  2016 file2',
        modifyTime: DateTime(2016, DateTime.april, 26),
        size: 2,
        name: 'file2',
        type: FTPEntryType.FILE),
    SimpleFtpEntry(
        originalLine: 'drwxrwx---    2 3312038  3312038         4 Oct  6 07:34 dir1',
        modifyTime: DateTime(currentYear, DateTime.october, 6, 7, 34),
        size: 4,
        name: 'dir1',
        type: FTPEntryType.DIR),
    SimpleFtpEntry(
        originalLine: 'drwxrwx---    2 3312038  3312038         3 Oct 12 2017 dir2',
        modifyTime: DateTime(2017, DateTime.october, 12),
        size: 3,
        name: 'dir2',
        type: FTPEntryType.DIR),
    SimpleFtpEntry(
        originalLine: 'lrwxrwx---    2 3312038  3312038         3 Oct 13 12:58 link-as-file',
        modifyTime: DateTime(currentYear, DateTime.october, 13, 12, 58),
        name: 'link-as-file',
        size: 3,
        type: FTPEntryType.FILE),
  ];

  correctLinesToTest.forEach((entry) {
    test('SimpleFtpEntry for ${entry.originalLine}', () {
      SimpleFtpEntry parsed = SimpleFtpEntry.parse(entry.originalLine);
      expect(parsed.type, entry.type);
      expect(parsed.size, entry.size);
      expect(parsed.modifyTime, entry.modifyTime);
      expect(parsed.name, entry.name);
    });
  });

  test(
    'SimpleFtpEntry exception when not parsable', () {
      expect(() => SimpleFtpEntry.parse('blablablabla'), throwsA(predicate((e) => e is ArgumentError)));
    }
  );
}
