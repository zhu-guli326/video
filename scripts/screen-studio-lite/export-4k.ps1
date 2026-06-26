$ErrorActionPreference = 'Stop'
$inputPath = 'D:/小红书发布/2026年/6月/0601 codex 新手/2026-05-31 21-38-27.mp4'
$outputPath = 'D:/小红书发布/2026年/6月/0601 codex 新手/2026-05-31 21-38-27-screenstudio-4k.mp4'
if ([string]::IsNullOrWhiteSpace($inputPath) -or -not (Test-Path -LiteralPath $inputPath)) {
  throw 'Recording file not found. Finish one Studio Recording first, then reopen the editor.'
}
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
  Copy-Item -LiteralPath $inputPath -Destination $outputPath -Force
  Write-Host "ffmpeg was not found on PATH; copied the existing OBS 4K recording to $outputPath"
  return
}
& $ffmpeg.Source -y -i $inputPath -vf "scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset slow -crf 16 -c:a aac -b:a 320k -movflags +faststart $outputPath
Write-Host "Exported $outputPath"
