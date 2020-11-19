import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';

void main() {
  FTPConnect _ftpConnect = new FTPConnect("speedtest.tele2.net",
      user: "anonymous", pass: "anonymous", debug: true);
  TestWidgetsFlutterBinding.ensureInitialized();

  ///mock a file for the demonstration example
  Future<File> _fileMock({fileName = 'FlutterTest.txt', content = ''}) async {
    final Directory directory = Directory('test')..createSync(recursive: true);
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  test('test ftpConnect', () async {
    expect(await _ftpConnect.connect(), equals(true));
    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect Dir functions', () async {
    expect(await _ftpConnect.connect(), equals(true));

    expect(await _ftpConnect.currentDirectory(), equals("/"));
    //make sure that the folder does not exist
    expect(await _ftpConnect.checkFolderExistence("NoName"), equals(false));
    //create a new dir NoName (Fails because we do not have permissions)
    expect(await _ftpConnect.createFolderIfNotExist('NoName'), equals(false));
    //change directory
    expect(await _ftpConnect.changeDirectory("upload"), equals(true));
    //list directory content
    expect(
        (await _ftpConnect.listDirectoryContent(cmd: DIR_LIST_COMMAND.LIST))
            is List<FTPEntry>,
        equals(true));

    //delete directory => false because the folder is protected
    expect(await _ftpConnect.deleteDirectory("upload"), equals(false));

    //make directory => false because the folder is protected
    expect(await _ftpConnect.makeDirectory("upload2"), equals(false));

    //close connexion
    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect File functions', () async {
    expect(await _ftpConnect.connect(), equals(true));
    //change to the directory where we can work
    expect(await _ftpConnect.changeDirectory("upload"), equals(true));
    expect(await _ftpConnect.currentDirectory(), equals("/upload"));

    //test upload file (this file will be automatically deleted after upload by the server)
    expect(
        await _ftpConnect.uploadFile(
            await _fileMock(fileName: 'salim.txt', content: 'Hola')),
        equals(true));
    //chech for file existence
    expect(await _ftpConnect.existFile('../512KB.zip'), equals(true));
    //test download file
    expect(await _ftpConnect.downloadFile('../512KB.zip', File('res.txt')),
        equals(true));
    //get file size
    expect(await _ftpConnect.sizeFile('../512KB.zip'), equals(512 * 1024));
    //test delete file (false because the server is protected)
    expect(await _ftpConnect.deleteFile('../512KB.zip'), equals(false));

    //test rename file (false because the server is protected)
    expect(await _ftpConnect.rename('../512KB.zip', '../512kb.zip'),
        equals(false));

    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect general functions', () async {
    expect(await _ftpConnect.connect(), equals(true));
    //change to the directory where we can work
    expect(await _ftpConnect.changeDirectory("upload"), equals(true));

    //download test
    expect(
        await _ftpConnect.downloadFileWithRetry(
            '../512KB.zip', File('local.zip')),
        equals(true));
    //upload file
    expect(
        await _ftpConnect.uploadFileWithRetry(
            await _fileMock(fileName: 'salim.txt', content: 'test')),
        equals(true));
  });
}
