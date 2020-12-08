import 'dart:io';

import '../../ftpconnect.dart';
import '../debug/debugLog.dart';
import '../ftpExceptions.dart';
import '../ftpSocket.dart';
import '../util/transferUtil.dart';
import 'file.dart';

class FileDownload {
  final FTPSocket _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Download Command
  FileDownload(this._socket, this._mode, this._log);

  Future<bool> downloadFile(String sRemoteName, File fLocalFile,
      {Function(int bytesReceived) onProgress}) async {
    _log.log('Download $sRemoteName to ${fLocalFile.path}');

    if (!await FTPFile(_socket).exist(sRemoteName)) {
      throw FTPException('Remote File $sRemoteName does not exist!');
    }

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    String sResponse = await TransferUtil.enterPassiveMode(_socket);

    //the response will be the file, witch will be loaded with another socket
    await _socket.sendCommand('RETR $sRemoteName', waitResponse: false);

    // Data Transfer Socket
    int iPort = TransferUtil.parsePort(sResponse);
    _log.log('Opening DataSocket to Port $iPort');
    final Socket dataSocket = await Socket.connect(_socket.host, iPort,
        timeout: Duration(seconds: _socket.timeout));
    // Test if second socket connection accepted or not
    sResponse = await TransferUtil.checkIsConnectionAccepted(_socket);

    // Changed to listen mode instead so that it's possible to send information back on downloaded amount
    var sink = fLocalFile.openWrite(mode: FileMode.writeOnly);
    _log.log('Start downloading...');
    await dataSocket.listen((data) {
      sink.add(data);
      if (onProgress != null) onProgress(data.length);
    }).asFuture();

    await dataSocket.close();
    await sink.flush();
    await sink.close();

    //Test if All data are well transferred
    await TransferUtil.checkTransferOK(_socket, sResponse);

    _log.log('File Downloaded!');
    return true;
  }
}
