import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapboxCachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);

    return CachedNetworkImageProvider(
      url,
      // هذا يضمن أن الصورة تبقى محفوظة في الجهاز ولا يتم تحميلها مجدداً
      cacheKey: url,
    );
  }
}