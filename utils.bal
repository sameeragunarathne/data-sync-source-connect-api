//  Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
//This software is the property of WSO2 LLC. and its suppliers, if any.
//Dissemination of any information or reproduction of any material contained
//herein is strictly forbidden, unless permitted by WSO2 in accordance with
//the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
//For specific language governing the permissions and limitations under
//this license, please see the license as well as any agreement you’ve
//entered into with WSO2 governing the purchase of this software and any associated services.

import wso2healthcare/healthcare.fhir.r4;
import wso2healthcare/healthcare.clients.fhirr4;

// This utility function is used to construct the http response payload for the FHIR interactions.
isolated function handleResponse(fhirr4:FHIRResponse|fhirr4:FHIRError fhirResponse) returns json {

    if (fhirResponse is fhirr4:FHIRResponse) {
        json|xml 'resource = fhirResponse.'resource;
        if 'resource is json {
            return 'resource;
        } else {
            return getOperationOutcome("XML payload type is not supported.");
        }
    } else {
        if (fhirResponse is fhirr4:FHIRServerError) {
            return getOperationOutcome("Error occured when constructing the response payload.");
        } 
    }
    return {};
}

// This utility function is used to construct the OperationOutcome resource for error scenarios.
isolated function getOperationOutcome(string detail) returns json {

    r4:OperationOutcome operationOutcome = {
        resourceType: "OperationOutcome",
        issue: [
            {
                severity: "error",
                code: "error",
                details: {
                    text: detail
                }
            }
        ]
    };
    return operationOutcome;
}
