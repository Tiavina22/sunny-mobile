package com.example.sunny

import android.app.Activity
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AlarmRingingActivity : Activity() {
    private val ringtone by lazy {
        RingtoneManager.getRingtone(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
    }
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }

        val challengeType = intent.getStringExtra("challengeType") ?: "math"
        val difficulty = intent.getStringExtra("difficulty") ?: "easy"

        title = "Alarm"
        setContentView(
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(48, 120, 48, 48)

                addView(
                    TextView(context).apply {
                        textSize = 30f
                        text = "Wake up"
                    },
                )

                addView(
                    TextView(context).apply {
                        textSize = 18f
                        text = "Challenge: $challengeType  Difficulty: $difficulty"
                    },
                )

                addView(
                    Button(context).apply {
                        text = "Open challenge"
                        setOnClickListener {
                            // Placeholder for the dedicated challenge screen.
                        }
                    },
                )

                addView(
                    Button(context).apply {
                        text = "Stop (temporary for dev)"
                        setOnClickListener {
                            stopAlertSignals()
                            finish()
                        }
                    },
                )
            },
        )

        startAlertSignals()
    }

    override fun onDestroy() {
        stopAlertSignals()
        super.onDestroy()
    }

    private fun startAlertSignals() {
        ringtone.audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        ringtone.play()

        vibrator = getSystemService(Vibrator::class.java)
        val pattern = longArrayOf(0, 700, 400)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopAlertSignals() {
        if (ringtone.isPlaying) {
            ringtone.stop()
        }
        vibrator?.cancel()
    }
}