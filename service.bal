import ballerina/http;
import ballerina/log;
import wso2healthcare/healthcare.clients.fhirr4;

configurable string base = "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4";
configurable string tokenUrl = "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token";
configurable string clientId = "07fe5f43-527b-4197-a2f7-c176bc22327f";

// FHIR client configuration for Epic.
fhirr4:FHIRConnectorConfig epicConfig = {
    baseURL: base,
    mimeType: fhirr4:FHIR_JSON,
    authConfig: {
        clientId: clientId,
        tokenEndpoint: tokenUrl,
        keyFile: "./privatekey.pem"
    }
};

// Initialize the FHIR client for Epic.
final fhirr4:FHIRConnector fhirConnectorObj = check new (epicConfig);

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9091) {

    # Data sync service resource.
    # + return - response from the source EHR system
    resource function post sync(http:RequestContext ctx, http:Request request) returns json|error {
        json payload = check request.getJsonPayload();
        string id = check payload.id;
        string resourceType = check payload.resourceType;
        log:printInfo("Resource type: " + resourceType + ", Resource Id: " + id);
        // The following example is using FHIR client to connect to the Epic FHIR server to read an Encounter resource.
        fhirr4:FHIRResponse|fhirr4:FHIRError fhirResponse = fhirConnectorObj->getById(resourceType, id);
        if fhirResponse is error {
            log:printError("Error occurred while reading the resource", fhirResponse);
        }
        return handleResponse(fhirResponse);
    }

    resource function post push(http:RequestContext ctx, http:Request request) returns json|error {
        json payload = check request.getJsonPayload();
        fhirr4:FHIRResponse|fhirr4:FHIRError createdEntity = fhirConnectorObj->create(payload);
        return handleResponse(createdEntity);
    }
}
