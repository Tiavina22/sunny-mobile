package com.example.sunny

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "sunny/alarm"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"syncAlarms" -> {
						val raw = call.arguments as? List<*> ?: emptyList<Any>()
						val alarms = raw.mapNotNull { item ->
							val map = item as? Map<*, *> ?: return@mapNotNull null
							AlarmData(
								id = map["id"] as? String ?: return@mapNotNull null,
								hour = (map["hour"] as? Number)?.toInt() ?: return@mapNotNull null,
								minute = (map["minute"] as? Number)?.toInt() ?: return@mapNotNull null,
								enabled = map["enabled"] as? Boolean ?: true,
								challengeType = map["challengeType"] as? String ?: "math",
								difficulty = map["difficulty"] as? String ?: "easy",
							)
						}

						AlarmScheduler.syncAlarms(this, alarms)
						result.success(null)
					}

					"getAlarmHistory" -> {
						result.success(AlarmHistoryStore.listEntries(this))
					}

					"clearAlarmHistory" -> {
						AlarmHistoryStore.clear(this)
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}
	}
}
