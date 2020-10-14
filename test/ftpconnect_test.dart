import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';

// Test credentials from https://dlptest.com/ftp-test/
const host = 'ftp.dlptest.com';
const user = 'dlpuser@dlptest.com';
const pass = 'eUj8GeW55SvYaswqUyDSm5v6N';

File _bytesToFile(List<int> bytes) {
  return MemoryFileSystem().file('aaaa')..writeAsBytesSync(bytes);
}

void main() {
  test("ftpconnect scenario: create folder, file, list content, delete", () async {
    FTPConnect ftpConnect = FTPConnect(host, user: user, pass: pass);
    String folderName = '/testdir';
    String filename = 'testfile.txt';
    String fileContent = 'This is test file';
    List<String> expectedFileNames = ['.', '..', filename];

    await ftpConnect.connect();
    expect(await ftpConnect.createFolderIfNotExist(folderName), true);
    expect(await ftpConnect.changeDirectory(folderName), true);
    expect(await ftpConnect.uploadFile(_bytesToFile(utf8.encode(fileContent)), sRemoteName: filename), true);

    void checkFileList(List<SimpleFtpEntry> list) {
      expect(list.map((e) => e.name).toList(), expectedFileNames);
    }

    checkFileList(await ftpConnect.listDirectoryContent());
    checkFileList(await ftpConnect.listContentWithCommand(ListCommand.MLSD));
    checkFileList(await ftpConnect.listContentWithCommand(ListCommand.LIST));

    expect(await ftpConnect.checkFolderExistence(folderName), true);
    expect(await ftpConnect.deleteDirectoryRecursively(folderName), true);
    expect(await ftpConnect.checkFolderExistence(folderName), false);
    await ftpConnect.disconnect();
  });
}
