import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MapCaptureService {
  static Future<Uint8List?> capture(
    GlobalKey key, {
    Duration delay = const Duration(milliseconds: 1200),
  }) async {
    try {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      await Future.delayed(delay);
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      unawaited(Sentry.captureException(e, stackTrace: st));
      return null;
    }
  }
}
