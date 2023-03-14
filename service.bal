import ballerina/http;
import wso2healthcare/healthcare.hl7v23;
import wso2healthcare/healthcare.hl7;
import ballerina/log;

final hl7:HL7Parser hl7Parser = new ();
final hl7:HL7Encoder hl7Encoder = new ();

configurable string hl7ServerIP = "20.163.213.27";
configurable int hl7ServerPort = 9988;

configurable string v2ToFHIRServiceUrl = "http://localhost:9090";

final http:Client v2ToFHIRServiceAPI = check new (v2ToFHIRServiceUrl);

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9091) {

    # Triggers data sync task
    # + return - task id or error
    resource function post sync(http:RequestContext ctx, http:Request request) returns http:Response|error {
        json payload = check request.getJsonPayload();
        string id = check payload.id;

        hl7v23:QRY_A19 qry_a19 = {
            msh: {
                msh3: {hd1: "ADT1"},
                msh4: {hd1: "MCM"},
                msh5: {hd1: "LABADT"},
                msh6: {hd1: "MCM"},
                msh8: "SECURITY",
                msh9: {cm_msg1: "QRY", cm_msg2: "A19"},
                msh10: "MSG00001",
                msh11: {pt1: "P"},
                msh12: "2.3"
            },
            qrd: {
                qrd1: {ts1: "20220828104856+0000"},
                qrd2: "R",
                qrd3: "I",
                qrd4: "QueryID01",
                qrd8: [{xcn1: id}]
            }
        };

        //encoding query message to HL7 wire format.
        byte[] encodedQRYA19 = check hl7Encoder.encode(hl7v23:VERSION, qry_a19);

        do {
            //sending query message to HL7 server
            hl7:HL7Client hl7Client = check new (hl7ServerIP, hl7ServerPort);
            hl7:Message sendMessage = check hl7Client.sendMessage(encodedQRYA19);
            json jsonObj = sendMessage.toJson();
            return v2ToFHIRServiceAPI->post("/v2tofhir/transform", jsonObj);

        } on fail var e {
            log:printError(e.message());
            hl7:HL7Error sendMsgError = error(hl7:HL7_V2_CLIENT_ERROR, message = "Error while sending message to the HL7 server.");
            return sendMsgError;
        }
    }

    resource function post push(http:RequestContext ctx, http:Request request) returns json|error {
        json payload = check request.getJsonPayload();
        return payload;
    }
}
