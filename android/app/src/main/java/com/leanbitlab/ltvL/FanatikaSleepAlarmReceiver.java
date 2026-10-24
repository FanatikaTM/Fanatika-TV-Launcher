package com.omeda.arc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Single inexact sleep alarm; no service keeps the television awake. */
public class FanatikaSleepAlarmReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        FanatikaSleepController.onAlarm(context);
    }
}
