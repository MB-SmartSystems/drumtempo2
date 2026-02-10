# Erstelle minimalen WAV-Click (50ms, 44.1kHz, Mono, 16-bit)
$sampleRate = 44100
$duration = 0.05
$numSamples = [int]($sampleRate * $duration)

# WAV Header erstellen
$bytes = New-Object System.Collections.Generic.List[byte]

# RIFF Header
$bytes.AddRange([Text.Encoding]::ASCII.GetBytes('RIFF'))
$fileSize = 36 + $numSamples * 2
$bytes.AddRange([BitConverter]::GetBytes([uint32]$fileSize))
$bytes.AddRange([Text.Encoding]::ASCII.GetBytes('WAVE'))

# fmt chunk
$bytes.AddRange([Text.Encoding]::ASCII.GetBytes('fmt '))
$bytes.AddRange([BitConverter]::GetBytes([uint32]16))  # chunk size
$bytes.AddRange([BitConverter]::GetBytes([uint16]1))   # PCM
$bytes.AddRange([BitConverter]::GetBytes([uint16]1))   # Mono
$bytes.AddRange([BitConverter]::GetBytes([uint32]$sampleRate))
$bytes.AddRange([BitConverter]::GetBytes([uint32]($sampleRate * 2)))  # byte rate
$bytes.AddRange([BitConverter]::GetBytes([uint16]2))   # block align
$bytes.AddRange([BitConverter]::GetBytes([uint16]16))  # bits per sample

# data chunk
$bytes.AddRange([Text.Encoding]::ASCII.GetBytes('data'))
$bytes.AddRange([BitConverter]::GetBytes([uint32]($numSamples * 2)))

# Generiere Click-Samples (1kHz Sinuston mit Decay)
for ($i = 0; $i -lt $numSamples; $i++) {
    $t = $i / $sampleRate
    $envelope = [Math]::Exp(-20 * $t)
    $value = [int16](16384 * [Math]::Sin(2 * [Math]::PI * 1000 * $t) * $envelope)
    $bytes.AddRange([BitConverter]::GetBytes($value))
}

# Schreibe Datei
[System.IO.File]::WriteAllBytes("$PSScriptRoot\assets\click.wav", $bytes.ToArray())
Write-Host "Click-Sound erstellt: click.wav (50ms, 44.1kHz)"
