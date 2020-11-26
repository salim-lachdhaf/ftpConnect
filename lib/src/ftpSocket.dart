import 'dart:convert';
import 'dart:io';

import 'package:ftpconnect/src/debug/debugLog.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';

import '../ftpconnect.dart';

class FTPSocket {
  final String host;
  final int port;
  final DebugLog _log;
  final int timeout;

  RawSocket _socket;

  FTPSocket(this.host, this.port, this._log, this.timeout);

  /// Read the FTP Server response from the Stream
  ///
  /// Blocks until data is received!
  Future<String> readResponse() async {
    String sResponse;
    await Future.doWhile(() async {
      if (_socket.available() > 0) {
        sResponse = String.fromCharCodes(_socket.read()).trim();
        return false;
      }
      await Future.delayed(Duration(milliseconds: 200));
      return true;
    }).timeout(Duration(seconds: timeout), onTimeout: () {
      throw FTPException('Timeout reached for Receiving response !');
    });

    _log.log('< $sResponse');
    return sResponse;
  }

  /// Send a command [cmd] to the FTP Server
  /// if [waitResponse] the function waits for the reply, other wise return ''
  Future<String> sendCommand(String cmd, {bool waitResponse = true}) async {
    _log.log('> $cmd');
    _socket.write(Utf8Codec().encode('$cmd\r\n'));

    if (waitResponse == true) {
      var res = await readResponse();
      return res;
    }
    return '';
  }

  ///if we receive a response different then that we are waiting for
  ///(both success or fail), we read again the response
  Future<bool> _isResponseOK(
      String response, List<int> successCode, List<int> failCode) async {
    if (TransferUtil.isResponseStartsWith(response, failCode)) return false;
    if (!TransferUtil.isResponseStartsWith(response, successCode)) {
      response = await readResponse();
      if (!TransferUtil.isResponseStartsWith(response, successCode)) {
        return false;
      }
    }
    return true;
  }

  /// Connect to the FTP Server and Login with [user] and [pass]
  Future<bool> connect(String user, String pass) async {
    _log.log('Connecting...');

    try {
      _socket = await RawSocket.connect(host, port,
          timeout: Duration(seconds: timeout));
    } catch (e) {
      throw FTPException(
          'Could not connect to $host ($port)', e?.toString() ?? '');
    }

    // Send Username
    String sResponse = await sendCommand('USER $user');
    if (!await _isResponseOK(sResponse, [220, 331], [520])) {
      throw FTPException('Wrong username $user', sResponse);
    }

    // Send Password
    sResponse = await sendCommand('PASS $pass');
    if (!await _isResponseOK(sResponse, [230], [530])) {
      throw FTPException('Wrong password', sResponse);
    }

    _log.log('Connected!');
    return true;
  }

  // Disconnect from the FTP Server
  Future<bool> disconnect() async {
    _log.log('Disconnecting...');

    try {
      await sendCommand('QUIT');
    } catch (ignored) {
      // Ignore
    } finally {
      await _socket?.close();
      _socket?.shutdown(SocketDirection.both);
      _socket = null;
    }

    _log.log('Disconnected!');
    return true;
  }
}
