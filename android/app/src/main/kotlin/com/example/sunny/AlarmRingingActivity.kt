package com.example.sunny

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.provider.MediaStore
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.View
import android.view.WindowManager
import android.widget.EditText
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import kotlin.random.Random

class AlarmRingingActivity : Activity() {
    companion object {
        private const val requestCapturePhoto = 1001
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val volumeHandler = Handler(Looper.getMainLooper())
    private var currentVolume = 0.15f
    private val volumeStepRunnable = object : Runnable {
        override fun run() {
            currentVolume = (currentVolume + 0.1f).coerceAtMost(1.0f)
            mediaPlayer?.setVolume(currentVolume, currentVolume)
            if (currentVolume < 1.0f) {
                volumeHandler.postDelayed(this, 4000)
            }
        }
    }

    private var expectedAnswer: Int = 0

    private lateinit var challengeTextView: TextView
    private lateinit var answerInput: EditText
    private lateinit var validateButton: Button

    private lateinit var challengeType: String
    private lateinit var difficulty: String

    private var photoCaptured = false
    private var challengeCompleted = false
    private var allowTemporaryBackground = false

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

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (!challengeCompleted && !allowTemporaryBackground) {
            Toast.makeText(this, "Complete the challenge to stop the alarm.", Toast.LENGTH_SHORT).show()
            relaunchSelfIfNeeded()
        }
    }

    override fun onStop() {
        super.onStop()
        if (!challengeCompleted && !allowTemporaryBackground && !isFinishing) {
            relaunchSelfIfNeeded()
        }
    }

    override fun onDestroy() {
        stopAlertSignals()
        super.onDestroy()
    }

    private fun startAlertSignals() {
        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        try {
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmRingingActivity, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                isLooping = true
                prepare()
                setVolume(currentVolume, currentVolume)
                start()
            }

            volumeHandler.postDelayed(volumeStepRunnable, 4000)
        } catch (error: Exception) {
            Toast.makeText(this, "Unable to start alarm sound.", Toast.LENGTH_SHORT).show()
        }

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
        volumeHandler.removeCallbacks(volumeStepRunnable)

        mediaPlayer?.let { player ->
            if (player.isPlaying) {
                player.stop()
            }
            player.release()
        }
        mediaPlayer = null

        vibrator?.cancel()
    }

    private fun configureChallengeUi() {
        when (challengeType) {
            "math" -> {
                answerInput.visibility = View.VISIBLE
                validateButton.text = "Validate"
                validateButton.setOnClickListener { validateMathAnswer() }
                generateMathChallenge()
            }

            "photo" -> {
                answerInput.visibility = View.GONE
                challengeTextView.text = "Take a photo to stop the alarm."
                validateButton.text = "Take photo"
                validateButton.setOnClickListener { launchCamera() }
            }

            "quote" -> {
                answerInput.visibility = View.GONE
                challengeTextView.text = randomQuote()
                validateButton.text = "I have read"
                validateButton.setOnClickListener { completeChallenge() }
            }

            else -> {
                // Unknown challenge types fallback to math so alarm cannot be dismissed trivially.
                answerInput.visibility = View.VISIBLE
                validateButton.text = "Validate"
                validateButton.setOnClickListener { validateMathAnswer() }
                generateMathChallenge()
            }
        }
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
        val userAnswer = answerInput.text.toString().trim().toIntOrNull()
        if (userAnswer == expectedAnswer) {
            completeChallenge()
            return
        }

        Toast.makeText(this, "Wrong answer. Try again.", Toast.LENGTH_SHORT).show()
        answerInput.text?.clear()
        generateMathChallenge()
    }

    private fun launchCamera() {
        val captureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (captureIntent.resolveActivity(packageManager) == null) {
            Toast.makeText(this, "No camera app found.", Toast.LENGTH_SHORT).show()
            return
        }
        allowTemporaryBackground = true
        startActivityForResult(captureIntent, requestCapturePhoto)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        allowTemporaryBackground = false

        if (requestCode == requestCapturePhoto && resultCode == RESULT_OK) {
            photoCaptured = true
            if (photoCaptured) {
                completeChallenge()
            }
        }
    }

    private fun randomQuote(): String {
        val quotes = listOf(
            "Rise up and keep moving. Small steps count.",
            "Today is a gift. Use it with purpose.",
            "Discipline beats motivation when the alarm rings.",
            "Start strong. Your future self will thank you.",
        )
        return quotes.random()
    }

    private fun completeChallenge() {
        challengeCompleted = true
        stopAlertSignals()
        finish()
    }

    private fun relaunchSelfIfNeeded() {
        val relaunchIntent = Intent(this, AlarmRingingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("challengeType", challengeType)
            putExtra("difficulty", difficulty)
        }
        startActivity(relaunchIntent)
    }
}