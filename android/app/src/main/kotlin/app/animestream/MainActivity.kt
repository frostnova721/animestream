package app.animestream

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.widget.Toast
import android.os.Looper
import android.os.Handler
import androidx.annotation.NonNull

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

    private lateinit var channel: MethodChannel

    private var autoPip = false
    private var playing = true

    private val pipActionIntent = "app.animestream.PIP_ACTION"

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra("action") ?: return
            if (::channel.isInitialized) channel.invokeMethod("pipAction", action)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(pipActionIntent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipReceiver, filter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(pipReceiver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/utils")
        channel.setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showToast" -> {
                val message = call.argument<String>("message")
                if(message == null || message.length == 0) {
                    result.error("MESSAGE_NOT_PROVIDED", "MESSAGE IS NULL OR EMPTY", null)
                }
                showToast(message ?: "")
                }
                "setAutoPip" -> {
                    autoPip = call.argument<Boolean>("enabled") ?: false
                    updatePipParams()
                    result.success(null)
                }
                "setPipPlaying" -> {
                    playing = call.argument<Boolean>("playing") ?: true
                    updatePipParams()
                    result.success(null)
                }
                "enterPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            enterPictureInPictureMode(buildPipParams())
                        } catch (e: Exception) {
                            // no support
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pipAction(action: String, iconRes: Int, title: String, requestCode: Int): RemoteAction {
        val intent = Intent(pipActionIntent).setPackage(packageName).putExtra("action", action)
        val pending = PendingIntent.getBroadcast(this, requestCode, intent, PendingIntent.FLAG_IMMUTABLE)
        return RemoteAction(Icon.createWithResource(this, iconRes), title, title, pending)
    }

    private fun buildPipParams(): PictureInPictureParams {
        val actions = listOf(
            pipAction("rewind", R.drawable.ic_pip_rewind, "Rewind", 0),
            if (playing) pipAction("playPause", R.drawable.ic_pip_pause, "Pause", 1)
            else pipAction("playPause", R.drawable.ic_pip_play, "Play", 1),
            pipAction("forward", R.drawable.ic_pip_forward, "Forward", 2),
        )
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))
            .setActions(actions)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Lets the system enter PiP itself during the home gesture
            builder.setAutoEnterEnabled(autoPip)
        }
        return builder.build()
    }

    private fun updatePipParams() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            setPictureInPictureParams(buildPipParams())
        } catch (e: Exception) {
            // device without PiP support
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // No auto-enter below Android 12, so request it here while still resumed
        if (autoPip && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            try {
                enterPictureInPictureMode(buildPipParams())
            } catch (e: Exception) {
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (::channel.isInitialized) {
            channel.invokeMethod("onPipChanged", isInPictureInPictureMode)
        }
    }

    fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }
    }
}
