metadata description = 'Creates an Azure API Management instance.'
param name string
param location string = resourceGroup().location
param tags object = {}

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string = 'noreply@microsoft.com'

@description('The name of the owner of the service')
@minLength(1)
param publisherName string = 'n/a'

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Consumption'

@description('The instance size of this API Management service.')
@allowed([ 0, 1, 2 ])
param skuCount int = 0

@description('Azure Application Insights Name')
param applicationInsightsName string

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  sku: {
    name: sku
    capacity: (sku == 'Consumption') ? 0 : ((sku == 'Developer') ? 1 : skuCount)
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    // Custom properties are not supported for Consumption SKU
    customProperties: sku == 'Consumption' ? {} : {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(applicationInsightsName)) {
  name: 'app-insights-logger'
  parent: apimService
  properties: {
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
    description: 'Logger to Azure Application Insights'
    isBuffered: false
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
  }
}

resource apimNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  name: 'LANDING_APP_URL'
  parent: apimService
  properties: {
    displayName: 'LANDING_APP_URL'
    value: 'https://localhost:5051'
    secret: false
  }
}

resource apimProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  name: 'default'
  parent: apimService
  properties: {
    displayName: 'Default Product'
    description: 'This is the default product created by the template, which includes all APIs.'
    state: 'published'
    subscriptionRequired: true
  }
}

resource apimsubScription 'Microsoft.ApiManagement/service/subscriptions@2023-05-01-preview' = {
  name: 'default'
  parent: apimService
  properties: {
    displayName: 'Default Subscription'
    scope: apimProduct.id
  }
}

var openapi = loadTextContent('openapi-rewriter.yaml')

resource apimApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  name: 'url-proxy-api'
  parent: apimService
  properties: {
    type: 'http'
    displayName: 'URL Proxy API'
    description: 'API to URL shortening service'
    serviceUrl: 'http://localhost'
    path: ''
    subscriptionRequired: true
    format: 'openapi'
    value: openapi
  }
}

resource apimProductApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  name: apimApi.name
  parent: apimProduct
}

resource apimApiOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' existing = {
  name: 'RewriteUrl'
  parent: apimApi
}

var xml = loadTextContent('policy-api-rewriter-operation-rewrite-url.xml')

resource apimApiOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-05-01-preview' = {
  name: 'policy'
  parent: apimApiOperation
  properties: {
    format: 'xml'
    value: xml
  }
}

output apimServiceName string = apimService.name
