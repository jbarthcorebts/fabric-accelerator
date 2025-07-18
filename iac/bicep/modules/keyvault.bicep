
// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('Key Vault name')
param keyvault_name string

@description('Purview Account name')
param purview_account_name string

@description('Resource group of Purview Account')
param purviewrg string

@description('Flag to indicate whether to enable integration of data platform resources with either an existing or new Purview resource')
param enable_purview bool=true

// Variables
var suffix = uniqueString(resourceGroup().id)
var keyvault_uniquename = '${keyvault_name}-${suffix}'


// Create Key Vault
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' ={
  name: keyvault_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  properties:{
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    // Default Access Policies. Replace the ObjectID's with your user/group id
    accessPolicies:[
      { tenantId: subscription().tenantId
        objectId: '535f92a8-72bf-4202-8e8f-f77f3cad62eb' // Replace this with your user/group ObjectID
        permissions: {secrets:['list','get','set']}
      }
      { tenantId: subscription().tenantId
        objectId: '140432a2-388c-4978-b93f-78804c7f2df2' // Replace this with your user/group ObjectID
        permissions: {secrets:['list','get']}
      }
    ]
  }
}

// Create Key Vault Access Policies for Purview
resource existing_purview_account 'Microsoft.Purview/accounts@2021-07-01' existing = if(enable_purview) {
    name: purview_account_name
    scope: resourceGroup(purviewrg)
  }
  
resource this_keyvault_accesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = if(enable_purview) {
  name: 'add'
  parent: keyvault
  properties: {
    accessPolicies: [
      { tenantId: subscription().tenantId
        //objectId: existing_purview_account.identity.principalId
        objectId: ''
        permissions: { secrets:  ['list','get']}

      }
    ]
  }
}

output keyvault_name string = keyvault.name
output existing_purview_account_name string = existing_purview_account.name
