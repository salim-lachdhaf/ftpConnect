import 'dart:io';

import 'package:path/path.dart';

import '../../ftpconnect.dart';
import '../ftpSocket.dart';
import '../debug/debugLog.dart';
import '../util/transferUtil.dart';

class FileUpload {
  final FTPSocket _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Upload Command
  FileUpload(this._socket, this._mode, this._log);

  /// Upload File [fFile] to the current directory with [sRemoteName] (using filename if not set)
  Future<bool> uploadFile(File fFile, [String sRemoteName = '']) async {
    _log.log('Upload File: ${fFile.path}');

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    String sResponse = await TransferUtil.enterPassiveMode(_socket);

    // Store File
    String sFilename = sRemoteName;
    if (sFilename == null || sFilename.isEmpty) {
      sFilename = basename(fFile.path);
    }

    // The response is the file to upload, witch will be managed by another socket
    await _socket.sendCommand('STOR $sFilename', waitResponse: false);

    // Data Transfer Socket
    int iPort = TransferUtil.parsePort(sResponse);
    _log.log('Opening DataSocket to Port $iPort');
    final Socket dataSocket = await Socket.connect(_socket.host, iPort);
    //Test if second socket connection accepted or not
    sResponse = await TransferUtil.checkIsConnectionAccepted(_socket);

    final readStream = fFile.openRead();
    await dataSocket.addStream(readStream);
    await dataSocket.close();

    // Test if All data are well transferred
    await TransferUtil.checkTransferOK(_socket, sResponse);

    _log.log('File Uploaded!');
    return true;
  }
}
