# super_network_logger

<img   height="30" src="https://raw.githubusercontent.com/navneet-singh-profile/super_network_logger/main/images/logo.png">

[![super_network_logger](https://img.shields.io/pub/v/super_network_logger "super_network_logger")](https://github.com/navneet-singh-profile/super_network_logger "super_network_logger")

Super Network Logger is a [Dio](https://pub.dev/packages/dio) interceptor for logging network calls with color, styling, and formatting support.

## Features
- Formatting support
- Color styling support
- Json support
- Fully customizable

## Usage

Simply add SuperNetworkLogger to your dio interceptors.

```Dart
Dio dio = Dio();
  dio.interceptors.add(SuperNetworkLogger());

  // optional customization
  dio.interceptors.add(
    SuperNetworkLogger(
      logError: true,
      logRequest: true,
      logResponse: true,
      logErrorBody: true,
      logRequestBody: true,
      logResponseBody: true,
      logErrorResponseHeader: true,
      logRequestHeader: true,
      logResponseHeader: true,
      compact: true,
      maxWidth: 100,
      errorStyle: [Styles.RED, Styles.BLINK],
      requestStyle: [Styles.YELLOW],
      responseStyle: [Styles.GREEN],
      logName: "SuperNetworkLogger",
    ),
  );
```

## Output Sample

###### Success Log
![Success Log](https://raw.githubusercontent.com/navneet-singh-profile/super_network_logger/main/images/success_image.png "Success Log")

###### Error Log
![Error Log](https://raw.githubusercontent.com/navneet-singh-profile/super_network_logger/main/images/error_image.png "Error Log")