package com.omeda.arc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Scheduled sleep alarms don't survive reboot; clear stale status. */
public class FanatikaSleepBootReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            FanatikaSleepController.prefs(context).edit().remove("timer_deadline_elapsed").apply();
        }
    }
}
