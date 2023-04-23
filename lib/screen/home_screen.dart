import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// static 키워드를 사용한 변수는 Hot Reload를 해도 바뀌지 않습니다. Hot Restart를 해야 변경됩니다.
class _HomeScreenState extends State<HomeScreen> {
  // latitude - 위도(가로), longitude - 경도(세로)
  static final LatLng companyLatLng = LatLng(
    37.5058,
    127.0342,
  );

  static final CameraPosition initialPosition = CameraPosition(
    target: companyLatLng,
    zoom: 15,
  );

  // m기준
  static final double okDistance = 100;

  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,
    strokeWidth: 1,
  );

  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );

  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,
    strokeWidth: 1,
  );

  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      // FutureBuilder의 제네릭<>에는 snapshot.data의 타입이 무엇인지를 적어주면 됩니다.
      body: FutureBuilder<String>(
        // Future를 return해주는 어떤 함수도 넣을 수 있습니다.
        // 함수의 상태가 변경될 때마다 builder를 다시 실행해서 화면을 다시 그려줄 수 있습니다.
        // future안에 들어간 함수가 return해준 값을 snapshot통해서 받아 볼 수 있습니다.
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // ConnectionState
          // none : future파라미터를 사용하지 않았을 경우 입니다.
          // waiting : future가 로딩 중일 때 입니다. 즉, 함수가 실행 중일 때 입니다.
          // active : FutureBuilder에서는 사용하지 않습니다. StreamBuilder에서만 사용합니다.
          // done : 함수가 완전이 끝이 났을 경우 입니다.
          // 정리하자면, future파라미터의 함수를 실행을 하면서, future함수의 상태가 변경이 될 때마다 계속 builder를 재실행을 해준다는 의미입니다.
          print(snapshot.connectionState);
          print(snapshot.data);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == 'Location permission granted.') {
            return StreamBuilder<Position>(
                stream: Geolocator.getPositionStream(),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  print(snapshot.data.runtimeType);

                  bool isWithinRange = false;

                  if (snapshot.hasData) {
                    final start = snapshot.data!;
                    final end = companyLatLng;

                    final distance = Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude,
                      end.latitude,
                      end.longitude,
                    );

                    if (distance < okDistance) {
                      isWithinRange = true;
                    }
                  }

                  return Column(
                    children: [
                      _CustomGoogleMap(
                        initialPosition: initialPosition,
                        circle: isWithinRange ? withinDistanceCircle : notWithinDistanceCircle,
                        marker: marker,
                      ),
                      _ChoolCheckButton(),
                    ],
                  );
                });
          }

          return Center(
            child: Text(
              snapshot.data,
            ),
          );
        },
      ),
    );
  }

  Future<String> checkPermission() async {
    // LocationService 활성화 여부 확인 (스마트폰 컨트롤 패널 기준)
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      return 'Please enable location services.';
    }

    // 권한
    LocationPermission checkedPermission = await Geolocator.checkPermission();

    // 앱 설치 후 초기 상태
    if (checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();

      if (checkedPermission == LocationPermission.denied) {
        return 'Please grant the location permission.';
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) {
      return 'Please allow the location permission of the app in settings.';
    }

    return 'Location permission granted.';
  }

  AppBar renderAppBar() {
    return AppBar(
      title: Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;

  const _CustomGoogleMap({
    Key? key,
    required this.initialPosition,
    required this.circle,
    required this.marker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: Set.from([circle]),
        markers: Set.from([marker]),
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  const _ChoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text('출근'),
    );
  }
}
