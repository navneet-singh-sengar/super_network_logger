import 'dart:developer';
import 'package:colorize/colorize.dart';
import 'package:dio/dio.dart';
import 'package:super_network_logger/super_network_logger.dart';

void main() async {
  final dio = Dio();
  dio.interceptors.add(
    SuperNetworkLogger(
      logError: true,
      logRequest: true,
      logResponse: true,
      errorStyle: [Styles.RED, Styles.BLINK],
      logName: "SuperNetworkLogger",
    ),
  );

  try {
    await dio.post(
      'https://jsonplaceholder.typicode.com/posts',
      data: {
        'title': 'foo',
        'body': 'bar',
        'userId': 1,
        'info': {
          'name': 'joseph',
          'age': 20,
        },
      },
      options: Options(
        headers: {
          'accessToken':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTIzNDU2Nzg5LCJuYW1lIjoiSm9zZXBoIn0.OpOSSw7e485LOP5PrzScxHb7SR6sAOMRckfFwi4rp7o'
        },
      ),
      queryParameters: {
        '_limit': 5,
        '_page': 1,
        '_sort': 'id',
      },
    );
  } catch (e) {
    log(e.toString());
  }
}
