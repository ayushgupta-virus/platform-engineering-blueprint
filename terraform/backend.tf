###############################################################################
# Remote state backend (Azure Storage).
#
# The backend cannot use variables, so values are supplied at init time:
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=sttfstate<unique>" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=platform/staging.tfstate"
#
# Create the storage account once with terraform/bootstrap before running this.
###############################################################################

terraform {
  backend "azurerm" {}
}
