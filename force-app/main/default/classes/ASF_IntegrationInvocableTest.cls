/*********************************************************
*Class        :  ASF_IntegrationInvocableTest
*Author       :  Ritika Dhandia
*Description  :  Test Class, which implements the Integration Invocable
*********************************************************/
@isTest
public with sharing class ASF_IntegrationInvocableTest implements ASF_IntegrationInvocable{
    
    public boolean evaluate(Case caseRec){
        return true;
    }

    public Object run(ASF_Integration__c integ, Case caseRec){
        // Create New Case Integration with Pending Type
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
        caseInteg.Case__c = caseRec.Id;

        // Accroding to the Integration Result above, set
        // to Success / Failure. Pending will be used for Async Integrations
        caseInteg.Status__c = 'Pending';
        insert caseInteg;
        return 'Success';
    }

    public void processResponse(ASF_Case_Integration__c caseInteg){
        // Close the Case
        Case cs = new Case();
        cs.Id = caseInteg.Case__c;
        cs.Status = 'Closed';
        update cs;

    }

}