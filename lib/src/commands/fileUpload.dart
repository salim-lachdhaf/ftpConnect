import 'dart:io';

import 'package:path/path.dart';

import '../../ftpconnect.dart';
import '../debug/debugLog.dart';
import '../ftpSocket.dart';
import '../util/transferUtil.dart';
import 'fileDownload.dart';

class FileUpload {
  final FTPSocket? _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Upload Command
  FileUpload(this._socket, this._mode, this._log);

  /// Upload File [fFile] to the current directory with [remoteName] (using filename if not set)
  Future<bool> uploadFile(
    File fFile, {
    String remoteName = '',
    FileProgress? onProgress,
    bool supportIPV6 = true,
  }) async {
    _log.log('Upload File: ${fFile.path}');

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    String response =
        await TransferUtil.enterPassiveMode(_socket!, supportIPV6);

    // Store File
    String sFilename = remoteName;
    if (sFilename.isEmpty) {
      sFilename = basename(fFile.path);
    }

    // The response is the file to upload, witch will be managed by another socket
    await _socket!.sendCommand('STOR $sFilename', waitResponse: false);

    // Data Transfer Socket
    int iPort = TransferUtil.parsePort(response, supportIPV6)!;
    _log.log('Opening DataSocket to Port $iPort');
    final Socket dataSocket = await Socket.connect(_socket!.host, iPort);
    //Test if second socket connection accepted or not
    response = await TransferUtil.checkIsConnectionAccepted(_socket!);

    _log.log('Start uploading...');
    final readStream = fFile.openRead();
    var received = 0;
    int fileSize = await fFile.length();
    await readStream.listen((data) {
      dataSocket.add(data);
      if (onProgress != null) {
        received += data.length;
        var percent = ((received / fileSize) * 100).toStringAsFixed(2);
        //in case that the file size is 0, then pass directly 100
        double percentVal = double.tryParse(percent) ?? 100;
        if (percentVal.isInfinite || percentVal.isNaN) percentVal = 100;
        onProgress(percentVal, received, fileSize);
      }
    }).asFuture();

    await dataSocket.close();

    // Test if All data are well transferred
    await TransferUtil.checkTransferOK(_socket, response);

    _log.log('File Uploaded!');
    return true;
  }
}
