@IsTest
public class ODPAlertResponse_Test {
    
    static testMethod void testParse() {
        String json = '[{'+
        '    \"document\": 1,'+
        '    \"service\": 3,'+
        '    \"release\": \"3.9\",'+
        '    \"lastUpdated\": \"2023-05-03T09:30:35.504Z\",'+
        '    \"createdAt\": \"2023-05-03T09:30:35.473Z\",'+
        '    \"isNbaPushed\": \"false\",'+
        '    \"assetId\": \"LNAHMHL_-04160026420\",'+
        '    \"messageText\": \"We are pleased to inform you that you are eligible for a pre-approved top up loan of Rs. 1125000, rate of interest 9.8%  for a tenure of 61 months . If you wish to apply for a top up loan, request you to click on the link  <a href=\'https://abcap.co.in/fsBkRsM\' target=\'_blank\'> https://abcap.co.in/fsBkRsM</a> and our executive will connect with you.\",'+
        '    \"clientId\": \"72291\",'+
        '    \"eventId\": \"EVE1390\",'+
        '    \"channelId\": \"CHA1001\",'+
        '    \"eventType\": \"Top-Up\",'+
        '    \"nbaLink\": \"https: //abcap.co.in/fsBkRsM\",'+
        '    \"dismissed\": false,'+
        '    \"uniqueRefId\": \"SRVC203872291LNAHMHL_-04160026420CHA1001\",'+
        '    \"_expireAt\": \"2023-05-08T16:23:44.454Z\"'+
        '},'+
        '{'+
        '    \"document\": 1,'+
        '    \"service\": 3,'+
        '    \"release\": \"3.9\",'+
        '    \"lastUpdated\": \"2023-05-03T09:30:35.504Z\",'+
        '    \"createdAt\": \"2023-05-03T09:30:35.473Z\",'+
        '    \"isNbaPushed\": \"false\",'+
        '    \"assetId\": \"LNAHMHL_-04160026420\",'+
        '    \"messageText\": \"We are pleased to inform you that you are eligible for a pre-approved top up loan of Rs. 1125000, rate of interest 9.8%  for a tenure of 61 months . If you wish to apply for a top up loan, request you to click on the link  <a href=\'https://abcap.co.in/fsBkRsM\' target=\'_blank\'> https://abcap.co.in/fsBkRsM</a> and our executive will connect with you.\",'+
        '    \"clientId\": \"72291\",'+
        '    \"eventId\": \"EVE1390\",'+
        '    \"channelId\": \"CHA1001\",'+
        '    \"eventType\": \"Top-Up\",'+
        '    \"nbaLink\": \"https: //abcap.co.in/fsBkRsM\",'+
        '    \"dismissed\": false,'+
        '    \"uniqueRefId\": \"SRVC203872291LNAHMHL_-04160026420CHA1001\",'+
        '    \"_expireAt\": \"2023-05-08T16:23:44.454Z\"'+
        '},'+
        '{'+
        '   \"message\": \"\'body\' field is not supported with GET or HEAD methods. ReferenceId: refExtension\",'+
        '   \"errorCode\": \"JSON_PARSER_ERROR\"'+
        '}'+
        ''+
        ']';
        List<ODPAlertResponse> r = ODPAlertResponse.parse(json);
        System.assert(r != null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ODPAlertResponse objJSON2Apex = new ODPAlertResponse(System.JSON.createParser(json));
        System.assert(objJSON2Apex != null);
        System.assert(objJSON2Apex.document == null);
        System.assert(objJSON2Apex.service == null);
        System.assert(objJSON2Apex.release == null);
        System.assert(objJSON2Apex.lastUpdated == null);
        System.assert(objJSON2Apex.createdAt == null);
        System.assert(objJSON2Apex.isNbaPushed == null);
        System.assert(objJSON2Apex.assetId == null);
        System.assert(objJSON2Apex.messageText == null);
        System.assert(objJSON2Apex.clientId == null);
        System.assert(objJSON2Apex.eventId == null);
        System.assert(objJSON2Apex.channelId == null);
        System.assert(objJSON2Apex.eventType == null);
        System.assert(objJSON2Apex.nbaLink == null);
        System.assert(objJSON2Apex.dismissed == null);
        System.assert(objJSON2Apex.uniqueRefId == null);
        System.assert(objJSON2Apex.x_expireAt == null);
        System.assert(objJSON2Apex.message == null);
        System.assert(objJSON2Apex.errorCode == null);
    }
}