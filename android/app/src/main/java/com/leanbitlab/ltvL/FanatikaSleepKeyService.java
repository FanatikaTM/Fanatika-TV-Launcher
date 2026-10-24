package com.omeda.arc;

import android.accessibilityservice.AccessibilityService;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;

/** Optional, manually enabled global key listener. Reads no window content. */
public class FanatikaSleepKeyService extends AccessibilityService {
    @Override public void onAccessibilityEvent(AccessibilityEvent event) { /* unused */ }
    @Override public void onInterrupt() { /* unused */ }
    @Override protected boolean onKeyEvent(KeyEvent event) {
        return FanatikaSleepController.handleRemoteKey(this, event);
    }
}
