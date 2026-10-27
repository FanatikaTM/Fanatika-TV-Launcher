/*
 * Fanatika TV Launcher sleep tools. GPL-3.0-or-later.
 * Deliberately uses user-approved Device Administrator force-lock instead of
 * privileged PowerManager or shell commands. Android TV may lock, sleep or
 * refuse the request depending on firmware. No HOME/POWER key interception.
 */
package com.omeda.arc;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.SystemClock;
import android.provider.Settings;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityManager;
import android.accessibilityservice.AccessibilityServiceInfo;

import java.util.HashMap;
import java.util.Map;

public final class FanatikaSleepController {
    private static final String PREFS = "fanatika_sleep_settings";
    private static final String SHORTCUT = "long_press_key";
    private static final String DEADLINE = "timer_deadline_elapsed";
    private static final long HOLD_MS = 1050L;
    private static long triggeredDownTime = -1L;
    private static long lastTriggeredAt = -10000L;

    private FanatikaSleepController() {}

    static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static ComponentName admin(Context ctx) {
        return new ComponentName(ctx, FanatikaSleepAdminReceiver.class);
    }

    public static boolean supportsAdmin(Context context) {
        // OEMs sometimes omit FEATURE_DEVICE_ADMIN even if the DPM service exists.
        // Actual enablement is determined by the system approval activity.
        return context.getSystemService(Context.DEVICE_POLICY_SERVICE) != null;
    }

    public static boolean adminActive(Context context) {
        DevicePolicyManager dpm = (DevicePolicyManager) context.getSystemService(Context.DEVICE_POLICY_SERVICE);
        return dpm != null && dpm.isAdminActive(admin(context));
    }

    public static boolean accessibilityActive(Context context) {
        AccessibilityManager manager = (AccessibilityManager) context.getSystemService(Context.ACCESSIBILITY_SERVICE);
        if (manager == null) return false;
        for (AccessibilityServiceInfo info : manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)) {
            if (info.getResolveInfo() != null && info.getResolveInfo().serviceInfo != null
                    && context.getPackageName().equals(info.getResolveInfo().serviceInfo.packageName)
                    && FanatikaSleepKeyService.class.getName().equals(info.getResolveInfo().serviceInfo.name)) {
                return true;
            }
        }
        return false;
    }

    public static boolean isAllowedKey(int key) {
        return key == 0 || key == KeyEvent.KEYCODE_MENU || key == KeyEvent.KEYCODE_INFO
                || key == KeyEvent.KEYCODE_GUIDE || key == KeyEvent.KEYCODE_PROG_RED
                || key == KeyEvent.KEYCODE_PROG_GREEN || key == KeyEvent.KEYCODE_PROG_YELLOW
                || key == KeyEvent.KEYCODE_PROG_BLUE;
    }

    public static Map<String, Object> status(Context context) {
        Map<String, Object> result = new HashMap<>();
        result.put("deviceAdminSupported", supportsAdmin(context));
        result.put("deviceAdminActive", adminActive(context));
        result.put("accessibilityActive", accessibilityActive(context));
        result.put("shortcutKey", prefs(context).getInt(SHORTCUT, 0));
        long deadline = prefs(context).getLong(DEADLINE, 0);
        long remaining = deadline == 0 ? 0 : Math.max(0L, deadline - SystemClock.elapsedRealtime());
        result.put("remainingSeconds", (int)Math.min(Integer.MAX_VALUE, (remaining + 999) / 1000));
        return result;
    }

    public static Map<String, Object> requestAdmin(Activity activity) {
        if (!supportsAdmin(activity)) return answer(false, "Device Administrator is unavailable on this TV.");
        if (adminActive(activity)) return answer(true, "Device Administrator is already enabled.");
        Intent intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin(activity));
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Optional: permit the launcher to lock/sleep the display after your chosen long-press shortcut or sleep timer. You can revoke access in Android settings.");
        try {
            activity.startActivity(intent);
            return answer(true, "Approve the permission on your TV, then return and refresh status.");
        } catch (Exception e) {
            return answer(false, "TV cannot open Device Administrator activation: " + e.getClass().getSimpleName());
        }
    }

    public static Map<String, Object> openAccessibility(Activity activity) {
        try {
            activity.startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            return answer(true, "Enable TV Sleep Shortcut in Android Accessibility settings only if you want global remote key handling.");
        } catch (Exception e) {
            return answer(false, "Android TV does not expose Accessibility settings on this device.");
        }
    }

    public static Map<String, Object> setShortcut(Context context, int keyCode) {
        if (!isAllowedKey(keyCode)) return answer(false, "Reserved or unsupported key. HOME, Power, Back, arrows and volume are protected.");
        prefs(context).edit().putInt(SHORTCUT, keyCode).apply();
        return answer(true, keyCode == 0 ? "Shortcut disabled." : "Long-press shortcut saved. Some TV remotes do not forward this key to apps.");
    }

    public static Map<String, Object> sleepNow(Context context) {
        if (!adminActive(context)) return answer(false, "Enable the optional Device Administrator permission first. No sleep command was sent.");
        DevicePolicyManager dpm = (DevicePolicyManager) context.getSystemService(Context.DEVICE_POLICY_SERVICE);
        if (dpm == null) return answer(false, "Device policy service unavailable.");
        try {
            // A manual sleep or shortcut cancels any pending timer to avoid a
            // second lock request after the TV is awakened.
            cancel(context);
            dpm.lockNow();
            return answer(true, "Android accepted lockNow(). The TV may enter standby, show a lock screen, or ignore it depending on firmware.");
        } catch (SecurityException e) {
            return answer(false, "Android denied force-lock permission. No privileged ADB fallback will be attempted.");
        } catch (Exception e) {
            return answer(false, "Standby request failed: " + e.getClass().getSimpleName());
        }
    }

    private static PendingIntent timerIntent(Context context) {
        Intent intent = new Intent(context, FanatikaSleepAlarmReceiver.class);
        return PendingIntent.getBroadcast(context, 1992, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    public static Map<String, Object> schedule(Context context, int minutes) {
        if (minutes != 15 && minutes != 30 && minutes != 45 && minutes != 60 && minutes != 90 && minutes != 120 && minutes != 180) {
            return answer(false, "Unsupported timer. Select 15, 30, 45, 60, 90, 120 or 180 minutes.");
        }
        if (!adminActive(context)) return answer(false, "Enable Device Administrator before setting a sleep timer.");
        AlarmManager alarm = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarm == null) return answer(false, "Android alarm service unavailable.");
        long deadline = SystemClock.elapsedRealtime() + minutes * 60000L;
        try {
            alarm.set(AlarmManager.ELAPSED_REALTIME, deadline, timerIntent(context));
            prefs(context).edit().putLong(DEADLINE, deadline).apply();
            return answer(true, "Sleep request scheduled for about " + minutes + " minutes. Android may delay it for power savings.");
        } catch (Exception e) {
            return answer(false, "Could not schedule sleep: " + e.getClass().getSimpleName());
        }
    }

    public static Map<String, Object> cancel(Context context) {
        AlarmManager alarm = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarm != null) alarm.cancel(timerIntent(context));
        prefs(context).edit().remove(DEADLINE).apply();
        return answer(true, "Sleep timer cancelled.");
    }

    static void onAlarm(Context context) {
        prefs(context).edit().remove(DEADLINE).apply();
        if (adminActive(context)) sleepNow(context);
    }

    public static synchronized boolean handleRemoteKey(Context context, KeyEvent event) {
        int selected = prefs(context).getInt(SHORTCUT, 0);
        if (selected == 0 || event.getKeyCode() != selected) return false;
        if (event.getAction() == KeyEvent.ACTION_UP) {
            return false; // Never block normal key-up or short-press behavior.
        }
        if (event.getAction() != KeyEvent.ACTION_DOWN || event.getRepeatCount() == 0) return false;
        if (event.getEventTime() - event.getDownTime() < HOLD_MS) return false;
        long now = SystemClock.elapsedRealtime();
        if (triggeredDownTime == event.getDownTime() || now - lastTriggeredAt < 4000L) return true;
        if (!adminActive(context)) return false; // Never claim to have slept the TV.
        triggeredDownTime = event.getDownTime();
        lastTriggeredAt = now;
        sleepNow(context);
        return true;
    }

    private static Map<String, Object> answer(boolean ok, String message) {
        Map<String, Object> map = new HashMap<>();
        map.put("ok", ok);
        map.put("message", message);
        return map;
    }
}
