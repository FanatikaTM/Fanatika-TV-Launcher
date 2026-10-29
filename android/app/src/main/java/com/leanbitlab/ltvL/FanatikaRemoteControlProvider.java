package com.omeda.arc;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.os.Process;
import org.json.JSONObject;

/** Restricted ADB-shell-only control endpoint. No general app can call it. */
public final class FanatikaRemoteControlProvider extends ContentProvider {
    private static final String PREFS = "fanatika_adb_control";
    private static final String[] BOOLEAN_KEYS = {"watch_next", "weather", "app_title", "center_favorites", "focus_glow"};
    private static final String[] TEXT_KEYS = {"title_font", "title_style", "plex_refresh_minutes", "title_weight", "title_spacing", "title_shadow", "title_outline"};
    private static final String[] FONTS = {"Automatic", "sans-serif", "sans-serif-condensed", "sans-serif-light", "sans-serif-medium", "sans-serif-black", "serif", "monospace", "cursive", "casual"};
    private static final String[] STYLES = {"Classic", "Bold", "Cinema", "Glass", "Glow", "Neon", "Minimal", "Wide", "Shadow", "Outline", "Elegant", "Sunset", "Steel"};
    private static boolean contains(String[] options, String value) { for (String v : options) if (v.equals(value)) return true; return false; }
    private static void allowedCaller() {
        int uid = Binder.getCallingUid();
        if (uid != Process.SHELL_UID && uid != Process.ROOT_UID && uid != Process.myUid())
            throw new SecurityException("Only an explicitly authorized Android Debug Bridge shell can use Fanatika controls.");
    }
    private SharedPreferences prefs() { return getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE); }
    @Override public boolean onCreate() { return true; }
    @Override public Bundle call(String method, String arg, Bundle extras) {
        allowedCaller();
        Bundle out = new Bundle();
        if ("ping".equals(method)) { out.putString("result", "Fanatika ADB bridge v1"); return out; }
        if ("backup".equals(method)) {
            prefs().edit().putBoolean("backup_requested", true).putString("backup_status", "pending").commit();
            out.putString("result", "backup queued; open launcher to save");
            return out;
        }
        if ("backup_status".equals(method)) {
            out.putString("result", prefs().getString("backup_status", "not-requested"));
            return out;
        }
        if ("status".equals(method)) {
            out.putString("result", prefs().getString("last_status", "not-yet-synced"));
            out.putString("settings", prefs().getString("confirmed", "{}"));
            return out;
        }
        if (!"set".equals(method) || arg == null || extras == null) throw new IllegalArgumentException("Expected set with a whitelisted key and value");
        String value = extras.getString("value", "");
        boolean boolKey = contains(BOOLEAN_KEYS, arg);
        if (boolKey && !("true".equals(value) || "false".equals(value))) throw new IllegalArgumentException("Boolean value required");
        if (!boolKey && !contains(TEXT_KEYS, arg)) throw new IllegalArgumentException("Unsupported option");
        if ("title_font".equals(arg) && !contains(FONTS,value)) throw new IllegalArgumentException("Unknown font");
        if ("title_style".equals(arg) && !contains(STYLES,value)) throw new IllegalArgumentException("Unknown style");
        if ("plex_refresh_minutes".equals(arg) && !("5".equals(value) || "15".equals(value) || "30".equals(value) || "60".equals(value))) throw new IllegalArgumentException("Invalid refresh interval");
        if ("title_weight".equals(arg) && !("0".equals(value) || "300".equals(value) || "400".equals(value) || "500".equals(value) || "600".equals(value) || "700".equals(value) || "800".equals(value) || "900".equals(value))) throw new IllegalArgumentException("Invalid title weight");
        if ("title_spacing".equals(arg) && !("-1.0".equals(value) || "0.0".equals(value) || "0.35".equals(value) || "1.0".equals(value) || "2.0".equals(value) || "3.0".equals(value) || "5.0".equals(value))) throw new IllegalArgumentException("Invalid title spacing");
        if ("title_shadow".equals(arg) && !("0.0".equals(value) || "0.5".equals(value) || "1.0".equals(value) || "1.5".equals(value) || "2.0".equals(value))) throw new IllegalArgumentException("Invalid shadow strength");
        if ("title_outline".equals(arg) && !("0.0".equals(value) || "0.5".equals(value) || "1.0".equals(value) || "1.5".equals(value) || "2.0".equals(value) || "3.0".equals(value))) throw new IllegalArgumentException("Invalid outline thickness");
        try {
            synchronized(FanatikaRemoteControlProvider.class) {
                JSONObject pending = new JSONObject(prefs().getString("pending", "{}"));
                pending.put(arg, value);
                if (!prefs().edit().putString("pending", pending.toString()).putString("last_status", "queued").commit()) throw new IllegalStateException("Cannot queue setting");
            }
            out.putString("result", "queued; open Fanatika to apply");
            return out;
        } catch (Exception e) { throw new IllegalStateException("Unable to queue settings", e); }
    }
    public static boolean consumeBackup(Context context) {
        synchronized(FanatikaRemoteControlProvider.class) {
            SharedPreferences p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            boolean result = p.getBoolean("backup_requested", false);
            if (result) p.edit().remove("backup_requested").commit();
            return result;
        }
    }
    public static void backupStatus(Context context, String status) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("backup_status", status).apply();
    }
    public static String consume(Context context) {
        synchronized(FanatikaRemoteControlProvider.class) {
            SharedPreferences p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            String pending = p.getString("pending", "{}");
            p.edit().remove("pending").commit();
            return pending;
        }
    }
    public static void confirmed(Context context, String json) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("confirmed", json).putString("last_status", "applied").apply();
    }
    @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String order) { allowedCaller(); throw new UnsupportedOperationException(); }
    @Override public String getType(Uri uri) { allowedCaller(); return null; }
    @Override public Uri insert(Uri uri, ContentValues values) { allowedCaller(); throw new UnsupportedOperationException(); }
    @Override public int delete(Uri uri, String selection, String[] args) { allowedCaller(); throw new UnsupportedOperationException(); }
    @Override public int update(Uri uri, ContentValues values, String selection, String[] args) { allowedCaller(); throw new UnsupportedOperationException(); }
}
