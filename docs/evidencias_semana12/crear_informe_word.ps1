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

function Html-Inline([string]$Texto) {
  $s = [System.Net.WebUtility]::HtmlEncode($Texto)
  $s = [regex]::Replace($s, '`([^`]+)`', '<code>$1</code>')
  $s = [regex]::Replace($s, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $s = [regex]::Replace($s, '\*([^*]+)\*', '<em>$1</em>')
  return $s
}

function Imagen-Uri([string]$Ruta) {
  return 'file:///' + ($Ruta.Replace('\','/'))
}

$capturas = @{
  C1 = Join-Path $Raiz 'docs\evidencias_semana12\capturas\C1_bienvenida_borrador.png'
  C2 = Join-Path $Raiz 'docs\evidencias_semana12\capturas\C2_captura_oportunidades.png'
  C3 = Join-Path $Raiz 'docs\evidencias_semana12\capturas\C3_sesion_huella.png'
  C4 = Join-Path $Raiz 'docs\evidencias_semana12\capturas\C4_traza_observador.png'
}
foreach ($c in $capturas.Keys) {
  if (-not (Test-Path -LiteralPath $capturas[$c])) { throw "Falta la captura $c" }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('<!DOCTYPE html><html><head><meta charset="utf-8"/><style>')
[void]$sb.AppendLine('@page{size:A4;margin:2.4cm 2.2cm 2.4cm 2.2cm} body{font-family:Calibri,Arial,sans-serif;font-size:11pt;color:#202020;line-height:1.15} h1{font-family:Calibri;font-size:15pt;color:#1F4E79;margin:15pt 0 8pt;page-break-after:avoid} h2{font-family:Calibri;font-size:12pt;color:#1F4E79;margin:11pt 0 5pt;page-break-after:avoid} p{margin:0 0 7pt} .caption{font-weight:bold;color:#1F4E79;margin:8pt 0 3pt} .note{font-size:9pt;color:#444} table{border-collapse:collapse;width:100%;font-family:Calibri;font-size:9pt;margin:5pt 0 9pt} th,td{border:1px solid #D9D9D9;padding:5pt 6pt;vertical-align:middle} th{background:#1F4E79;color:white;font-weight:bold} tr:nth-child(even) td{background:#F0F5FA} pre{font-family:Consolas,monospace;font-size:9pt;white-space:pre-wrap;word-wrap:break-word;line-height:1.05;margin:5pt 0 8pt} code{font-family:Consolas,monospace;font-size:9pt} .cover{text-align:center} .coverTitle{font-family:Calibri;font-size:19pt;font-weight:bold;color:#111;margin:26pt 0 8pt} .coverSub{font-size:14pt;color:#1F4E79;margin:8pt 0 22pt} .coverInfo{font-size:10pt} .draft{font-weight:bold;color:#1F4E79} .figure{text-align:center;margin:6pt 0 10pt} .annex{page-break-before:always} .pagebreak{page-break-after:always}</style></head><body>')
[void]$sb.AppendLine('<div class="cover"><p style="font-size:15pt;font-weight:bold;color:#1F4E79">UNIVERSIDAD ANDINA DEL CUSCO</p><p>Facultad de Ingeniería y Arquitectura<br/>Escuela Profesional de Ingeniería de Sistemas</p><p class="coverTitle">INFORME TÉCNICO SEMANA 12</p><p class="coverSub">Gestión de estado avanzada con Riverpod en ManosSeguras</p><p class="draft">BORRADOR PARA REVISIÓN DEL EQUIPO</p><p>Desarrollo de Software II · SIS048<br/>Unidad II · Guía de Aplicación 08 · Parte I<br/>Semestre 2026-II · Ciclo VII</p><p style="margin-top:24pt;font-weight:bold">Integrantes</p><p>CARDENAS CARRASCO LEONARDO · código: Pendiente de completar<br/>QUISPE DAVIDA JOSE JOSE · código: Pendiente de completar<br/>VITORINO DURAN DAVIS SHUMAGER · código: Pendiente de completar<br/>YABAR LATORRE GONZALO YABAR · código: Pendiente de completar</p><p class="coverInfo">Roles y responsabilidades: propuesta por confirmar por el equipo.<br/>Repositorio: Pendiente de completar.<br/>Docente: Mtro. Ing. Yover Collantes Valer.</p><p style="margin-top:28pt">Cusco, Perú · 17 de octubre de 2026</p></div><div class="pagebreak"></div>')
[void]$sb.AppendLine('<p class="draft">BORRADOR. Las evidencias C1–C4 están guardadas; faltan códigos, URL del repositorio, confirmación de roles y la versión de Semana 11 para comparaciones históricas.</p>')

$lineas = Get-Content -LiteralPath $fuente -Encoding utf8
$empezar = $false
$enCodigo = $false
$tipoCodigo = ''
$codigo = [System.Collections.Generic.List[string]]::new()
$enTabla = $false
$primeraFila = $false
$enAnexo = $false
$figuraNumero = 1
foreach ($linea in $lineas) {
  if (-not $empezar) {
    if ($linea -match '^## 1\. ') { $empezar = $true } else { continue }
  }
  if ($linea -match '^```(.*)$') {
    if (-not $enCodigo) {
      $enCodigo = $true; $tipoCodigo = $Matches[1]; $codigo.Clear()
    } else {
      if ($tipoCodigo -eq 'mermaid') {
        [void]$sb.AppendLine('<div class="figure"><img alt="Diagrama del grafo de estado" src="' + (Imagen-Uri $diagrama) + '" width="620"/></div>')
      } else {
        [void]$sb.AppendLine('<pre>' + [System.Net.WebUtility]::HtmlEncode(($codigo -join "`n")) + '</pre>')
      }
      $enCodigo = $false; $tipoCodigo = ''
    }
    continue
  }
  if ($enCodigo) { $codigo.Add($linea); continue }
  if ($linea -match '^\|') {
    if ($linea -match '^\|[\s:\-|]+\|\s*$') { continue }
    if (-not $enTabla) { [void]$sb.AppendLine('<table>'); $enTabla=$true; $primeraFila=$true }
    $celdas = $linea.Trim().Trim('|').Split('|')
    $tag = if ($primeraFila) { 'th' } else { 'td' }
    [void]$sb.Append('<tr>')
    foreach ($c in $celdas) { [void]$sb.Append('<' + $tag + '>' + (Html-Inline $c.Trim()) + '</' + $tag + '>') }
    [void]$sb.AppendLine('</tr>')
    $primeraFila = $false
    continue
  }
  if ($enTabla) { [void]$sb.AppendLine('</table>'); $enTabla=$false }
  if ($linea.Trim().Length -eq 0) { continue }
  if ($linea -match '^## (.+)$') {
    $titulo = $Matches[1]
    if ($titulo -match '^Anexo ') { $enAnexo = $true; [void]$sb.AppendLine('<h1 class="annex">' + (Html-Inline $titulo) + '</h1>') }
    else { [void]$sb.AppendLine('<h1>' + (Html-Inline $titulo) + '</h1>') }
    continue
  }
  if ($linea -match '^### (.+)$') { [void]$sb.AppendLine('<h2>' + (Html-Inline $Matches[1]) + '</h2>'); continue }
  if ($linea -match '^\[INSERTAR EVIDENCIA (C[1-4]):') {
    $codigoCaptura = $Matches[1]
    $ancho = if ($enAnexo) { 620 } else { 525 }
    $tituloFigura = "Figura $figuraNumero. Evidencia $codigoCaptura de la aplicación ejecutada"
    [void]$sb.AppendLine('<p class="caption">' + $tituloFigura + '</p><div class="figure"><img alt="EVIDENCIA_' + $codigoCaptura + '" src="' + (Imagen-Uri $capturas[$codigoCaptura]) + '" width="' + $ancho + '"/></div>')
    $figuraNumero++
    continue
  }
  if ($linea -match '^\*\*(Tabla|Figura) .+') { [void]$sb.AppendLine('<p class="caption">' + (Html-Inline $linea) + '</p>'); continue }
  if ($linea -match '^\*Nota') { [void]$sb.AppendLine('<p class="note">' + (Html-Inline $linea) + '</p>'); continue }
  [void]$sb.AppendLine('<p>' + (Html-Inline $linea) + '</p>')
}
if ($enTabla) { [void]$sb.AppendLine('</table>') }
[void]$sb.AppendLine('</body></html>')
[System.IO.File]::WriteAllText($htmlPath,$sb.ToString(),[System.Text.UTF8Encoding]::new($false))

$word = $null
$doc = $null
try {
  Write-Output 'WORD_START'
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  Write-Output 'WORD_OPEN_HTML'
  $doc = $word.Documents.Open($htmlPath, $false, $false, $false)
  Write-Output 'WORD_HTML_OPENED'
  $doc.PageSetup.PageWidth = 595.28
  $doc.PageSetup.PageHeight = 841.89
  $doc.PageSetup.LeftMargin = 62.36
  $doc.PageSetup.RightMargin = 62.36
  $doc.PageSetup.TopMargin = 68.03
  $doc.PageSetup.BottomMargin = 68.03
  $doc.PageSetup.HeaderDistance = 28.35
  $doc.PageSetup.FooterDistance = 28.35
  $normal = $doc.Styles.Item(-1)
  $normal.Font.Name = 'Calibri'
  $normal.Font.Size = 11
  $normal.ParagraphFormat.LineSpacingRule = 5
  $normal.ParagraphFormat.LineSpacing = 13.8
  $normal.ParagraphFormat.SpaceAfter = 5
  foreach ($tabla in $doc.Tables) {
    $tabla.Borders.Enable = 1
    $tabla.Range.Font.Name = 'Calibri'
    $tabla.Range.Font.Size = 9
    try { $tabla.Rows.Item(1).HeadingFormat = -1 } catch {}
  }
  $h = $doc.Sections.Item(1).Headers.Item(1).Range
  $h.Text = 'UNIVERSIDAD ANDINA DEL CUSCO  ·  Facultad de Ingeniería y Arquitectura  ·  Escuela Profesional de Ingeniería de Sistemas'
  $h.Font.Name = 'Calibri'; $h.Font.Size = 8
  $h.ParagraphFormat.Alignment = 1
  $f = $doc.Sections.Item(1).Footers.Item(1).Range
  $f.Text = 'Informe técnico · Semana 12 · SIS048 · 2026-II · Página '
  $f.Font.Name = 'Calibri'; $f.Font.Size = 8
  $f.ParagraphFormat.Alignment = 1
  $f.Collapse(0)
  [void]$doc.Fields.Add($f,33)

  $imageInfo = [System.Collections.Generic.List[string]]::new()
  Write-Output "WORD_STYLE_DONE IMAGES=$($doc.InlineShapes.Count)"
  for ($i=1; $i -le $doc.InlineShapes.Count; $i++) {
    $im = $doc.InlineShapes.Item($i)
    $alt = [string]$im.AlternativeText
    $imageInfo.Add("$i|$alt|$([math]::Round($im.Width,1))|$([math]::Round($im.Height,1))")
    if ($alt -match 'EVIDENCIA_C3') {
      $im.PictureFormat.CropBottom = [math]::Round($im.Height * 0.56, 1)
    }
    if ($alt -match 'EVIDENCIA_C4') {
      $im.PictureFormat.CropTop = [math]::Round($im.Height * 0.36, 1)
    }
  }
  $imageInfo | Set-Content -Encoding utf8 (Join-Path $qa 'imagenes_insertadas.txt')
  Write-Output 'WORD_SAVE_DOCX'
  $doc.SaveAs2($salida,16)
  Write-Output 'WORD_EXPORT_PDF'
  $doc.ExportAsFixedFormat($pdfPath,17)
  Write-Output 'WORD_PDF_DONE'
  $paginas = $doc.ComputeStatistics(2)
  $anexoPagina = $null
  foreach ($p in $doc.Paragraphs) {
    if ($p.Range.Text.Trim() -like 'Anexo A.*') {
      $anexoPagina = $p.Range.Information(3)
      break
    }
  }
  "Paginas=$paginas`nAnexoA_Pagina=$anexoPagina`nImagenes=$($doc.InlineShapes.Count)`nTablas=$($doc.Tables.Count)" | Set-Content -Encoding utf8 (Join-Path $qa 'resumen_render.txt')
  Write-Output "DOCX=$salida"
  Write-Output "PDF_QA=$pdfPath"
  Write-Output "PAGINAS=$paginas ANEXO_A=$anexoPagina IMAGENES=$($doc.InlineShapes.Count) TABLAS=$($doc.Tables.Count)"
}
finally {
  if ($doc -ne $null) { $doc.Close($false) }
  if ($word -ne $null) { $word.Quit() }
  if ($doc -ne $null) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) }
  if ($word -ne $null) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) }
}
