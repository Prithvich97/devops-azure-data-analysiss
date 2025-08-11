output "data_factory_id" {
  value = azurerm_data_factory.adf.id
}
output "data_factory_name" {
  value = azurerm_data_factory.adf.name
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "storage_account_primary_blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}
output "datalake_account_id" {
  value = azurerm_storage_account.datalake.id
}

output "datalake_blob_endpoint" {
  value = azurerm_storage_account.datalake.primary_blob_endpoint
}
