import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';

void main() {
  final FTPConnect _ftpConnect = new FTPConnect("speedtest.tele2.net",
      user: "anonymous", pass: "anonymous", debug: true);
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

  test('test FTP Entry Class', () {
    var data = '-rw-------    1 105      108        1024 Jan 10 11:50 file.zip';
    FTPEntry ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.FILE));
    expect(ftpEntry.persmission, equals('rw-------'));
    expect(ftpEntry.name, equals('file.zip'));
    expect(ftpEntry.owner, equals('105'));
    expect(ftpEntry.group, equals('108'));
    expect(ftpEntry.size, equals(1024));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    var data2 = 'drw-------    1 105      108        1024 Jan 10 11:50 dir/';
    ftpEntry = FTPEntry.parse(data2, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));

    var data3 = ftpEntry.toString();
    ftpEntry = FTPEntry.parse(data3, DIR_LIST_COMMAND.MLSD);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));
    expect(ftpEntry.owner, equals('105'));
    expect(ftpEntry.group, equals('108'));
    expect(ftpEntry.size, equals(1024));
    expect(ftpEntry.modifyTime is DateTime, equals(true));
  });

  test('test FTPConnect exception', () {
    String msgError = 'message';
    String msgResponse = 'reply is here';
    FTPException exception = FTPException(msgError);
    expect(exception.message, equals(msgError));
    exception = FTPException(msgError, msgResponse);
    expect(exception.message, equals(msgError));
    expect(exception.response, equals(msgResponse));
    expect(exception.toString(),
        equals('FTPException: $msgError (Response: $msgResponse)'));
  });
}
