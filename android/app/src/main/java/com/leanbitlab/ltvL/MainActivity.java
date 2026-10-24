/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.omeda.arc;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.*;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.provider.Settings;
import android.util.Pair;
import android.media.tv.TvContract;
import android.media.tv.TvInputManager;
import android.media.tv.TvInputInfo;
import android.content.ComponentName;
import android.content.ActivityNotFoundException;
import android.database.Cursor;
import android.Manifest;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.FileProvider;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.ByteArrayOutputStream;
import java.io.File;
import android.app.usage.NetworkStats;
import android.app.usage.NetworkStatsManager;
import android.app.AppOpsManager;
import android.os.RemoteException;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletionService;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class MainActivity extends FlutterActivity {
    private static final int FANATIKA_SAVE_JSON = 9321;
    private static final int FANATIKA_READ_JSON = 9322;
    private static final int FANATIKA_PICK_APK = 9323;
    private MethodChannel.Result fanatikaPending;
    private String fanatikaExportPayload;

    private final String METHOD_CHANNEL = "me.efesser.flauncher/method";
    private final String APPS_EVENT_CHANNEL = "me.efesser.flauncher/event_apps";
    private final String NETWORK_EVENT_CHANNEL = "me.efesser.flauncher/event_network";
    private static final String PERMISSION_READ_TV_LISTINGS = "android.permission.READ_TV_LISTINGS";
    private static final int REQUEST_CODE_READ_TV_LISTINGS = 1001;
    private static final String COLUMN_ASPECT_RATIO = "aspect_ratio";

    @Override
    public boolean onKeyDown(int keyCode, android.view.KeyEvent event) {
        if (FanatikaSleepController.handleRemoteKey(this, event)) return true;
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

        new MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "fanatikaSaveBackup" -> fanatikaChooseDocument(result, false, (String)call.arguments());
                case "fanatikaReadBackup" -> fanatikaChooseDocument(result, true, null);
                case "fanatikaPickUpdateApk" -> fanatikaPickUpdate(result);
                case "fanatikaSleepStatus" -> result.success(FanatikaSleepController.status(this));
                case "fanatikaRequestSleepAdmin" -> result.success(FanatikaSleepController.requestAdmin(this));
                case "fanatikaOpenSleepAccessibility" -> result.success(FanatikaSleepController.openAccessibility(this));
                case "fanatikaSleepNow" -> result.success(FanatikaSleepController.sleepNow(this));
                case "fanatikaSleepTimer" -> {
                    Number minutes = call.argument("minutes");
                    result.success(FanatikaSleepController.schedule(this, minutes == null ? 0 : minutes.intValue()));
                }
                case "fanatikaCancelSleepTimer" -> result.success(FanatikaSleepController.cancel(this));
                case "fanatikaSetSleepShortcut" -> {
                    Number key = call.argument("keyCode");
                    result.success(FanatikaSleepController.setShortcut(this, key == null ? -1 : key.intValue()));
                }
                case "getApplications" -> result.success(getApplications());
                case "getTvInputs" -> result.success(getTvInputs());
                case "openTvInput" -> result.success(openTvInput(call.arguments()));
                case "openTvSourcePicker" -> result.success(openTvSourcePicker());
                case "tryXiaomiHdmi" -> result.success(tryXiaomiHdmi(call.arguments()));
                case "getApplicationBanner" -> result.success(getApplicationBanner(call.arguments()));
                case "getApplicationIcon" -> result.success(getApplicationIcon(call.arguments()));
                case "applicationExists" -> result.success(applicationExists(call.arguments()));
                case "launchActivityFromAction" -> result.success(launchActivityFromAction(call.arguments()));
                case "launchApp" -> result.success(launchApp(call.arguments()));
                case "openSettings" -> result.success(openSettings());
                case "installApk" -> result.success(installApk(call.arguments()));
                case "requestInstallUnknownAppsPermission" -> {
                    requestInstallUnknownAppsPermission();
                    result.success(null);
                }
                case "openScreensaverSettings" -> result.success(openScreensaverSettings());
                case "openAppInfo" -> result.success(openAppInfo(call.arguments()));
                case "uninstallApp" -> result.success(uninstallApp(call.arguments()));
                case "isDefaultLauncher" -> result.success(isDefaultLauncher());
                case "checkForGetContentAvailability" -> result.success(checkForGetContentAvailability());
                case "startAmbientMode" -> result.success(startAmbientMode());
                case "getActiveNetworkInformation" -> result.success(getActiveNetworkInformation());
                case "getDailyWifiUsage" -> {
                    long usage = getDailyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getWeeklyWifiUsage" -> {
                    long usage = getWeeklyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getMonthlyWifiUsage" -> {
                    long usage = getMonthlyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "checkUsageStatsPermission" -> result.success(checkUsageStatsPermission());
                case "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission();
                    result.success(null);
                }
                case "checkWriteSettingsPermission" -> result.success(checkWriteSettingsPermission());
                case "requestWriteSettingsPermission" -> {
                    requestWriteSettingsPermission();
                    result.success(null);
                }
                case "setSystemBrightness" -> {
                    int brightness = call.argument("brightness");
                    result.success(setSystemBrightness(brightness));
                }
                case "openWifiSettings" -> result.success(openWifiSettings());
                case "getMediaStoreImages" -> result.success(getMediaStoreImages());
                case "getMediaStoreVideos" -> result.success(getMediaStoreVideos());
                case "getMediaStoreVideoThumbnail" -> {
                    Number id = call.argument("id");
                    String path = call.argument("path");
                    result.success(getMediaStoreVideoThumbnail(
                        id != null ? id.longValue() : -1, path));
                }
                case "checkMediaPermissions" -> result.success(checkMediaPermissions());
                case "requestMediaPermissions" -> {
                    requestMediaPermissions();
                    result.success(null);
                }
                case "checkWatchNextPermission" -> result.success(checkWatchNextPermission());
                case "requestWatchNextPermission" -> {
                    requestWatchNextPermission();
                    result.success(null);
                }
                case "getWatchNextItems" -> {
                    int limit = call.arguments() != null ? (int) call.arguments() : 10;
                    result.success(getWatchNextItems(limit));
                }
                case "launchWatchNextItem" -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> args = (Map<String, Object>) call.arguments();
                    if (args != null) {
                        String packageName = (String) args.get("packageName");
                        String contentId = (String) args.get("contentId");
                        String action = (String) args.get("action");
                        result.success(launchWatchNextItem(packageName, contentId, action));
                    } else {
                        result.success(false);
                    }
                }
                case "loadContentUriImage" -> {
                    String contentUri = (String) call.arguments();
                    if (contentUri != null) {
                        result.success(loadContentUriImage(contentUri));
                    } else {
                        result.success(new byte[0]);
                    }
                }
                default -> throw new IllegalArgumentException("Unknown method: " + call.method);
            }
        });

        new EventChannel(messenger, APPS_EVENT_CHANNEL).setStreamHandler(
                new LauncherAppsEventStreamHandler(this));

        new EventChannel(messenger, NETWORK_EVENT_CHANNEL).setStreamHandler(
                new NetworkEventStreamHandler(this));
    }


    // Android Storage Access Framework: the user decides where backups are saved.
    private void fanatikaChooseDocument(MethodChannel.Result result, boolean read, String content) {
        if (fanatikaPending != null) { result.error("BUSY", "File picker already open", null); return; }
        fanatikaPending = result;
        fanatikaExportPayload = content;
        try {
            Intent intent = new Intent(read ? Intent.ACTION_OPEN_DOCUMENT : Intent.ACTION_CREATE_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("application/json");
            if (!read) intent.putExtra(Intent.EXTRA_TITLE, "fanatika-backup.json");
            startActivityForResult(intent, read ? FANATIKA_READ_JSON : FANATIKA_SAVE_JSON);
        } catch (Exception ex) {
            fanatikaPending = null;
            result.error("PICKER_UNAVAILABLE", ex.getMessage(), null);
        }
    }

    private void fanatikaPickUpdate(MethodChannel.Result result) {
        if (fanatikaPending != null) { result.error("BUSY", "File picker already open", null); return; }
        fanatikaPending = result;
        try {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("application/vnd.android.package-archive");
            startActivityForResult(intent, FANATIKA_PICK_APK);
        } catch (Exception ex) {
            fanatikaPending = null;
            result.error("PICKER_UNAVAILABLE", ex.getMessage(), null);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FANATIKA_SAVE_JSON && requestCode != FANATIKA_READ_JSON && requestCode != FANATIKA_PICK_APK) return;
        MethodChannel.Result callback = fanatikaPending;
        fanatikaPending = null;
        if (callback == null) return;
        if (resultCode != RESULT_OK || data == null || data.getData() == null) {
            callback.success(null);
            return;
        }
        Uri uri = data.getData();
        try {
            if (requestCode == FANATIKA_SAVE_JSON) {
                if (fanatikaExportPayload == null || fanatikaExportPayload.length() > 2000000)
                    throw new IllegalArgumentException("Backup too large");
                try (java.io.OutputStream out = getContentResolver().openOutputStream(uri, "wt")) {
                    if (out == null) throw new java.io.IOException("Cannot write file");
                    out.write(fanatikaExportPayload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                }
                callback.success(true);
            } else if (requestCode == FANATIKA_READ_JSON) {
                try (java.io.InputStream in = getContentResolver().openInputStream(uri)) {
                    if (in == null) throw new java.io.IOException("Cannot read file");
                    java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();
                    byte[] buffer = new byte[8192];
                    int size;
                    while ((size = in.read(buffer)) != -1) {
                        if (output.size() + size > 2000000) throw new java.io.IOException("File too large");
                        output.write(buffer, 0, size);
                    }
                    callback.success(output.toString("UTF-8"));
                }
            } else {
                File cache = new File(getCacheDir(), "fanatika-reviewed-update.apk");
                try (java.io.InputStream in = getContentResolver().openInputStream(uri);
                     java.io.OutputStream out = new java.io.FileOutputStream(cache)) {
                    if (in == null) throw new java.io.IOException("Cannot read selected APK");
                    byte[] buffer = new byte[16384];
                    int n;
                    long total = 0;
                    while ((n = in.read(buffer)) != -1) {
                        total += n;
                        if (total > 200000000) throw new java.io.IOException("APK too large");
                        out.write(buffer, 0, n);
                    }
                }
                PackageInfo apkInfo = getPackageManager().getPackageArchiveInfo(cache.getAbsolutePath(), 0);
                if (apkInfo == null || !getPackageName().equals(apkInfo.packageName)) {
                    cache.delete();
                    throw new SecurityException("This APK is not Fanatika TV Launcher");
                }
                callback.success(cache.getAbsolutePath());
            }
        } catch (Exception ex) {
            callback.error("FILE_ERROR", ex.getMessage(), null);
        } finally {
            fanatikaExportPayload = null;
        }
    }

    // TV Input Framework: read-only discovery; third-party apps do not have the
    // system TV application's privileges to tune arbitrary hardware inputs.
    private List<Map<String, Object>> getTvInputs() {
        List<Map<String, Object>> outputs = new ArrayList<>();
        if (Build.VERSION.SDK_INT < 21) return outputs;
        try {
            TvInputManager manager = (TvInputManager) getSystemService(Context.TV_INPUT_SERVICE);
            if (manager == null) return outputs;
            for (TvInputInfo tvInput : manager.getTvInputList()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", tvInput.getId());
                CharSequence title = tvInput.loadLabel(MainActivity.this);
                item.put("label", title != null ? title.toString() : tvInput.getId());
                item.put("type", tvInput.getType());
                item.put("passthrough", tvInput.isPassthroughInput());
                try { item.put("state", manager.getInputState(tvInput.getId())); }
                catch (Exception ignored) { item.put("state", -1); }
                outputs.add(item);
            }
        } catch (Exception e) {
            android.util.Log.w("FanatikaSources", "Unable to list TV inputs", e);
        }
        return outputs;
    }

    // Requests that the installed TV player handle a passthrough source. This
    // deliberately never claims that the hardware changed source.
    private Map<String, Object> openTvInput(Object requested) {
        Map<String, Object> response = new HashMap<>();
        response.put("opened", false);
        if (!(requested instanceof String)) { response.put("detail", "Invalid source"); return response; }
        String id = (String) requested;
        try {
            TvInputManager manager = (TvInputManager) getSystemService(Context.TV_INPUT_SERVICE);
            TvInputInfo input = manager != null ? manager.getTvInputInfo(id) : null;
            if (input == null || !input.isPassthroughInput()) {
                response.put("detail", "Input isn't an available HDMI/passthrough source");
                return response;
            }
            Intent intent = new Intent(Intent.ACTION_VIEW, TvContract.buildChannelUriForPassthroughInput(id));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            response.put("opened", true);
            response.put("detail", "Sent to TV player; confirm that the source changed");
        } catch (ActivityNotFoundException ex) {
            response.put("detail", "No TV app handles standard HDMI switching on this device");
        } catch (Exception ex) {
            response.put("detail", "Unable to open TV input: " + ex.getClass().getSimpleName());
        }
        return response;
    }

    // OEMs expose different source menus; these intents are not guaranteed on
    // every Android TV. Never fall back to disabling or modifying launchers.
    private Map<String, Object> openTvSourcePicker() {
        Map<String, Object> response = new HashMap<>();
        response.put("opened", false);
        String[] actions = {"android.intent.action.TV_INPUT", "android.settings.TV_INPUT_SETTINGS"};
        for (String action : actions) {
            try {
                Intent intent = new Intent(action);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                if (intent.resolveActivity(getPackageManager()) != null) {
                    startActivity(intent);
                    response.put("opened", true);
                    response.put("detail", "Opened available TV input menu/settings");
                    return response;
                }
            } catch (Exception ignored) { }
        }
        response.put("detail", "This TV does not expose an input picker to third-party launchers. Use the remote INPUT button or TV settings.");
        return response;
    }

    // Explicit opt-in for selected Xiaomi models. These values are documented
    // on some Xiaomi TV models, NOT verified on MiTV-MOSR4 firmware.
    // Never silently use this path; the Flutter screen requires confirmation.
    private Map<String, Object> tryXiaomiHdmi(Object request) {
        Map<String, Object> response = new HashMap<>();
        response.put("opened", false);
        if (!(request instanceof Map)) { response.put("detail", "Invalid request"); return response; }
        Map<?, ?> args = (Map<?, ?>) request;
        Object idObject = args.get("id");
        if (!(idObject instanceof String)) { response.put("detail", "Invalid input ID"); return response; }
        String id = (String) idObject;
        String device = (Build.MANUFACTURER + " " + Build.MODEL).toLowerCase(java.util.Locale.ROOT);
        if (!(device.contains("xiaomi") || device.contains("mitv"))) {
            response.put("detail", "Experimental switch is restricted to Xiaomi TVs"); return response;
        }
        try {
            TvInputManager manager = (TvInputManager) getSystemService(Context.TV_INPUT_SERVICE);
            TvInputInfo info = manager != null ? manager.getTvInputInfo(id) : null;
            if (info == null || info.getType() != TvInputInfo.TYPE_HDMI) {
                response.put("detail", "Only a detected HDMI source can be selected"); return response;
            }
            String label = String.valueOf(info.loadLabel(MainActivity.this)).toLowerCase(java.util.Locale.ROOT);
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("hdmi\\s*([123])").matcher(label);
            if (!matcher.find()) {
                response.put("detail", "HDMI port number could not be verified; use TV remote INPUT"); return response;
            }
            int port = Integer.parseInt(matcher.group(1));
            int vendorCode = 22 + port;
            Intent intent = new Intent("com.xiaomi.mitv.tvplayer.EXTSRC_PLAY");
            intent.setComponent(new ComponentName("com.xiaomi.mitv.tvplayer", "com.xiaomi.mitv.tvplayer.ExternalSourceActivity"));
            intent.putExtra("input", vendorCode);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            response.put("opened", true);
            response.put("detail", "Experimental Xiaomi HDMI request sent; verify the selected port on the television");
        } catch (ActivityNotFoundException ex) {
            response.put("detail", "Xiaomi TV player source activity is unavailable on this firmware");
        } catch (Exception ex) {
            response.put("detail", "Xiaomi input request failed: " + ex.getClass().getSimpleName());
        }
        return response;
    }

    private List<Map<String, Serializable>> getApplications() {
        ExecutorService executor = Executors.newFixedThreadPool(4);
        CompletionService<Pair<Boolean, List<ResolveInfo>>> queryIntentActivitiesCompletionService = new ExecutorCompletionService<>(
                executor);
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(false, queryIntentActivities(false)));
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(true, queryIntentActivities(true)));
        List<ResolveInfo> tvActivitiesInfo = null;
        List<ResolveInfo> nonTvActivitiesInfo = null;

        int completed = 0;
        while (completed < 2) {
            try {
                var activitiesInfo = queryIntentActivitiesCompletionService.take().get();

                if (!activitiesInfo.first) {
                    tvActivitiesInfo = activitiesInfo.second;
                } else {
                    nonTvActivitiesInfo = activitiesInfo.second;
                }
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                completed += 1;
            }
        }

        CompletionService<Map<String, Serializable>> completionService = new ExecutorCompletionService<>(executor);

        List<Map<String, Serializable>> applications = new ArrayList<>(
                tvActivitiesInfo.size() + nonTvActivitiesInfo.size());

        boolean settingsPresent = false;
        int appCount = 0;
        for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
            if (!settingsPresent) {
                settingsPresent = tvActivityInfo.activityInfo.packageName.equals("com.android.tv.settings");
            }

            completionService.submit(() -> buildAppMap(tvActivityInfo.activityInfo, false, null));
            appCount += 1;
        }

        for (ResolveInfo nonTvActivityInfo : nonTvActivitiesInfo) {
            boolean nonDuplicate = true;

            if (!settingsPresent) {
                settingsPresent = nonTvActivityInfo.activityInfo.packageName.equals("com.android.settings");
            }

            for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
                if (tvActivityInfo.activityInfo.packageName.equals(nonTvActivityInfo.activityInfo.packageName)) {
                    nonDuplicate = false;
                    break;
                }
            }

            if (nonDuplicate) {
                appCount += 1;
                completionService.submit(() -> buildAppMap(nonTvActivityInfo.activityInfo, true, null));
            }
        }

        while (appCount > 0) {
            try {
                Future<Map<String, Serializable>> appMap = completionService.take();
                applications.add(appMap.get());
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                appCount -= 1;
            }
        }

        executor.shutdown();

        if (!settingsPresent) {
            PackageManager packageManager = getPackageManager();
            Intent settingsIntent = new Intent(Settings.ACTION_SETTINGS);
            ActivityInfo activityInfo = settingsIntent.resolveActivityInfo(packageManager, 0);

            if (activityInfo != null) {
                applications.add(buildAppMap(activityInfo, false, Settings.ACTION_SETTINGS));
            }
        }

        return applications;
    }

    public Map<String, Serializable> getApplication(String packageName) {
        Map<String, Serializable> map = Map.of();
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        if (intent != null) {
            ActivityInfo activityInfo = intent.resolveActivityInfo(getPackageManager(), 0);

            if (activityInfo != null) {
                map = buildAppMap(activityInfo, false, null);
            }
        }

        return map;
    }

    private byte[] getApplicationBanner(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            // Many TV apps (e.g. Free TV, S0undTV) declare android:banner on their leanback activity
            // only; getActivityBanner falls back to the application banner when the activity has none.
            Intent leanbackIntent = packageManager.getLeanbackLaunchIntentForPackage(packageName);
            Drawable drawable = leanbackIntent != null ? packageManager.getActivityBanner(leanbackIntent) : null;
            if (drawable == null) {
                drawable = info.loadBanner(packageManager);
            }

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private byte[] getApplicationIcon(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadIcon(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private boolean applicationExists(String packageName) {
        int flags;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            flags = PackageManager.MATCH_UNINSTALLED_PACKAGES;
        } else {
            flags = PackageManager.GET_UNINSTALLED_PACKAGES;
        }

        try {
            getPackageManager().getApplicationInfo(packageName, flags);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private List<ResolveInfo> queryIntentActivities(boolean sideloaded) {
        String category;
        if (sideloaded) {
            category = Intent.CATEGORY_LAUNCHER;
        } else {
            category = Intent.CATEGORY_LEANBACK_LAUNCHER;
        }

        // NOTE: Would be nice to query the applications that match *either* of the
        // above categories
        // but from the addCategory function documentation, it says that it will "use
        // activities
        // that provide *all* the requested categories"
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .addCategory(category);

        return getPackageManager()
                .queryIntentActivities(intent, 0);
    }

    private Map<String, Serializable> buildAppMap(ActivityInfo activityInfo, boolean sideloaded, String action) {
        PackageManager packageManager = getPackageManager();

        String applicationName = activityInfo.loadLabel(packageManager).toString(),
                applicationVersionName = "";
        try {
            applicationVersionName = packageManager.getPackageInfo(activityInfo.packageName, 0).versionName;
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        Map<String, Serializable> appMap = new HashMap<>();
        appMap.put("name", applicationName);
        appMap.put("packageName", activityInfo.packageName);
        appMap.put("version", applicationVersionName);
        appMap.put("sideloaded", sideloaded);

        if (action != null) {
            appMap.put("action", action);
        }
        return appMap;
    }

    private boolean launchActivityFromAction(String action) {
        return tryStartActivity(new Intent(action));
    }

    private boolean launchApp(String packageName) {
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        return tryStartActivity(intent);
    }

    private boolean openSettings() {
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean installApk(String apkPath) {
        File apkFile = new File(apkPath);
        if (!apkFile.exists()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !getPackageManager().canRequestPackageInstalls()) {
            return false;
        }

        Uri apkUri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                apkFile
        );

        Intent installIntent = new Intent(Intent.ACTION_VIEW)
                .setDataAndType(apkUri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        return tryStartActivity(installIntent);
    }

    private void requestInstallUnknownAppsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                    .setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean openAppInfo(String packageName) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean uninstallApp(String packageName) {
        Intent intent = new Intent(Intent.ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean checkForGetContentAvailability() {
        List<ResolveInfo> intentActivities = getPackageManager().queryIntentActivities(
                new Intent(Intent.ACTION_GET_CONTENT, null).setTypeAndNormalize("image/*"),
                0);

        return !intentActivities.isEmpty();
    }

    private boolean isDefaultLauncher() {
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
        ResolveInfo defaultLauncher = getPackageManager().resolveActivity(intent, 0);

        if (defaultLauncher != null && defaultLauncher.activityInfo != null) {
            return defaultLauncher.activityInfo.packageName.equals(getPackageName());
        }

        return false;
    }

    private boolean startAmbientMode() {
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .setClassName("com.android.systemui", "com.android.systemui.Somnambulator");

        return tryStartActivity(intent);
    }

    private Map<String, Object> getActiveNetworkInformation() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetwork());
        } else {
            // noinspection deprecation
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetworkInfo());
        }
    }

    private boolean tryStartActivity(Intent intent) {
        boolean success = true;

        try {
            startActivity(intent);
        } catch (Exception ignored) {
            success = false;
        }

        return success;
    }

    private byte[] drawableToByteArray(Drawable drawable) {
        if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) {
            return new byte[0];
        }

        Bitmap bitmap;
        if (drawable instanceof BitmapDrawable bitmapDrawable) {
            bitmap = bitmapDrawable.getBitmap();
        } else {
            bitmap = drawableToBitmap(drawable);
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        return stream.toByteArray();
    }

    Bitmap drawableToBitmap(Drawable drawable) {
        Bitmap bitmap = Bitmap.createBitmap(
                drawable.getIntrinsicWidth(),
                drawable.getIntrinsicHeight(),
                Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    private long getDailyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getWeeklyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_WEEK, calendar.getFirstDayOfWeek());
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getMonthlyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_MONTH, 1);
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private boolean checkUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private void requestUsageStatsPermission() {
        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        tryStartActivity(intent);
    }

    private boolean checkWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.System.canWrite(this);
        }
        return true;
    }

    private void requestWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean setSystemBrightness(int brightness) {
        if (checkWriteSettingsPermission()) {
            try {
                android.content.ContentResolver resolver = getContentResolver();
                // 1. Standard Android brightness
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS, brightness);
                
                // 2. Try common TV "Backlight" keys (Vendor specific)
                Settings.System.putInt(resolver, "backlight", brightness);
                Settings.System.putInt(resolver, "backlight_level", brightness);
                
                return true;
            } catch (Exception e) {
                // Ignore errors on specific keys as they may not exist
                return true;
            }
        }
        return false;
    }

    private boolean openWifiSettings() {
        // 1. Try Android Q+ WiFi panel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent panelIntent = new Intent(Settings.Panel.ACTION_WIFI);
            if (tryStartActivity(panelIntent)) {
                return true;
            }
        }

        // 2. Try standard WiFi settings
        Intent wifiIntent = new Intent(Settings.ACTION_WIFI_SETTINGS);
        if (tryStartActivity(wifiIntent)) {
            return true;
        }

        // 3. Fallback to general wireless settings
        Intent wirelessIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
        if (tryStartActivity(wirelessIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openScreensaverSettings() {
        // 1. Try Android TV specific screensaver settings (DaydreamActivity - from
        // Aerial Views)
        Intent tvIntent = new Intent(Intent.ACTION_MAIN);
        tvIntent.setClassName("com.android.tv.settings",
                "com.android.tv.settings.device.display.daydream.DaydreamActivity");
        if (tryStartActivity(tvIntent)) {
            return true;
        }

        // 2. Try standard Android screensaver/dream settings
        Intent dreamIntent = new Intent(Settings.ACTION_DREAM_SETTINGS);
        if (tryStartActivity(dreamIntent)) {
            return true;
        }

        // 3. FALLBACK: Try Display Settings (often contains screensaver on newer
        // Android TV/Google TV)
        Intent displayIntent = new Intent(Settings.ACTION_DISPLAY_SETTINGS);
        if (tryStartActivity(displayIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean checkWatchNextPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }
        return checkSelfPermission(PERMISSION_READ_TV_LISTINGS) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestWatchNextPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return;
        }
        if (checkWatchNextPermission()) {
            return;
        }
        ActivityCompat.requestPermissions(
                this,
                new String[]{PERMISSION_READ_TV_LISTINGS},
                REQUEST_CODE_READ_TV_LISTINGS);
    }

    private List<Map<String, Object>> getWatchNextItems(int limit) {
        List<Map<String, Object>> items = new ArrayList<>();

        if (!checkWatchNextPermission()) {
            android.util.Log.w("MainActivity", "READ_TV_LISTINGS permission not granted");
            return items;
        }

        try {
            String[] projection = {
                TvContract.WatchNextPrograms._ID,
                TvContract.WatchNextPrograms.COLUMN_TITLE,
                TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION,
                TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI,
                TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME,
                TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
                TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS,
                TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
                TvContract.WatchNextPrograms.COLUMN_INTENT_URI,
                TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE
            };

            String sortOrder = TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS + " DESC";

            try (Cursor cursor = getContentResolver().query(
                    TvContract.WatchNextPrograms.CONTENT_URI,
                    projection,
                    null,
                    null,
                    sortOrder)) {

                if (cursor != null && cursor.moveToFirst()) {
                    int count = 0;
                    int fetchLimit = Math.max(limit * 3, 30);

                    do {
                        try {
                            Map<String, Object> item = new HashMap<>();

                            int idIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms._ID);
                            int titleIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_TITLE);
                            int descIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION);
                            int posterIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI);
                            int pkgIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME);
                            int contentIdIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID);
                            int durationIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS);
                            int lastEngIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS);
                            int intentUriIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_INTENT_URI);
                            int watchTypeIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE);
                            int aspectRatioIndex = cursor.getColumnIndex(COLUMN_ASPECT_RATIO);

                            String title = (titleIndex >= 0 && !cursor.isNull(titleIndex))
                                ? cursor.getString(titleIndex) : null;
                            if (title == null || title.isEmpty()) {
                                continue;
                            }

                            item.put("id", idIndex >= 0 ? cursor.getLong(idIndex) : 0);
                            item.put("title", title);
                            item.put("description", (descIndex >= 0 && !cursor.isNull(descIndex))
                                ? cursor.getString(descIndex) : null);
                            item.put("posterUri", (posterIndex >= 0 && !cursor.isNull(posterIndex))
                                ? cursor.getString(posterIndex) : null);
                            item.put("packageName", (pkgIndex >= 0 && !cursor.isNull(pkgIndex))
                                ? cursor.getString(pkgIndex) : null);
                            item.put("contentId", (contentIdIndex >= 0 && !cursor.isNull(contentIdIndex))
                                ? cursor.getString(contentIdIndex) : null);
                            item.put("duration", (durationIndex >= 0 && !cursor.isNull(durationIndex))
                                ? cursor.getInt(durationIndex) : null);

                            item.put("intentUri", (intentUriIndex >= 0 && !cursor.isNull(intentUriIndex))
                                ? cursor.getString(intentUriIndex) : null);

                            item.put("watchNextType", (watchTypeIndex >= 0 && !cursor.isNull(watchTypeIndex))
                                ? cursor.getInt(watchTypeIndex) : 0);

                            item.put("aspectRatio", (aspectRatioIndex >= 0 && !cursor.isNull(aspectRatioIndex))
                                ? cursor.getString(aspectRatioIndex) : null);

                            if (lastEngIndex >= 0 && !cursor.isNull(lastEngIndex)) {
                                item.put("lastEngagementDate", cursor.getLong(lastEngIndex));
                            }

                            item.put("progressPercent", 0);

                            items.add(item);
                            count++;
                        } catch (Exception rowEx) {
                            android.util.Log.w("MainActivity", "Error parsing Watch Next row", rowEx);
                        }
                    } while (cursor.moveToNext() && count < fetchLimit);
                }
            }
        } catch (SecurityException e) {
            android.util.Log.w("MainActivity", "SecurityException when querying Watch Next: " + e.getMessage());
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error querying Watch Next", e);
        }

        return items.subList(0, Math.min(items.size(), limit));
    }

    private boolean launchWatchNextItem(String packageName, String contentId, String action) {
        android.util.Log.d("MainActivity", "launchWatchNextItem: packageName=" + packageName + ", contentId=" + contentId + ", action=" + action);

        // Try to use the intent action/uri from arguments first
        if (action != null && !action.isEmpty()) {
            try {
                Intent intent;
                if (action.startsWith("intent://")) {
                    android.util.Log.d("MainActivity", "Parsing intent URI: " + action);
                    intent = Intent.parseUri(action, Intent.URI_INTENT_SCHEME);
                } else if (action.startsWith("content://") || action.startsWith("http://") || action.startsWith("https://")) {
                    android.util.Log.d("MainActivity", "Creating VIEW intent for URI: " + action);
                    intent = new Intent(Intent.ACTION_VIEW, Uri.parse(action));
                } else if (action.contains(":")) {
                    try {
                        android.util.Log.d("MainActivity", "Trying to parse as intent URI: " + action);
                        intent = Intent.parseUri(action, Intent.URI_INTENT_SCHEME);
                    } catch (Exception e) {
                        android.util.Log.w("MainActivity", "Failed to parse as intent URI, treating as action: " + action);
                        intent = new Intent(action);
                    }
                } else {
                    android.util.Log.d("MainActivity", "Creating intent with action: " + action);
                    intent = new Intent(action);
                }

                if (packageName != null) {
                    intent.setPackage(packageName);
                    android.util.Log.d("MainActivity", "Set package to: " + packageName);
                }
                if (contentId != null) {
                    intent.putExtra("contentId", contentId);
                    android.util.Log.d("MainActivity", "Added contentId extra: " + contentId);
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                android.util.Log.d("MainActivity", "Starting activity with intent: " + intent.toUri(0));
                return tryStartActivity(intent);
            } catch (Exception e) {
                android.util.Log.e("MainActivity", "Failed to launch with action/uri: " + action, e);
            }
        }

        // Fallback to package name
        if (packageName == null) {
            android.util.Log.w("MainActivity", "No package name or action available, cannot launch");
            return false;
        }

        try {
            android.util.Log.d("MainActivity", "Falling back to package launch: " + packageName);
            PackageManager pm = getPackageManager();
            Intent intent = pm.getLeanbackLaunchIntentForPackage(packageName);
            if (intent == null) {
                intent = pm.getLaunchIntentForPackage(packageName);
            }

            if (intent != null) {
                if (contentId != null) {
                    intent.putExtra("contentId", contentId);
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                return tryStartActivity(intent);
            } else {
                android.util.Log.w("MainActivity", "No launch intent found for package: " + packageName);
            }
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error launching Watch Next item for package: " + packageName, e);
        }

        return false;
    }

    /**
     * Load image bytes from a content:// URI
     */
    private byte[] loadContentUriImage(String contentUri) {
        android.util.Log.d("MainActivity", "Loading content URI image: " + contentUri);
        try {
            android.net.Uri uri = android.net.Uri.parse(contentUri);
            android.util.Log.d("MainActivity", "Parsed URI: " + uri);

            try (java.io.InputStream inputStream = getContentResolver().openInputStream(uri)) {
                if (inputStream != null) {
                    java.io.ByteArrayOutputStream byteArrayOutputStream = new java.io.ByteArrayOutputStream();
                    byte[] buffer = new byte[8192];  // Increased buffer size
                    int length;
                    while ((length = inputStream.read(buffer)) != -1) {
                        byteArrayOutputStream.write(buffer, 0, length);
                    }
                    byte[] result = byteArrayOutputStream.toByteArray();
                    android.util.Log.d("MainActivity", "Loaded " + result.length + " bytes from content URI");
                    return result;
                } else {
                    android.util.Log.w("MainActivity", "openInputStream returned null for: " + contentUri);
                }
            }
        } catch (SecurityException e) {
            android.util.Log.w("MainActivity", "SecurityException loading content URI: " + e.getMessage());
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error loading content URI image: " + contentUri, e);
        }
        android.util.Log.w("MainActivity", "Returning empty byte array for: " + contentUri);
        return new byte[0];
    }

    private static final int MEDIA_PERMISSION_REQUEST_CODE = 9001;

    private boolean checkMediaPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return checkSelfPermission(Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
                && checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED;
        }
        return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestMediaPermissions() {
        String[] permissions;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions = new String[]{
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            };
        } else {
            permissions = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE};
        }
        ActivityCompat.requestPermissions(this, permissions, MEDIA_PERMISSION_REQUEST_CODE);
    }

    private List<Map<String, Object>> getMediaStoreImages() {
        List<Map<String, Object>> images = new ArrayList<>();
        String[] projection = {
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED
        };
        String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";

        try (Cursor cursor = getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection, null, null, sortOrder)) {
            if (cursor != null) {
                int idCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
                int nameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME);
                int dataCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                while (cursor.moveToNext()) {
                    long id = cursor.getLong(idCol);
                    Uri contentUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", id);
                    item.put("name", cursor.getString(nameCol));
                    item.put("path", cursor.getString(dataCol));
                    item.put("uri", contentUri.toString());
                    images.add(item);
                }
            }
        } catch (Exception ignored) {
        }
        return images;
    }

    private List<Map<String, Object>> getMediaStoreVideos() {
        List<Map<String, Object>> videos = new ArrayList<>();
        String[] projection = {
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_ADDED
        };
        String sortOrder = MediaStore.Video.Media.DATE_ADDED + " DESC";

        try (Cursor cursor = getContentResolver().query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection, null, null, sortOrder)) {
            if (cursor != null) {
                int idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID);
                int nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME);
                int dataCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA);
                while (cursor.moveToNext()) {
                    long id = cursor.getLong(idCol);
                    Uri contentUri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", id);
                    item.put("name", cursor.getString(nameCol));
                    item.put("path", cursor.getString(dataCol));
                    item.put("uri", contentUri.toString());
                    videos.add(item);
                }
            }
        } catch (Exception ignored) {
        }
        return videos;
    }

    private byte[] getMediaStoreVideoThumbnail(long id, String path) {
        Bitmap bitmap = null;
        try {
            if (id >= 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Uri uri = android.content.ContentUris.withAppendedId(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id);
                bitmap = getContentResolver().loadThumbnail(
                    uri, new android.util.Size(256, 256), null);
            }
        } catch (Exception ignored) {
        }

        if (bitmap == null && path != null && !path.isEmpty()) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    bitmap = android.media.ThumbnailUtils.createVideoThumbnail(
                        new File(path), new android.util.Size(256, 256), null);
                } else {
                    bitmap = android.media.ThumbnailUtils.createVideoThumbnail(
                        path, MediaStore.Images.Thumbnails.MINI_KIND);
                }
            } catch (Exception ignored) {
            }
        }

        if (bitmap == null && path != null && !path.isEmpty()) {
            android.media.MediaMetadataRetriever retriever = null;
            try {
                retriever = new android.media.MediaMetadataRetriever();
                retriever.setDataSource(path);
                bitmap = retriever.getFrameAtTime(0);
            } catch (Exception ignored) {
            } finally {
                try {
                    if (retriever != null) retriever.release();
                } catch (Exception ignored) {
                }
            }
        }

        if (bitmap == null) return null;
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream);
        bitmap.recycle();
        return stream.toByteArray();
    }

}
