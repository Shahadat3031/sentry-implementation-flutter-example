import 'dart:async';
import 'dart:io';
import 'package:device_info/device_info.dart';

import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_implementation_flutter/config.dart';

/*
*  This Application will catch all the unhandled exception that occurred in the application and that will be sent to the sentry dashboard.
*  If we want to send all catch exception to the sentry dashboard the we have to call  reportError(exception,stacktrace) method with proper parameter.
*
*  This application is not fully optimized. If any one want to use it please test it first and test with your own "dsn" key.
*  Firstly log in into Sentry.io then get the dsn key and replace the key dsn scope.
*
*  This application will send specific device data to the sentry. This application is tested for android only.
*
* */

/// replace sentryDSN with your DSN
final SentryClient sentry = SentryClient(SentryOptions(dsn: "https://3a3c129ebc404b77a2cfcec6f6571cc5@o510088.ingest.sentry.io/123456"));
final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///Must add this line to get all the error from flutter framwork
  WidgetsFlutterBinding.ensureInitialized(); //imp line need to be added first
  // This captures errors reported by the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) async {
    if (Config.isDebug) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
      reportError(details.exception, details.stack);
      //Testing for firebase Crashlytics
     }
  };

  runZonedGuarded<Future<Null>>(() async {
    runApp(new MyApp());
  }, (Object error, StackTrace stackTrace) {
    // Whenever an error occurs, call the `_reportError` function. This sends
    // Dart errors to the dev console or Sentry depending on the environment.
    reportError(error,stackTrace);
  });
}

Future<SentryEvent> getSentryEnvEvent(dynamic exception, dynamic stackTrace) async {
  /// return Event with IOS extra information to send it to Sentry
  if (Platform.isIOS) {
    final IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;

    return SentryEvent(
      release: '0.0.1',
      environment: 'production', // replace it as it's desired
      extra: <String, dynamic>{
        'name': iosDeviceInfo.name,
        'model': iosDeviceInfo.model,
        'systemName': iosDeviceInfo.systemName,
        'systemVersion': iosDeviceInfo.systemVersion,
        'localizedModel': iosDeviceInfo.localizedModel,
        'utsname': iosDeviceInfo.utsname.sysname,
        'identifierForVendor': iosDeviceInfo.identifierForVendor,
        'isPhysicalDevice': iosDeviceInfo.isPhysicalDevice,
      },
      //exception: exception,
      //stackTrace: stackTrace,
    );
  }

  /// return Event with Andriod extra information to send it to Sentry
  if (Platform.isAndroid) {
    SentryException sentryException = SentryException(type: "Digigo", value: stackTrace.toString());
    //SentryStackTrace sentryStackTrace = SentryStackTrace(frames: );

    print(" ********** "+exception.toString());

    final AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
    return SentryEvent(
      release: '0.0.2',
      environment: 'production', // replace it as it's desired
      extra: <String, dynamic>{
        'type': androidDeviceInfo.type,
        'model': androidDeviceInfo.model,
        'device': androidDeviceInfo.device,
        'id': androidDeviceInfo.id,
        'androidId': androidDeviceInfo.androidId,
        'brand': androidDeviceInfo.brand,
        'display': androidDeviceInfo.display,
        'hardware': androidDeviceInfo.hardware,
        'manufacturer': androidDeviceInfo.manufacturer,
        'product': androidDeviceInfo.product,
        'version': androidDeviceInfo.version.release,
        'supported32BitAbis': androidDeviceInfo.supported32BitAbis,
        'supported64BitAbis': androidDeviceInfo.supported64BitAbis,
        'supportedAbis': androidDeviceInfo.supportedAbis,
        'isPhysicalDevice': androidDeviceInfo.isPhysicalDevice,
      },
      exception: sentryException,
      //stackTrace: stackTrace,
    );
  }
  ///Return standard Error in case of non-specifed paltform
  /// if there is no detected platform,
  /// just return a normal event with no extra information
  return SentryEvent(
    release: '0.0.1',
    environment: 'production',
    exception: exception,
    //stackTrace: stackTrace,
  );
}

Future<void> reportError(error, stack) async {
  if (Config.isDebug) {
    // In development mode, simply print to console.
    print('No Sending report to sentry.io as mode is debugging DartError');
    // Print the full stacktrace in debug mode.
    //print(stackTrace);
    return;
  } else {
    try {
      // In production mode, report to the application zone to report to Sentry.
      final SentryEvent event = await getSentryEnvEvent(error, stack);
      print('Sending report to sentry.io $event');
      await sentry.captureEvent(event);
    } catch (e) {
      print('Sending report to sentry.io failed: $e');
      print('Original error: $error');
    }
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // is not restarted.
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Sentry Implementation Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Sentry Demo Testing",style: Theme.of(context).textTheme.headline4),
            ElevatedButton(onPressed:(){
              //Example 1
              //handled Exception
              /*try{
                //do something
              } catch(exception,stackTrace){
                reportError(exception, stackTrace)
              }*/
              //Example 2
              //Unhandled Exception
              throw Exception();
            } , child: Text(
              "Create Exception"
            ))
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
