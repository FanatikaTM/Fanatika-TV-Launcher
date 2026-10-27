@echo off
setlocal
set "TV=192.168.4.105:5555"
echo Read-only source selector diagnostics for Xiaomi MiTV-M0EU0
adb connect %TV%
adb -s %TV% shell getprop ro.product.model
adb -s %TV% shell cmd package query-activities -a com.android.tv.action.VIEW_INPUTS
adb -s %TV% shell cmd package query-activities -a android.intent.action.TV_INPUT
adb -s %TV% shell cmd package query-activities -a android.settings.TV_INPUT_SETTINGS
echo Now press the TV's physical Input Source button, then run:
echo adb -s %TV% shell dumpsys activity activities
pause
