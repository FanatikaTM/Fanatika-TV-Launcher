package com.omeda.arc;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityEvent;

/**
 * Optional, TV-owner-authorized HOME redirect for Google TV firmware that ignores
 * the Android HOME role. Does not read screen content, intercept remote keys,
 * modify default-home roles, or disable any OEM system package.
 */
public final class FanatikaHomeOverrideService extends AccessibilityService {
    static final String PREFS = "fanatika_home_override";
    static final String ENABLED = "home_override_enabled";
    private static final String GOOGLE_HOME_PACKAGE = "com.google.android.apps.tv.launcherx";
    private static final String GOOGLE_HOME = "com.google.android.apps.tv.launcherx.home.HomeActivity";
    private static final String GOOGLE_VANILLA = "com.google.android.apps.tv.launcherx.home.VanillaModeHomeActivity";
    private final Handler main = new Handler(Looper.getMainLooper());
    private long lastLaunchElapsed = -10000L;
    private Runnable pending;

    static boolean isRequested(android.content.Context context) {
        return context.getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean(ENABLED, true);
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null || event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        // Never redirect other TV apps, setup/recovery activities, or Settings.
        final String packageName = event.getPackageName() == null ? "" : event.getPackageName().toString();
        final String className = event.getClassName() == null ? "" : event.getClassName().toString();
        if (!GOOGLE_HOME_PACKAGE.equals(packageName)
                || (!GOOGLE_HOME.equals(className) && !GOOGLE_VANILLA.equals(className))) {
            // A new foreground window cancels a pending redirect.
            if (pending != null) { main.removeCallbacks(pending); pending = null; }
            return;
        }
        if (!isRequested(this)) return;
        if (!getPackageName().equals("com.fanatika.tvlauncher")) return; // release only
        if (SystemClock.elapsedRealtime() - lastLaunchElapsed < 1700L) return;
        if (pending != null) main.removeCallbacks(pending);
        pending = () -> {
            pending = null;
            if (!isRequested(this)) return;
            lastLaunchElapsed = SystemClock.elapsedRealtime();
            Intent target = new Intent(this, MainActivity.class);
            target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            try { startActivity(target); }
            catch (RuntimeException ignored) {
                // Android 14/OEM may deny background launches; leave OEM HOME intact.
            }
        };
        // Let the system finish its HOME transition before launching Fanatika.
        main.postDelayed(pending, 120L);
    }

    @Override public void onInterrupt() {
        if (pending != null) main.removeCallbacks(pending);
        pending = null;
    }
    @Override public void onDestroy() { onInterrupt(); super.onDestroy(); }
}
