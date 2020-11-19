import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/dto/FTPEntry.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';

class FTPDirectory {
  final FTPSocket _socket;

  FTPDirectory(this._socket);

  Future<bool> makeDirectory(String sName) async {
    String sResponse = await _socket.sendCommand('MKD $sName');

    return sResponse.startsWith('257');
  }

  Future<bool> deleteDirectory(String sName) async {
    String sResponse = await _socket.sendCommand('RMD $sName');

    return sResponse.startsWith('250');
  }

  Future<bool> changeDirectory(String sName) async {
    String sResponse = await _socket.sendCommand('CWD $sName');

    return sResponse.startsWith('250');
  }

  Future<String> currentDirectory() async {
    String sResponse = await _socket.sendCommand('PWD');
    if (!sResponse.startsWith('257')) {
      throw FTPException('Failed to get current working directory', sResponse);
    }

    int iStart = sResponse.indexOf('"') + 1;
    int iEnd = sResponse.lastIndexOf('"');

    return sResponse.substring(iStart, iEnd);
  }

  Future<List<FTPEntry>> listDirectoryContent(
      {DIR_LIST_COMMAND cmd = DIR_LIST_COMMAND.MLSD}) async {
    // Transfer mode
    await TransferUtil.setTransferMode(_socket, TransferMode.ascii);

    // Enter passive mode
    String sResponse = await TransferUtil.enterPassiveMode(_socket);

    // Directoy content listing, the response will be handled by another socket
    await _socket.sendCommand(describeEnum(cmd ?? DIR_LIST_COMMAND.MLSD),
        waitResponse: false);

    // Data transfer socket
    int iPort = TransferUtil.parsePort(sResponse);
    Socket dataSocket = await Socket.connect(_socket.host, iPort);
    //Test if second socket connection accepted or not
    sResponse = await TransferUtil.checkIsConnectionAccepted(_socket);

    List<int> lstDirectoryListing = List();
    await dataSocket.listen((Uint8List data) {
      lstDirectoryListing.addAll(data);
    }).asFuture();

    await dataSocket.close();

    //Test if All data are well transferred
    await TransferUtil.checkTransferOK(_socket, sResponse);

    // Convert MLSD response into FTPEntry
    List<FTPEntry> lstFTPEntries = List<FTPEntry>();
    String.fromCharCodes(lstDirectoryListing).split('\n').forEach((line) {
      if (line.trim().isNotEmpty) {
        lstFTPEntries.add(FTPEntry(line));
      }
    });

    return lstFTPEntries;
  }
}

enum DIR_LIST_COMMAND { LIST, MLSD }
