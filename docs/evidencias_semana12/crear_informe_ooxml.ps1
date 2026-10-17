$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source = Join-Path $root 'docs\Informe_Tecnico_Semana12_BORRADOR.md'
$target = Join-Path $root 'docs\Informe_Tecnico_Semana12.docx'
$diagram = Join-Path $root 'docs\evidencias_semana12\word_qa\diagrama_estado.png'
$capDir = Join-Path $root 'docs\evidencias_semana12\capturas'
$pics = @{
  C1 = Join-Path $capDir 'C1_bienvenida_borrador.png'
  C2 = Join-Path $capDir 'C2_captura_oportunidades.png'
  C3 = Join-Path $capDir 'C3_sesion_huella.png'
  C4 = Join-Path $capDir 'C4_traza_observador.png'
  D = $diagram
}
foreach ($key in $pics.Keys) { if (-not (Test-Path -LiteralPath $pics[$key])) { throw "Falta imagen $key" } }

function Esc([string]$v) { return [System.Security.SecurityElement]::Escape($v) }
function Run([string]$v, [string]$kind = '') {
  $rpr = switch ($kind) {
    'bold' { '<w:rPr><w:b/></w:rPr>' }
    'italic' { '<w:rPr><w:i/></w:rPr>' }
    'code' { '<w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="18"/></w:rPr>' }
    default { '' }
  }
  return '<w:r>' + $rpr + '<w:t xml:space="preserve">' + (Esc $v) + '</w:t></w:r>'
}
function Inline([string]$v) {
  $out = [System.Text.StringBuilder]::new()
  $i = 0
  while ($i -lt $v.Length) {
    $kind = ''
    $start = $i
    $delimiter = ''
    if ($i + 1 -lt $v.Length -and $v.Substring($i,2) -eq '**') { $delimiter='**'; $kind='bold' }
    elseif ($v[$i] -eq '`') { $delimiter='`'; $kind='code' }
    elseif ($v[$i] -eq '*') { $delimiter='*'; $kind='italic' }
    if ($delimiter -ne '') {
      $end = $v.IndexOf($delimiter,$i+$delimiter.Length,[StringComparison]::Ordinal)
      if ($end -ge 0) {
        [void]$out.Append((Run $v.Substring($i+$delimiter.Length,$end-$i-$delimiter.Length) $kind))
        $i = $end + $delimiter.Length
        continue
      }
    }
    $i++
    while ($i -lt $v.Length -and $v[$i] -ne '*' -and $v[$i] -ne '`') { $i++ }
    [void]$out.Append((Run $v.Substring($start,$i-$start)))
  }
  return $out.ToString()
}
function Para([string]$text,[string]$style='Normal',[bool]$pageBefore=$false,[bool]$keepNext=$false,[bool]$center=$false) {
  $pr = '<w:pPr><w:pStyle w:val="'+$style+'"/>'
  if ($pageBefore) { $pr += '<w:pageBreakBefore/>' }
  if ($keepNext) { $pr += '<w:keepNext/>' }
  if ($center) { $pr += '<w:jc w:val="center"/>' }
  $pr += '</w:pPr>'
  return '<w:p>'+$pr+(Inline $text)+'</w:p>'
}
function ImageParagraph([string]$key,[int]$widthCm10,[int]$id) {
  $path=$pics[$key]
  $img=[System.Drawing.Image]::FromFile($path)
  $originalWidth=$img.Width; $originalHeight=$img.Height
  $img.Dispose()
  $cropTop=0; $cropBottom=0
  if ($key -eq 'C3') { $cropBottom=57000 }
  if ($key -eq 'C4') { $cropTop=54000 }
  $visibleFraction=1.0-($cropTop+$cropBottom)/100000.0
  $cx=[int64]([math]::Round(($widthCm10/10.0)/2.54*914400))
  $cy=[int64]([math]::Round($cx*$originalHeight/$originalWidth*$visibleFraction))
  $rel=@{D='rIdImgD';C1='rIdImgC1';C2='rIdImgC2';C3='rIdImgC3';C4='rIdImgC4'}[$key]
  $src=''
  if ($cropTop -gt 0 -or $cropBottom -gt 0) { $src='<a:srcRect t="'+$cropTop+'" b="'+$cropBottom+'"/>' }
  $alt=Esc ('Evidencia '+$key+' recortada dentro de Word; imagen original incorporada')
  $drawing='<w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="'+$cx+'" cy="'+$cy+'"/><wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="'+$id+'" name="'+$key+'" descr="'+$alt+'"/><wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="0" name="'+$key+'.png"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="'+$rel+'"/>'+$src+'<a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="'+$cx+'" cy="'+$cy+'"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing>'
  return '<w:p><w:pPr><w:pStyle w:val="Figure"/><w:jc w:val="center"/></w:pPr><w:r>'+$drawing+'</w:r></w:p>'
}
function TableXml([System.Collections.Generic.List[object]]$rows) {
  if ($rows.Count -eq 0) { return '' }
  $colCount=($rows[0]).Count
  $widths=switch($colCount) {
    2 { @(3400,6014) }
    3 { @(2300,3300,3814) }
    4 { @(1900,1750,3700,2064) }
    5 { @(1450,1850,2150,2450,1514) }
    6 { @(2200,1250,1900,1100,1700,1264) }
    default { @(1..$colCount | ForEach-Object {[int][math]::Floor(9414/$colCount)}) }
  }
  $sb=[System.Text.StringBuilder]::new()
  [void]$sb.Append('<w:tbl><w:tblPr><w:tblW w:w="9414" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="D9D9D9"/><w:left w:val="single" w:sz="4" w:color="D9D9D9"/><w:bottom w:val="single" w:sz="4" w:color="D9D9D9"/><w:right w:val="single" w:sz="4" w:color="D9D9D9"/><w:insideH w:val="single" w:sz="4" w:color="D9D9D9"/><w:insideV w:val="single" w:sz="4" w:color="D9D9D9"/></w:tblBorders><w:tblCellMar><w:top w:w="75" w:type="dxa"/><w:left w:w="90" w:type="dxa"/><w:bottom w:w="75" w:type="dxa"/><w:right w:w="90" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>')
  for ($j=0;$j -lt $colCount;$j++) { [void]$sb.Append('<w:gridCol w:w="'+$widths[$j]+'"/>') }
  [void]$sb.Append('</w:tblGrid>')
  for ($i=0;$i -lt $rows.Count;$i++) {
    [void]$sb.Append('<w:tr>')
    if ($i -eq 0) { [void]$sb.Append('<w:trPr><w:tblHeader/></w:trPr>') }
    $cells=$rows[$i]
    for ($j=0;$j -lt $colCount;$j++) {
      $v=if ($j -lt $cells.Count) { [string]$cells[$j] } else { '' }
      $shade=if ($i -eq 0) { '1F4E79' } elseif ($i % 2 -eq 0) { 'F0F5FA' } else { 'FFFFFF' }
      $style=if ($colCount -ge 5) { if ($i -eq 0) { 'TableHeadSmall' } else { 'TableTextSmall' } } elseif ($i -eq 0) { 'TableHead' } else { 'TableText' }
      [void]$sb.Append('<w:tc><w:tcPr><w:tcW w:w="'+$widths[$j]+'" w:type="dxa"/><w:shd w:fill="'+$shade+'"/><w:vAlign w:val="center"/></w:tcPr>'+(Para $v $style)+'</w:tc>')
    }
    [void]$sb.Append('</w:tr>')
  }
  [void]$sb.Append('</w:tbl>')
  return $sb.ToString()
}

$body=[System.Text.StringBuilder]::new()
[void]$body.Append((Para 'UNIVERSIDAD ANDINA DEL CUSCO' 'CoverInstitution' $false $false $true))
[void]$body.Append((Para 'Facultad de Ingeniería y Arquitectura' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Escuela Profesional de Ingeniería de Sistemas' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'INFORME TÉCNICO SEMANA 12' 'Title' $false $false $true))
[void]$body.Append((Para 'Gestión de estado avanzada con Riverpod en ManosSeguras' 'Subtitle' $false $false $true))
[void]$body.Append((Para 'BORRADOR PARA REVISIÓN DEL EQUIPO' 'Draft' $false $false $true))
[void]$body.Append((Para 'Desarrollo de Software II · SIS048 · Unidad II · Guía de Aplicación 08 · Parte I' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Semestre académico 2026-II · Ciclo VII' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Integrantes' 'Heading2' $false $false $true))
foreach ($name in @('CARDENAS CARRASCO LEONARDO','QUISPE DAVIDA JOSE JOSE','VITORINO DURAN DAVIS SHUMAGER','YABAR LATORRE GONZALO YABAR')) {
  [void]$body.Append((Para ($name+' · Código: Pendiente de completar') 'CoverMeta' $false $false $true))
}
[void]$body.Append((Para 'Roles y responsabilidades: propuesta por confirmar por el equipo.' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Repositorio: Pendiente de completar.' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Docente: Mtro. Ing. Yover Collantes Valer.' 'CoverMeta' $false $false $true))
[void]$body.Append((Para 'Cusco, Perú · 17 de octubre de 2026' 'CoverMeta' $false $false $true))
[void]$body.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
[void]$body.Append((Para 'Índice del informe' 'Heading1'))
foreach ($entry in @(
  '1. Datos del equipo y del proyecto',
  '2. Resumen ejecutivo',
  '3. Decisión de arquitectura: por qué Riverpod',
  '4. Diseño de la capa de estado',
  '5. Providers simples y generación de código',
  '6. Migración de la captura (setState → Notifier)',
  '7. Migración de la sesión',
  '8. Pruebas y evidencias',
  '9. Reconstrucciones y rendimiento',
  '10. Alcance: qué no se migró y por qué',
  '11. Conclusiones y trabajo futuro',
  'Referencias',
  'Anexo A. Configuración del entorno',
  'Anexo B. Comparación setState vs Riverpod',
  'Anexo C. Evidencias censuradas',
  'Anexo D. Guion de sustentación de cinco minutos'
)) { [void]$body.Append((Para $entry 'CoverMeta')) }
[void]$body.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
[void]$body.Append((Para 'BORRADOR. C1–C4 están guardadas. Faltan códigos, URL del repositorio, confirmación de roles y la versión de Semana 11 para comparaciones históricas.' 'Draft'))

$lines=Get-Content -LiteralPath $source -Encoding utf8
$lines = $lines | ForEach-Object {
  $v = $_
  $v = $v.Replace('C3 está guardada y muestra la huella sin el valor del token; antes de insertarla conviene recortar el directorio simulado que aparece debajo de la tarjeta de sesión.', 'C3 muestra la huella sin el valor del token. En este documento se recortó el directorio simulado situado debajo de la tarjeta de sesión, conservando el archivo original.')
  $v = $v.Replace('C4 está guardada y muestra dos actualizaciones de providers; debe recortarse la línea de recarga de Flutter antes de insertarla.', 'C4 muestra dos actualizaciones de providers. En este documento se recortó la línea de recarga de Flutter, conservando el archivo original.')
  $v = $v.Replace('las cuatro capturas guardadas aún deben prepararse para la edición institucional', 'las cuatro capturas están insertadas con los recortes necesarios')
  $v = $v.Replace('Preparación antes de insertar', 'Tratamiento aplicado en Word')
  $v = $v.Replace('Revisar encuadre y datos ajenos.', 'Encuadre y datos ajenos revisados.')
  $v = $v.Replace('Recortar el directorio simulado con nombres y documentos completos.', 'Directorio simulado recortado; original conservado.')
  $v = $v.Replace('Recortar la línea de recarga de Flutter; no atribuir contadores a la imagen.', 'Línea de recarga recortada; la imagen no mide contadores.')
  $v = $v.Replace('Se abrieron y revisaron visualmente, pero aún no se han insertado en el documento paginado.', 'Se abrieron, revisaron e insertaron en este documento paginado. C3 y C4 tienen recortes aplicados dentro de Word; los PNG originales se conservan.')
  $v
}
$started=$false; $inCode=$false; $codeType=''; $code=[System.Collections.Generic.List[string]]::new()
$rows=[System.Collections.Generic.List[object]]::new(); $inTable=$false; $annex=$false
$figNo=2; $drawingId=1
foreach ($line in $lines) {
  if (-not $started) { if ($line -match '^## 1\. ') { $started=$true } else { continue } }
  if ($line -match '^```(.*)$') {
    if (-not $inCode) { $inCode=$true; $codeType=$Matches[1]; $code.Clear() }
    else {
      if ($codeType -eq 'mermaid') { [void]$body.Append((ImageParagraph 'D' 155 (++$drawingId))) }
      else { foreach ($cl in $code) { [void]$body.Append((Para $cl 'Code')) } }
      $inCode=$false; $codeType=''
    }
    continue
  }
  if ($inCode) { $code.Add($line); continue }
  if ($line.StartsWith('|')) {
    if ($line -match '^\|[\s:\-|]+\|\s*$') { continue }
    $cells=[System.Collections.Generic.List[string]]::new()
    foreach ($c in $line.Trim().Trim('|').Split('|')) { $cells.Add($c.Trim()) }
    $rows.Add($cells); $inTable=$true; continue
  }
  if ($inTable) { [void]$body.Append((TableXml $rows)); $rows.Clear(); $inTable=$false }
  if ($line.Trim().Length -eq 0) { continue }
  if ($line -match '^## (.+)$') {
    $heading=$Matches[1]; $break=$heading.StartsWith('Anexo ')
    if ($break) { $annex=$true }
    [void]$body.Append((Para $heading 'Heading1' $break $true))
    continue
  }
  if ($line -match '^### (.+)$') { [void]$body.Append((Para $Matches[1] 'Heading2' $false $true)); continue }
  if ($line -match '^\*\*(Tabla|Figura) ') { [void]$body.Append((Para $line 'Caption' $false $true)); continue }
  if ($line -match '^\*Nota') { [void]$body.Append((Para $line 'Note')); continue }
  $mark=[regex]::Match($line,'\[INSERTAR EVIDENCIA (C[1-4]):')
  if ($mark.Success) {
    $prefix=$line.Substring(0,$mark.Index).Trim()
    if ($prefix -ne '') { [void]$body.Append((Para $prefix)) }
    $key=$mark.Groups[1].Value
    [void]$body.Append((Para ("Figura $figNo. Evidencia $key de la aplicación ejecutada") 'Caption' $false $true))
    $width=if ($annex) { 155 } else { 135 }
    [void]$body.Append((ImageParagraph $key $width (++$drawingId)))
    $figNo++
    continue
  }
  [void]$body.Append((Para $line))
}
if ($inTable) { [void]$body.Append((TableXml $rows)) }

$sect='<w:sectPr><w:headerReference w:type="default" r:id="rIdHeader"/><w:footerReference w:type="default" r:id="rIdFooter"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1361" w:right="1247" w:bottom="1361" w:left="1247" w:header="567" w:footer="567" w:gutter="0"/></w:sectPr>'
$document='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>'+$body.ToString()+$sect+'</w:body></w:document>'
$styles=@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:lang w:val="es-PE"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:styleId="Normal" w:default="1"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="650" w:after="180"/><w:jc w:val="center"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="38"/><w:color w:val="111111"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="400"/><w:jc w:val="center"/></w:pPr><w:rPr><w:sz w:val="28"/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="280" w:after="130"/><w:keepNext/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="210" w:after="90"/><w:keepNext/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Caption"><w:name w:val="Caption"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="130" w:after="50"/><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="18"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableText"><w:name w:val="Table Text"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr><w:rPr><w:sz w:val="18"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableHead"><w:name w:val="Table Head"/><w:basedOn w:val="TableText"/><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableTextSmall"><w:name w:val="Table Text Small"/><w:basedOn w:val="TableText"/><w:rPr><w:sz w:val="17"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableHeadSmall"><w:name w:val="Table Head Small"/><w:basedOn w:val="TableTextSmall"/><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="CoverInstitution"><w:name w:val="Cover Institution"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="280" w:after="160"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="CoverMeta"><w:name w:val="Cover Meta"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="90"/></w:pPr><w:rPr><w:sz w:val="21"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Draft"><w:name w:val="Draft"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="140" w:after="180"/></w:pPr><w:rPr><w:b/><w:color w:val="1F4E79"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Note"><w:name w:val="Note"/><w:basedOn w:val="Normal"/><w:rPr><w:sz w:val="19"/><w:color w:val="444444"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Figure"><w:name w:val="Figure"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="130"/><w:jc w:val="center"/></w:pPr></w:style>
</w:styles>
'@
$settings='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:updateFields w:val="true"/></w:settings>'
$header='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'+(Para 'UNIVERSIDAD ANDINA DEL CUSCO · Facultad de Ingeniería y Arquitectura · Escuela Profesional de Ingeniería de Sistemas' 'CoverMeta' $false $false $true)+'</w:hdr>'
$footer='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:jc w:val="center"/></w:pPr>'+(Run 'Informe técnico · Semana 12 · SIS048 · 2026-II · Página ')+'<w:fldSimple w:instr="PAGE"/></w:p></w:ftr>'
$ct='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>'
$rels='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>'
$dr=[System.Text.StringBuilder]::new()
[void]$dr.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
[void]$dr.Append('<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/><Relationship Id="rIdHeader" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/><Relationship Id="rIdFooter" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>')
foreach ($k in @('D','C1','C2','C3','C4')) { [void]$dr.Append('<Relationship Id="rIdImg'+$k+'" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/'+$k+'.png"/>') }
[void]$dr.Append('</Relationships>')
$core='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Informe técnico Semana 12 ManosSeguras</dc:title><dc:subject>Gestión de estado con Riverpod</dc:subject><dc:description>Borrador para revisión del equipo</dc:description></cp:coreProperties>'
$app='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Microsoft Office Word</Application></Properties>'

function AddText($zip,[string]$name,[string]$xml) {
  $e=$zip.CreateEntry($name,[System.IO.Compression.CompressionLevel]::Optimal)
  $s=$e.Open(); $b=[System.Text.UTF8Encoding]::new($false).GetBytes($xml)
  $s.Write($b,0,$b.Length); $s.Dispose()
}
function AddFile($zip,[string]$name,[string]$path) {
  $e=$zip.CreateEntry($name,[System.IO.Compression.CompressionLevel]::Optimal)
  $s=$e.Open(); $fs=[System.IO.File]::OpenRead($path)
  $fs.CopyTo($s); $fs.Dispose(); $s.Dispose()
}
if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
$fs=[System.IO.File]::Open($target,[System.IO.FileMode]::CreateNew)
$zip=[System.IO.Compression.ZipArchive]::new($fs,[System.IO.Compression.ZipArchiveMode]::Create)
try {
  AddText $zip '[Content_Types].xml' $ct
  AddText $zip '_rels/.rels' $rels
  AddText $zip 'word/document.xml' $document
  AddText $zip 'word/styles.xml' $styles
  AddText $zip 'word/settings.xml' $settings
  AddText $zip 'word/header1.xml' $header
  AddText $zip 'word/footer1.xml' $footer
  AddText $zip 'word/_rels/document.xml.rels' $dr.ToString()
  AddText $zip 'docProps/core.xml' $core
  AddText $zip 'docProps/app.xml' $app
  foreach ($k in @('D','C1','C2','C3','C4')) { AddFile $zip ('word/media/'+$k+'.png') $pics[$k] }
}
finally { $zip.Dispose(); $fs.Dispose() }
Write-Output "Creado $target ($((Get-Item $target).Length) bytes)"
Write-Output "Figuras insertadas: $($drawingId-1); tablas: $(([regex]::Matches($document,'<w:tbl>')).Count)"
