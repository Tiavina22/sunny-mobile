package com.example.sunny

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            AlarmScheduler.restoreAfterBoot(context)
            return
        }

        val ringIntent = Intent(context, AlarmRingingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("alarmId", intent.getStringExtra("alarmId"))
            putExtra("challengeType", intent.getStringExtra("challengeType"))
            putExtra("difficulty", intent.getStringExtra("difficulty"))
        }
        context.startActivity(ringIntent)
    }
}