<h1 align="center">
  Flutter FTP Connect
  <br>
</h1>

<h4 align="center">
  <a href="https://flutter.io" target="_blank">Flutter</a> simple and robust dart FTP Connect Library to interact with FTP Servers with possibility of zip and unzip files.
</h4>

<p align="center">
  <a href="https://github.com/salim-lachdhaf/ftpConnect/actions">
    <img src="https://github.com/salim-lachdhaf/ftpConnect/workflows/build/badge.svg" />
  </a>
  <a href="https://pub.dev/packages/ftpconnect"><img src="https://img.shields.io/pub/v/ftpconnect"></a>
  <a href="https://codecov.io/gh/salim-lachdhaf/ftpConnect">
    <img src="https://codecov.io/gh/salim-lachdhaf/ftpConnect/branch/master/graph/badge.svg" />
  </a>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="https://github.com/salim-lachdhaf/ftpconnect/blob/master/example">Examples</a> •
  <a href="#license">License</a>
</p>


## Key Features
* Upload files to FTP
* Download files/directories from FTP
* List FTP directory contents
* Manage FTP files (rename/delete)
* Manage file zipping/unzipping
* Completely asynchronous functions


## Example upload file
###example 1:
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
    FTPConnect ftpConnect = FTPConnect('example.com',user:'user', pass:'pass');
    File fileToUpload = File('fileToUpload.txt');
    await ftpConnect.connect();
    bool res = await ftpConnect.uploadFileWithRetry(fileToUpload, pRetryCount: 2);
    await ftpConnect.disconnect();
    print(res);
}
```

###example 2: step by step
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
  FTPConnect ftpConnect = FTPConnect('example.com',user:'user', pass:'pass');
 try {
      File fileToUpload = File('fileToUpload.txt');
      await ftpConnect.connect();
      await ftpConnect.uploadFile(fileToUpload);
      await ftpConnect.disconnect();
    } catch (e) {
      //error
    }
}
```

## Download file
###example 1:
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
    FTPConnect ftpConnect = FTPConnect('example.com',user:'user', pass:'pass');
    String fileName = 'toDownload.txt';
    await ftpConnect.connect();
    bool res = await ftpConnect.downloadFileWithRetry(fileName, File('myFileFromFTP.txt'));
    await ftpConnect.disconnect();
    print(res)
}
```

###example 2: step by step
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() {
  FTPConnect ftpConnect = FTPConnect('example.com',user:'user', pass:'pass');
 try {
      String fileName = 'toDownload.txt';
      await ftpConnect.connect();
      await ftpConnect.downloadFile(fileName, File('myFileFromFTP.txt'));
      await ftpConnect.disconnect();
    } catch (e) {
      //error
    }
}
```
## Other Features
###Directory functions:
```dart
//Get directory content
ftpConnect.listDirectoryContent();

//Create directory
ftpConnect.makeDirectory('newDir');

//Change directory
ftpConnect.changeDirectory('moveHereDir');

//get current directory
ftpConnect.currentDirectory();

//Delete directory
ftpConnect.deleteDirectory('dirToDelete');

//check for directory existance
ftpConnect.checkFolderExistence('dirToCheck');

//create a directory if it does not exist
ftpConnect.createFolderIfNotExist('dirToCreate');
```
###File functions:
```dart
//rename file
ftpConnect.rename('test1.txt', 'test2.txt');

//file size
ftpConnect.sizeFile('test1.txt');

//file existence
ftpConnect.existFile('test1.txt');

//delete file
ftpConnect.deleteFile('test2.zip');
```
###Zip functions:
```dart
//compress a list of files/directories into Zip file
FTPConnect.zipFiles(List<String> paths, String destinationZipFile);

//unzip a zip file
FTPConnect.unZipFile(File zipFile, String destinationPath, {password});
```

## Paramaters

|  Properties |   Description|
| ------------ | ------------ |
|`host`|Hostname or IP Address|
|`port`|Port number (Defaults to 21)|
|`user`|Username (Defaults to anonymous)|
|`pass`|Password if not anonymous login|
|`debug`|Enable Debug Logging|
|`timeout`|Timeout in seconds to wait for responses (Defaults to 30)|

# [View more Examples](https://github.com/salim-lachdhaf/ftpconnect/tree/master/example)

## License
MIT