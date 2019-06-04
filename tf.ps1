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
  "apply", "destroy"
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

################################################################################

if ($false -eq (IsValidCommand $command)) {
  Write-Error "Invalid command - currently supported commands are: `
  ${availableCommands}"
  exit 1
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

terraform init -backend-config="tf/$env.beconf.tfvars" .\tf
terraform $command -var-file="tf\$env.tfvars" -var-file="tf\$env.secrets.tfvars" .\tf