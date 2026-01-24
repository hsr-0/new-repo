import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/map/ride_map_controller.dart';

import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_icons.dart';

class PolyLineMapScreen extends StatefulWidget {
  const PolyLineMapScreen({super.key});

  @override
  State<PolyLineMapScreen> createState() => _PolyLineMapScreenState();
}

class _PolyLineMapScreenState extends State<PolyLineMapScreen> {
  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;
  PointAnnotationManager? pointAnnotationManager;

  bool isMapReady = false;

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    try {
      polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

      setState(() {
        isMapReady = true;
      });

      final controller = Get.find<RideMapController>();
      _updateMapUI(controller);

    } catch (e) {
      print("🔴 Error creating annotation managers: $e");
    }
  }

  Future<void> _updateMapUI(RideMapController controller) async {
    if (!isMapReady || mapboxMap == null) return;

    try {
      await polylineAnnotationManager?.deleteAll();
      await pointAnnotationManager?.deleteAll();

      if (controller.polylineCoordinates.isNotEmpty) {

        // ✅ الخطوة 1: إنشاء قائمة Positions (مطلوبة لرسم الخط LineString)
        List<Position> routePositions = controller.polylineCoordinates.map((e) {
          return Position(e.longitude, e.latitude);
        }).toList();

        // ✅ الخطوة 2: إنشاء قائمة Points (مطلوبة لضبط الكاميرا CameraBounds)
        List<Point> routePoints = routePositions.map((pos) {
          return Point(coordinates: pos);
        }).toList();

        // ✅ الخطوة 3: رسم الخط باستخدام Positions
        var polylineOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePositions), // ✅ صحيح: يأخذ Positions
          lineColor: MyColor.primaryColor.value, // تجاهل التحذير الأصفر، هذا صحيح
          lineWidth: 5.0,
          lineOpacity: 1.0,
        );

        await polylineAnnotationManager?.create(polylineOptions);

        // ✅ الخطوة 4: ضبط الكاميرا باستخدام Points
        _fitCameraToBounds(routePoints); // ✅ صحيح: يأخذ Points
      }

      await _drawMarkers(controller);

    } catch (e) {
      print("🔴 Error updating map UI: $e");
    }
  }

  Future<void> _drawMarkers(RideMapController controller) async {
    List<PointAnnotationOptions> markers = [];

    if (controller.pickupLatLng.latitude != 0) {
      final icon = await _loadIcon(MyIcons.mapMarkerPickUpIcon);
      if (icon != null) {
        markers.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(
              controller.pickupLatLng.longitude,
              controller.pickupLatLng.latitude
          )),
          image: icon,
          iconSize: 1.0,
        ));
      }
    }

    if (controller.destinationLatLng.latitude != 0) {
      final icon = await _loadIcon(MyIcons.mapMarkerIcon);
      if (icon != null) {
        markers.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(
              controller.destinationLatLng.longitude,
              controller.destinationLatLng.latitude
          )),
          image: icon,
          iconSize: 1.0,
        ));
      }
    }

    if (markers.isNotEmpty && pointAnnotationManager != null) {
      await pointAnnotationManager!.createMulti(markers);
    }
  }

  Future<Uint8List?> _loadIcon(String path) async {
    try {
      final ByteData bytes = await rootBundle.load(path);
      return bytes.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  // ✅ تم تعديل الدالة لتقبل List<Point> كما هو مطلوب في التحديث الجديد
  void _fitCameraToBounds(List<Point> points) {
    if (mapboxMap == null || points.isEmpty) return;

    MbxEdgeInsets padding = MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50);

    // هذه الدالة تتوقع List<Point>
    mapboxMap!.cameraForCoordinates(
        points,
        padding,
        null,
        null
    ).then((cameraOptions) {
      mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
    }).catchError((e) {
      print("🔴 Error fitting camera: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          final initialLat = (controller.pickupLatLng.latitude == 0) ? 32.5029 : controller.pickupLatLng.latitude;
          final initialLng = (controller.pickupLatLng.longitude == 0) ? 45.8219 : controller.pickupLatLng.longitude;

          if (isMapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMapUI(controller);
            });
          }

          return Stack(
            children: [
              MapWidget(
                styleUri: MapboxStyles.MAPBOX_STREETS,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(initialLng, initialLat)),
                  zoom: 14.0,
                ),
                onMapCreated: _onMapCreated,
              ),

              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong, color: Colors.black),
                  onPressed: () {
                    if(controller.polylineCoordinates.isNotEmpty && isMapReady) {
                      // تحويل إلى Points للكاميرا
                      List<Point> points = controller.polylineCoordinates
                          .map((e) => Point(coordinates: Position(e.longitude, e.latitude)))
                          .toList();
                      _fitCameraToBounds(points);
                    }
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}