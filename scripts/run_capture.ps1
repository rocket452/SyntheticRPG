Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ArtifactsDir = Join-Path $ProjectRoot "artifacts"
$LogPath = Join-Path $ArtifactsDir "log.txt"
$VideoPath = Join-Path $ArtifactsDir "latest.mp4"
$CapturePath = Join-Path $ArtifactsDir "latest.avi"
$StdoutPath = Join-Path $ArtifactsDir "godot_stdout.log"
$GodotExe = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }

New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null
if (Test-Path $LogPath) { Remove-Item $LogPath -Force }
if (Test-Path $VideoPath) { Remove-Item $VideoPath -Force }
if (Test-Path $CapturePath) { Remove-Item $CapturePath -Force }
if (Test-Path $StdoutPath) { Remove-Item $StdoutPath -Force }
Set-Content -Path $LogPath -Value "" -Encoding UTF8

$env:AUTOPLAY_TEST = "1"
$env:AUTOPLAY_LOG_PATH = $LogPath

$godotArgs = @(
	"--path", $ProjectRoot,
	"--fixed-fps", "60",
	"--quit-after", "900",
	"--write-movie", $CapturePath,
	"--",
	"--autoplay_test"
)

Write-Host "Running capture with $GodotExe..."
& $GodotExe @godotArgs | Tee-Object -FilePath $StdoutPath
$ExitCode = $LASTEXITCODE

if ((-not (Test-Path $VideoPath)) -or ((Get-Item $VideoPath).Length -le 0)) {
	if ((Test-Path $CapturePath) -and ((Get-Item $CapturePath).Length -gt 0)) {
		$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
		if ($ffmpegCmd) {
			& ffmpeg -y -i $CapturePath -an -c:v libx264 -pix_fmt yuv420p $VideoPath | Out-Null
			if (($LASTEXITCODE -ne 0) -or (-not (Test-Path $VideoPath)) -or ((Get-Item $VideoPath).Length -le 0)) {
				Copy-Item -Path $CapturePath -Destination $VideoPath -Force
			}
		}
		else {
			Copy-Item -Path $CapturePath -Destination $VideoPath -Force
		}
	}
}

if ($ExitCode -ne 0) {
	Write-Error "Godot exited with code $ExitCode."
	exit $ExitCode
}
if ((-not (Test-Path $LogPath)) -or ((Get-Item $LogPath).Length -le 0)) {
	Write-Error "Missing or empty log file: $LogPath"
	exit 1
}
if ((-not (Test-Path $VideoPath)) -or ((Get-Item $VideoPath).Length -le 0)) {
	Write-Error "Missing or empty movie file: $VideoPath"
	exit 1
}

Write-Host "Capture complete."
Write-Host "Log: $LogPath"
Write-Host "Video: $VideoPath"
