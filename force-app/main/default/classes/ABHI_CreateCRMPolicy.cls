/*********************************************************
*Class        :  ABHI_CreateCRMPolicy
*Author       :  Aditee Churiwala
*@description    Create CRM Policy
*********************************************************/
@RestResource(urlMapping='/CreateCRMPolicy/*')
global with sharing class ABHI_CreateCRMPolicy {
    public static String proposalNumber;
    public class ABHI_CreateCRMPolicyException extends Exception {}
    /**
    * @param 
    * @return - String 
    * @description - This method creates record in Account, Contact, Asset, LAN Mapping, Mem Mapping, Policy nomineee
    */
    @HttpPost
    global static String createCRMPolicy(){
        System.debug('@@@Tme_'+Limits.getCPUTime());
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateCRMPolicy_Inbound');
        integrationResponse.requestBody = RestContext.request.requestBody.toString();
        ASF_Case_Integration__c caseIntg = new ASF_Case_Integration__c(Type__c = 'CreateCRMPolicy');
        try {
            new ABHI_CreatePolicy(integrationResponse.requestBody);
            ABHI_ResponseWrapper resp = new ABHI_ResponseWrapper('200',ABHI_Constants.SUCCESS, Custom_Messages__mdt.getInstance('ABHI_CRMPolicySuccess').Message__c);
            resp.ProposalNumber = proposalNumber; 
            integrationResponse.responseBody = JSON.serialize(resp, true);
        }catch(Exception e) {
            String mes = e.getMessage();
            if(mes.contains('LAN__c')) {
                mes = mes.replace('LAN__c', 'Policy No.');
            }
            caseIntg.Error_Message__c = String.valueOf('Time taken:'+Limits.getCPUTime());
            integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('100', ABHI_Constants.FAILURE, mes), true);
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, true);
        }
        /*finally {
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, hasError);
            if(hasError) {
            	integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('100', ABHI_Constants.FAILURE, Custom_Messages__mdt.getInstance('ABHI_CRMPolicyDMLFailure').Message__c), true);
            }
        }*/
        System.debug('@@@Tmes'+Limits.getCPUTime());
        return integrationResponse.responseBody;
    }
}