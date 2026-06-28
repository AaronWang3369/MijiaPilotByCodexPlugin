param(
  [string]$ApiUrl = $env:MIJIA_API_URL,
  [string]$ExpectedPython = "",
  [string]$InstallDir = "$env:USERPROFILE\mijia-control"
)

$ErrorActionPreference = "Continue"

function Write-Check {
  param(
    [string]$Name,
    [bool]$Ok,
    [string]$Detail
  )

  $status = if ($Ok) { "OK" } else { "MISSING" }
  Write-Host ("[{0}] {1}: {2}" -f $status, $Name, $Detail)
}

function Find-Python {
  function Test-Python {
    param(
      [string]$Command,
      [string[]]$Args = @(),
      [string]$Display = $Command
    )

    if (-not $Command) {
      return $null
    }

    & $Command @Args -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) {
      return @{
        Command = $Command
        Args = $Args
        Display = $Display
      }
    }

    return $null
  }

  if ($ExpectedPython -and (Test-Path -LiteralPath $ExpectedPython)) {
    $resolved = (Resolve-Path -LiteralPath $ExpectedPython).Path
    $result = Test-Python -Command $resolved
    if ($result) {
      return $result
    }
  }

  $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
  if ($pythonCommand) {
    $result = Test-Python -Command $pythonCommand.Source
    if ($result) {
      return $result
    }
  }

  $pyCommand = Get-Command py -ErrorAction SilentlyContinue
  if ($pyCommand) {
    $result = Test-Python -Command $pyCommand.Source -Args @("-3") -Display "$($pyCommand.Source) -3"
    if ($result) {
      return $result
    }
  }

  $knownPaths = @(
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
    "$env:ProgramFiles\Python312\python.exe",
    "$env:ProgramFiles\Python311\python.exe"
  )

  foreach ($candidate in $knownPaths) {
    if (Test-Path -LiteralPath $candidate) {
      $result = Test-Python -Command $candidate
      if ($result) {
        return $result
      }
    }
  }

  return $null
}

function Find-MijiaCli {
  $mijiaCli = Get-Command mijia-control -ErrorAction SilentlyContinue
  if ($mijiaCli) {
    return @{
      Path = $mijiaCli.Source
      OnPath = $true
    }
  }

  $knownCliPaths = @()
  if ($ExpectedPython) {
    $expectedPythonDir = Split-Path -Parent $ExpectedPython
    $knownCliPaths += (Join-Path $expectedPythonDir "mijia-control.exe")
  }
  if ($InstallDir) {
    $knownCliPaths += (Join-Path $InstallDir "venv\Scripts\mijia-control.exe")
  }

  foreach ($candidate in $knownCliPaths) {
    if (Test-Path -LiteralPath $candidate) {
      return @{
        Path = (Resolve-Path -LiteralPath $candidate).Path
        OnPath = $false
      }
    }
  }

  return $null
}

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
Write-Check "git" ([bool]$gitCommand) ($(if ($gitCommand) { $gitCommand.Source } else { "Install Git for Windows or run winget install -e --id Git.Git" }))

$pythonPath = Find-Python
Write-Check "python" ([bool]$pythonPath) ($(if ($pythonPath) { $pythonPath.Display } else { "Install Python 3.10+ or run winget install -e --id Python.Python.3.12" }))

if ($pythonPath) {
  & $pythonPath.Command @($pythonPath.Args) -c "import sys; print(sys.version)"
  & $pythonPath.Command @($pythonPath.Args) -c "import mcp_server, mijia_cli; print('mijia-control imports OK')" 2>$null
  $modulesOk = $LASTEXITCODE -eq 0
  $modulesDetail = if ($modulesOk) { "imports OK" } else { "Need upstream install: pip install -e `".[mcp]`" or run scripts\setup-windows.ps1" }
  Write-Check "mijia-control Python modules" $modulesOk $modulesDetail
}

$mijiaCli = Find-MijiaCli
Write-Check "mijia-control CLI" ([bool]$mijiaCli) ($(if ($mijiaCli) { if ($mijiaCli.OnPath) { "$($mijiaCli.Path) (on PATH)" } else { "$($mijiaCli.Path) (not on PATH; use this absolute path or activate the venv)" } } else { "Install upstream with scripts\setup-windows.ps1 or pip install -e `".[mcp]`"" }))

Write-Check "MIJIA_API_URL" ([bool]$ApiUrl) ($(if ($ApiUrl) { $ApiUrl } else { "Set to upstream API, e.g. http://127.0.0.1:5000/api" }))
Write-Check "MIJIA_TOKEN" ([bool]$env:MIJIA_TOKEN) ($(if ($env:MIJIA_TOKEN) { "set" } else { "not set; obtain with mijia-control login or upstream JWT API" }))

if ($ApiUrl) {
  try {
    $healthUrl = $ApiUrl.TrimEnd("/") + "/auth/me"
    $headers = @{}
    if ($env:MIJIA_TOKEN) {
      $headers["Authorization"] = "Bearer $env:MIJIA_TOKEN"
    }
    Invoke-WebRequest -Uri $healthUrl -Headers $headers -Method GET -TimeoutSec 5 | Out-Null
    Write-Check "mijia-control API reachability" $true $healthUrl
  } catch {
    $response = $_.Exception.Response
    if ($response -and $response.StatusCode) {
      Write-Check "mijia-control API reachability" $true "$healthUrl returned HTTP $([int]$response.StatusCode), so the service is reachable"
    } else {
      Write-Check "mijia-control API reachability" $false "Could not connect to $healthUrl. The web service may be stopped."
    }
  }
}
