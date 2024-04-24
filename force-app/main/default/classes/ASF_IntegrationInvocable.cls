/*********************************************************
*Class        :  ASF_IntegrationInvocable
*Author       :  Ritika Dhandia
*Description  :  Interface to implement Business Integrations
*********************************************************/

public interface ASF_IntegrationInvocable {
    
    /**
     * evaluate method to be implemented by the class
     * mentioned in Visibility Class field of ASF Integration record
     * Returns if the integration needs to be fired (for prepopulate)
     * or the visibility of a UI component
     */
    ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec);
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs);

    /**
     * run method to be implemented by the class
     * mentioned in the Processing Class field of ASF Integration record
     * Needs to invoke the actual integration and return the response back
     * This method also decides how to run - Sync or Async
     */
    ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec);
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs);


    /**
     * processResponse method to be implemented by the class
     * mentioned in the Processing Class field of ASF Integration record
     * Needs to process the response back from an integration call
     */
    void processResponse(ASF_Case_Integration__c caseInteg);

}