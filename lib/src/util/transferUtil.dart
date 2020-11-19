import 'dart:async';

import 'package:ftpconnect/ftpconnect.dart';

import '../ftpSocket.dart';

class TransferUtil {
  /// Set the Transfer mode on [socket] to [mode]
  static Future<void> setTransferMode(
      FTPSocket socket, TransferMode mode) async {
    switch (mode) {
      case TransferMode.ascii:
        // Set to ASCII mode
        await socket.sendCommand('TYPE A');
        break;
      case TransferMode.binary:
        // Set to BINARY mode
        await socket.sendCommand('TYPE I');
        break;
      default:
        break;
    }
  }

  /// Parse the Passive Mode Port from the Servers [sResponse]
  static int parsePort(String sResponse) {
    int iParOpen = sResponse.indexOf('(');
    int iParClose = sResponse.indexOf(')');

    if (iParClose > -1) {
      sResponse = sResponse.substring(iParOpen + 1, iParClose);
    }
    List<String> lstParameters = sResponse.split(',');

    int iPort1 = int.parse(lstParameters[lstParameters.length - 2]);
    int iPort2 = int.parse(lstParameters[lstParameters.length - 1]);

    return (iPort1 * 256) + iPort2;
  }

  ///retry a function [retryCount] times, until exceed [retryCount] or execute the function successfully
  ///Return true if the future executed successfully , false other wises
  static Future<bool> retryAction(FutureOr<bool> action(), retryCount) async {
    int lAttempts = 1;
    bool result = true;
    await Future.doWhile(() async {
      try {
        result = await action();
        //if there is no exception we exit the loop (return false to exit)
        return false;
      } catch (e) {
        if (lAttempts++ >= retryCount) {
          throw e;
        }
      }
      //return true to loop again
      return true;
    });
    return result;
  }

  ///for Upload, Download, getDirectoryFileList , we pass in passive mode
  ///that require a second socket that will handle the response from the
  ///original socket [socket], So here we test if the connection to the primary
  ///socket [socket] is accepted or not, if not we throw an exception.
  static Future<String> checkIsConnectionAccepted(FTPSocket socket) async {
    String sResponse = await socket.readResponse();
    if (!sResponse.startsWith('150')) {
      throw FTPException('Connection refused. ', sResponse);
    }
    return sResponse;
  }

  ///Test if All data are well transferred from the primary socket [socket] to
  ///the secondary socket in the passive mode.
  ///Test first if the response already sent in the previous reply [pResponse]
  ///other wise read again socket [socket] response.
  static Future<String> checkTransferOK(FTPSocket socket, pResponse) async {
    if (!pResponse.contains('226')) {
      pResponse = await socket.readResponse();
      if (!pResponse.startsWith('226')) {
        throw FTPException('Transfer Error.', pResponse);
      }
    }
    return pResponse;
  }

  ///check the existence of given code inside a a given response
  static bool isResponseStartsWith(String response, int code) {
    var lines = response?.split('\n') ?? [];
    for (var l in lines) {
      if (l.startsWith(code.toString())) return true;
    }
    return false;
  }

  ///Tell the socket [socket] that we will enter in passive mode
  static Future<String> enterPassiveMode(FTPSocket socket) async {
    String sResponse = await socket.sendCommand('PASV');
    if (!sResponse.startsWith('227')) {
      throw FTPException('Could not start Passive Mode', sResponse);
    }
    return sResponse;
  }
}

enum TransferMode { ascii, binary }
