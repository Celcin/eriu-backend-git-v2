[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]
	[switch]$All,

	[Parameter(Mandatory=$false, Position=0)]
	[string]$Path
)

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($env:OS -eq 'Windows_NT' -and -not (Test-Path /proc/version -ErrorAction SilentlyContinue))
{
	chcp 65001 > $null
}

# -------------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------------

$wslDistro = 'Ubuntu24-Clean'
$wslProjectPath = '/home/hoerster/projects/private/coding/eriu-backend-git-v2'

$excludeDirs = @(
	'vendor',
	'var',
	'node_modules',
	'.git'
)

$excludeFiles = @(
	'composer.lock',
	'package-lock.json'
)

# -------------------------------------------------------------------
# PATH RESOLUTION
# -------------------------------------------------------------------

function Get-ProjectRoot
{
	if (Test-Path /proc/version -ErrorAction SilentlyContinue)
	{
		$scriptDir = $PSScriptRoot

		if ([string]::IsNullOrEmpty($scriptDir))
		{
			$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
		}

		if ([string]::IsNullOrEmpty($scriptDir))
		{
			return $wslProjectPath
		}

		return (Get-Item $scriptDir).Parent.Parent.FullName
	}
	else
	{
		$scriptDir = $PSScriptRoot

		if ([string]::IsNullOrEmpty($scriptDir))
		{
			$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
		}

		if (-not [string]::IsNullOrEmpty($scriptDir) -and $scriptDir -match '\\\\wsl')
		{
			return (Get-Item $scriptDir).Parent.Parent.FullName
		}

		$uncPath = "\\wsl.localhost\$wslDistro" + ($wslProjectPath -replace '/', '\')

		if (-not (Test-Path $uncPath -ErrorAction SilentlyContinue))
		{
			$uncPath = "\\wsl$\$wslDistro" + ($wslProjectPath -replace '/', '\')
		}

		return $uncPath
	}
}

# -------------------------------------------------------------------
# TYPE DETECTION HELPER
# -------------------------------------------------------------------

function Test-IsObject
{
	param($Value)

	if ($null -eq $Value)
	{
		return $false
	}

	if ($Value -is [string] -or $Value -is [System.ValueType])
	{
		return $false
	}

	if ($Value.PSObject.TypeNames -contains 'System.Management.Automation.PSCustomObject')
	{
		return $true
	}

	if ($Value -is [System.Collections.IDictionary])
	{
		return $true
	}

	return $false
}

function Test-IsArray
{
	param($Value)

	if ($null -eq $Value)
	{
		return $false
	}

	if ($Value -is [string])
	{
		return $false
	}

	if (Test-IsObject -Value $Value)
	{
		return $false
	}

	if ($Value -is [System.Collections.IEnumerable])
	{
		return $true
	}

	return $false
}

function Test-IsComplex
{
	param($Value)

	return (Test-IsObject -Value $Value) -or (Test-IsArray -Value $Value)
}

# -------------------------------------------------------------------
# STRING ESCAPING HELPER
# -------------------------------------------------------------------

function Get-EscapedString
{
	param([string]$Value)

	return $Value.Replace('\', '\\').Replace('"', '\"')
}

# -------------------------------------------------------------------
# HELPER: Render arrays and objects recursively
# -------------------------------------------------------------------

function Add-Complex
{
	param(
		[Parameter(Mandatory=$true)][System.Text.StringBuilder]$Sb,
		[Parameter(Mandatory=$true)]$Value,
		[Parameter(Mandatory=$true)][string]$Indent,
		[string]$Comma = ''
	)

	$indentInner = $Indent + "`t"

	if (Test-IsObject -Value $Value)
	{
		$Sb.AppendLine($Indent + '{') | Out-Null
		$props = @($Value.psobject.Properties)
		$propCount = $props.Count

		for ($k = 0; $k -lt $propCount; $k++)
		{
			$p = $props[$k]
			$kname = $p.Name
			$v2 = $p.Value
			$innerComma = if ($k -lt $propCount - 1) { ',' } else { '' }
			$escapedKey = Get-EscapedString -Value $kname

			if ($null -eq $v2)
			{
				$Sb.AppendLine($indentInner + '"' + $escapedKey + '": null' + $innerComma) | Out-Null
			}
			elseif ($v2 -is [bool])
			{
				$boolStr = if ($v2) { 'true' } else { 'false' }
				$Sb.AppendLine($indentInner + '"' + $escapedKey + '": ' + $boolStr + $innerComma) | Out-Null
			}
			elseif (Test-IsComplex -Value $v2)
			{
				$Sb.AppendLine($indentInner + '"' + $escapedKey + '":') | Out-Null
				Add-Complex -Sb $Sb -Value $v2 -Indent $indentInner -Comma $innerComma
			}
			elseif ($v2 -is [int] -or $v2 -is [long] -or $v2 -is [double] -or $v2 -is [decimal])
			{
				$Sb.AppendLine($indentInner + '"' + $escapedKey + '": ' + $v2.ToString() + $innerComma) | Out-Null
			}
			else
			{
				$escaped2 = Get-EscapedString -Value ([string]$v2)
				$Sb.AppendLine($indentInner + '"' + $escapedKey + '": "' + $escaped2 + '"' + $innerComma) | Out-Null
			}
		}

		$Sb.AppendLine($Indent + '}' + $Comma) | Out-Null
		return
	}

	$items = @($Value)
	$Sb.AppendLine($Indent + '[') | Out-Null

	for ($i = 0; $i -lt $items.Count; $i++)
	{
		$item = $items[$i]
		$itemComma = if ($i -lt $items.Count - 1) { ',' } else { '' }

		if ($null -eq $item)
		{
			$Sb.AppendLine($indentInner + 'null' + $itemComma) | Out-Null
		}
		elseif ($item -is [bool])
		{
			$boolStr = if ($item) { 'true' } else { 'false' }
			$Sb.AppendLine($indentInner + $boolStr + $itemComma) | Out-Null
		}
		elseif (Test-IsComplex -Value $item)
		{
			Add-Complex -Sb $Sb -Value $item -Indent $indentInner -Comma $itemComma
		}
		elseif ($item -is [int] -or $item -is [long] -or $item -is [double] -or $item -is [decimal])
		{
			$Sb.AppendLine($indentInner + $item.ToString() + $itemComma) | Out-Null
		}
		else
		{
			$escapedItem = Get-EscapedString -Value ([string]$item)
			$Sb.AppendLine($indentInner + '"' + $escapedItem + '"' + $itemComma) | Out-Null
		}
	}

	$Sb.AppendLine($Indent + ']' + $Comma) | Out-Null
}

# -------------------------------------------------------------------
# MAIN FORMATTER
# -------------------------------------------------------------------

function Format-JSON
{
	param(
		[Parameter(Mandatory=$true)][string]$Json
	)

	$data = $Json | ConvertFrom-Json
	$sb = [System.Text.StringBuilder]::new()
	$indent0 = ''
	$indent1 = "`t"
	$indent2 = "`t`t"

	if (Test-IsArray -Value $data)
	{
		$list = @($data)
		$objCount = $list.Count

		$sb.AppendLine($indent0 + '[') | Out-Null
		$sb.AppendLine('') | Out-Null

		for ($j = 0; $j -lt $objCount; $j++)
		{
			$obj = $list[$j]
			$isLastObj = ($j -eq $objCount - 1)
			$objComma = if ($isLastObj) { '' } else { ',' }

			if ($null -eq $obj)
			{
				$sb.AppendLine($indent1 + 'null' + $objComma) | Out-Null

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}

			if ($obj -is [bool])
			{
				$boolStr = if ($obj) { 'true' } else { 'false' }
				$sb.AppendLine($indent1 + $boolStr + $objComma) | Out-Null

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}

			if ($obj -is [int] -or $obj -is [long] -or $obj -is [double] -or $obj -is [decimal])
			{
				$sb.AppendLine($indent1 + $obj.ToString() + $objComma) | Out-Null

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}

			if ($obj -is [string])
			{
				$escaped = Get-EscapedString -Value ([string]$obj)
				$sb.AppendLine($indent1 + '"' + $escaped + '"' + $objComma) | Out-Null

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}

			if (Test-IsObject -Value $obj)
			{
				$sb.AppendLine($indent1 + '{') | Out-Null

				$props = @($obj.psobject.Properties)
				$propCount = $props.Count

				for ($i = 0; $i -lt $propCount; $i++)
				{
					$prop = $props[$i]
					$key = $prop.Name
					$value = $prop.Value
					$isLast = ($i -eq $propCount - 1)
					$comma = if ($isLast) { '' } else { ',' }
					$escapedKey = Get-EscapedString -Value $key
					$isComplex = Test-IsComplex -Value $value

					if ($null -eq $value)
					{
						$sb.AppendLine($indent2 + '"' + $escapedKey + '": null' + $comma) | Out-Null
					}
					elseif ($value -is [bool])
					{
						$boolStr = if ($value) { 'true' } else { 'false' }
						$sb.AppendLine($indent2 + '"' + $escapedKey + '": ' + $boolStr + $comma) | Out-Null
					}
					elseif ($isComplex)
					{
						$sb.AppendLine($indent2 + '"' + $escapedKey + '":') | Out-Null
						Add-Complex -Sb $sb -Value $value -Indent $indent2 -Comma $comma
					}
					elseif ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal])
					{
						$sb.AppendLine($indent2 + '"' + $escapedKey + '": ' + $value.ToString() + $comma) | Out-Null
					}
					else
					{
						$escaped = Get-EscapedString -Value ([string]$value)
						$sb.AppendLine($indent2 + '"' + $escapedKey + '": "' + $escaped + '"' + $comma) | Out-Null
					}

					if ($isComplex -and -not $isLast)
					{
						$sb.AppendLine('') | Out-Null
					}
				}

				$sb.AppendLine($indent1 + '}' + $objComma) | Out-Null

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}

			if (Test-IsArray -Value $obj)
			{
				Add-Complex -Sb $sb -Value $obj -Indent $indent1 -Comma $objComma

				if (-not $isLastObj)
				{
					$sb.AppendLine('') | Out-Null
				}

				continue
			}
		}

		$sb.AppendLine($indent0 + ']') | Out-Null
	}
	else
	{
		$sb.AppendLine($indent0 + '{') | Out-Null

		$props = @($data.psobject.Properties)
		$propCount = $props.Count

		for ($i = 0; $i -lt $propCount; $i++)
		{
			$prop = $props[$i]
			$key = $prop.Name
			$value = $prop.Value
			$isLast = ($i -eq $propCount - 1)
			$comma = if ($isLast) { '' } else { ',' }
			$escapedKey = Get-EscapedString -Value $key
			$isComplex = Test-IsComplex -Value $value

			if ($null -eq $value)
			{
				$sb.AppendLine($indent1 + '"' + $escapedKey + '": null' + $comma) | Out-Null
			}
			elseif ($value -is [bool])
			{
				$boolStr = if ($value) { 'true' } else { 'false' }
				$sb.AppendLine($indent1 + '"' + $escapedKey + '": ' + $boolStr + $comma) | Out-Null
			}
			elseif ($isComplex)
			{
				$sb.AppendLine($indent1 + '"' + $escapedKey + '":') | Out-Null
				Add-Complex -Sb $sb -Value $value -Indent $indent1 -Comma $comma
			}
			elseif ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal])
			{
				$sb.AppendLine($indent1 + '"' + $escapedKey + '": ' + $value.ToString() + $comma) | Out-Null
			}
			else
			{
				$escaped = Get-EscapedString -Value ([string]$value)
				$sb.AppendLine($indent1 + '"' + $escapedKey + '": "' + $escaped + '"' + $comma) | Out-Null
			}

			if ($isComplex -and -not $isLast)
			{
				$sb.AppendLine('') | Out-Null
			}
		}

		$sb.AppendLine($indent0 + '}') | Out-Null
	}

	return $sb.ToString()
}

# -------------------------------------------------------------------
# DIRECTORY SCANNER
# -------------------------------------------------------------------

function Should-ExcludePath
{
	param(
		[Parameter(Mandatory=$true)][string]$Path
	)

	foreach ($dir in $excludeDirs)
	{
		if ($Path -match "[\\/]$dir[\\/]" -or $Path -match "[\\/]$dir$")
		{
			return $true
		}
	}

	return $false
}

function Should-ExcludeFile
{
	param(
		[Parameter(Mandatory=$true)][string]$FileName
	)

	foreach ($file in $excludeFiles)
	{
		if ($FileName -ieq $file)
		{
			return $true
		}
	}

	return $false
}

# -------------------------------------------------------------------
# SINGLE FILE FORMATTER
# -------------------------------------------------------------------

function Format-SingleFile
{
	param(
		[Parameter(Mandatory=$true)][string]$FilePath,
		[Parameter(Mandatory=$true)][string]$ProjectRoot
	)

	$fullPath = Join-Path -Path $ProjectRoot -ChildPath $FilePath

	if (-not (Test-Path $fullPath -PathType Leaf))
	{
		Write-Host "[ERR]  File not found: $FilePath" -ForegroundColor Red
		return $false
	}

	if (-not $fullPath.EndsWith('.json'))
	{
		Write-Host "[ERR]  Not a JSON file: $FilePath" -ForegroundColor Red
		return $false
	}

	try
	{
		$content = Get-Content -Path $fullPath -Raw -Encoding UTF8

		if ([string]::IsNullOrWhiteSpace($content))
		{
			Write-Host "[ERR]  File is empty: $FilePath" -ForegroundColor Red
			return $false
		}

		$formatted = Format-JSON -Json $content

		$utf8noBom = New-Object System.Text.UTF8Encoding($false)
		[System.IO.File]::WriteAllText($fullPath, $formatted, $utf8noBom)

		Write-Host "[OK]   $FilePath" -ForegroundColor Green
		return $true
	}
	catch
	{
		Write-Host "[ERR]  $FilePath - $($_.Exception.Message)" -ForegroundColor Red
		return $false
	}
}

# -------------------------------------------------------------------
# ALL FILES FORMATTER
# -------------------------------------------------------------------

function Format-AllFiles
{
	param(
		[Parameter(Mandatory=$true)][string]$ProjectRoot
	)

	Write-Host "==================================================" -ForegroundColor Cyan
	Write-Host "JSON Formatter - Scanning Project Tree" -ForegroundColor Cyan
	Write-Host "==================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Excluded Directories: $($excludeDirs -join ', ')" -ForegroundColor DarkGray
	Write-Host "Excluded Files: $($excludeFiles -join ', ')" -ForegroundColor DarkGray
	Write-Host ""

	$jsonFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.json" -Recurse -File -ErrorAction SilentlyContinue

	$processedCount = 0
	$skippedCount = 0
	$errorCount = 0

	foreach ($file in $jsonFiles)
	{
		$relativePath = $file.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/')

		if (Should-ExcludePath -Path $file.FullName)
		{
			Write-Host "[SKIP] $relativePath (excluded directory)" -ForegroundColor DarkGray
			$skippedCount++
			continue
		}

		if (Should-ExcludeFile -FileName $file.Name)
		{
			Write-Host "[SKIP] $relativePath (excluded file)" -ForegroundColor DarkGray
			$skippedCount++
			continue
		}

		try
		{
			$content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

			if ([string]::IsNullOrWhiteSpace($content))
			{
				Write-Host "[SKIP] $relativePath (empty file)" -ForegroundColor DarkGray
				$skippedCount++
				continue
			}

			$formatted = Format-JSON -Json $content

			$utf8noBom = New-Object System.Text.UTF8Encoding($false)
			[System.IO.File]::WriteAllText($file.FullName, $formatted, $utf8noBom)

			Write-Host "[OK]   $relativePath" -ForegroundColor Green
			$processedCount++
		}
		catch
		{
			Write-Host "[ERR]  $relativePath - $($_.Exception.Message)" -ForegroundColor Red
			$errorCount++
		}
	}

	Write-Host ""
	Write-Host "==================================================" -ForegroundColor Cyan
	Write-Host "Summary" -ForegroundColor Cyan
	Write-Host "==================================================" -ForegroundColor Cyan
	Write-Host "Processed: $processedCount" -ForegroundColor Green
	Write-Host "Skipped:   $skippedCount" -ForegroundColor Yellow
	Write-Host "Errors:    $errorCount" -ForegroundColor Red
	Write-Host ""
}

# -------------------------------------------------------------------
# MAIN EXECUTION
# -------------------------------------------------------------------

if (-not $All -and [string]::IsNullOrEmpty($Path))
{
	Write-Host "Usage:" -ForegroundColor Yellow
	Write-Host "  Format all JSON files:    .\format-json.ps1 -All" -ForegroundColor White
	Write-Host "  Format single file:       .\format-json.ps1 path/to/file.json" -ForegroundColor White
	Write-Host ""
	exit 1
}

if ($All -and -not [string]::IsNullOrEmpty($Path))
{
	Write-Host "[ERR]  Cannot use -All flag together with a file path" -ForegroundColor Red
	exit 1
}

$projectRoot = Get-ProjectRoot

if ($All)
{
	Format-AllFiles -ProjectRoot $projectRoot
}
else
{
	Format-SingleFile -FilePath $Path -ProjectRoot $projectRoot
}