/*
 * Copyright (c) 2021 nullptrX
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../feedview.dart';
import '../platform_controller.dart';
import 'feedview_android.dart';
import 'feedview_method_channel.dart';
import 'platform_interface.dart';

/// Android [FeedViewPlatform] that uses [AndroidViewSurface] to build the
/// [FeedView] widget.
///
/// To use this, set [FeedView.platform] to an instance of this class.
///
/// This implementation uses [AndroidViewSurface] to render the [FeedView] on
/// Android. It solves multiple issues related to accessibility and interaction
/// with the [FeedView] at the cost of some performance on Android versions below
/// 10.
///
/// To support transparent backgrounds on all Android devices, this
/// implementation uses hybrid composition when the opacity of
/// `CreationParams.backgroundColor` is less than 1.0. See
/// https://github.com/flutter/flutter/wiki/Hybrid-Composition for more
/// information.
class SurfaceAndroidFeedView extends AndroidFeedView with AndroidViewMixin {
  // On some Android devices, transparent backgrounds can cause
  // rendering issues on the non hybrid composition
  // AndroidViewSurface. Switch the widget to Hybrid
  // Composition when the background color is not 100% opaque.
  final bool hybridComposition;

  /// Constructs a [SurfaceAndroidFeedView].
  SurfaceAndroidFeedView({this.hybridComposition = false});

  @override
  Widget build({
    required BuildContext context,
    required Map<String, dynamic> creationParams,
    required FeedViewPlatformCallbacksHandler feedViewPlatformCallbacksHandler,
    FeedViewPlatformCreatedCallback? onFeedViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return PlatformViewLink(
        viewType: kFeedViewType,
        surfaceFactory: (
          BuildContext context,
          PlatformViewController controller,
        ) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: gestureRecognizers ??
                const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return createView(
            viewType: kFeedViewType,
            hybridComposition: hybridComposition,
            creationParams: creationParams,
            params: params,
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener((id) async {
              if (onFeedViewPlatformCreated == null) {
                return;
              }
              onFeedViewPlatformCreated(MethodChannelFeedViewPlatform(
                id,
                feedViewPlatformCallbacksHandler,
              ));
            })
            ..create();
        });
  }
}
