[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [int]$NewLimit = 0,

    [Parameter(Position = 1)]
    [string]$JarPath = "",

    [switch]$NoBackup
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 自动解析 Jar 路径
if ([string]::IsNullOrWhiteSpace($JarPath)) {
    if (Test-Path "unlimited-stacks-mod-1.0.3.jar") {
        $JarPath = "unlimited-stacks-mod-1.0.3.jar"
    } else {
        $found = Get-ChildItem -Filter "unlimited-stacks-mod*.jar" | Where-Object { $_.Name -notlike "*.bak" }
        if ($found.Count -eq 1) {
            $JarPath = $found[0].FullName
        } elseif ($found.Count -gt 1) {
            Write-Warning "发现多个 mod jar 文件，请使用 -JarPath 参数明确指定要操作的文件："
            $found | ForEach-Object { Write-Host "  - $($_.Name)" }
            return
        } else {
            Write-Error "当前目录下未找到 unlimited-stacks-mod*.jar 文件！"
            return
        }
    }
}

$resolvedJar = Resolve-Path $JarPath -ErrorAction SilentlyContinue
if (-not $resolvedJar) {
    Write-Error "找不到目标文件: $JarPath"
    return
}
$jarFullPath = $resolvedJar.Path

$targets = @{
    "com/harrytheewizard/unlimitedstacks/UnlimitedStacksMod.class" = 44;
    "com/harrytheewizard/unlimitedstacks/mixin/ContainerMixin.class" = 3;
    "com/harrytheewizard/unlimitedstacks/mixin/ItemStackMixin.class" = 3;
    "com/harrytheewizard/unlimitedstacks/mixin/ExtraCodecsMixin.class" = 9;
}

function Read-U1($reader) { [int]$reader.ReadByte() }
function Read-U2($reader) { (([int]$reader.ReadByte() -shl 8) -bor [int]$reader.ReadByte()) }
function Read-U4($reader) {
    $b1 = [int]$reader.ReadByte(); $b2 = [int]$reader.ReadByte(); $b3 = [int]$reader.ReadByte(); $b4 = [int]$reader.ReadByte()
    return (($b1 -shl 24) -bor ($b2 -shl 16) -bor ($b3 -shl 8) -bor $b4)
}

function Get-CPIntegerOffset($bytes, $cpIndex) {
    $stream = New-Object System.IO.MemoryStream(,$bytes)
    $reader = New-Object System.IO.BinaryReader($stream)

    $null = Read-U4 $reader; $null = Read-U2 $reader; $null = Read-U2 $reader
    $cpCount = Read-U2 $reader
    $i = 1
    while ($i -lt $cpCount) {
        $tag = Read-U1 $reader
        if ($i -eq $cpIndex) {
            if ($tag -ne 3) { throw "CP[$cpIndex] 不是 Integer 标签 (Tag: $tag)" }
            $offset = $stream.Position
            $val = Read-U4 $reader
            return @{ Offset = $offset; Value = $val }
        }
        switch ($tag) {
            1 { $len = Read-U2 $reader; $null = $reader.ReadBytes($len) }
            3 { $null = Read-U4 $reader }
            4 { $null = $reader.ReadBytes(4) }
            5 { $null = $reader.ReadBytes(8); $i++ }
            6 { $null = Read-U2 $reader }
            7 { $null = Read-U2 $reader }
            8 { $null = Read-U2 $reader }
            9 { $null = Read-U4 $reader }
            10 { $null = Read-U4 $reader }
            11 { $null = Read-U4 $reader }
            12 { $null = Read-U4 $reader }
            15 { $null = Read-U1 $reader; $null = Read-U2 $reader }
            16 { $null = Read-U2 $reader }
            17 { $null = Read-U4 $reader }
            18 { $null = Read-U4 $reader }
            19 { $null = Read-U2 $reader }
            20 { $null = Read-U2 $reader }
        }
        $i++
    }
    throw "未找到常量池条目 CP[$cpIndex]"
}

# 模式 1: 仅查看当前数值
if ($NewLimit -le 0) {
    Write-Host "`n=== Unlimited Stacks Mod: 读取当前设置 ===" -ForegroundColor Cyan
    Write-Host "模组文件: $(Split-Path -Leaf $jarFullPath)"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($jarFullPath)
    try {
        foreach ($kv in $targets.GetEnumerator()) {
            $entry = $zip.GetEntry($kv.Key)
            if (-not $entry) {
                Write-Warning "缺少类: $($kv.Key)"
                continue
            }
            $mem = New-Object System.IO.MemoryStream
            $s = $entry.Open()
            $s.CopyTo($mem)
            $s.Close()
            $info = Get-CPIntegerOffset $mem.ToArray() $kv.Value
            Write-Host ("  [{0}] -> {1:N0} (0x{1:X8})" -f ([System.IO.Path]::GetFileName($kv.Key)), $info.Value) -ForegroundColor Green
        }
    } finally {
        $zip.Dispose()
    }
    Write-Host "`n使用说明: 若要修改上限，请指定数值参数，例如: .\Modify-StackLimit.ps1 1000" -ForegroundColor Yellow
    return
}

# 模式 2: 修改上限数值
Write-Host "`n=== Unlimited Stacks Mod: 开始修改堆叠上限 ===" -ForegroundColor Cyan
Write-Host "当前文件: $(Split-Path -Leaf $jarFullPath)"
Write-Host "新上限值: $($NewLimit.ToString('N0')) (0x$($NewLimit.ToString('X8')))"

# 先读取原本的 limit
$oldLimit = $null
$zipCheck = [System.IO.Compression.ZipFile]::OpenRead($jarFullPath)
try {
    $entry = $zipCheck.GetEntry("com/harrytheewizard/unlimitedstacks/UnlimitedStacksMod.class")
    if ($entry) {
        $mem = New-Object System.IO.MemoryStream
        $s = $entry.Open()
        $s.CopyTo($mem)
        $s.Close()
        $info = Get-CPIntegerOffset $mem.ToArray() 44
        $oldLimit = $info.Value
    }
} finally {
    $zipCheck.Dispose()
}

if ($null -eq $oldLimit) {
    $oldLimit = "unknown"
}

# 计算清理后的基础名称（去除旧的 limit 标记，防止多次修改时文件名重复追加）
$dir = Split-Path -Parent $jarFullPath
$baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($jarFullPath)
$cleanBase = $baseFileName -replace '[-_.]?limit[-_.]?\d+', ''

# 1. 备份原文件（文件名标注原本的 limit）
if (-not $NoBackup) {
    $backupFileName = "$cleanBase-limit-$oldLimit.jar.bak"
    $backupFullPath = Join-Path $dir $backupFileName
    Copy-Item $jarFullPath $backupFullPath -Force
    Write-Host "已创建备份: $backupFileName (标注原上限: $oldLimit)" -ForegroundColor DarkGray
}

# 2. 修改文件内部字节码与描述
$zip = [System.IO.Compression.ZipFile]::Open($jarFullPath, [System.IO.Compression.ZipArchiveMode]::Update)
try {
    foreach ($kv in $targets.GetEnumerator()) {
        $entry = $zip.GetEntry($kv.Key)
        if (-not $entry) { throw "未在 jar 中找到关键类: $($kv.Key)" }
        $mem = New-Object System.IO.MemoryStream
        $s = $entry.Open()
        $s.CopyTo($mem)
        $s.Close()
        $bytes = $mem.ToArray()

        $info = Get-CPIntegerOffset $bytes $kv.Value
        $oldVal = $info.Value
        $offset = $info.Offset

        $newBytes = [System.BitConverter]::GetBytes([int]$NewLimit)
        if ([System.BitConverter]::IsLittleEndian) {
            [Array]::Reverse($newBytes)
        }
        [System.Array]::Copy($newBytes, 0, $bytes, $offset, 4)

        $entry.Delete()
        $newEntry = $zip.CreateEntry($kv.Key, [System.IO.Compression.CompressionLevel]::Optimal)
        $newStream = $newEntry.Open()
        $newStream.Write($bytes, 0, $bytes.Length)
        $newStream.Close()

        Write-Host ("  [已修改] {0}: {1:N0} -> {2:N0}" -f ([System.IO.Path]::GetFileName($kv.Key)), $oldVal, $NewLimit) -ForegroundColor Green
    }

    $fabricEntry = $zip.GetEntry("fabric.mod.json")
    if ($fabricEntry) {
        $mem = New-Object System.IO.MemoryStream
        $s = $fabricEntry.Open()
        $s.CopyTo($mem)
        $s.Close()
        $jsonText = [System.Text.Encoding]::UTF8.GetString($mem.ToArray())
        
        $newDesc = "Raises the item and container max stack size cap to $($NewLimit.ToString('N0'))."
        $updatedJson = [regex]::Replace($jsonText, '("description"\s*:\s*")[^"]*(")', "`${1}$newDesc`${2}")
        
        $fabricEntry.Delete()
        $newFabricEntry = $zip.CreateEntry("fabric.mod.json", [System.IO.Compression.CompressionLevel]::Optimal)
        $sw = New-Object System.IO.StreamWriter($newFabricEntry.Open(), [System.Text.Encoding]::UTF8)
        $sw.Write($updatedJson)
        $sw.Close()
        Write-Host "  [已更新] fabric.mod.json 模组信息描述" -ForegroundColor Green
    }
} finally {
    $zip.Dispose()
}

# 3. 给修改后的 mod 文件重命名加上新 limit
$newJarFileName = "$cleanBase-limit-$NewLimit.jar"
$newJarFullPath = Join-Path $dir $newJarFileName

if ($newJarFullPath -ne $jarFullPath) {
    if (Test-Path $newJarFullPath) {
        Remove-Item $newJarFullPath -Force
    }
    Rename-Item -Path $jarFullPath -NewName $newJarFileName
    Write-Host "已更新名称: $newJarFileName (标注新上限: $NewLimit)" -ForegroundColor Green
}

Write-Host "`n[SUCCESS] 修改完成！" -ForegroundColor Cyan
Write-Host "  - 最终模组文件: $newJarFileName" -ForegroundColor Cyan
if (-not $NoBackup) {
    Write-Host "  - 备份原始文件: $backupFileName" -ForegroundColor DarkGray
}
