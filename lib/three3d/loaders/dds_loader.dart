import 'dart:typed_data';
import '../constants.dart';
import './compressed_texture_loader.dart';

class DDSLoader extends CompressedTextureLoader {
  DDSLoader([manager]) : super(manager);

  @override
  Map<String, dynamic> parse(json, [String? path, Function? onLoad, Function? onError]) {
    var buffer = json; // In this context buffer is the json param
    var loadMipmaps = true;

    var dds = {
      'mipmaps': [],
      'width': 0,
      'height': 0,
      'format': null,
      'mipmapCount': 1,
      'isCubemap': false
    };

    const int ddsMagic = 0x20534444;
    const int ddsdMipmapcount = 0x20000;
    const int ddscaps2Cubemap = 0x200;
    const int ddscaps2CubemapPositivex = 0x400;
    const int ddscaps2CubemapNegativex = 0x800;
    const int ddscaps2CubemapPositivey = 0x1000;
    const int ddscaps2CubemapNegativey = 0x2000;
    const int ddscaps2CubemapPositivez = 0x4000;
    const int ddscaps2CubemapNegativez = 0x8000;

    const int fourccDxt1 = 0x31545844; // 'DXT1'
    const int fourccDxt3 = 0x33545844; // 'DXT3'
    const int fourccDxt5 = 0x35545844; // 'DXT5'
    const int fourccEtc1 = 0x31435445; // 'ETC1'
    const int fourccDx10 = 0x30315844; // 'DX10'

    const int dxgiFormatBc6hSf16 = 96;
    const int dxgiFormatBc6hUf16 = 95;

    Uint8List loadARGBMip(ByteBuffer buffer, int dataOffset, int width, int height) {
      int dataLength = width * height * 4;
      var srcBuffer = Uint8List.view(buffer, dataOffset, dataLength);
      var byteArray = Uint8List(dataLength);
      int dst = 0;
      int src = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int b = srcBuffer[src];
          src++;
          int g = srcBuffer[src];
          src++;
          int r = srcBuffer[src];
          src++;
          int a = srcBuffer[src];
          src++;
          byteArray[dst] = r;
          dst++; //r
          byteArray[dst] = g;
          dst++; //g
          byteArray[dst] = b;
          dst++; //b
          byteArray[dst] = a;
          dst++; //a
        }
      }
      return byteArray;
    }

    Uint8List loadRGBMip(ByteBuffer buffer, int dataOffset, int width, int height) {
      int dataLength = width * height * 3;
      var srcBuffer = Uint8List.view(buffer, dataOffset, dataLength);
      var byteArray = Uint8List(width * height * 4);
      int dst = 0;
      int src = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int b = srcBuffer[src];
          src++;
          int g = srcBuffer[src];
          src++;
          int r = srcBuffer[src];
          src++;
          byteArray[dst] = r;
          dst++; //r
          byteArray[dst] = g;
          dst++; //g
          byteArray[dst] = b;
          dst++; //b
          byteArray[dst] = 255;
          dst++; //a
        }
      }
      return byteArray;
    }

    const int headerLengthInt = 31;
    const int offMagic = 0;
    const int offSize = 1;
    const int offFlags = 2;
    const int offHeight = 3;
    const int offWidth = 4;
    const int offMipmapCount = 7;
    const int offPfFourCC = 21;
    const int offRGBBitCount = 22;
    const int offRBitMask = 23;
    const int offGBitMask = 24;
    const int offBBitMask = 25;
    const int offABitMask = 26;
    const int offCaps2 = 28;

    var header = Int32List.view(buffer, 0, headerLengthInt);

    if (header[offMagic] != ddsMagic) {
      print('THREE.DDSLoader.parse: Invalid magic number in DDS header.');
      return dds;
    }

    int? blockBytes;
    int fourCC = header[offPfFourCC];

    bool isRGBAUncompressed = false;
    bool isRGBUncompressed = false;
    int dataOffset = header[offSize] + 4;

    switch (fourCC) {
      case fourccDxt1:
        blockBytes = 8;
        dds['format'] = RGB_S3TC_DXT1_Format;
        break;
      case fourccDxt3:
        blockBytes = 16;
        dds['format'] = RGBA_S3TC_DXT3_Format;
        break;
      case fourccDxt5:
        blockBytes = 16;
        dds['format'] = RGBA_S3TC_DXT5_Format;
        break;
      case fourccEtc1:
        blockBytes = 8;
        dds['format'] = RGB_ETC1_Format;
        break;
      case fourccDx10:
        dataOffset += 20; // extendedHeaderLengthInt * 4
        var extendedHeader = Int32List.view(buffer, (headerLengthInt + 1) * 4, 5);
        int dxgiFormat = extendedHeader[0];
        switch (dxgiFormat) {
          case dxgiFormatBc6hSf16:
            blockBytes = 16;
            dds['format'] = RGB_BPTC_SIGNED_Format;
            break;
          case dxgiFormatBc6hUf16:
            blockBytes = 16;
            dds['format'] = RGB_BPTC_UNSIGNED_Format;
            break;
          default:
            print('THREE.DDSLoader.parse: Unsupported DXGI_FORMAT code $dxgiFormat');
            return dds;
        }
        break;
      default:
        if (header[offRGBBitCount] == 32 &&
            header[offRBitMask] & 0xff0000 != 0 &&
            header[offGBitMask] & 0xff00 != 0 &&
            header[offBBitMask] & 0xff != 0 &&
            header[offABitMask] & 0xff000000 != 0) {
          isRGBAUncompressed = true;
          blockBytes = 64;
          dds['format'] = RGBAFormat;
        } else if (header[offRGBBitCount] == 24 &&
            header[offRBitMask] & 0xff0000 != 0 &&
            header[offGBitMask] & 0xff00 != 0 &&
            header[offBBitMask] & 0xff != 0) {
          isRGBUncompressed = true;
          blockBytes = 64;
          dds['format'] = RGBAFormat;
        } else {
          print('THREE.DDSLoader.parse: Unsupported FourCC code ${fourCC}');
          return dds;
        }
    }

    dds['mipmapCount'] = 1;
    if (header[offFlags] & ddsdMipmapcount != 0 && loadMipmaps != false) {
      dds['mipmapCount'] = (header[offMipmapCount] > 1) ? header[offMipmapCount] : 1;
    }

    int caps2 = header[offCaps2];
    dds['isCubemap'] = (caps2 & ddscaps2Cubemap != 0);
    if (dds['isCubemap'] == true &&
        (caps2 & ddscaps2CubemapPositivex == 0 ||
            caps2 & ddscaps2CubemapNegativex == 0 ||
            caps2 & ddscaps2CubemapPositivey == 0 ||
            caps2 & ddscaps2CubemapNegativey == 0 ||
            caps2 & ddscaps2CubemapPositivez == 0 ||
            caps2 & ddscaps2CubemapNegativez == 0)) {
      print('THREE.DDSLoader.parse: Incomplete cubemap faces');
      return dds;
    }

    dds['width'] = header[offWidth];
    dds['height'] = header[offHeight];

    int faces = (dds['isCubemap'] == true) ? 6 : 1;

    for (int face = 0; face < faces; face++) {
      int width = dds['width'] as int;
      int height = dds['height'] as int;

      for (int i = 0; i < (dds['mipmapCount'] as int); i++) {
        Uint8List byteArray;
        int dataLength;

        if (isRGBAUncompressed) {
          byteArray = loadARGBMip(buffer, dataOffset, width, height);
          dataLength = byteArray.length;
        } else if (isRGBUncompressed) {
          byteArray = loadRGBMip(buffer, dataOffset, width, height);
          dataLength = width * height * 3;
        } else {
          dataLength = ((((width + 3) ~/ 4) * ((height + 3) ~/ 4)) * blockBytes).toInt();
          byteArray = Uint8List.view(buffer, dataOffset, dataLength);
        }

        (dds['mipmaps'] as List).add({'data': byteArray, 'width': width, 'height': height});

        dataOffset += dataLength;
        width = (width ~/ 2 > 1) ? width ~/ 2 : 1;
        height = (height ~/ 2 > 1) ? height ~/ 2 : 1;
      }
    }

    return dds;
  }
}
