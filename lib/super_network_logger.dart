import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:colorize/colorize.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SuperNetworkLogger extends Interceptor {
  SuperNetworkLogger({
    this.logRequest = true,
    this.logRequestHeader = true,
    this.logRequestBody = true,
    this.logResponse = true,
    this.logResponseHeader = true,
    this.logResponseBody = true,
    this.logError = true,
    this.logErrorResponseHeader = true,
    this.logErrorBody = true,
    this.maxWidth = 100,
    this.compact = true,
    this.logName = 'SuperNetworkLogger',
    this.errorStyle = const <Styles>[Styles.RED, Styles.BLINK],
    this.requestStyle = const <Styles>[Styles.YELLOW],
    this.responseStyle = const <Styles>[Styles.GREEN],
  });

  /// Determines if the request should be logged. [Default: true]
  final bool logRequest;

  /// Determines if the request header should be logged. [Options.headers] [Default: true]
  final bool logRequestHeader;

  /// Determines if the request data should be logged. [Options.data] [Default: true]
  final bool logRequestBody;

  /// Determines if the response data should be logged. [Response.data] [Default: true]
  final bool logResponseBody;

  /// Determines if the response header should be logged. [Response.headers] [Default: true]
  final bool logResponseHeader;

  /// Determines if the error should be logged.
  final bool logError;

  /// InitialTab count to logPrint json response
  static const int kInitialTab = 1;

  /// 1 tab length
  static const String tabStep = '  ';

  /// Determines whether to print compact json response. [Default: true]
  final bool compact;

  /// Width size per logPrint. [Default: 100]
  final int maxWidth;

  /// Size in which the Uint8List will be splitted.
  static const int chunkSize = 20;

  /// Log name; defaults to `SuperLogger`.
  final String logName;

  /// Determines if the error response header should be logged. [Default: true]
  final bool logErrorResponseHeader;

  /// Determines if the error response body should be logged. [Default: true]
  final bool logErrorBody;

  /// Determines if the response should be logged. [Default: true]
  final bool logResponse;

  /// Error Style. [Default: [Styles.RED, Styles.BLINK]]
  final List<Styles> errorStyle;

  /// Request Style. [Default: [Styles.YELLOW]]
  final List<Styles> requestStyle;

  /// Response Style. [Default: [Styles.GREEN]]
  final List<Styles> responseStyle;
  void logPrint(String data, {List<Styles>? styles}) {
    final Colorize colorize = Colorize(data);

    for (final Styles style in styles ?? <Styles>[]) {
      colorize.apply(style);
    }

    log('$colorize', name: logName);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logRequest) {
      _printRequestHeader(options, styles: requestStyle);
    }
    if (logRequestHeader) {
      _printMapAsTable(
        options.queryParameters,
        header: 'Query Parameters',
        styles: requestStyle,
      );
      final Map<String, dynamic> requestHeaders = <String, dynamic>{};
      requestHeaders.addAll(options.headers);
      requestHeaders['contentType'] = options.contentType?.toString();
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      _printMapAsTable(
        requestHeaders,
        header: 'Headers',
        styles: requestStyle,
      );
      _printMapAsTable(
        options.extra,
        header: 'Extras',
        styles: requestStyle,
      );
    }
    if (logRequestBody && options.method != 'GET') {
      final dynamic data = options.data;
      if (data != null) {
        if (data is Map) {
          _printMapAsTable(
            options.data as Map?,
            header: 'Body',
            styles: requestStyle,
          );
        }
        if (data is FormData) {
          final Map<String, dynamic> formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _printMapAsTable(
            formDataMap,
            header: 'Form data | ${data.boundary}',
            styles: requestStyle,
          );
        } else {
          _printBlock(
            data.toString(),
            styles: requestStyle,
          );
        }
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Uri? uri = err.response?.requestOptions.uri;
    if (logError) {
      if (err.type == DioExceptionType.badResponse) {
        _printBoxed(
          header:
              'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage}',
          text: uri.toString(),
          styles: errorStyle,
        );
      } else {
        _printBoxed(
          header: 'DioError ║ ${err.type}',
          text: err.message,
          styles: errorStyle,
        );
      }
    }

    if (logErrorResponseHeader) {
      logPrint(
        '╔ Error Response Header',
        styles: errorStyle,
      );
      _printPrettyMap(
        err.response?.headers.map ?? <dynamic, dynamic>{},
        styles: errorStyle,
      );

      _printLine(
        '╚',
        styles: errorStyle,
      );
    }

    if (logErrorBody) {
      if (err.response != null && err.response?.data != null) {
        logPrint(
          '╔ ${err.type.toString()}',
          styles: errorStyle,
        );

        _printResponse(
          err.response!,
          styles: errorStyle,
        );
      }
      _printLine(
        '╚',
        styles: errorStyle,
      );
      logPrint(
        '',
        styles: errorStyle,
      );
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (logResponse) {
      _printResponseHeader(
        response,
        styles: responseStyle,
      );
    }
    if (logResponseHeader) {
      final Map<String, String> responseHeaders = <String, String>{};
      response.headers.forEach(
        (String k, List<String> list) => responseHeaders[k] = list.toString(),
      );
      _printMapAsTable(
        responseHeaders,
        header: 'Headers',
        styles: responseStyle,
      );
    }

    if (logResponseBody) {
      logPrint(
        '╔ Body',
        styles: responseStyle,
      );
      logPrint(
        '║',
        styles: responseStyle,
      );
      _printResponse(
        response,
        styles: responseStyle,
      );
      logPrint(
        '║',
        styles: responseStyle,
      );
      _printLine(
        '╚',
        styles: responseStyle,
      );
    }
    super.onResponse(response, handler);
  }

  void _printBoxed({String? header, String? text, List<Styles>? styles}) {
    logPrint('', styles: styles);
    logPrint('╔╣ $header', styles: styles);
    logPrint('║  $text', styles: styles);
    _printLine('╚', styles: styles);
  }

  void _printResponse(Response<dynamic> response, {List<Styles>? styles}) {
    if (response.data != null) {
      if (response.data is Map) {
        _printPrettyMap(response.data as Map, styles: styles);
      } else if (response.data is Uint8List) {
        logPrint('║${_indent()}[', styles: styles);
        _printUint8List(response.data as Uint8List, styles: styles);
        logPrint('║${_indent()}]', styles: styles);
      } else if (response.data is List) {
        logPrint('║${_indent()}[', styles: styles);
        _printList(response.data as List, styles: styles);
        logPrint('║${_indent()}]', styles: styles);
      } else {
        _printBlock(response.data.toString(), styles: styles);
      }
    }
  }

  void _printResponseHeader(
    Response<dynamic> response, {
    List<Styles>? styles,
  }) {
    final Uri uri = response.requestOptions.uri;
    final String method = response.requestOptions.method;
    _printBoxed(
      header:
          'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}',
      text: uri.toString(),
      styles: styles,
    );
  }

  void _printRequestHeader(RequestOptions options, {List<Styles>? styles}) {
    final Uri uri = options.uri;
    final String method = options.method;
    _printBoxed(
      header: 'Request ║ $method ',
      text: options.baseUrl.isEmpty
          ? '$uri'
          : 'BASEURL: ${options.baseUrl}\n║  PATH: $uri',
      styles: styles,
    );
  }

  void _printLine(String pre, {List<Styles>? styles}) =>
      logPrint('$pre${'═' * maxWidth}╝', styles: styles);

  void _printKV(String? key, Object? v, {List<Styles>? styles}) {
    final String pre = '╟ $key: ';
    final String msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      logPrint(pre, styles: styles);
      _printBlock(msg, styles: styles);
    } else {
      logPrint('$pre$msg', styles: styles);
    }
  }

  void _printBlock(String msg, {List<Styles>? styles}) {
    final int lines = (msg.length / maxWidth).ceil();
    for (int i = 0; i < lines; ++i) {
      logPrint(
        (i >= 0 ? '║ ' : '') +
            msg.characters
                .getRange(
                  i * maxWidth,
                  math.min<int>(i * maxWidth + maxWidth, msg.length),
                )
                .toString(),
        styles: styles,
      );
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printPrettyMap(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
    List<Styles>? styles,
  }) {
    int tabs = initialTab;
    final bool isRoot = tabs == kInitialTab;
    final String initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) {
      logPrint('║$initialIndent{', styles: styles);
    }

    data.keys.toList().asMap().forEach((int index, dynamic key) {
      final bool isLast = index == data.length - 1;
      dynamic value = data[key];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint(
            '║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}',
            styles: styles,
          );
        } else {
          logPrint(
            '║${_indent(tabs)} $key: {',
            styles: styles,
          );
          _printPrettyMap(
            value,
            initialTab: tabs,
            styles: styles,
          );
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint(
            '║${_indent(tabs)} $key: ${value.toString()}',
            styles: styles,
          );
        } else {
          logPrint(
            '║${_indent(tabs)} $key: [',
            styles: styles,
          );
          _printList(
            value,
            tabs: tabs,
            styles: styles,
          );
          logPrint(
            '║${_indent(tabs)} ]${isLast ? '' : ','}',
            styles: styles,
          );
        }
      } else {
        final String msg = value.toString().replaceAll('\n', '');
        final String indent = _indent(tabs);
        final int linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final int lines = (msg.length / linWidth).ceil();
          for (int i = 0; i < lines; ++i) {
            logPrint(
              '║${_indent(tabs)} ${msg.characters.getRange(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}',
              styles: styles,
            );
          }
        } else {
          logPrint(
            '║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}',
            styles: styles,
          );
        }
      }
    });

    logPrint(
      '║$initialIndent}${isListItem && !isLast ? ',' : ''}',
      styles: styles,
    );
  }

  void _printList(List list, {int tabs = kInitialTab, List<Styles>? styles}) {
    list.asMap().forEach((int i, dynamic e) {
      final bool isLast = i == list.length - 1;
      if (e is Map) {
        if (compact && _canFlattenMap(e)) {
          logPrint(
            '║${_indent(tabs)}  $e${!isLast ? ',' : ''}',
            styles: styles,
          );
        } else {
          _printPrettyMap(
            e,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
            styles: styles,
          );
        }
      } else {
        logPrint(
          '║${_indent(tabs + 2)} $e${isLast ? '' : ','}',
          styles: styles,
        );
      }
    });
  }

  void _printUint8List(
    Uint8List list, {
    int tabs = kInitialTab,
    List<Styles>? styles,
  }) {
    final List chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    for (final element in chunks) {
      logPrint(
        '║${_indent(tabs)} ${element.join(", ")}',
        styles: styles,
      );
    }
  }

  bool _canFlattenMap(Map map) {
    return map.values
            .where((dynamic val) => val is Map || val is List)
            .isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(Map? map, {String? header, List<Styles>? styles}) {
    if (map == null || map.isEmpty) {
      return;
    }
    logPrint(
      '╔ $header ',
      styles: styles,
    );
    map.forEach(
      (dynamic key, dynamic value) => _printKV(
        key.toString(),
        value,
        styles: styles,
      ),
    );
    _printLine(
      '╚',
      styles: styles,
    );
  }
}
