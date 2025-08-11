variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "East US"
}

variable "data_factory_name" {
  type        = string
  description = "Name of the Azure Data Factory"
}
variable "data_factory_id" {
  type        = string
  description = "ID of the Azure Data Factory"
  default     = ""
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name of the storage account"
}

variable "datalake_storage_account_name" {
  type        = string
  description = "Globally unique name of the Data Lake Gen2 storage account"
}

variable "sql_server_name" {
  type        = string
  description = "Name of the SQL Server"
}

variable "sql_database_name" {
  type        = string
  description = "Name of the SQL Database"
}

variable "sql_admin_login" {
  type        = string
  description = "Admin username for SQL Server"
}

variable "sql_admin_password" {
  type        = string
  description = "Admin password for SQL Server"
  sensitive   = true
}


variable "storage_container_name" {
  type        = string
  description = "Name of the blob container"
}
variable "storage_container_name_dl" {
  type        = string
  description = "Name of the blob container"
}

variable "covidreportingsapc_account_key" {
  type      = string
  sensitive = true
}

variable "datalake_storage_account_key" {
  type      = string
  sensitive = true
}