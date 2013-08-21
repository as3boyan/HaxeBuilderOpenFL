set PATH=%PATH%;C:\Program Files (x86)\NSIS
echo %PATH%
makensis.exe /X"SetCompressor /SOLID /FINAL lzma" HaxeBuilder.nsi
timeout 3