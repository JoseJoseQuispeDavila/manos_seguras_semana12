param(
  [string]$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$fuente = Join-Path $Raiz 'docs\Informe_Tecnico_Semana12_BORRADOR.md'
$salida = Join-Path $Raiz 'docs\Informe_Tecnico_Semana12.docx'
$qa = Join-Path $Raiz 'docs\evidencias_semana12\word_qa'
New-Item -ItemType Directory -Path $qa -Force | Out-Null
$htmlPath = Join-Path $qa 'informe.html'
$pdfPath = Join-Path $qa 'informe_render.pdf'
$diagrama = Join-Path $qa 'diagrama_estado.png'

function Dibujar-Diagrama {
  param([string]$Ruta)
  $bmp = [System.Drawing.Bitmap]::new(1800, 620)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::White)
  $navy = [System.Drawing.Color]::FromArgb(31, 78, 121)
  $sky = [System.Drawing.Color]::FromArgb(231, 241, 249)
  $line = [System.Drawing.Pen]::new($navy, 5)
  $arrow = [System.Drawing.Drawing2D.AdjustableArrowCap]::new(7, 8)
  $line.CustomEndCap = $arrow
  $border = [System.Drawing.Pen]::new($navy, 4)
  $fill = [System.Drawing.SolidBrush]::new($sky)
  $dark = [System.Drawing.SolidBrush]::new($navy)
  $font = [System.Drawing.Font]::new('Calibri', 30, [System.Drawing.FontStyle]::Bold)
  $fontLong = [System.Drawing.Font]::new('Calibri', 24, [System.Drawing.FontStyle]::Bold)
  $small = [System.Drawing.Font]::new('Calibri', 24)
  $center = [System.Drawing.StringFormat]::new()
  $center.Alignment = [System.Drawing.StringAlignment]::Center
  $center.LineAlignment = [System.Drawing.StringAlignment]::Center
  function Box([int]$x,[int]$y,[int]$w,[int]$h,[string]$title,[string]$detail) {
    $rect=[System.Drawing.Rectangle]::new($x,$y,$w,$h)
    $g.FillRectangle($fill,$rect)
    $g.DrawRectangle($border,$rect)
    $titleRect=[System.Drawing.RectangleF]::new($x+8,$y+10,$w-16,55)
    $detailRect=[System.Drawing.RectangleF]::new($x+10,$y+65,$w-20,$h-70)
    $titleFont = if ($title.Length -gt 15) { $fontLong } else { $font }
    $g.DrawString($title,$titleFont,$dark,$titleRect,$center)
    $g.DrawString($detail,$small,$dark,$detailRect,$center)
  }
  Box 30 215 320 175 'get_it' 'Base de datos, repositorios y servicios'
  Box 445 215 350 175 '10 providers puente' 'Publican las instancias existentes'
  Box 900 20 350 155 'Tema' 'temaProvider'
  Box 900 225 350 155 'Captura' 'capturaProvider'
  Box 900 430 350 155 'Sesión' 'sesionCtrlProvider'
  Box 1370 20 390 155 'Raíz y bienvenida' 'Tema compartido'
  Box 1370 225 390 155 'Captura y bienvenida' 'Borrador compartido'
  Box 1370 430 390 155 'Sesión y bienvenida' 'Sesión compartida'
  $g.DrawLine($line,350,302,440,302)
  $g.DrawLine($line,795,302,875,302)
  $g.DrawLine($line,875,98,875,507)
  $g.DrawLine($line,875,98,895,98)
  $g.DrawLine($line,875,302,895,302)
  $g.DrawLine($line,875,507,895,507)
  $g.DrawLine($line,1250,98,1365,98)
  $g.DrawLine($line,1250,302,1365,302)
  $g.DrawLine($line,1250,507,1365,507)
  $bmp.Save($Ruta,[System.Drawing.Imaging.ImageFormat]::Png)
  $center.Dispose(); $font.Dispose(); $fontLong.Dispose(); $small.Dispose(); $dark.Dispose()
  $fill.Dispose(); $border.Dispose(); $line.Dispose(); $g.Dispose(); $bmp.Dispose()
}

Dibujar-Diagrama $diagrama
