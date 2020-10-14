import 'dart:io';
import 'dart:typed_data';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/dto/FTPEntry.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';

FTPEntry _buildMlsdEntry(String line) {
  return FTPEntry(line);
}

SimpleFtpEntry _buildListEntry(String line) {
  return SimpleFtpEntry.parse(line);
}

class ListCommand<T> {
  static const MLSD = ListCommand._private('MLSD', _buildMlsdEntry);
  static const LIST = ListCommand._private('LIST', _buildListEntry);

  final String cmd;
  final T Function(String line) entryBuilder;

  const ListCommand._private(this.cmd, this.entryBuilder);
}

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

  Future<List<FTPEntry>> listDirectoryContent() => listContentWithCommand(ListCommand.MLSD);

  Future<List<T>> listContentWithCommand<T>(ListCommand<T> command) async {
    // Transfer mode
    await TransferUtil.setTransferMode(_socket, TransferMode.ascii);

    // Enter passive mode
    String sResponse = await TransferUtil.enterPassiveMode(_socket);

    // Directoy content listing, the response will be handled by another socket
    await _socket.sendCommand(command.cmd, waitResponse: false);

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

    // Convert response into FTPEntry
    List<T> lstFTPEntries = List<T>();
    String.fromCharCodes(lstDirectoryListing).split('\n').forEach((line) {
      if (line.trim().isNotEmpty) {
        T entry = command.entryBuilder(line);
        if (entry != null) {
          lstFTPEntries.add(entry);
        }
      }
    });

    return lstFTPEntries;
  }
}
