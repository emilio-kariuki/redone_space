import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:get/get.dart' hide FormData;
import 'package:geolocator/geolocator.dart' hide ServiceStatus;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:ui' as ui;
import '../Controller/spaceController.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isActivated = false, isValidate = false, loading = false;
  File? image;
  final picker = ImagePicker();
  double? latitude, longitude, unique, density, lat, long;
  DateTime? today, plantation;
  String? selectedType, selectedMethod;
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? currentPosition;
  final Location _location = Location();
  final spaceController = Get.put(SpaceController());
  final heights = TextEditingController();
  final variety = TextEditingController();
  final row = TextEditingController();
  final column = TextEditingController();
  final name = TextEditingController();
  Set<Marker> _markers = Set();

  addMarkers() async {
    final Uint8List markerIcon =
        await getBytesFromAsset("assets/Images/pick_marker.png", 50);
    _markers.add(
      Marker(
          markerId: const MarkerId('marker_2'),
          position: const LatLng(36.959988288487104, -0.398163985596978),
          icon: BitmapDescriptor.fromBytes(markerIcon),
          draggable: true),
    );
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.initState();
    checkConnectivity();
    getUserLocation();
    addMarkers();
  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Center(child: showTitle("D-Krops")),
              displayImage(),
              const SizedBox(height: 5),
              fieldsContain(),
              const SizedBox(height: 5),
              mapContain(),
              const SizedBox(height: 5),
              rowButton()
            ],
          ),
        ),
      ),
    ));
  }

  Widget fieldsContain() {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.65,
      padding: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 14, 14, 20), width: 1),
          color: Colors.blueGrey[800],
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          whiteText("Type of crop"),
          showDivider(),
          rowDown("assets/Lottie/select.json", "Select", items, selectedType),
          const SizedBox(height: 3),
          rowField(variety, "Identity", TextInputType.number,
              "assets/Lottie/balls.json"),
          whiteText("Spacing"),
          showDivider(),
          rowField(row, "Row", TextInputType.number, "assets/Lottie/row.json"),
          const SizedBox(height: 3),
          rowField(column, "Identity", TextInputType.number,
              "assets/Lottie/columns.json"),
          whiteText("Features"),
          showDivider(),
          rowDown("assets/Lottie/shovel.json", "Select Method", itemz,
              selectedMethod),
          const SizedBox(height: 3),
          rowField(name, "Project Name", TextInputType.text,
              "assets/Lottie/height.json"),
          whiteText("Plantation Date"),
          showDivider(),
          Row(
            children: [
              InkWell(
                  onTap: datePick,
                  child: lottieContain("assets/Lottie/icon.json")),
              const SizedBox(width: 15),
              Obx(() {
                return whiteText(
                    spaceController.plantationDate.value.toString());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget mapContain() {
    final size = MediaQuery.of(context).size;
    return Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromARGB(255, 14, 14, 20), width: 1),
            color: Colors.blueGrey[800],
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: whiteText("Type of crop"),
            ),
            showDivider(),
            showMap()
          ],
        ));
  }

  Widget showMap() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: BoxDecoration(
        border:
            Border.all(color: const Color.fromARGB(255, 14, 14, 20), width: 1),
        color: Colors.blueGrey[800],
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: googleMaps(),
    );
  }

  Future<void> datePick() {
    return showDatePicker(
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color.fromARGB(
                        255, 221, 165, 9), // header background color
                    onPrimary: Colors.black, // header text color
                    onSurface: Color.fromARGB(255, 0, 0, 0), // body text color
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      primary: Colors.red, // button text color
                    ),
                  ),
                ),
                child: child!,
              );
            },
            context: context,
            initialDate: today ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2030))
        .then((value) {
      setState(() {
        spaceController.plantationDate.value = value!;
        spaceController.plantationDate.value = (DateFormat.yMMM()
            .format(spaceController.plantationDate.value) as DateTime);
        // row_2 = double.parse(row.text);
        // column_2 =
        //     double.parse(column.text);
      });
    });
  }

  Future<void> getImage(ImageSource source) async {
    final image = await picker.pickImage(
        source: source, maxHeight: 480, maxWidth: 640, imageQuality: 60);
    try {
      if (image == null) return;

      final imageTempo = File(image.path);
      setState(() {
        this.image = imageTempo;
      });
    } on PlatformException catch (e) {
      showToast(
        "Failed to pick image $e",
      );
    }
  }

  Future<void> showToast(String message) {
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      showToast("No internet connection");
    } else if (result == ConnectivityResult.mobile) {
      showToast("Connected to mobile data");
    } else if (result == ConnectivityResult.wifi) {
      showToast("Connected to wifi");
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> updateCameraPosition(CameraPosition position) async {
    latitude = position.target.latitude;
    longitude = position.target.longitude;
    print(
        'inside updatePosition ${position.target.latitude} ${position.target.longitude}');
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/Images/pick_marker.png', 150);

    _markers.add(
      Marker(
          markerId: const MarkerId('marker_2'),
          position: LatLng(position.target.latitude, position.target.longitude),
          icon: BitmapDescriptor.fromBytes(markerIcon),
          draggable: true),
    );

    setState(() {});
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToast("Please enable location service");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      showToast("Please enable location permission");
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print(position);
    latitude = position.latitude;
    longitude = position.longitude;
    updateCameraPosition(CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    ));
  }

  Future<String?> imageDialog() async {
    final size = MediaQuery.of(context).size;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => Container(
        width: size.width,
        height: size.height * 0.2,
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 14, 14, 20), width: 1),
          //border: Border.all(color: Color.fromARGB(255, 182, 36, 116),width:1 ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(5),
          title: const Text('choose image from: '),
          content: SingleChildScrollView(
            child: ListBody(children: [
              imageTile(ImageSource.camera, 'Camera'),
              imageTile(ImageSource.gallery, "Gallery"),
              ListTile(
                selectedColor: Colors.grey,
                onTap: () {
                  Get.back();
                },
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text("Cancel"),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget imageTile(ImageSource source, String text) {
    return ListTile(
      selectedColor: Colors.grey,
      onTap: () {
        setState(() {
          getImage(source);
          Get.back();
        });
      },
      leading: const Icon(Icons.layers, color: Color.fromARGB(255, 0, 0, 0)),
      title: GestureDetector(
          onTap: () {
            setState(() {
              getImage(source);
              Get.back();
            });
          },
          child: showTexts(text)),
    );
  }

  Widget showTexts(String text) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
          fontSize: 16,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.001),
    );
  }

  Widget whiteText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            text,
            textAlign: TextAlign.left,
            style: GoogleFonts.quicksand(
                fontSize: 18,
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget displayImage() {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Material(
          color: const Color.fromARGB(255, 36, 47, 53),
          elevation: 20,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: size.height * 0.2,
            width: size.width,
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color.fromARGB(255, 14, 14, 20), width: 1),
            ),
            child: Center(
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        image!,
                        width: size.width,
                        height: size.height * 0.32,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text("Select Image",
                      style: GoogleFonts.roboto(
                          fontSize: 16, color: Colors.white)),
            ),
            // image: image
          ),
        ),
        Positioned(top: 5, right: 5, child: iconImage()),
      ],
    );
  }

  Widget iconImage() {
    return IconButton(
        onPressed: () {
          setState(() {
            imageDialog();
          });
        },
        icon: Icon(Icons.add_a_photo,
            size: 20,
            color: image != null
                ? Colors.white
                : const Color.fromARGB(255, 223, 152, 1)));
  }

  Widget dropDown(String hint, List list, String? values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton2(
          underline: Container(
            height: 0,
          ),
          icon: const Icon(
            Icons.arrow_forward_ios_outlined,
            size: 18,
          ),
          buttonPadding: const EdgeInsets.only(left: 10, right: 10),
          buttonDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          scrollbarAlwaysShow: true,
          dropdownMaxHeight: MediaQuery.of(context).size.height * 0.3,
          hint: showTexts(hint),
          buttonWidth: MediaQuery.of(context).size.width * 0.68,
          items: list
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: showTexts(item),
                  ))
              .toList(),
          value: values,
          onChanged: (value) {
            setState(() {
              values = value as String;
              print(value.toString());
              isActivated = true;
              switch (value) {
                case 'godget':
                  unique = 0;
                  break;
                case 'maize':
                  unique = 1;
                  break;
                case 'coffee':
                  unique = 2;
                  break;
                case 'bananas':
                  unique = 3;
                  break;
                case 'lettuce':
                  unique = 4;
                  break;
                case 'beans':
                  unique = 5;
                  break;
                case 'cabbage':
                  unique = 6;
                  break;
                case 'capcicum':
                  unique = 7;
                  break;
                case 'dania':
                  unique = 8;
                  break;
                case 'carrots':
                  unique = 9;
                  break;
                case 'dengu':
                  unique = 10;
                  break;
                case 'kales':
                  unique = 11;
                  break;
                case 'napiergrass':
                  unique = 12;
                  break;
                case 'onions':
                  unique = 13;
                  break;
                case 'peas':
                  unique = 14;
                  break;
                case 'potatoes':
                  unique = 15;
                  break;
                case 'pumpkins':
                  unique = 16;
                  break;
                case 'sorghum':
                  unique = 17;
                  break;
                case 'sweet-potatoes':
                  unique = 18;
                  break;
                case 'spinach':
                  unique = 19;
                  break;
                case 'tomatoes':
                  unique = 20;
                  break;
                case 'tea':
                  unique = 21;
                  break;
                case 'wheat':
                  unique = 22;
                  break;
                case 'yams':
                  unique = 23;
                  break;
                case 'arrow-roots':
                  unique = 24;
                  break;
                case 'buildings':
                  unique = 25;
                  break;
                case 'bare-land':
                  unique = 26;
                  break;
                case 'dams':
                  unique = 27;
                  break;

                case 'forest':
                  unique = 29;
                  break;
                case 'grassland':
                  unique = 30;
                  break;
                case 'road':
                  unique = 31;
                  break;
                case 'range-land':
                  unique = 32;
                  break;
                case 'swamps':
                  unique = 33;
                  break;
                case 'river':
                  unique = 34;
                  break;
                case 'shrub-land':
                  unique = 35;
                  break;
                case 'cauliflower':
                  unique = 36;
                  break;
                case 'cucumber':
                  unique = 37;
                  break;
                case 'garlic':
                  unique = 38;
                  break;
                default:
                  unique = 0;
                  break;
              }
              print(unique);
            });
          },
        )
      ],
    );
  }

  Widget lottieContain(String lottieUrl) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
        child: buildContain(
      color: const Color.fromARGB(255, 189, 139, 31),
      child:
          Lottie.asset(lottieUrl, height: size.height * 0.4, width: size.width),
    ));
  }

  Widget buildContain({required child, required Color color}) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          shape: BoxShape.rectangle,
          color: color,
        ),
        height: 50,
        width: 50,
        child: child);
  }

  Widget rowDown(String lottieUrl, String hint, List list, String? value) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        lottieContain(lottieUrl),
        SizedBox(width: size.width * 0.06),
        dropDown(hint, list, value)
      ],
    );
  }

  Widget showField(TextEditingController controller, String hint,
      TextInputType textInputType) {
    return Flexible(
      flex: 1,
      child: TextFormField(
        keyboardType: textInputType,
        decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(15, 20, 15, 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 255, 255, 255),
                width: 1.0,
              ),
            ),
            filled: true,
            hintStyle: GoogleFonts.quicksand(
                fontSize: 16,
                color: Colors.black38,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.001),
            focusColor: Colors.red,
            hintText: hint,
            fillColor: Colors.white),
        controller: controller,
      ),
    );
  }

  Widget rowField(TextEditingController controller, String hint,
      TextInputType textInputType, String lottieUrl) {
    final size = MediaQuery.of(context).size;
    return Flexible(
      flex: 1,
      child: Row(
        children: [
          lottieContain(lottieUrl),
          SizedBox(width: size.width * 0.06),
          showField(controller, hint, textInputType)
        ],
      ),
    );
  }

  Widget showTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
            fontSize: 24,
            color: const Color.fromARGB(255, 24, 23, 37),
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget showDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
              margin: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: const Divider(
                color: Color.fromARGB(255, 255, 255, 255),
                height: 15,
                thickness: 0.4,
              )),
        ),
      ],
    );
  }

  Widget googleMaps() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          child: GoogleMap(
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onCameraMove: ((position) => updateCameraPosition(position)),
            markers: Set<Marker>.of(_markers),
            mapType: MapType.hybrid,
            myLocationButtonEnabled: true,
            myLocationEnabled: false,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
            indoorViewEnabled: true,
            zoomGesturesEnabled: false,
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              //getLocation();
              // getPermission();
            },
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: SizedBox(
            height: 30,
            width: 30,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () => goToLocation(),
              child: Icon(Icons.my_location,
                  size: 18, color: Theme.of(context).primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> goToLocation() async {
    final GoogleMapController controller = await _controller.future;
    _location.onLocationChanged.listen((locationData) {
      latitude = locationData.latitude;
      longitude = locationData.longitude;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude!, longitude!),
            zoom: 14,
          ),
        ),
      );
    });
  }

  getUserLocation() async {
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      print(currentPosition);
    });
  }

  Widget showButton(String text, Function() function) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.06,
      width: size.width * 0.36,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all(const Color.fromARGB(255, 14, 14, 20)),
          // MaterialStateProperty<Color?>?
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: const BorderSide(
                color: Color.fromARGB(255, 14, 14, 20),
                width: 2.0,
              ),
            ),
          ),
        ),
        onPressed: function,
        child: Text(text, style: GoogleFonts.roboto(fontSize: 20)),
      ),
    );
  }

  Widget rowButton() {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        showButton("Close", () => exit(0)),
        SizedBox(width: size.width * 0.08),
        loading
            ? const CircularProgressIndicator()
            : showButton("Submit", () async {
                if (selectedType == null && image == null && today == null) {
                  showToast("Fill all the fields");
                } else {
                  setState(() {
                    loading = true;
                  });
                  await sendData();
                  loading
                      ? const CircularProgressIndicator(
                          color: Color.fromARGB(255, 240, 144, 1),
                        )
                      : await showToast("Information sent Successfully");
                  setState(() {
                    loading = false;
                  });
                  selectedType = null;
                  //selectedMethod = null;
                }
              }),
      ],
    );
  }

  Future<void> sendData() async {
    final String variety_1 = variety.text;
    final String row_1 = row.text;
    final String column_1 = column.text;
    final String location = heights.text;
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = spaceController.plantationDate.toString();

    final double density_1 = double.parse(row.text) * double.parse(column.text);
    final bytes = image?.readAsBytesSync();
    String imageEncoded = base64Encode(bytes!);
    var dio = Dio();
    var formData = FormData.fromMap({
      "variety": variety_1,
      "location": location,
      "crop_density": density_1,
      "plantation_method": selectedMethod,
      "row": row_1,
      "column": column_1,
      "image": imageEncoded,
      "x_coordinate": latitude,
      "y_coordinate": longitude,
      "latitude": latitude,
      "longitude": longitude,
      "type": selectedType,
      "date_of_plantation": formatted,
      "land_cover": unique,
    });

    var response = await dio
        .post('https://iggresapps.dkut.ac.ke/crop_mapping.php', data: formData);
    print(response);
    getLocation();
    loading = false;
  }

  List<String> items = [
    'arrow-roots',
    'bananas',
    "beans",
    "cabbage",
    'capcicum',
    'cauliflower',
    'cucumber',
    "carrots",
    'coffee',
    'dania',
    'dengu',
    'godget',
    'garlic',
    "kales",
    'lettuce',
    'maize',
    'napiergrass',
    "onions",
    "peas",
    "potatoes",
    'pumpkins',
    "spinach",
    "sorghum",
    'sweet-potatoes',
    'tomatoes',
    'tea',
    'wheat',
    'yams',
    "-------------------------",
    'buildings',
    'bare-land',
    'dams',
    'forest',
    'grassland',
    'road',
    'range-land',
    'swamps',
    'river',
    'shrub-land',
  ];
  List<String> itemz = [
    'Agro-forestry',
    "Broadcasting",
    "Fallowing",
    "Tranplanting",
    "Direct-seeding",
    "ploughing",
    "Harrowing",
  ];
}
