param(
    [Parameter(Mandatory = $true)]
    [string]$StatePath,

    [Parameter(Mandatory = $true)]
    [string]$StopPath,

    [int]$IntervalMs = 16
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ScreenStudioLiteNative
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);

    [DllImport("user32.dll")]
    public static extern bool GetGUIThreadInfo(uint idThread, ref GUITHREADINFO guiThreadInfo);

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct GUITHREADINFO
    {
        public int cbSize;
        public int flags;
        public IntPtr hwndActive;
        public IntPtr hwndFocus;
        public IntPtr hwndCapture;
        public IntPtr hwndMenuOwner;
        public IntPtr hwndMoveSize;
        public IntPtr hwndCaret;
        public RECT rcCaret;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref RECT pvParam, int fWinIni);
}
"@

[ScreenStudioLiteNative]::SetProcessDPIAware() | Out-Null

$stateDir = Split-Path -Parent $StatePath
if ($stateDir -and -not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

$eventId = 0
$keyEventId = 0
$lastKeyCombo = ""
$leftWasDown = $false
$rightWasDown = $false
$middleWasDown = $false

function Test-KeyDown {
    param([int]$VirtualKey)
    return ([ScreenStudioLiteNative]::GetAsyncKeyState($VirtualKey) -band 0x8000) -ne 0
}

$keyNames = @{
    0x08 = "Backspace"; 0x09 = "Tab"; 0x0D = "Enter"; 0x1B = "Esc"; 0x20 = "Space";
    0x25 = "Left"; 0x26 = "Up"; 0x27 = "Right"; 0x28 = "Down"; 0x2E = "Delete";
    0x30 = "0"; 0x31 = "1"; 0x32 = "2"; 0x33 = "3"; 0x34 = "4"; 0x35 = "5"; 0x36 = "6"; 0x37 = "7"; 0x38 = "8"; 0x39 = "9";
    0x41 = "A"; 0x42 = "B"; 0x43 = "C"; 0x44 = "D"; 0x45 = "E"; 0x46 = "F"; 0x47 = "G"; 0x48 = "H"; 0x49 = "I"; 0x4A = "J"; 0x4B = "K"; 0x4C = "L"; 0x4D = "M";
    0x4E = "N"; 0x4F = "O"; 0x50 = "P"; 0x51 = "Q"; 0x52 = "R"; 0x53 = "S"; 0x54 = "T"; 0x55 = "U"; 0x56 = "V"; 0x57 = "W"; 0x58 = "X"; 0x59 = "Y"; 0x5A = "Z";
    0x70 = "F1"; 0x71 = "F2"; 0x72 = "F3"; 0x73 = "F4"; 0x74 = "F5"; 0x75 = "F6"; 0x76 = "F7"; 0x77 = "F8"; 0x78 = "F9"; 0x79 = "F10"; 0x7A = "F11"; 0x7B = "F12";
    0xBA = ";"; 0xBB = "="; 0xBC = ","; 0xBD = "-"; 0xBE = "."; 0xBF = "/"; 0xC0 = "Backtick"; 0xDB = "["; 0xDC = "Backslash"; 0xDD = "]"; 0xDE = "Quote"
}

function Get-KeyCombo {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Test-KeyDown 0x11) -or (Test-KeyDown 0xA2) -or (Test-KeyDown 0xA3)) { $parts.Add("Ctrl") }
    if ((Test-KeyDown 0x12) -or (Test-KeyDown 0xA4) -or (Test-KeyDown 0xA5)) { $parts.Add("Alt") }
    if ((Test-KeyDown 0x10) -or (Test-KeyDown 0xA0) -or (Test-KeyDown 0xA1)) { $parts.Add("Shift") }
    if ((Test-KeyDown 0x5B) -or (Test-KeyDown 0x5C)) { $parts.Add("Win") }

    foreach ($code in $keyNames.Keys | Sort-Object) {
        if (Test-KeyDown ([int]$code)) {
            $name = $keyNames[$code]
            if ($name -notin @("Ctrl", "Alt", "Shift", "Win")) {
                $parts.Add($name)
                break
            }
        }
    }

    if ($parts.Count -eq 0) {
        return ""
    }

    return ($parts -join "+")
}

function Get-CaretSnapshot {
    $result = [ordered]@{
        Valid = 0
        X = 0
        Y = 0
        Width = 0
        Height = 0
    }

    $foreground = [ScreenStudioLiteNative]::GetForegroundWindow()
    if ($foreground -eq [IntPtr]::Zero) {
        return $result
    }

    $threadId = [ScreenStudioLiteNative]::GetWindowThreadProcessId($foreground, [IntPtr]::Zero)
    if ($threadId -eq 0) {
        return $result
    }

    $info = New-Object ScreenStudioLiteNative+GUITHREADINFO
    $info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($info)
    if (-not [ScreenStudioLiteNative]::GetGUIThreadInfo($threadId, [ref]$info)) {
        return $result
    }

    if ($info.hwndCaret -eq [IntPtr]::Zero) {
        return $result
    }

    $topLeft = New-Object ScreenStudioLiteNative+POINT
    $topLeft.X = $info.rcCaret.Left
    $topLeft.Y = $info.rcCaret.Top
    $bottomRight = New-Object ScreenStudioLiteNative+POINT
    $bottomRight.X = $info.rcCaret.Right
    $bottomRight.Y = $info.rcCaret.Bottom

    if (-not [ScreenStudioLiteNative]::ClientToScreen($info.hwndCaret, [ref]$topLeft)) {
        return $result
    }
    if (-not [ScreenStudioLiteNative]::ClientToScreen($info.hwndCaret, [ref]$bottomRight)) {
        return $result
    }

    $width = [Math]::Abs($bottomRight.X - $topLeft.X)
    $height = [Math]::Abs($bottomRight.Y - $topLeft.Y)
    if ($width -le 0 -and $height -le 0) {
        return $result
    }

    $result.Valid = 1
    $result.X = [int][Math]::Round(($topLeft.X + $bottomRight.X) / 2)
    $result.Y = [int][Math]::Round(($topLeft.Y + $bottomRight.Y) / 2)
    $result.Width = [int]$width
    $result.Height = [int]$height
    return $result
}

function Write-StateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $bytes = [System.Text.Encoding]::ASCII.GetBytes($Content)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
    try {
        $stream.SetLength(0)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally {
        $stream.Dispose()
    }
}

while (-not (Test-Path -LiteralPath $StopPath)) {
    $point = New-Object ScreenStudioLiteNative+POINT
    [ScreenStudioLiteNative]::GetCursorPos([ref]$point) | Out-Null

    $leftDown = Test-KeyDown 0x01
    $rightDown = Test-KeyDown 0x02
    $middleDown = Test-KeyDown 0x04
    $button = 0

    if ($leftDown -and -not $leftWasDown) {
        $eventId += 1
        $button = 1
    } elseif ($rightDown -and -not $rightWasDown) {
        $eventId += 1
        $button = 2
    } elseif ($middleDown -and -not $middleWasDown) {
        $eventId += 1
        $button = 3
    }

    $leftWasDown = $leftDown
    $rightWasDown = $rightDown
    $middleWasDown = $middleDown
    $keyCombo = Get-KeyCombo
    if ($keyCombo -ne "" -and $keyCombo -ne $lastKeyCombo) {
        $keyEventId += 1
        $lastKeyCombo = $keyCombo
    } elseif ($keyCombo -eq "") {
        $lastKeyCombo = ""
    }
    $caret = Get-CaretSnapshot

    $virtualX = [ScreenStudioLiteNative]::GetSystemMetrics(76)
    $virtualY = [ScreenStudioLiteNative]::GetSystemMetrics(77)
    $virtualWidth = [ScreenStudioLiteNative]::GetSystemMetrics(78)
    $virtualHeight = [ScreenStudioLiteNative]::GetSystemMetrics(79)
    $primaryWidth = [ScreenStudioLiteNative]::GetSystemMetrics(0)
    $primaryHeight = [ScreenStudioLiteNative]::GetSystemMetrics(1)
    $workRect = New-Object ScreenStudioLiteNative+RECT
    [ScreenStudioLiteNative]::SystemParametersInfo(0x0030, 0, [ref]$workRect, 0) | Out-Null
    $workWidth = [Math]::Max(0, $workRect.Right - $workRect.Left)
    $workHeight = [Math]::Max(0, $workRect.Bottom - $workRect.Top)
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

    $content = @"
event=$eventId
button=$button
x=$($point.X)
y=$($point.Y)
time=$timestamp
primary_width=$primaryWidth
primary_height=$primaryHeight
work_x=$($workRect.Left)
work_y=$($workRect.Top)
work_width=$workWidth
work_height=$workHeight
virtual_x=$virtualX
virtual_y=$virtualY
virtual_width=$virtualWidth
virtual_height=$virtualHeight
key_event=$keyEventId
key_combo=$keyCombo
caret_valid=$($caret.Valid)
caret_x=$($caret.X)
caret_y=$($caret.Y)
caret_width=$($caret.Width)
caret_height=$($caret.Height)
"@

    Write-StateFile -Path $StatePath -Content $content
    Start-Sleep -Milliseconds $IntervalMs

    if (Test-Path -LiteralPath $StopPath) {
        break
    }
}

Remove-Item -LiteralPath $StopPath -Force -ErrorAction SilentlyContinue
