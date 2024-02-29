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
    public static List<ODPAlertResponse> getOdpAlerts(Id AccountId, boolean isABFL){
        List<ODPAlertResponse> odpAlertResponseList = new List<ODPAlertResponse>();
        String integrationName;
        try{
            Account accObj = [SELECT Id,Client_Code__c FROM Account WHERE Id =: AccountId];
            //New
            if(isABFL){
                integrationName = ABFL_Constants.ODP_ALERTS;
            }else{
                integrationName = ABHFL_Constants.ODP_ALERTS;
            }
            If(accObj.Client_Code__c != null){
                String payload = JSON.serialize(new PayloadWrapper(accObj.Client_Code__c, isABFL)); //New 
                
                ABCL_IntegrationCallout.IntegrationResponseWrapper odpResponseWrp = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
                
                if(odpResponseWrp.responseBody == '[]'){
                    odpAlertResponseList = ODPAlertResponse.parse('[{\"messageText\":\"There is no odp alert avalible\"}]');
                }else{
                    odpAlertResponseList = ODPAlertResponse.parse(odpResponseWrp.responseBody);
                }
            }else{
                odpAlertResponseList = ODPAlertResponse.parse('[{\"errorCode\":\"401\",\"message\":\"There is client code missing\"}]');
            }
        }catch(Exception e){
            system.debug('Error=='+e.getMessage()+ ' Line no=='+e.getLineNumber());
        }
        return odpAlertResponseList;
    }
    
    public class PayloadWrapper{
        public string clientId;
        public string channelId;
        
        payloadWrapper(string clientId, boolean isAbfl){
            this.clientId = clientId;
            this.channelId = isAbfl ? ABFL_Constants.CHANNEL_ID : ABHFL_Constants.CHANNEL_ID; //New
        }
    }
}