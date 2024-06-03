targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Location for the OpenAI resource')
// https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
@allowed([
  'australiaeast'
  'brazilsouth'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'northcentralus'
  'norwayeast'
  'southafricanorth'
  'southcentralus'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
  'westeurope'
  'westus'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

param productivityAppExists bool
@secure()
param productivityAppDefinition object

var abbrs = loadJsonContent('./abbreviations.json')

@description('Name of the OpenAI resource group. If not specified, the resource group name will be generated.')
param openAiResourceGroupName string = ''

@description('Name of the GPT model to deploy')
param gptModelName string = 'gpt-35-turbo'

@description('Version of the GPT model to deploy')
// See version availability in this table:
// https://learn.microsoft.com/azure/ai-services/openai/concepts/models#gpt-4-and-gpt-4-turbo-preview-models
param gptModelVersion string = '0125'

@description('Name of the model deployment')
param gptDeploymentName string = 'mygptdeployment'

@description('Capacity of the GPT deployment')
// You can increase this, but capacity is limited per model/region, so you will get errors if you go over
// https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits
param gptDeploymentCapacity int = 30

@description('Id of the user or app to assign application roles')
param principalId string = ''

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var prefix = '${environmentName}${resourceToken}'
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' =
  if (empty(openAiResourceGroupName)) {
    name: '${prefix}-rg'
    location: location
    tags: tags
  }

resource openAiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing =
  if (!empty(openAiResourceGroupName)) {
    name: !empty(openAiResourceGroupName) ? openAiResourceGroupName : resourceGroup.name
  }

module openAi 'core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: openAiResourceGroup
  params: {
    name: '${prefix}-openai'
    location: location
    tags: tags
    sku: {
      name: 'S0'
    }
    disableLocalAuth: true
    deployments: [
      {
        name: gptDeploymentName
        model: {
          format: 'OpenAI'
          name: gptModelName
          version: gptModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: gptDeploymentCapacity
        }
      }
    ]
  }
}

// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = {
  scope: openAiResourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

module monitoring './shared/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
  }
  scope: resourceGroup
}

module dashboard './shared/dashboard-web.bicep' = {
  name: 'dashboard'
  params: {
    name: '${abbrs.portalDashboards}${resourceToken}'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    location: location
    tags: tags
  }
  scope: resourceGroup
}

module registry './shared/registry.bicep' = {
  name: 'registry'
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
  scope: resourceGroup
}

module keyVault './shared/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    tags: tags
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    principalId: principalId
  }
  scope: resourceGroup
}

module appsEnv './shared/apps-env.bicep' = {
  name: 'apps-env'
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
  scope: resourceGroup
}

module productivityApp './app/productivity_app.bicep' = {
  name: 'productivity_app'
  params: {
    name: '${abbrs.appContainerApps}productivity-${resourceToken}'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}productivity-${resourceToken}'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: productivityAppExists
    appDefinition: productivityAppDefinition
  }
  scope: resourceGroup
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer

// Specific to Azure OpenAI
output AZURE_OPENAI_SERVICE string = openAi.outputs.name
output AZURE_OPENAI_GPT_MODEL string = gptModelName
output AZURE_OPENAI_GPT_DEPLOYMENT string = gptDeploymentName
