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

  [string]$env
)

$availableCommands = @(
  "apply", "destroy", "create", "delete", "list"
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

  $beconfContents = @"
resource_group_name = "RG_NAME"
storage_account_name = "terraform"
container_name = "terraformstate"
key = "terraformstate-$env"
access_key = "ACCESS_KEY"
"@

  CreateIfNotExists -path "./tf/" -name "$env.beconf.tfvars" `
    -value $beconfContents
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

function ListEnvironments() {
  $envFiles = @{ }
  $envFiles = Get-ChildItem -Path tf/* -Include *.tfvars | `
    Select-Object -Property Name

  $envFiles | ForEach-Object -Process {
    $_.Name = $_.Name.Substring(0, $_.Name.IndexOf("."))
  }

  return $envFiles.Name | Select-Object -Unique
}

function RunTerraformCommands() {
  param (
    [Parameter(Mandatory = $True)]
    [string]$tfCommand,

    [Parameter(Mandatory = $True)]
    [string]$tfEnv
  )

  terraform init -backend-config="tf/$tfEnv.beconf.tfvars" ./tf
  terraform $tfCommand `
    -var-file="tf/$tfEnv.tfvars" -var-file="tf/$tfEnv.secrets.tfvars" ./tf
}

################################################################################

if ($false -eq (IsValidCommand $command)) {
  Write-Error "Invalid command - currently supported commands are: `
  ${availableCommands}"
  exit 1
}

if ($command -eq "list") {
  ListEnvironments
  exit 0;
}

if ($null -eq $env) {
  Write-Output "'env' parameter is required, please provide an environment."
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

if ($false -eq (DoesEnvExist) -and $env -ne "all") {
  Write-Error "Environment configuration '$env' doesn't exist (.beconf.tfvars, `
    .tfvars, and .secrets.tfvars). Ensure the environment is entered correctly."
  exit 1
}

if ($command -eq "delete") {
  DeleteEnv
  Write-Output "$env environment deleted."
  exit 0
}

if ($env -eq "all") {
  ListEnvironments | ForEach-Object -Process {
    RunTerraformCommands -tfCommand $command -tfEnv $_
  }
}
else {
  RunTerraformCommands -tfCommand $command -tfEnv $env
}

