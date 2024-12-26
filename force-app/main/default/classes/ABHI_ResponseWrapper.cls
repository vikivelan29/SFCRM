/*********************************************************
*Class        :  ABHI_ResponseWrapper
*Author       :  Aditee Churiwala
*Created Date :  08/09/2024
*Last Modified:  08/09/2024
*@description :  Create response wrapper
*********************************************************/
public with sharing class ABHI_ResponseWrapper {
    public String ProposalNumber;
    public String StatusCode { get; set; }
    public String StatusMessage { get; set; }
    public String StatusRemarks { get; set; }

    public ABHI_ResponseWrapper(String StatusCode, String StatusMessage, String StatusRemarks) {
        this.StatusCode = StatusCode;
        this.StatusMessage = StatusMessage;
        this.StatusRemarks = StatusRemarks;
    }
     public static ABCL_IntegrationCallout.IntegrationResponseWrapper createLog(ASF_Case_Integration__c integrationLog, ABCL_Integrations__mdt integrationMdt,ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse, Boolean hasError){
        if(!hasError){
            integrationLog.Status__c = ABHI_Constants.SUCCESS;
            integrationResponse = ABCL_IntegrationCallout.getStaticResource(integrationMdt,integrationResponse);
        } else {
            integrationLog.Status__c = ABHI_Constants.FAILURE;
        }

        if(!integrationMdt.StoreAsAttachment__c){
            integrationLog.Response__c = integrationResponse.responseBody;
            integrationLog.Request__c = integrationResponse.requestBody;
        }
        
        if(integrationMdt.Full_Log__c || (integrationMdt.Exception_Log__c && hasError)){
            if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert integrationLog;
                ABCL_IntegrationCallout.storeResponseAttachment(integrationMdt,integrationResponse,integrationLog.Id);
            }
        }        
        return integrationResponse;
    }
}