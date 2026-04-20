package com.example.sunny

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.ZoneId

data class AlarmData(
    val id: String,
    val hour: Int,
    val minute: Int,
    val enabled: Boolean,
    val challengeType: String,
    val difficulty: String,
)

object AlarmScheduler {
    private const val prefsName = "sunny_native_alarms"
    private const val keyAlarms = "alarms_json"

    fun syncAlarms(context: Context, alarms: List<AlarmData>) {
        saveAlarms(context, alarms)

        alarms.forEach { alarm ->
            if (alarm.enabled) {
                scheduleExactAlarm(context, alarm)
            } else {
                cancelAlarm(context, alarm.id)
            }
        }
    }

    fun restoreAfterBoot(context: Context) {
        loadAlarms(context)
            .filter { it.enabled }
            .forEach { scheduleExactAlarm(context, it) }
    }

    fun cancelAlarm(context: Context, id: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = buildPendingIntent(context, id, PendingIntent.FLAG_NO_CREATE)
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun scheduleExactAlarm(context: Context, alarm: AlarmData) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAtMillis = computeNextTriggerMillis(alarm.hour, alarm.minute)
        val pendingIntent = buildPendingIntent(
            context = context,
            id = alarm.id,
            flags = PendingIntent.FLAG_UPDATE_CURRENT,
            challengeType = alarm.challengeType,
            difficulty = alarm.difficulty,
        ) ?: return

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent,
        )
    }

    private fun buildPendingIntent(
        context: Context,
        id: String,
        flags: Int,
        challengeType: String = "math",
        difficulty: String = "easy",
    ): PendingIntent? {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.example.sunny.ACTION_TRIGGER_ALARM"
            putExtra("alarmId", id)
            putExtra("challengeType", challengeType)
            putExtra("difficulty", difficulty)
        }

        return PendingIntent.getBroadcast(
            context,
            id.hashCode(),
            intent,
            flags or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun computeNextTriggerMillis(hour: Int, minute: Int): Long {
        val now = LocalDateTime.now()
        var next = now.withHour(hour).withMinute(minute).withSecond(0).withNano(0)
        if (!next.isAfter(now)) {
            next = next.plusDays(1)
        }
        return next.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
    }

    private fun saveAlarms(context: Context, alarms: List<AlarmData>) {
        val json = JSONArray().apply {
            alarms.forEach { alarm ->
                put(
                    JSONObject().apply {
                        put("id", alarm.id)
                        put("hour", alarm.hour)
                        put("minute", alarm.minute)
                        put("enabled", alarm.enabled)
                        put("challengeType", alarm.challengeType)
                        put("difficulty", alarm.difficulty)
                    },
                )
            }
        }

        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(keyAlarms, json.toString())
            .apply()
    }

    private fun loadAlarms(context: Context): List<AlarmData> {
        val raw = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(keyAlarms, "[]") ?: "[]"
        val jsonArray = JSONArray(raw)

        val alarms = mutableListOf<AlarmData>()
        for (i in 0 until jsonArray.length()) {
            val item = jsonArray.getJSONObject(i)
            alarms.add(
                AlarmData(
                    id = item.optString("id"),
                    hour = item.optInt("hour"),
                    minute = item.optInt("minute"),
                    enabled = item.optBoolean("enabled", true),
                    challengeType = item.optString("challengeType", "math"),
                    difficulty = item.optString("difficulty", "easy"),
                ),
            )
        }
        return alarms
    }
}