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
        Account accObj = [SELECT Id,Client_Code__c, Business_Unit__c FROM Account WHERE Id =: AccountId];
        //New
        if(isABFL){
            integrationName = ABFL_Constants.ODP_ALERTS;
        }else{
            integrationName = ABHFL_Constants.ODP_ALERTS;
        }
        if(accObj.Client_Code__c != null){
            String payload = JSON.serialize(new PayloadWrapper(accObj.Client_Code__c, isABFL)); //New 
            system.debug('payload--->'+payload);
            ABCL_IntegrationCallout.IntegrationResponseWrapper odpResponseWrp = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
            
            if(odpResponseWrp.statusCode != 200){
                ODPAlertResponse errorResp = new ODPAlertResponse();
                errorResp.messageText = 'Service not available';
                odpAlertResponseList.add(errorResp);
            }else{
                odpAlertResponseList = ODPAlertResponse.parse(odpResponseWrp.responseBody);
            }
        }else{
            throw new AuraHandledException(label.ODP_Client_Code_Msg);
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