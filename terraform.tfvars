    resource_group_name = "covid-reporting-rg"
    data_factory_name   = "covid-reporting-adf-prithvi"
    location            = "West US 2"
    storage_account_name = "covidreportingsapc"
    datalake_storage_account_name = "covidreportingdlsapc"

    sql_server_name     = "covid-srv-pcs1"
    sql_database_name   = "covid-db-pc"
    sql_admin_login     = "prithvi"
    sql_admin_password  = "Covid@2020"
    storage_container_name = "population"
    storage_container_name1 = "config"
    storage_container_name_dl = "raw"
    covidreportingsapc_account_key = "zSCUogZnwHB3sp7M0O+O8nLkjt3FpDY/8EL5NoA0X7URFbI5xkgmEMb06OehCC5kdBjBbH2ZZqza+ASt1d68/w=="#blob sa key
    datalake_storage_account_key ="sSMzaYPMAiGID7db2tx2zQHAGy2ScGkU9V2sasTKFHZoYgk/rxOYBKidwnfKT2gXz7pL2EYA++im+AStp4H/HA=="#destination storage account key, dla sa
    population_file_name        = "population_by_age.tsv.gz"
    files_to_be_analyzed        = "ecdc_file_list.json"
    population_file_delimiter   = "\t"
    population_file_compression = "GZip"