package com.example.sunny

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class AlarmHistoryEntry(
    val id: String,
    val alarmId: String,
    val challengeType: String,
    val difficulty: String,
    val startedAtMillis: Long,
    val endedAtMillis: Long,
    val durationSeconds: Long,
    val status: String,
    val actionTaken: Boolean,
    val wrongAttempts: Int,
)

object AlarmHistoryStore {
    private const val prefsName = "sunny_alarm_history"
    private const val keyHistory = "entries_json"
    private const val maxEntries = 300

    fun addEntry(context: Context, entry: AlarmHistoryEntry) {
        val current = loadEntries(context).toMutableList()
        current.add(0, entry)
        val trimmed = if (current.size > maxEntries) {
            current.take(maxEntries)
        } else {
            current
        }
        saveEntries(context, trimmed)
    }

    fun listEntries(context: Context): List<Map<String, Any>> {
        return loadEntries(context).map { entry ->
            mapOf(
                "id" to entry.id,
                "alarmId" to entry.alarmId,
                "challengeType" to entry.challengeType,
                "difficulty" to entry.difficulty,
                "startedAtMillis" to entry.startedAtMillis,
                "endedAtMillis" to entry.endedAtMillis,
                "durationSeconds" to entry.durationSeconds,
                "status" to entry.status,
                "actionTaken" to entry.actionTaken,
                "wrongAttempts" to entry.wrongAttempts,
            )
        }
    }

    fun clear(context: Context) {
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .remove(keyHistory)
            .apply()
    }

    private fun loadEntries(context: Context): List<AlarmHistoryEntry> {
        val raw = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(keyHistory, "[]") ?: "[]"
        val array = JSONArray(raw)
        val entries = mutableListOf<AlarmHistoryEntry>()

        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            entries.add(
                AlarmHistoryEntry(
                    id = item.optString("id"),
                    alarmId = item.optString("alarmId"),
                    challengeType = item.optString("challengeType"),
                    difficulty = item.optString("difficulty"),
                    startedAtMillis = item.optLong("startedAtMillis"),
                    endedAtMillis = item.optLong("endedAtMillis"),
                    durationSeconds = item.optLong("durationSeconds"),
                    status = item.optString("status", "unknown"),
                    actionTaken = item.optBoolean("actionTaken", false),
                    wrongAttempts = item.optInt("wrongAttempts", 0),
                ),
            )
        }

        return entries
    }

    private fun saveEntries(context: Context, entries: List<AlarmHistoryEntry>) {
        val array = JSONArray().apply {
            entries.forEach { entry ->
                put(
                    JSONObject().apply {
                        put("id", entry.id)
                        put("alarmId", entry.alarmId)
                        put("challengeType", entry.challengeType)
                        put("difficulty", entry.difficulty)
                        put("startedAtMillis", entry.startedAtMillis)
                        put("endedAtMillis", entry.endedAtMillis)
                        put("durationSeconds", entry.durationSeconds)
                        put("status", entry.status)
                        put("actionTaken", entry.actionTaken)
                        put("wrongAttempts", entry.wrongAttempts)
                    },
                )
            }
        }

        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(keyHistory, array.toString())
            .apply()
    }
}