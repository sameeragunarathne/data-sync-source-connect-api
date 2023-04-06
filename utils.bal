// Copyright (c) 2022, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import ballerina/tcp;
import wso2healthcare/healthcare.hl7;

# HL7 Client implementation
public class HL7Client {

    final string host;
    final int port;
    final hl7:HL7Parser parser = new ();
    final hl7:HL7Encoder encoder = new ();

    public isolated function init(string remoteHost, int remotePort) returns hl7:HL7Error? {

        self.host = remoteHost;
        self.port = remotePort;
    }

    # Send a single HL7 message to given encoded HL7 message to given endpoint
    # + message - HL7 message as record or encoded binary message. If record is given, it will be encoded to binary message
    # + return - Response HL7 encoded response from the target server. HL7Error if error occurred
    public function sendMessage(hl7:Message|byte[] message) returns byte[]|hl7:HL7Error {

        if message is hl7:Message {
            anydata mshSegment = message.get("msh");
            if mshSegment is hl7:Segment {
                anydata hl7Version = mshSegment.get("msh12");
                if hl7Version is string {
                    byte[]|hl7:HL7Error encodedMessage = self.encoder.encode(hl7Version, message);
                    if encodedMessage is byte[] {
                        return self.writeToHL7Stream(encodedMessage);
                    } else {
                        return encodedMessage;
                    }
                } else {
                    hl7:HL7Error err = error hl7:HL7Error(hl7:HL7_V2_MSG_VALIDATION_ERROR, message = "HL7 message version cannot be empty.");
                    return err;
                }
            }
        } else {
            return self.writeToHL7Stream(message);
        }
        hl7:HL7Error err = error hl7:HL7Error(hl7:HL7_V2_CLIENT_ERROR, message = "Something went wrong sending HL7 message.");
        return err;
    }


    # This function is used to send HL7 message to given HL7 endpoint using TCP Client.
    #
    # + message - Byte stream of the HL7 message.
    # + return - Returns byte stream of the HL7 response or HL7Error if error occurred.
    function writeToHL7Stream(byte[] message) returns byte[]|hl7:HL7Error {

        if message.length() > 0 {
            do {
                tcp:Client tcpClient = check new (self.host, self.port);
                check tcpClient->writeBytes(message);
                readonly & byte[] receivedData = check tcpClient->readBytes();
                check tcpClient->close();
                return receivedData;
            } on fail var e {
                hl7:HL7Error err = error hl7:HL7Error(hl7:HL7_V2_CLIENT_ERROR, e, message = "Error occurred while sending HL7 message.");
                return err;
            }
        } else {
            hl7:HL7Error err = error hl7:HL7Error(hl7:HL7_V2_MSG_VALIDATION_ERROR, message = "HL7 message content cannot be empty.");
            return err;
        }
    }
}
