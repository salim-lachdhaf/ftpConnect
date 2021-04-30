import 'dart:async';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';

import '../ftpSocket.dart';

class FTPFile {
  FTPSocket? _socket;

  FTPFile(this._socket);

  Future<bool> rename(String sOldName, String sNewName) async {
    String sResponse = await (_socket!.sendCommand('RNFR $sOldName'));
    if (!sResponse.startsWith('350')) {
      return false;
    }

    sResponse = await (_socket!.sendCommand('RNTO $sNewName'));
    if (!sResponse.startsWith('250')) {
      return false;
    }

    return true;
  }

  Future<bool> delete(String? sFilename) async {
    String sResponse = await (_socket!.sendCommand('DELE $sFilename'));

    return sResponse.startsWith('250');
  }

  Future<bool> exist(String sFilename) async {
    return await size(sFilename) != -1;
  }

  Future<int> size(String? sFilename) async {
    try {
      String sResponse = await (_socket!.sendCommand('SIZE $sFilename'));
      if (sResponse.startsWith('550')) {
        //check if ascii mode get refused
        //change to binary mode if ascii mode refused
        await TransferUtil.setTransferMode(_socket, TransferMode.binary);
        sResponse = await (_socket!.sendCommand('SIZE $sFilename'));
        //back to ascci mode
        await TransferUtil.setTransferMode(_socket, TransferMode.ascii);
      }
      return int.parse(sResponse.replaceAll('213 ', ''));
    } catch (e) {
      return -1;
    }
  }
}
