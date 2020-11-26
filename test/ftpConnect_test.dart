@Timeout(const Duration(minutes: 15))
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/commands/directory.dart';
import 'package:test/test.dart';

void main() async {
  final FTPConnect _ftpConnect = new FTPConnect("speedtest.tele2.net",
      user: "anonymous", pass: "anonymous", debug: true);
  final FTPConnect _ftpConnect2 = new FTPConnect("demo.wftpserver.com",
      user: "demo", pass: "demo", debug: true, timeout: 60);
  final FTPConnect _ftpConnectNoLog = new FTPConnect("speedtest.tele2.net",
      user: "anonymous", pass: "anonymous", debug: false);
  const String _testFileDir = 'test/testResFiles/';
  const String _localUploadFile = 'test_upload.txt';
  const String _localDownloadFile = 'test_download.txt';
  const String _localZip = 'testZip.zip';
  const String _localUnZipDir = 'test/testUnZip';

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

  test('test ftpConnect No log', () async {
    expect(await _ftpConnectNoLog.connect(), equals(true));
    expect(await _ftpConnectNoLog.disconnect(), equals(true));
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
    expect((await _ftpConnect.listDirectoryContentOnlyNames()) is List<String>,
        equals(true));

    //delete directory => false because the folder is protected
    expect(await _ftpConnect.deleteEmptyDirectory("upload"), equals(false));

    //make directory => false because the folder is protected
    expect(await _ftpConnect.makeDirectory("upload2"), equals(false));

    //download a dir => false to prevent long loading duration of the test
    expect(await _ftpConnect2.connect(), equals(true));

    try {
      bool res = await _ftpConnect2.downloadDirectory(
          '/upload', Directory(_testFileDir),
          cmd: DIR_LIST_COMMAND.MLSD);
      expect(res, equals(true));
    } catch (e) {}

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

    //test download non exist file
    var remoteFile = 'notExist.zip';
    try {
      await _ftpConnect.downloadFile(remoteFile, File('dist'));
    } catch (e) {
      expect(e is FTPException, equals(true));
      expect(
          e.message == 'Remote File $remoteFile does not exist!', equals(true));
    }
    //get file size
    expect(await _ftpConnect.sizeFile('../512KB.zip'), equals(512 * 1024));
    expect(await _ftpConnect.sizeFile('../notExist.zip'), equals(-1));
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

    //download non exist file
    try {
      await _ftpConnect.downloadFileWithRetry(
          '../51xx2KB.zip', File('$_testFileDir$_localZip'),
          pRetryCount: 2);
    } catch (e) {
      assert(e is FTPException);
    }

    //upload file
    expect(
        await _ftpConnect.uploadFileWithRetry(await _fileMock()), equals(true));

    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect ZIP functions', () async {
    //zip file
    expect(
        await FTPConnect.zipFiles(
            ['$_testFileDir$_localUploadFile', _testFileDir],
            '$_testFileDir$_localZip'),
        equals(true));

    //test unzip
    expect(
        await FTPConnect.unZipFile(
            File('$_testFileDir$_localZip'), _localUnZipDir) is List<String>,
        equals(true));
  });

  test('test FTP Entry Class', () {
    //test LIST COMMAND with standard response
    var data = '-rw-------    1 105      108        1024 Jan 10 11:50 file.zip';
    FTPEntry ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.FILE));
    expect(ftpEntry.persmission, equals('rw-------'));
    expect(ftpEntry.name, equals('file.zip'));
    expect(ftpEntry.owner, equals('105'));
    expect(ftpEntry.group, equals('108'));
    expect(ftpEntry.size, equals(1024));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    //test LIS COMMAND with IIS servers
    data = '02-11-15  03:05PM      <DIR>     1410887680 directory';
    ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));
    expect(ftpEntry.name, equals('directory'));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    data = '02-11-15  03:05PM               1410887680 directory';
    ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.FILE));
    expect(ftpEntry.name, equals('directory'));
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

    var data4 = 'drw-------    1 105';
    ftpEntry = FTPEntry.parse(data4, DIR_LIST_COMMAND.MLSD);
    expect(ftpEntry.name, equals(data4));
    ftpEntry = FTPEntry.parse(data4, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry is FTPEntry, equals(true));

    var data5;
    expect(() => FTPEntry.parse(data5, DIR_LIST_COMMAND.MLSD),
        throwsA(isA<FTPException>()));
    expect(() => FTPEntry.parse(data5, DIR_LIST_COMMAND.LIST),
        throwsA(isA<FTPException>()));
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
