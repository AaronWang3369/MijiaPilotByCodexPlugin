param(
  [string]$ApiUrl = $env:MIJIA_API_URL,
  [string]$ExpectedPython = ""
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
  if ($ExpectedPython -and (Test-Path -LiteralPath $ExpectedPython)) {
    $resolved = (Resolve-Path -LiteralPath $ExpectedPython).Path
    & $resolved -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) {
      return @{
        Command = $resolved
        Args = @()
        Display = $resolved
      }
    }
  }

  $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
  if ($pythonCommand) {
    & $pythonCommand.Source -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) {
      return @{
        Command = $pythonCommand.Source
        Args = @()
        Display = $pythonCommand.Source
      }
    }
  }

  $pyCommand = Get-Command py -ErrorAction SilentlyContinue
  if ($pyCommand) {
    & $pyCommand.Source -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) {
      return @{
        Command = $pyCommand.Source
        Args = @("-3")
        Display = "$($pyCommand.Source) -3"
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
  $modulesDetail = if ($modulesOk) { "imports OK" } else { "Need upstream install: pip install -e `".[mcp]`"" }
  Write-Check "mijia-control Python modules" $modulesOk $modulesDetail
}

$mijiaCli = Get-Command mijia-control -ErrorAction SilentlyContinue
Write-Check "mijia-control CLI on PATH" ([bool]$mijiaCli) ($(if ($mijiaCli) { $mijiaCli.Source } else { "Optional for MCP, but useful for login and diagnostics" }))

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
    Write-Check "mijia-control API reachability" $false "Could not complete GET $healthUrl. The web service may be stopped or token may be invalid."
  }
}
