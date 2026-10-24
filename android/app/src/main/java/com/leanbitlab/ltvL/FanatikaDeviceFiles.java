package com.omeda.arc;

import android.Manifest;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.location.Location;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.storage.StorageManager;
import android.os.storage.StorageVolume;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import io.flutter.plugin.common.MethodChannel;

public final class FanatikaDeviceFiles {
    private FanatikaDeviceFiles() {}
    static Map<String, Object> outcome(boolean ok, String message) {
        Map<String, Object> obj = new HashMap<>(); obj.put("ok", ok); obj.put("message", message); return obj;
    }
    static List<Map<String, Object>> usbVolumes(Activity activity) {
        List<Map<String, Object>> found = new ArrayList<>();
        if (Build.VERSION.SDK_INT < 24) return found;
        StorageManager manager = (StorageManager) activity.getSystemService(Context.STORAGE_SERVICE);
        if (manager == null) return found;
        try {
            for (StorageVolume volume : manager.getStorageVolumes()) {
                if (!volume.isRemovable()) continue;
                Map<String, Object> info = new HashMap<>();
                info.put("description", volume.getDescription(activity));
                info.put("state", volume.getState());
                found.add(info);
            }
        } catch (Exception ignored) {} // Permission-free informational view only.
        return found;
    }
    static void approximateLocation(Activity activity, MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < 23 || activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            result.success(outcome(false, "Approximate location permission required. Select Request permission in Weather settings.")); return;
        }
        LocationManager lm = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);
        if (lm == null) { result.success(outcome(false, "This TV provides no Android location service. Use manual city.")); return; }
        try {
            Location best = null;
            for (String provider : lm.getProviders(true)) {
                Location cached = lm.getLastKnownLocation(provider);
                // Avoid displaying weather based on an old location from a different household.
                if (cached != null && System.currentTimeMillis() - cached.getTime() < 24L*60*60*1000 &&
                    (best == null || cached.getTime() > best.getTime())) best = cached;
            }
            if (best != null) { result.success(locationMap(best)); return; }
            if (Build.VERSION.SDK_INT >= 30) {
                String provider = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ? LocationManager.NETWORK_PROVIDER
                    : lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ? LocationManager.GPS_PROVIDER : null;
                if (provider == null) { result.success(outcome(false, "Location is disabled or unavailable on this TV. Use manual city.")); return; }
                AtomicBoolean delivered = new AtomicBoolean(false);
                Handler handler = new Handler(Looper.getMainLooper());
                handler.postDelayed(() -> {
                    if (delivered.compareAndSet(false,true)) result.success(outcome(false, "Location timed out. Use manual city."));
                }, 12000);
                lm.getCurrentLocation(provider, null, activity.getMainExecutor(), loc -> {
                    if (delivered.compareAndSet(false,true)) result.success(loc == null
                        ? outcome(false, "No location fix. Use manual city.") : locationMap(loc));
                });
            } else {
                result.success(outcome(false, "No recent location fix. Enter a city manually."));
            }
        } catch (SecurityException ex) { result.success(outcome(false, "Approximate location permission denied.")); }
          catch (Exception ex) { result.success(outcome(false, "Location unavailable on this TV.")); }
    }
    private static Map<String, Object> locationMap(Location fix) {
        Map<String, Object> value = outcome(true, "Approximate location available for weather.");
        // Coarsen position before sending to weather API; no precise tracking.
        value.put("latitude", Math.round(fix.getLatitude()*10.0)/10.0);
        value.put("longitude", Math.round(fix.getLongitude()*10.0)/10.0);
        return value;
    }
    static Map<String, Object> copySelectedImageToGallery(Activity activity, Uri uri) throws Exception {
        if (Build.VERSION.SDK_INT < 29) return outcome(false, "USB image import requires Android 10+ on this build.");
        String mime = activity.getContentResolver().getType(uri);
        if (!"image/jpeg".equals(mime) && !"image/png".equals(mime) && !"image/webp".equals(mime))
            return outcome(false, "Only JPG, PNG and WEBP wallpapers are supported.");
        String ext = "image/png".equals(mime) ? ".png" : "image/webp".equals(mime) ? ".webp" : ".jpg";
        String name = "fanatika-usb-" + System.currentTimeMillis() + ext;
        ContentValues meta = new ContentValues();
        meta.put(MediaStore.MediaColumns.DISPLAY_NAME, name);
        meta.put(MediaStore.MediaColumns.MIME_TYPE, mime);
        meta.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Fanatika/");
        Uri outUri = activity.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, meta);
        if (outUri == null) throw new java.io.IOException("TV picture storage unavailable");
        try (InputStream in = activity.getContentResolver().openInputStream(uri);
             OutputStream out = activity.getContentResolver().openOutputStream(outUri)) {
            if (in == null || out == null) throw new java.io.IOException("Cannot read USB image");
            byte[] buffer = new byte[16_384]; int n; long total=0;
            while ((n=in.read(buffer)) != -1) {
                total+=n; if (total > 40L*1024*1024) throw new java.io.IOException("Image exceeds 40 MB");
                out.write(buffer,0,n);
            }
        } catch (Exception ex) { activity.getContentResolver().delete(outUri,null,null); throw ex; }
        return outcome(true, "Wallpaper saved to Pictures/Fanatika. Select it from Arc wallpaper gallery.");
    }
    static Map<String, Object> readBackup(Activity activity, Uri uri) throws Exception {
        try (InputStream in = activity.getContentResolver().openInputStream(uri)) {
            if (in == null) throw new java.io.IOException("Cannot open USB backup");
            byte[] buf = new byte[8192]; int n; int total = 0;
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            while ((n=in.read(buf)) != -1) {
                total += n; if (total > 2_000_000) throw new java.io.IOException("Backup exceeds 2 MB");
                out.write(buf, 0, n);
            }
            Map<String, Object> data = outcome(true, "USB backup loaded. Review before restoring.");
            data.put("backup", out.toString("UTF-8")); return data;
        }
    }
}
