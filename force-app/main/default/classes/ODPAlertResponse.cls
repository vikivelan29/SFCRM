/*********************************************************
*@Class        :  ODPAlertResponse 
*@Author       :  Vishal Gangwar
*@Created Date :  17/01/2024
*@Last Modified:  
*@description  :  Class is used for Parsing ODP Alrts JSON from ABHFL_ODPAlerts Class
*********************************************************/

public class ODPAlertResponse {
    public Integer document {get;set;} 
    public Integer service {get;set;} 
    public String release {get;set;} 
    public String lastUpdated {get;set;} 
    public String createdAt {get;set;} 
    public String isNbaPushed {get;set;} 
    public String assetId {get;set;} 
    @auraEnabled
    public String messageText {get;set;} 
    public String clientId {get;set;} 
    public String eventId {get;set;} 
    public String channelId {get;set;} 
    public String eventType {get;set;} 
    public String nbaLink {get;set;} 
    public Boolean dismissed {get;set;} 
    public String uniqueRefId {get;set;} 
    public String x_expireAt {get;set;} // in json: _expireAt
    @auraEnabled
    public String message {get;set;} 
    @auraEnabled
    public String errorCode {get;set;} 

    public ODPAlertResponse(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'document') {
                        document = parser.getIntegerValue();
                    } else if (text == 'service') {
                        service = parser.getIntegerValue();
                    } else if (text == 'release') {
                        release = parser.getText();
                    } else if (text == 'lastUpdated') {
                        lastUpdated = parser.getText();
                    } else if (text == 'createdAt') {
                        createdAt = parser.getText();
                    } else if (text == 'isNbaPushed') {
                        isNbaPushed = parser.getText();
                    } else if (text == 'assetId') {
                        assetId = parser.getText();
                    } else if (text == 'messageText') {
                        messageText = parser.getText();
                    } else if (text == 'clientId') {
                        clientId = parser.getText();
                    } else if (text == 'eventId') {
                        eventId = parser.getText();
                    } else if (text == 'channelId') {
                        channelId = parser.getText();
                    } else if (text == 'eventType') {
                        eventType = parser.getText();
                    } else if (text == 'nbaLink') {
                        nbaLink = parser.getText();
                    } else if (text == 'dismissed') {
                        dismissed = parser.getBooleanValue();
                    } else if (text == 'uniqueRefId') {
                        uniqueRefId = parser.getText();
                    } else if (text == '_expireAt') {
                        x_expireAt = parser.getText();
                    } else if (text == 'message') {
                        message = parser.getText();
                    } else if (text == 'errorCode') {
                        errorCode = parser.getText();
                    } else {
                        System.debug(LoggingLevel.WARN, 'ODPAlertResponse consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    
    public static List<ODPAlertResponse> parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return arrayOfODPAlertResponse(parser);
    }
    
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT ||
                curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }
    

    private static List<ODPAlertResponse> arrayOfODPAlertResponse(System.JSONParser p) {
        List<ODPAlertResponse> res = new List<ODPAlertResponse>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new ODPAlertResponse(p));
        }
        return res;
    }

}