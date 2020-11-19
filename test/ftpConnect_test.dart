import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';

void main() {
  final FTPConnect _ftpConnect = new FTPConnect("speedtest.tele2.net",
      user: "anonymous", pass: "anonymous", timeout: 60, debug: true);
  const String _testFileDir = 'test/testResFiles/';
  const String _localUploadFile = 'test_upload.txt';
  const String _localDownloadFile = 'test_download.txt';
  const String _localZip = 'testZip.zip';
  const String _localUnZipDir = 'testUnZip';
  TestWidgetsFlutterBinding.ensureInitialized();

  ///mock a file for the demonstration example
  Future<File> _fileMock({fileName = _localUploadFile}) async {
    final Directory directory = Directory(_testFileDir)
      ..createSync(recursive: true);
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(DateTime.now().toString());
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

    //download a dir => false to prevent long loading duration of the test
    expect(
        () async => await _ftpConnect.downloadDirectory(
            'nonExstanceDir', Directory(_testFileDir),
            cmd: DIR_LIST_COMMAND.LIST),
        throwsA(isInstanceOf<FTPException>()));

    //close connexion
    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect File functions', () async {
    expect(await _ftpConnect.connect(), equals(true));
    //change to the directory where we can work
    expect(await _ftpConnect.changeDirectory("upload"), equals(true));
    expect(await _ftpConnect.currentDirectory(), equals("/upload"));

    //test upload file (this file will be automatically deleted after upload by the server)
    expect(await _ftpConnect.uploadFile(await _fileMock()), equals(true));
    //chech for file existence
    expect(await _ftpConnect.existFile('../512KB.zip'), equals(true));
    //test download file
    expect(
        await _ftpConnect.downloadFile(
            '../512KB.zip', File('$_testFileDir$_localDownloadFile')),
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
            '../512KB.zip', File('$_testFileDir$_localZip')),
        equals(true));

    //upload file
    expect(
        await _ftpConnect.uploadFileWithRetry(await _fileMock()), equals(true));

    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect ZIP functions', () async {
    //zip file
    expect(
        await FTPConnect.zipFiles(
            ['test/$_localUploadFile'], '$_testFileDir$_localZip'),
        equals(true));

    //test unzip
    expect(
        await FTPConnect.unZipFile(
            File('$_testFileDir$_localZip'), _localUnZipDir) is List<String>,
        equals(true));
  });
}
