param(
  [string]$InstallDir = "$env:USERPROFILE\mijia-control",
  [string]$RepoUrl = "https://github.com/handsomejustin/mijia-control.git",
  [switch]$SkipClone,
  [switch]$InstallPythonWithWinget
)

$ErrorActionPreference = "Stop"

function Require-Command {
  param(
    [string]$Name,
    [string]$InstallHint
  )

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $command) {
    throw "$Name not found. $InstallHint"
  }
  return $command.Source
}

function Resolve-PythonCommand {
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

  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python) {
    $result = Test-Python -Command $python.Source
    if ($result) {
      return $result
    }
  }

  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    $result = Test-Python -Command $py.Source -Args @("-3") -Display "$($py.Source) -3"
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

  throw "Python 3.10+ not found. Install it first, for example: winget install -e --id Python.Python.3.12"
}

Require-Command git "Install Git for Windows, for example: winget install -e --id Git.Git" | Out-Null
try {
  $pythonCommand = Resolve-PythonCommand
} catch {
  if (-not $InstallPythonWithWinget) {
    throw "$($_.Exception.Message). To let this script install Python with winget, rerun it with -InstallPythonWithWinget."
  }

  Require-Command winget "Install Python manually from https://www.python.org/downloads/windows/ if winget is unavailable." | Out-Null
  winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  $pythonCommand = Resolve-PythonCommand
}

if (-not (Test-Path -LiteralPath $InstallDir)) {
  if ($SkipClone) {
    throw "InstallDir does not exist and -SkipClone was used: $InstallDir"
  }
  git clone $RepoUrl $InstallDir
} else {
  Write-Host "Using existing upstream directory: $InstallDir"
}

Push-Location $InstallDir
try {
  $venvDir = Join-Path $InstallDir "venv"
  $venvPython = Join-Path $venvDir "Scripts\python.exe"

  if (-not (Test-Path -LiteralPath $venvPython)) {
    & $pythonCommand.Command @($pythonCommand.Args) -m venv $venvDir
  }

  & $venvPython -m pip install --upgrade pip
  & $venvPython -m pip install -e ".[mcp]"
  & $venvPython -c "import mcp_server, mijia_cli; print('mijia-control imports OK')"

  $escapedPython = $venvPython.Replace("\", "\\")
  Write-Host ""
  Write-Host "Upstream mijia-control MCP runtime is ready."
  Write-Host "Use this Python path for Codex MCP if plain 'python' is not on PATH:"
  Write-Host $venvPython
  Write-Host ""
  Write-Host "Local .mcp.json command override example:"
  Write-Host @"
{
  "mcpServers": {
    "mijia-control": {
      "type": "stdio",
      "command": "$escapedPython",
      "args": ["-m", "mcp_server"],
      "env": {
        "MCP_TRANSPORT": "stdio"
      },
      "env_vars": ["MIJIA_API_URL", "MIJIA_TOKEN"]
    }
  }
}
"@
  Write-Host ""
  Write-Host "Next steps:"
  Write-Host "1. Start upstream web service from $InstallDir with: .\venv\Scripts\python.exe run.py"
  Write-Host "2. Log in with: .\venv\Scripts\mijia-control.exe login"
  Write-Host "3. Set MIJIA_API_URL and MIJIA_TOKEN in the environment used by Codex."
  Write-Host "4. Start a new Codex thread so plugin Skill/MCP config is loaded."
} finally {
  Pop-Location
}
