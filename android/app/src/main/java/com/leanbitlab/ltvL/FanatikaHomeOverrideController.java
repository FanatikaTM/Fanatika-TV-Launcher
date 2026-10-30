package com.omeda.arc;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import android.view.accessibility.AccessibilityManager;
import android.accessibilityservice.AccessibilityServiceInfo;
import java.util.HashMap;
import java.util.Map;

/** One-time setup and reversible preferences for the optional HOME override. */
public final class FanatikaHomeOverrideController {
    private FanatikaHomeOverrideController() {}
    public static Map<String, Object> status(Context c) {
        Map<String, Object> result = new HashMap<>();
        result.put("requested", FanatikaHomeOverrideService.isRequested(c));
        result.put("active", active(c));
        result.put("package", c.getPackageName());
        result.put("service", new ComponentName(c, FanatikaHomeOverrideService.class).flattenToString());
        result.put("message", active(c) ? "HOME override is enabled in Android Accessibility. Press HOME to test."
            : "One-time approval required: enable Fanatika HOME Override in Android Accessibility settings.");
        return result;
    }
    public static boolean active(Context c) {
        AccessibilityManager manager = (AccessibilityManager) c.getSystemService(Context.ACCESSIBILITY_SERVICE);
        if (manager == null) return false;
        for (AccessibilityServiceInfo item : manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)) {
            if (item.getResolveInfo() == null || item.getResolveInfo().serviceInfo == null) continue;
            if (c.getPackageName().equals(item.getResolveInfo().serviceInfo.packageName)
                && FanatikaHomeOverrideService.class.getName().equals(item.getResolveInfo().serviceInfo.name)) return true;
        }
        return false;
    }
    public static Map<String, Object> setEnabled(Context c, boolean enabled) {
        c.getSharedPreferences(FanatikaHomeOverrideService.PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean(FanatikaHomeOverrideService.ENABLED, enabled).apply();
        return status(c);
    }
    public static Map<String, Object> openSettings(Activity a) {
        try {
            a.startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            return status(a);
        } catch (RuntimeException e) {
            Map<String, Object> result = status(a);
            result.put("message", "TV Accessibility settings could not be opened: " + e.getClass().getSimpleName());
            return result;
        }
    }
    public static Map<String, Object> openAppInfo(Activity a) {
        try {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:" + a.getPackageName()));
            a.startActivity(intent);
        } catch (RuntimeException ignored) { }
        return status(a);
    }
}
