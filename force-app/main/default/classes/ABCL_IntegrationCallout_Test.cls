@IsTest
public class ABCL_IntegrationCallout_Test {
	
    @IsTest
    static void testExecuteCallout(){
        Map<String,String> urlParameters = new Map<String,String>();
        urlParameters.put('test','test');
        Map<String,String> header = ABCL_IntegrationCallout.prepareHeaders(JSON.serialize(urlParameters));
        System.assertEquals('test',header.get('test'),'PASS');
        Test.StartTest();
        ABCL_IntegrationCallout.IntegrationResponseWrapper response = ABCL_IntegrationCallout.executeCallout('Paytm_Link','{}',urlParameters);
        System.assertEquals(true,response != null,'PASS');
        Test.StopTest();
        ABCL_Integrations__mdt intMetadata = new ABCL_Integrations__mdt();
        intMetadata.Exception_Log__c = true;
        intMetadata.StoreAsAttachment__c = true;
        ABCL_Integrations__mdt intMetadata1 = new ABCL_Integrations__mdt();
        intMetadata1.Exception_Log__c = true;
        intMetadata1.StoreAsAttachment__c = true;
        intMetadata1.EnableMockResponse__c = true;
        intMetadata1.Mock_Response_Resource__c = 'ComplaintInvestigationMockResponse';
        ABCL_IntegrationCallout.IntegrationResponseWrapper failedResponse = ABCL_IntegrationCallout.handleResponse(intMetadata,response,true);
        ABCL_IntegrationCallout.IntegrationResponseWrapper res = ABCL_IntegrationCallout.getStaticResource(intMetadata1, response);
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        insert caseInt;
        ABCL_IntegrationCallout.storeResponseAttachment(intMetadata1, response, caseInt.Id);
        System.assertEquals(true,failedResponse != null,'PASS');
    }
}