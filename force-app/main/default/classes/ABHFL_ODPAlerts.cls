/*********************************************************
*@Class        :  ABHFL_ODPAlerts 
*@Author       :  Vishal Gangwar
*@Created Date :  17/01/2024
*@Last Modified:  
*@description  :  Class for Get ODP Alerts
*********************************************************/

public with sharing class ABHFL_ODPAlerts {

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getOdpAlerts
    * @param AccountId - Account Id getting from abhfl_OdpAlerts Lwc Component.
    * @return - List<ODPAlertResponse>
    * @description - Invoked from the abhfl_OdpAlerts Lwc components to get ODP Alerts
    *****************************************************************************************************************/

    @auraEnabled
    public static List<ODPAlertResponse> getOdpAlerts(Id AccountId){
        List<ODPAlertResponse> odpAlertResponseList = new List<ODPAlertResponse>();
        try{
            Account accObj = [SELECT Id,Client_Code__c FROM Account WHERE Id =: AccountId];
            
            If(accObj.Client_Code__c != null){
                String payload = JSON.serialize(new payloadWrapper(accObj.Client_Code__c));
                
                ABCL_IntegrationCallout.IntegrationResponseWrapper odpResponseWrp = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.ODP_ALERTS,payload,null);
                odpAlertResponseList = ODPAlertResponse.parse(odpResponseWrp.responseBody);
            }
        }catch(Exception e){
            
        }
        return odpAlertResponseList;
    }
    
    public class payloadWrapper{
        public string clientId;
        public string channelId;
        
        payloadWrapper(string clientId){
            this.clientId = clientId;
            this.channelId = ABHFL_Constants.CHANNEL_ID;
        }
    }
}