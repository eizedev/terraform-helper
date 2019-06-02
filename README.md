# terraform-helper
PowerShell script to assist with running Terraform for multiple projects and environments.

## Installation

To install from the PowerShell Gallery:

```
Install-Script -Name tf
```

## Usage

To use, when in a directory with Terraform files stored in `/tf`:

```
tf apply prod
tf destroy prod
```

When requested whether to overwrite state changes, make sure to select *No*.
