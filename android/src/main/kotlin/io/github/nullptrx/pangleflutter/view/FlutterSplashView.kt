package io.github.nullptrx.pangleflutter.view

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import com.bytedance.sdk.openadsdk.CSJAdError
import com.bytedance.sdk.openadsdk.CSJSplashAd
import com.bytedance.sdk.openadsdk.TTAdNative
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.github.nullptrx.pangleflutter.PangleAdManager
import io.github.nullptrx.pangleflutter.PangleAdSlotManager
import io.github.nullptrx.pangleflutter.common.TTSize
import io.github.nullptrx.pangleflutter.util.asMap

class FlutterSplashView(
  val context: Context,
  messenger: BinaryMessenger,
  val id: Int,
  params: Map<String, Any?>
) : PlatformView, MethodChannel.MethodCallHandler, TTAdNative.CSJSplashAdListener,
  CSJSplashAd.SplashAdListener {

  private val methodChannel: MethodChannel =
    MethodChannel(messenger, "nullptrx.github.io/pangle_splashview_$id")
  private val container: FrameLayout
  private var hideSkipButton = false

  init {
    methodChannel.setMethodCallHandler(this)
    container = FrameLayout(context)
    val slotId = params["slotId"] as? String
    if (slotId != null) {
      val isSupportDeepLink = params["isSupportDeepLink"] as? Boolean ?: true
      val tolerateTimeout = params["tolerateTimeout"] as Double?
      hideSkipButton = params["hideSkipButton"] as? Boolean ?: false

      val imgArgs: Map<String, Double?> = params["expressSize"]?.asMap() ?: mapOf()
      val w: Double = imgArgs["width"] ?: 1080.0
      val h: Double = imgArgs["height"] ?: 1920.0
      val imgSize = TTSize(w.toInt(), h.toInt())
      val adSlot = PangleAdSlotManager.getSplashAdSlot(
        slotId,
        imgSize,
        isSupportDeepLink,
      )
      PangleAdManager.shared.loadSplashAd(adSlot, this, timeout = tolerateTimeout)
    }
  }

  override fun getView(): View {
    return container
  }

  override fun dispose() {
    methodChannel.setMethodCallHandler(null)
    container.removeAllViews()
  }


  override fun onSplashLoadSuccess(ad: CSJSplashAd) {

  }

  override fun onSplashLoadFail(error: CSJAdError) {
    postMessage("onError", mapOf("message" to error.msg, "code" to error.code))
  }

  override fun onSplashRenderSuccess(ad: CSJSplashAd) {
    postMessage("onLoad")
    ad.apply {

      if (hideSkipButton) {
        hideSkipButton()
      }

      val params = FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply {
        gravity = Gravity.CENTER
      }
      container.addView(splashView, params)

      setSplashAdListener(this@FlutterSplashView)

    }
  }

  override fun onSplashRenderFail(ad: CSJSplashAd, error: CSJAdError) {
    postMessage("onError", mapOf("message" to error.msg, "code" to error.code))
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

    when (call.method) {
      else -> result.notImplemented()
    }
  }

  override fun onSplashAdShow(ad: CSJSplashAd?) {
    postMessage("onShow")
  }

  override fun onSplashAdClick(ad: CSJSplashAd?) {
    postMessage("onClick")
  }

  override fun onSplashAdClose(ad: CSJSplashAd?, type: Int) {
    postMessage("onClose", mapOf("type" to type))
  }

  private fun postMessage(method: String, arguments: Map<String, Any?> = mapOf()) {
    Handler(Looper.getMainLooper()).post {
      methodChannel.invokeMethod(method, arguments)
    }
  }
}

