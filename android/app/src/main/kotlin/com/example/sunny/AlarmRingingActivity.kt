package com.example.sunny

import android.app.Activity
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import android.widget.EditText
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import kotlin.random.Random

class AlarmRingingActivity : Activity() {
    private val ringtone by lazy {
        RingtoneManager.getRingtone(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
    }
    private var vibrator: Vibrator? = null

    private var expectedAnswer: Int = 0

    private lateinit var challengeTextView: TextView
    private lateinit var answerInput: EditText
    private lateinit var validateButton: Button

    private lateinit var challengeType: String
    private lateinit var difficulty: String

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

        challengeType = intent.getStringExtra("challengeType") ?: "math"
        difficulty = intent.getStringExtra("difficulty") ?: "easy"

        title = "Alarm"

        challengeTextView = TextView(this).apply {
            textSize = 22f
        }
        answerInput = EditText(this).apply {
            textSize = 22f
            hint = "Enter result"
            inputType = android.text.InputType.TYPE_CLASS_NUMBER or
                android.text.InputType.TYPE_NUMBER_FLAG_SIGNED
        }
        validateButton = Button(this).apply {
            text = "Validate"
            setOnClickListener { validateMathAnswer() }
        }

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
                        text = "Challenge: $challengeType | Difficulty: $difficulty"
                    },
                )

                addView(challengeTextView)
                addView(answerInput)
                addView(validateButton)
            },
        )

        configureChallengeUi()
        startAlertSignals()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Keep the ringing screen active until challenge flow resolves.
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

    private fun configureChallengeUi() {
        if (challengeType != "math") {
            challengeTextView.text = "This challenge is not implemented yet."
            answerInput.hint = "Tap validate to stop (temporary)"
            validateButton.text = "Stop"
            validateButton.setOnClickListener {
                stopAlertSignals()
                finish()
            }
            return
        }

        generateMathChallenge()
    }

    private fun generateMathChallenge() {
        val useAddition = Random.nextBoolean()
        val (a, b) = when (difficulty) {
            "medium" -> if (useAddition) {
                Pair(Random.nextInt(10, 51), Random.nextInt(10, 51))
            } else {
                Pair(Random.nextInt(2, 13), Random.nextInt(2, 13))
            }

            "hard" -> if (useAddition) {
                Pair(Random.nextInt(20, 100), Random.nextInt(20, 100))
            } else {
                Pair(Random.nextInt(6, 21), Random.nextInt(6, 21))
            }

            else -> if (useAddition) {
                Pair(Random.nextInt(1, 10), Random.nextInt(1, 10))
            } else {
                Pair(Random.nextInt(1, 6), Random.nextInt(1, 6))
            }
        }

        if (useAddition) {
            expectedAnswer = a + b
            challengeTextView.text = "Solve: $a + $b"
        } else {
            expectedAnswer = a * b
            challengeTextView.text = "Solve: $a x $b"
        }
    }

    private fun validateMathAnswer() {
        if (challengeType != "math") {
            stopAlertSignals()
            finish()
            return
        }

        val userAnswer = answerInput.text.toString().trim().toIntOrNull()
        if (userAnswer == expectedAnswer) {
            stopAlertSignals()
            finish()
            return
        }

        Toast.makeText(this, "Wrong answer. Try again.", Toast.LENGTH_SHORT).show()
        answerInput.text?.clear()
        generateMathChallenge()
    }
}