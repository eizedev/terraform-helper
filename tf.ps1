<#PSScriptInfo
.VERSION 1.${VERSION}
.GUID fde96073-cd23-48f2-b85a-1b39d52777e8
.AUTHOR Dave Farinelli
.LICENSEURI https://www.gnu.org/licenses/gpl-3.0.en.html
.PROJECTURI https://github.com/dfar-io/terraform-helper
#>

<#
.DESCRIPTION
 This Terraform helper allows for quickly using Terraform with different backend
 configurations for different projects.
#>

param (
  [Parameter(Mandatory = $True)]
  [string]$command,

  [Parameter(Mandatory = $True)]
  [string]$env
)

$availableCommands = @(
  "apply", "destroy", "create", "delete"
)

function IsValidCommand {
  param (
    [Parameter(Mandatory = $True)]
    [string]$command
  )

  return $availableCommands.Contains($command)
}

function DoesTFDirExist {
  return Test-Path "./tf/"
}

function DoesEnvExist {
  return ((Test-Path "./tf/$env.beconf.tfvars") -and
    (Test-Path "./tf/$env.tfvars") -and
    (Test-Path "./tf/$env.secrets.tfvars"))
}

function CreateEnv {
  function CreateIfNotExists {
    param (
      [Parameter(Mandatory = $True)]
      [string]$path,

      [Parameter(Mandatory = $True)]
      [string]$name,

      [string]$value
    )

    if ($false -eq (Test-Path "$path$name")) {
      New-Item -Path $path -Name $name -ItemType "file" -Value $value | Out-Null
      Write-Output "$path$name created."
    }
  }

  CreateIfNotExists "./tf/" "$env.beconf.tfvars"
  CreateIfNotExists -path "./tf/" -name "$env.tfvars" -value "env = `"$env`""
  CreateIfNotExists "./tf/" "$env.secrets.tfvars"
}

function DeleteEnv {

  Remove-Item "./tf/$env.beconf.tfvars"
  Remove-Item "./tf/$env.tfvars"
  Remove-Item "./tf/$env.secrets.tfvars"
}

function CreateTfFolder {
  WaitForPrompt("tf/ does not exist, create?")
  New-Item -Path ./tf/ -ItemType "directory" | Out-Null
  Write-Output "$path$name created."
}

function WaitForPrompt($prompt) {
  do {
    $value = Read-Host "$prompt ('y' to continue, Ctrl-C to quit)"
  }
  while ($value -notmatch 'y')
}

################################################################################

if ($false -eq (IsValidCommand $command)) {
  Write-Error "Invalid command - currently supported commands are: `
  ${availableCommands}"
  exit 1
}

if ($command -eq "create") {
  if ($false -eq (DoesTFDirExist)) {
    CreateTfFolder
  }

  CreateEnv
  Write-Output "$env environment created, please configure .tfvars files and `
    run the 'apply' command."
  exit 0
}

if ($false -eq (DoesTFDirExist)) {
  Write-Error "tf/ directory does not exist, ensure you are in the correct `
    project and the project has a tf/ directory."
  exit 1
}

if ($false -eq (DoesEnvExist)) {
  Write-Error "Environment configuration doesn't exist (.beconf.tfvars, `
    .tfvars, and .secrets.tfvars). Ensure the environment is entered correctly."
  exit 1
}

if ($command -eq "delete") {
  DeleteEnv
  Write-Output "$env environment deleted."
  exit 0
}

terraform init -backend-config="tf/$env.beconf.tfvars" .\tf
terraform $command -var-file="tf\$env.tfvars" -var-file="tf\$env.secrets.tfvars" .\tf