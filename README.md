# super_network_logger


Super Network Logger is a [Dio](https://pub.dev/packages/dio) interceptor for logging network calls with color, styling, and formatting support.

## Features
- Formatting support
- Color styling support
- Json support
- Fully customizable


## Usage

Simply add SuperNetworkLogger to your dio interceptors.

```Dart
dio.interceptors.add(
    SuperNetworkLogger(
      logError: true,
      logRequest: true,
      logResponse: true,
      errorStyle: [Styles.RED, Styles.BLINK],
      logName: "SuperNetworkLogger",
    ),
  );
```

## Output Sample


Success Log
![Success Log](https://raw.githubusercontent.com/navneet-singh-profile/super_network_logger/main/images/success_image.png "Success Log")

Error Log
![Error Log](https://raw.githubusercontent.com/navneet-singh-profile/super_network_logger/main/images/error_image.png "Error Log")

