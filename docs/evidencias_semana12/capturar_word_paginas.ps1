param([int[]]$Paginas = @(), [int[]]$Figuras = @())
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$src=@'
using System;
using System.Runtime.InteropServices;
public class CapturaVentanaWord {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr insert, int x, int y, int w, int hgt, uint flags);
  public struct RECT { public int Left,Top,Right,Bottom; }
}
'@
Add-Type $src
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$out=Join-Path $PSScriptRoot 'word_qa\paginas_word'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$word=New-Object -ComObject Word.Application
$word.Visible=$true
$word.DisplayAlerts=0
$wordPid=$null
try {
  $doc=$word.Documents.Open((Join-Path $root 'docs\Informe_Tecnico_Semana12.docx'),$false,$true)
  $win=$word.ActiveWindow
  $win.View.Type=3
  try { $win.DocumentMap=$false } catch {}
  $win.View.Zoom.Percentage=65
  $h=(Get-Process WINWORD | Sort-Object StartTime -Descending | Select-Object -First 1).MainWindowHandle
  $wordPid=(Get-Process WINWORD | Sort-Object StartTime -Descending | Select-Object -First 1).Id
  if ($h -eq [IntPtr]::Zero) { throw 'Word no expuso una ventana visible para la captura.' }
  [void][CapturaVentanaWord]::SetWindowPos($h,[IntPtr]::Zero,10,10,1400,1100,0)
  foreach($n in $Paginas) {
    $range=$word.Selection.GoTo(1,1,$n)
    $range.Select()
    $win.ScrollIntoView($range,$true)
    Start-Sleep -Milliseconds 120
    $rect=New-Object CapturaVentanaWord+RECT
    [void][CapturaVentanaWord]::GetWindowRect($h,[ref]$rect)
    $width=$rect.Right-$rect.Left; $height=$rect.Bottom-$rect.Top
    $bmp=[System.Drawing.Bitmap]::new($width,$height)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $dc=$g.GetHdc()
    [void][CapturaVentanaWord]::PrintWindow($h,$dc,2)
    $g.ReleaseHdc($dc)
    $path=Join-Path $out ('pagina-{0:D2}.png' -f $n)
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose();$bmp.Dispose()
    Write-Output $path
  }
  foreach($n in $Figuras) {
    $range=$doc.InlineShapes.Item($n).Range
    $range.Select()
    $win.ScrollIntoView($range,$true)
    Start-Sleep -Milliseconds 120
    $rect=New-Object CapturaVentanaWord+RECT
    [void][CapturaVentanaWord]::GetWindowRect($h,[ref]$rect)
    $width=$rect.Right-$rect.Left; $height=$rect.Bottom-$rect.Top
    $bmp=[System.Drawing.Bitmap]::new($width,$height)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $dc=$g.GetHdc()
    [void][CapturaVentanaWord]::PrintWindow($h,$dc,2)
    $g.ReleaseHdc($dc)
    $path=Join-Path $out ('figura-{0:D2}.png' -f $n)
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose();$bmp.Dispose()
    Write-Output $path
  }
  try { $doc.Close($false) } catch {}
}
finally {
  try { $word.Quit() } catch {}
  if ($wordPid -ne $null) {
    Start-Sleep -Milliseconds 300
    Get-Process -Id $wordPid -ErrorAction SilentlyContinue | Stop-Process -Force
  }
}
