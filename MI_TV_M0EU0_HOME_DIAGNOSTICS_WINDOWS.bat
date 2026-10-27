@echo off
setlocal
set TV=192.168.4.105:5555
echo Read-only HOME diagnostics for MiTV-M0EU0 on %TV%
adb connect %TV%
adb -s %TV% shell getprop ro.product.model
adb -s %TV% shell cmd role get-role-holders android.app.role.HOME
adb -s %TV% shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
adb -s %TV% shell cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME
adb -s %TV% shell dumpsys activity activities
pause
