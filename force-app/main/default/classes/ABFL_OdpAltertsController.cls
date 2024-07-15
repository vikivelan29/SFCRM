/**
 * @description       : Class to handle Odp Alerts
 * @group             : ABFL
 * @last modified on  : 06-28-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * 
 * Modifications Log
 * Ver      Date           Author                            Modification
 * 1.0      28-12-2023     svyavhare@salesforce.com          Initial Version
 **/

public with sharing class ABFL_OdpAltertsController {

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - getOdpAlerts
    * @param accountId - Account Id getting from ABFL_OdpAltertsController Lwc Component.
    * @return - List<ODPAlertResponse>
    * @description - Invoked from the ABFL_OdpAltertsController Lwc components to get ODP Alerts
    *****************************************************************************************************************/

    @auraEnabled
    public static List<ODPAlertResponse> getOdpAlerts(Id accountId){
        List<ODPAlertResponse> odpAlertResponseList = new List<ODPAlertResponse>();
        String integrationName = ABFL_Constants.ODP_ALERTS;
        Account accObj = [SELECT Id,Client_Code__c FROM Account WHERE Id =: accountId WITH SECURITY_ENFORCED];
        //New
        if(accObj.Client_Code__c != null){
            String payload = JSON.serialize(new PayloadWrapper(accObj.Client_Code__c));
            ABCL_IntegrationCallout.IntegrationResponseWrapper odpResponseWrp = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
            if(odpResponseWrp.responseBody == '[]'){
                odpAlertResponseList = ODPAlertResponse.parse('[{\"messageText\":\"There is no odp alert avalible\"}]');
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
        
        payloadWrapper(string clientId){
            this.clientId = clientId;
            this.channelId = ABFL_Constants.CHANNEL_ID;
        }
    }
}