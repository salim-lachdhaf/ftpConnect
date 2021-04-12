import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ftpconnect/src/commands/file.dart';
import 'package:ftpconnect/src/commands/fileDownload.dart';
import 'package:ftpconnect/src/commands/fileUpload.dart';
import 'package:ftpconnect/src/debug/debugLog.dart';
import 'package:ftpconnect/src/debug/noopLog.dart';
import 'package:ftpconnect/src/debug/printLog.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';
import 'package:path/path.dart';

import 'commands/directory.dart';
import 'dto/FTPEntry.dart';
import 'ftpExceptions.dart';
import 'ftpSocket.dart';

class FTPConnect {
  final String _user;
  final String _pass;
  late FTPSocket _socket;
  final DebugLog _log;

  /// Create a FTP Client instance
  ///
  /// [host]: Hostname or IP Address
  /// [port]: Port number (Defaults to 21)
  /// [user]: Username (Defaults to anonymous)
  /// [pass]: Password if not anonymous login
  /// [debug]: Enable Debug Logging
  /// [timeout]: Timeout in seconds to wait for responses
  FTPConnect(String host,
      {int port = 21,
      String user = 'anonymous',
      String pass = '',
      bool debug = false,
      int timeout = 30})
      : _user = user,
        _pass = pass,
        _log = debug ? PrintLog() : NoOpLogger() {
    _socket = FTPSocket(host, port, _log, timeout);
  }

  /// Connect to the FTP Server
  /// return true if we are connected successfully
  Future<bool> connect() => _socket.connect(_user, _pass);

  /// Disconnect from the FTP Server
  /// return true if we are disconnected successfully
  Future<bool> disconnect() => _socket.disconnect();

  /// Upload the File [fFile] to the current directory
  Future<bool> uploadFile(File fFile,
      {String sRemoteName = '',
      TransferMode mode = TransferMode.binary,
      FileProgress? onProgress}) {
    return FileUpload(_socket, mode, _log)
        .uploadFile(fFile, remoteName: sRemoteName, onProgress: onProgress);
  }

  /// Download the Remote File [sRemoteName] to the local File [fFile]
  Future<bool> downloadFile(String? sRemoteName, File fFile,
      {TransferMode mode = TransferMode.binary, FileProgress? onProgress}) {
    return FileDownload(_socket, mode, _log)
        .downloadFile(sRemoteName, fFile, onProgress: onProgress);
  }

  /// Create a new Directory with the Name of [sDirectory] in the current directory.
  ///
  /// Returns `true` if the directory was created successfully
  /// Returns `false` if the directory could not be created or already exists
  Future<bool> makeDirectory(String sDirectory) {
    return FTPDirectory(_socket).makeDirectory(sDirectory);
  }

  /// Deletes the Directory with the Name of [sDirectory] in the current directory.
  ///
  /// Returns `true` if the directory was deleted successfully
  /// Returns `false` if the directory could not be deleted or does not nexist
  Future<bool> deleteEmptyDirectory(String? sDirectory) {
    return FTPDirectory(_socket).deleteEmptyDirectory(sDirectory);
  }

  /// Deletes the Directory with the Name of [sDirectory] in the current directory.
  ///
  /// Returns `true` if the directory was deleted successfully
  /// Returns `false` if the directory could not be deleted or does not nexist
  /// THIS USEFUL TO DELETE NON EMPTY DIRECTORY
  Future<bool> deleteDirectory(String? sDirectory,
      {DIR_LIST_COMMAND cmd = DIR_LIST_COMMAND.MLSD}) async {
    String currentDir = await this.currentDirectory();
    if (!await this.changeDirectory(sDirectory)) {
      throw FTPException("Couldn't change directory to $sDirectory");
    }
    List<FTPEntry> dirContent = await this.listDirectoryContent(cmd: cmd);
    await Future.forEach(dirContent, (FTPEntry entry) async {
      if (entry.type == FTPEntryType.FILE) {
        if (!await deleteFile(entry.name)) {
          throw FTPException("Couldn't delete file ${entry.name}");
        }
      } else {
        if (!await deleteDirectory(entry.name, cmd: cmd)) {
          throw FTPException("Couldn't delete folder ${entry.name}");
        }
      }
    });
    await this.changeDirectory(currentDir);
    return await deleteEmptyDirectory(sDirectory);
  }

  /// Change into the Directory with the Name of [sDirectory] within the current directory.
  ///
  /// Use `..` to navigate back
  /// Returns `true` if the directory was changed successfully
  /// Returns `false` if the directory could not be changed (does not exist, no permissions or another error)
  Future<bool> changeDirectory(String? sDirectory) {
    return FTPDirectory(_socket).changeDirectory(sDirectory);
  }

  /// Returns the current directory
  Future<String> currentDirectory() {
    return FTPDirectory(_socket).currentDirectory();
  }

  /// Returns the content of the current directory
  /// [cmd] refer to the used command for the server, there is servers working
  /// with MLSD and other with LIST
  Future<List<FTPEntry>> listDirectoryContent({DIR_LIST_COMMAND? cmd}) {
    return FTPDirectory(_socket).listDirectoryContent(cmd: cmd);
  }

  /// Returns the content names of the current directory
  /// [cmd] refer to the used command for the server, there is servers working
  /// with MLSD and other with LIST for detailed content
  Future<List<String>> listDirectoryContentOnlyNames() {
    return FTPDirectory(_socket).listDirectoryContentOnlyNames();
  }

  /// Rename a file (or directory) from [sOldName] to [sNewName]
  Future<bool> rename(String sOldName, String sNewName) {
    return FTPFile(_socket).rename(sOldName, sNewName);
  }

  /// Delete the file [sFilename] from the server
  Future<bool> deleteFile(String? sFilename) {
    return FTPFile(_socket).delete(sFilename);
  }

  /// check the existence of  the file [sFilename] from the server
  Future<bool> existFile(String sFilename) {
    return FTPFile(_socket).exist(sFilename);
  }

  /// returns the file [sFilename] size from server,
  /// returns -1 if file does not exist
  Future<int> sizeFile(String sFilename) {
    return FTPFile(_socket).size(sFilename);
  }

  /// Upload the File [fileToUpload] to the current directory
  /// if [pRemoteName] is not setted the remote file will take take the same local name
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> upload -> disconnect) or there is a need for a number of attemps
  /// in case of a poor connexion for example
  Future<bool> uploadFileWithRetry(File fileToUpload,
      {String pRemoteName = '', int pRetryCount = 1}) {
    Future<bool> uploadFileRetry() async {
      bool res = await this.uploadFile(fileToUpload, sRemoteName: pRemoteName);
      return res;
    }

    return TransferUtil.retryAction(() => uploadFileRetry(), pRetryCount);
  }

  /// Download the Remote File [pRemoteName] to the local File [pLocalFile]
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> download -> disconnect) or there is a need for a number of attempts
  /// in case of a poor connexion for example
  Future<bool> downloadFileWithRetry(String pRemoteName, File pLocalFile,
      {int pRetryCount = 1}) {
    Future<bool> downloadFileRetry() async {
      bool res = await this.downloadFile(pRemoteName, pLocalFile);
      return res;
    }

    return TransferUtil.retryAction(() => downloadFileRetry(), pRetryCount);
  }

  /// Download the Remote Directory [pRemoteDir] to the local File [pLocalDir]
  /// [pRetryCount] number of attempts
  Future<bool> downloadDirectory(String pRemoteDir, Directory pLocalDir,
      {DIR_LIST_COMMAND? cmd, int pRetryCount = 1}) {
    Future<bool> downloadDir(String? pRemoteDir, Directory pLocalDir) async {
      await pLocalDir.create(recursive: true);

      //read remote directory content
      if (!await this.changeDirectory(pRemoteDir)) {
        throw FTPException('Cannot download directory',
            '$pRemoteDir not found or inaccessible !');
      }
      List<FTPEntry> dirContent = await this.listDirectoryContent(cmd: cmd);
      await Future.forEach(dirContent, (FTPEntry entry) async {
        if (entry.type == FTPEntryType.FILE) {
          File localFile = File(join(pLocalDir.path, entry.name));
          await downloadFile(entry.name, localFile);
        } else if (entry.type == FTPEntryType.DIR) {
          //create a local directory
          var localDir = await Directory(join(pLocalDir.path, entry.name))
              .create(recursive: true);
          await downloadDir(entry.name, localDir);
          //back to current folder
          await this.changeDirectory('..');
        }
      });
      return true;
    }

    Future<bool> downloadDirRetry() async {
      bool res = await downloadDir(pRemoteDir, pLocalDir);
      return res;
    }

    return TransferUtil.retryAction(() => downloadDirRetry(), pRetryCount);
  }

  /// check the existence of the Directory with the Name of [pDirectory].
  ///
  /// Returns `true` if the directory was changed successfully
  /// Returns `false` if the directory could not be changed (does not exist, no permissions or another error)
  Future<bool> checkFolderExistence(String pDirectory) {
    return this.changeDirectory(pDirectory);
  }

  /// Create a new Directory with the Name of [pDirectory] in the current directory if it does not exist.
  ///
  /// Returns `true` if the directory exists or was created successfully
  /// Returns `false` if the directory not found and could not be created
  Future<bool> createFolderIfNotExist(String pDirectory) async {
    if (!await checkFolderExistence(pDirectory)) {
      return this.makeDirectory(pDirectory);
    }
    return true;
  }

  ///Function that compress list of files and directories into a Zip file
  ///Return true if files compression is finished successfully
  ///[paths] list of files and directories paths to be compressed into a Zip file
  ///[destinationZipFile] full path of destination zip file
  static Future<bool> zipFiles(
      List<String> paths, String destinationZipFile) async {
    var encoder = ZipFileEncoder();
    encoder.create(destinationZipFile);
    for (String path in paths) {
      FileSystemEntityType type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.directory) {
        encoder.addDirectory(Directory(path));
      } else if (type == FileSystemEntityType.file) {
        encoder.addFile(File(path));
      }
    }
    encoder.close();
    return true;
  }

  ///Function that unZip a zip file and returns the decompressed files/directories path
  ///[zipFile] file to decompress
  ///[destinationPath] local directory path where the zip file will be extracted
  ///[password] optional: use password if the zip is crypted
  static Future<List<String>> unZipFile(File zipFile, String destinationPath,
      {password}) async {
    //path should ends with '/'
    if (!destinationPath.endsWith('/')) destinationPath += '/';
    //list that will be returned with extracted paths
    final List<String> lPaths = [];

    // Read the Zip file from disk.
    final bytes = await zipFile.readAsBytes();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes, password: password);

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final File f = File(destinationPath + filename);
        await f.create(recursive: true);
        await f.writeAsBytes(data);
        lPaths.add(f.path);
      } else {
        final Directory dir = Directory(destinationPath + filename);
        await dir.create(recursive: true);
        lPaths.add(dir.path);
      }
    }
    return lPaths;
  }
}

///Note that [LIST] and [MLSD] return content detailed
///BUT [NLST] return only dir/file names inside the given directory
enum DIR_LIST_COMMAND { NLST, LIST, MLSD }
enum TransferMode { ascii, binary }
