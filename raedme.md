#step -1

how to get sub id in azure ----->(az account show --query id --output tsv)
#loginto your account and set subscription
az login 
az account show
az account set --subscription "Azure subscription 1"


#step-2
 - change subscription_id in main.tf, if ussing diff account (for azure datafactory)
steps:
  - terraform init
  - terraform plan
  - terraform apply
- now creating storage account , upadted the config 
  - terraform plan
  - terraform apply
#download azure stoarge explorer  

step-3

craeted sql datbase and server 
for redundancy have to change manully to lrs

step-4
when creating pipeline-1, we need to mention key 

        Steps to get the key:
        In Azure Portal, go to your storage account (covidreportingsapc).

        Click on Access keys under Security + networking.

        Copy one of the key values (Key1 or Key2).

        Paste that key as the value for covidreportingsapc_account_key in your Terraform variables.
step-5
when craeted data sets for the linkes sevices need to do some changes manually after deploying like encryption , only for source  data set 

delete command , can come in handy 
az deployment group delete --name deploy-ds-population-raw-gz --resource-group covid-reporting-rg
