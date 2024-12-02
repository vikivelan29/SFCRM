/**
 * @description       : Queuable Class to make callout to call Welcome Bot
 * @author            : Achuriwala@salesforce.com,
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : Achuriwala@salesforce.com,
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-10-2024   Achuriwala@salesforce.com,   Initial Version
**/
public with sharing class ABHI_WelcomeBot_Queuable Implements Queueable, Database.AllowsCallouts {
    String payload;
    /****************************************************************************************************************
     * @LOB - ABHI
     * @Function  
     * @param payload - String
     * @description - constructor
     *****************************************************************************************************************/
    public ABHI_WelcomeBot_Queuable(String payload)
    {
        this.payload = payload;
    }
    /****************************************************************************************************************
     * @LOB - ABHI
     * @Function - execute function of Queuable 
     * @param qc - QueueableContext
     * @description - 
     *****************************************************************************************************************/
    public void execute(QueueableContext qc)
    {
        String integrationName = 'ABHI_WelcomeBot';
        ASF_Case_Integration__c caseIntg = new ASF_Case_Integration__c();
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata(integrationName);
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        
        integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
        if(integrationResponse.StatusCode == 200) {
            //Success
            System.debug('@@@Reponse'+integrationResponse);
        }
        else {
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, true);
        }
    }
}
