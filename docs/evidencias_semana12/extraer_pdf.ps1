param([Parameter(Mandatory=$true)][string]$Archivo, [Parameter(Mandatory=$true)][string]$Salida)
$bytes = [IO.File]::ReadAllBytes((Resolve-Path $Archivo))
$latin = [Text.Encoding]::GetEncoding(28591)
$contenido = $latin.GetString($bytes)
$bloques = [Text.StringBuilder]::new()
$flujos = @{}
foreach ($m in [regex]::Matches($contenido, '(?s)(\d+) 0 obj((?:(?!endobj).)*?)stream\r?\n(.*?)\r?\nendstream')) {
  $numero = $m.Groups[1].Value
  $cabecera = $m.Groups[2].Value
  if ($cabecera -notmatch '/FlateDecode') { continue }
  $comprimido = $latin.GetBytes($m.Groups[3].Value)
  try {
    $memoria = [IO.MemoryStream]::new($comprimido, 2, $comprimido.Length - 6)
    $deflate = [IO.Compression.DeflateStream]::new($memoria, [IO.Compression.CompressionMode]::Decompress)
    $destino = [IO.MemoryStream]::new()
    $deflate.CopyTo($destino)
    $descomprimido = $latin.GetString($destino.ToArray())
    $flujos[$numero] = $descomprimido
    if ($descomprimido -match 'BT|beginbfchar|beginbfrange') {
      [void]$bloques.AppendLine("`n===== OBJETO $numero =====`n")
      [void]$bloques.AppendLine($descomprimido)
    }
    $deflate.Dispose(); $memoria.Dispose(); $destino.Dispose()
  } catch { }
}
[IO.File]::WriteAllText((Join-Path (Get-Location) $Salida), $bloques.ToString(), [Text.Encoding]::UTF8)
Write-Output "Objetos extraídos: $([regex]::Matches($bloques.ToString(), '===== OBJETO').Count)"

$objetos = @{}
function TextoUnicodeHex([string]$hex) {
  $resultado = [Text.StringBuilder]::new()
  for ($j=0; $j+3 -lt $hex.Length; $j+=4) {
    [void]$resultado.Append([char][Convert]::ToInt32($hex.Substring($j,4),16))
  }
  return $resultado.ToString()
}
foreach ($m in [regex]::Matches($contenido, '(?s)(\d+) 0 obj(.*?)endobj')) {
  $objetos[$m.Groups[1].Value] = $m.Groups[2].Value
}
$fuentes = @{}
$anchuras = @{}
foreach ($id in $objetos.Keys) {
  if ($objetos[$id] -match '(?s)/Type\s*/Font\b.*?/ToUnicode\s*(\d+) 0 R') {
    $mapa = @{}
    $cmap = $flujos[$Matches[1]]
    if ($cmap) {
      $anchuras[$id] = if ($cmap -match '<([0-9A-Fa-f]+)>\s*<[0-9A-Fa-f]+>\s*\r?\nendcodespacerange') { $Matches[1].Length } else { 4 }
      foreach ($fila in ($cmap -split "`n")) {
        if ($fila -match '^<([0-9A-Fa-f]+)> <([0-9A-Fa-f]+)>$') {
          $mapa[[Convert]::ToInt32($Matches[1],16)] = TextoUnicodeHex $Matches[2]
        } elseif ($fila -match '^<([0-9A-Fa-f]+)> <([0-9A-Fa-f]+)> <([0-9A-Fa-f]+)>$') {
          $inicio=[Convert]::ToInt32($Matches[1],16); $fin=[Convert]::ToInt32($Matches[2],16); $valor=[Convert]::ToInt32($Matches[3],16)
          if ($Matches[3].Length -eq 4) {
            for ($codigo=$inicio; $codigo -le $fin; $codigo++) { $mapa[$codigo] = [string][char]($valor+$codigo-$inicio) }
          }
        }
      }
      $fuentes[$id] = $mapa
    }
  }
}
$texto = [Text.StringBuilder]::new()
Write-Output "Fuentes: $($fuentes.Count); flujo 13: $($flujos.ContainsKey('13')); objetos: $($objetos.Count)"
$pagina=0
foreach ($id in ($objetos.Keys | Sort-Object { [int]$_ })) {
  $obj = $objetos[$id]
  if ($obj -notmatch '/Type\s*/Page\b') { continue }
  $pagina++
  [void]$texto.AppendLine("`n===== PÁGINA $pagina =====")
  if ($obj -notmatch '/Contents\s*(\d+) 0 R') { continue }
  $flujo = $flujos[$Matches[1]]
  $refs = @{}
  $recursos = $obj
  if ($obj -match '/Resources\s*(\d+) 0 R') { $recursos = $objetos[$Matches[1]] }
  if ($recursos -match '/Font\s*(\d+) 0 R') { $recursos = $objetos[$Matches[1]] }
  foreach ($ref in [regex]::Matches($recursos, '/F(\d+)\s*(\d+) 0 R')) { $refs[$ref.Groups[1].Value] = $ref.Groups[2].Value }
  $fuenteActual = $null
  foreach ($bt in [regex]::Matches($flujo, '(?s)BT(.*?)ET')) {
    $fragmento = $bt.Groups[1].Value
    if ($fragmento -match '/F(\d+)\s+[\d.]+\s+Tf') { $fuenteActual = $refs[$Matches[1]] }
    $mapa = $fuentes[$fuenteActual]
    $linea = [Text.StringBuilder]::new()
    foreach ($cadena in [regex]::Matches($fragmento, '<([0-9A-Fa-f]+)>')) {
      $hex = $cadena.Groups[1].Value
      $ancho = $anchuras[$fuenteActual]
      if (!$ancho) { $ancho = 4 }
        for ($i=0; $i+$ancho-1 -lt $hex.Length; $i+=$ancho) {
          $c=[Convert]::ToInt32($hex.Substring($i,$ancho),16)
          if ($mapa -and $mapa.ContainsKey($c)) { [void]$linea.Append($mapa[$c]) }
        }
    }
    if ($linea.Length -gt 0) { [void]$texto.AppendLine($linea.ToString()) }
  }
}
$textoSalida = [IO.Path]::ChangeExtension((Join-Path (Get-Location) $Salida), '.decodificado.txt')
[IO.File]::WriteAllText($textoSalida, $texto.ToString(), [Text.Encoding]::UTF8)
Write-Output "Páginas decodificadas: $pagina"
