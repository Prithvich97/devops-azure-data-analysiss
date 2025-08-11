terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.39.0"
    }
  }
  required_version = ">= 1.2.0"
}


provider "azurerm" {
  features {}
  subscription_id = "f1207822-329f-4b78-936e-45539b8aad1b"
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_data_factory" "adf" {
  name                = var.data_factory_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  public_network_enabled = true  # default networking settings
}

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "datalake" {
  name                     = var.datalake_storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable Data Lake Gen2
  is_hns_enabled = true  # hierarchical namespace
}



# Get current public IP
data "http" "my_ip" {
  url = "https://api.ipify.org/"
}

# Extract IP from response
locals {
  my_public_ip = trim(data.http.my_ip.response_body, "\n")
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  version                      = "12.0"

  public_network_access_enabled = true
  #backup_storage_redundancy = "LRS"
}

# Allow Azure Services to access SQL
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow My Public IP to access SQL
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = local.my_public_ip
  end_ip_address   = local.my_public_ip
}

# SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sql_server.id
  sku_name       = "Basic"
  zone_redundant = false
  
}


resource "azurerm_storage_container" "population" {
  name                  = var.storage_container_name
  storage_account_id   = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "datalake_container" {
  name                  = var.storage_container_name_dl
  storage_account_id   = azurerm_storage_account.datalake.id
  container_access_type = "private"
}

#just too add file can be removed, and file can be addes manually (independent block)
resource "azurerm_storage_blob" "local_file" {
  name                   = "population_by_age.tsv" # blob name in container
  storage_account_name     = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.population.name
  type                   = "Block"
  source                 = "C:\\Users\\prith\\Downloads\\population_by_age.tsv.gz" # local file path
}


#PIPELINE1
#source loinkes service 
resource "azurerm_data_factory_linked_service_azure_blob_storage" "ls_ablob_covidreportingsapc" {
  name            = "ls_ablob_covidreportingsapc"
  data_factory_id = azurerm_data_factory.adf.id

  connection_string = format(
    "DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;EndpointSuffix=core.windows.net",
    azurerm_storage_account.storage.name,
    azurerm_storage_account.storage.primary_access_key
  )

  description = "Linked service for COVID reporting blob storage"

  depends_on = [
    azurerm_storage_account.storage,
  ]
}



resource "azurerm_resource_group_template_deployment" "data_factory_linked_service_dla" {
  name                = "deploy-dla-linked-service"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "type": "Microsoft.DataFactory/factories/linkedservices",
      "apiVersion": "2018-06-01",
      "name": "[concat('${azurerm_data_factory.adf.name}', '/ls_dla_covidreportingdlsapc')]",
      "properties": {
        "type": "AzureBlobFS",
        "typeProperties": {
          "url": "https://${var.datalake_storage_account_name}.dfs.core.windows.net",
          "accountKey": "${var.datalake_storage_account_key}"
        }
      }
    }
  ]
}
TEMPLATE
}

#dataset for source data set blob_storage
resource "azurerm_resource_group_template_deployment" "ds_population_raw_gz" {
  name                = "deploy-ds-population-raw-gz"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "dataFactoryName": {
        "type": "string"
      }
    },
    "resources": [
      {
        "name": "[concat(parameters('dataFactoryName'), '/ds_population_raw_gz')]",
        "type": "Microsoft.DataFactory/factories/datasets",
        "apiVersion": "2018-06-01",
        "properties": {
          "linkedServiceName": {
            "referenceName": "ls_ablob_covidreportingsapc",
            "type": "LinkedServiceReference"
          },
          "type": "DelimitedText",
          "typeProperties": {
            "location": {
              "type": "AzureBlobStorageLocation",
              "container": "population",
              "fileName": "population_by_age.tsv.gz"
            },
            "columnDelimiter": "\t",
            
            "encodingName": "UTF-8",
            "compression": {
              "type": "GZip"},
            "firstRowAsHeader": true,
            "schemaImportType": "FromConnectionStore"
          }
        }
      }
    ]
  }
  TEMPLATE

  parameters_content = jsonencode({
    dataFactoryName = {
      value = azurerm_data_factory.adf.name
    }
  })
}
#dataset for destination Data Lake Gen2
resource "azurerm_resource_group_template_deployment" "ds_population_raw_dls" {
  name                = "deploy-ds-population-raw-dls"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "dataFactoryName": {
      "type": "string"
    }
  },
  "resources": [
    {
      "name": "[concat(parameters('dataFactoryName'), '/ds_population_raw_dls')]",
      "type": "Microsoft.DataFactory/factories/datasets",
      "apiVersion": "2018-06-01",
      "properties": {
        "linkedServiceName": {
          "referenceName": "ls_dla_covidreportingdlsapc",
          "type": "LinkedServiceReference"
        },
        "type": "DelimitedText",
        "typeProperties": {
          "location": {
            "type": "AzureBlobFSLocation",
            "fileSystem": "raw",
            "folderPath": "population",
            "fileName": "population_by_age.tsv"
          },
          "columnDelimiter": "\t",
          
          "encodingName": "UTF-8",
          "firstRowAsHeader": true
        }
      }
    }
  ]
}
TEMPLATE

  parameters_content = jsonencode({
    dataFactoryName = {
      value = azurerm_data_factory.adf.name
    }
  })
  
}

# Pipeline to copy data from Blob Storage to Data Lake Gen2


resource "azurerm_data_factory_pipeline" "pl_ingest_population_data" {
  name            = "pl_ingest_population_data"
  data_factory_id = azurerm_data_factory.adf.id

  concurrency = 1

  activities_json = <<ACTIVITIES
[
  {
    "name": "CheckIfFileExists",
    "type": "GetMetadata",
    "typeProperties": {
      "dataset": {
        "referenceName": "ds_population_raw_gz",
        "type": "DatasetReference"
      },
      "fieldList": ["exists"]
    }
  },
  {
    "name": "GetFileStructure",
    "type": "GetMetadata",
    "dependsOn": [
      {
        "activity": "CheckIfFileExists",
        "dependencyConditions": ["Succeeded"]
      }
    ],
    "typeProperties": {
      "dataset": {
        "referenceName": "ds_population_raw_gz",
        "type": "DatasetReference"
      },
      "fieldList": ["structure"]
    },
    "condition": "@activity('CheckIfFileExists').output.exists"
  },
  {
    "name": "CheckColumnCount",
    "type": "IfCondition",
    "dependsOn": [
      {
        "activity": "GetFileStructure",
        "dependencyConditions": ["Succeeded"]
      }
    ],
    "typeProperties": {
      "expression": {
        "value": "@equals(length(activity('GetFileStructure').output.structure), 13)",
        "type": "Expression"
      },
      "ifTrueActivities": [],
      "ifFalseActivities": [
        {
          "name": "FailDueToColumnCount",
          "type": "Fail",
          "typeProperties": {
            "errorCode": "ColumnCountMismatch",
            "message": "File column count does not match 13"
          }
        }
      ]
    },
    "condition": "@activity('CheckIfFileExists').output.exists"
  },
  {
    "name": "CopyData",
    "type": "Copy",
    "dependsOn": [
      {
        "activity": "CheckColumnCount",
        "dependencyConditions": ["Succeeded"]
      }
    ],
    "typeProperties": {
      "source": {
        "type": "DelimitedTextSource"
      },
      "sink": {
        "type": "DelimitedTextSink"
      }
    },
    "inputs": [
      {
        "referenceName": "ds_population_raw_gz",
        "type": "DatasetReference"
      }
    ],
    "outputs": [
      {
        "referenceName": "ds_population_raw_dls",
        "type": "DatasetReference"
      }
    ],
    "condition": "@activity('CheckIfFileExists').output.exists"
  }
]
ACTIVITIES
}

resource "azurerm_resource_group_template_deployment" "adf_event_grid_trigger" {
  name                = "deploy-adf-event-grid-trigger"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "dataFactoryName": {
      "type": "string"
    },
    "triggerName": {
      "type": "string"
    },
    "storageAccountName": {
      "type": "string"
    },
    "pipelineName": {
      "type": "string"
    }
  },
  "resources": [
    {
      "name": "[concat(parameters('dataFactoryName'), '/', parameters('triggerName'))]",
      "type": "Microsoft.DataFactory/factories/triggers",
      "apiVersion": "2018-06-01",
      "properties": {
        "type": "BlobEventsTrigger",
        "typeProperties": {
          "blobPathBeginsWith": "/population/",
          "events": [
            "Microsoft.Storage.BlobCreated"
          ],
          "scope": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Storage/storageAccounts/', parameters('storageAccountName'))]"
        },
        "pipelines": [
          {
            "pipelineReference": {
              "referenceName": "[parameters('pipelineName')]",
              "type": "PipelineReference"
            },
            "parameters": {}
          }
        ],
        "runtimeState": "Started"
      }
    }
  ]
}
TEMPLATE

  parameters_content = jsonencode({
    dataFactoryName = { value = azurerm_data_factory.adf.name },
    triggerName = { value = "blobUploadTrigger" },
    storageAccountName = { value = "covidreportingsapc" },
    pipelineName = { value = azurerm_data_factory_pipeline.pl_ingest_population_data.name },
  })
}

