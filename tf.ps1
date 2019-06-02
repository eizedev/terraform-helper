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
  [string]$command,
  [string]$env
)

terraform init -backend-config="tf/$env.beconf.tfvars" .\tf

if ($False -eq (Test-Path "./tf/$env.secrets.tfvars")) {
  Write-Output  "Running without secrets .tfvars"
  terraform $command -var-file="tf\$env.tfvars" .\tf
  exit 0
}

terraform $command -var-file="tf\$env.tfvars" -var-file="tf\$env.secrets.tfvars" .\tf