/**
 * @description       : Batch Class to make callout to call Welcome Bot
 * @author            : Achuriwala@salesforce.co,
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : Achuriwala@salesforce.co,
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-10-2024   Achuriwala@salesforce.co,   Initial Version
**/

global class ABHI_WelcomeBot_Batch implements Database.Batchable<sObject>,  Schedulable,  Database.AllowsCallouts {  
    List<sObject> scope = new List<sObject>();
     /****************************************************************************************************************
     * @LOB - ABHI
     * @Function - start function of batch 
     * @param bC - Batchable Context
     * @return Database.getQueryLocator
     * @description - Method to get asset records  
     *****************************************************************************************************************/
    global List<sObject> start(Database.BatchableContext bC) {  
        List<sObject> scope = new List<sObject>();
        scope.addAll([select id, Account.Name, Account.IsPersonAccount, Account.Phone,
                      Account.PersonMobilePhone,Account.Client_Code__c,
                      Account.Is_Chronic__c, Account.CMP_OPD__c, Account.Chronic_care__c,
                      PolicyType__c, Policy_No__c, ProductName__c, Plan_Name__c,  
                      Account.State__c, Channel__c, Source__c, LAN__c
                      FROM Asset 
                      WHERE CreatedDate = N_DAYS_AGO:2 AND Business_Unit__c = :ABHI_Constants.ABHI
                      AND CreatedBy.name != 'Data Sync Automation User']);
        scope.addAll([SELECT id, Policy_Number__c, CreatedBy.username,
                      Policy_Number__r.Account.Name, Policy_Number__r.Account.IsPersonAccount,
                      Policy_Number__r.Account.Phone, Policy_Number__r.Account.PersonMobilePhone,
                      Policy_Number__r.Account.Client_Code__c,Policy_Number__r.Account.Is_Chronic__c,
                      Policy_Number__r.Account.CMP_OPD__c, Policy_Number__r.Account.Chronic_care__c,
                      Policy_Number__r.PolicyType__c, Policy_Number__r.Policy_No__c, Policy_Number__r.ProductName__c,
                      Policy_Number__r.Plan_Name__c, Policy_Number__r.LAN__c, ABHI_Retry__c,
                      Policy_Number__r.Account.State__c, Policy_Number__r.Channel__c, Policy_Number__r.Source__c
                      from Dispositions__c  
                      WHERE Status__c = :ABHI_Constants.FAILURE AND ABHI_Retry__c <= :Integer.valueOf(Label.ABHI_Retry)]);
        return scope;
	}
    
     /****************************************************************************************************************
     * @LOB - ABHI
     * @Function - execute function of batch 
     * @param bC - Batchable Context
     * @param scope - List of Assets & disposition for failure
     * @description - 
     *****************************************************************************************************************/
    global void execute(Database.BatchableContext bC, List<sObject> scope) {
        ABHI_WelcomeBotWrapper botRequest = null;
        List<ABHI_WelcomeBotWrapper> listWelcome = new List<ABHI_WelcomeBotWrapper>();
        Map<String, Dispositions__c> mapDisposition = new Map<String, Dispositions__c>();
        Map<String, ABHI_WelcomeBotWrapper> mapWelcome = new Map<String, ABHI_WelcomeBotWrapper>();
        Dispositions__c disposition = null;
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse;
        ASF_Case_Integration__c caseIntg = new ASF_Case_Integration__c();
        String key;
        Map<String, String> mapProductDetService = new Map<String, String>();
        Map<String, String> mapProductNameService = new Map<String, String>(); 
        for(ABHI_Welcome_Call__mdt welcome : [select id,Chronic_care__c,CMP_OPD__c,DeveloperName,IsChronicFlag__c,
                                              Plan_Name__c,ProductName__c,Service_Id__c, Ignore_All_Fields__c  from ABHI_Welcome_Call__mdt]) {
                                 					key = welcome.Plan_Name__c + welcome.ProductName__c + welcome.CMP_OPD__c + welcome.Chronic_care__c + welcome.IsChronicFlag__c;         
                                                  //2 maps: 1 if ignore all true map of product name+plan name & serviceId
                                                  //else: mapProductDetService
                                                  if(welcome.Ignore_All_Fields__c && !mapProductNameService.containsKey(welcome.Plan_Name__c + welcome.ProductName__c)) {
                                                      mapProductNameService.put(welcome.Plan_Name__c + welcome.ProductName__c, welcome.Service_Id__c);
                                                  }
                                                  if(!mapProductDetService.containskey(key)) {
                                                      mapProductDetService.put(key, welcome.Service_Id__c);
                                                  }
                                              }
        System.debug('@@@mapProductDetService'+mapProductDetService);
    	for(sObject obj : scope)
        {
            botRequest = new ABHI_WelcomeBotWrapper();
            disposition = new Dispositions__c();
            switch on obj
            {
                when Asset asset
                {
                    if(mapProductNameService.containsKey(asset.Plan_Name__c + asset.ProductName__c)) {
                        botRequest.serviceId = mapProductNameService.get(asset.Plan_Name__c + asset.ProductName__c);
                    }
                    else {
                        key = asset.Plan_Name__c + asset.ProductName__c + asset.Account.CMP_OPD__c + asset.Account.Chronic_care__c + asset.Account.Is_Chronic__c;         
                        System.debug('@@@key'+key);
                        botRequest.serviceId = mapProductDetService.get(key); 
                    }
                    botRequest.msisdn = asset.Account.IsPersonAccount?asset.Account.PersonMobilePhone:asset.Account.Phone;
                    botRequest.language = 'en';
                    botRequest.group_or_retail = asset.PolicyType__c;
                    botRequest.policy_holder_name = asset.Account.Name;
                    botRequest.policy_type = asset.PolicyType__c;
                    botRequest.policy_number = asset.Policy_No__c;
                    botRequest.policy_name = asset.ProductName__c+asset.Plan_Name__c;
                    botRequest.customer_id = asset.Account.Client_Code__c;
                    botRequest.State = asset.Account.State__c;
                    botRequest.Policy_Channel = asset.Channel__c;
                    botRequest.Policy_Source = asset.Source__c;

                    mapWelcome.put(asset.LAN__c, botRequest);
                    
                    //Create Disposition record for all the asset record
                    disposition.Policy_Number__r = new Asset(LAN__c = asset.LAN__c);
                    disposition.Status__c = ABHI_Constants.PENDING;
                    disposition.Remarks__c = ABHI_Constants.SUCCESS;
                    
                    mapDisposition.put(asset.LAN__c, disposition);
                }
                when Dispositions__c dispositions
                {
                    //Do Disposition stuff
                    if(mapProductNameService.containsKey(dispositions.Policy_Number__r.Plan_Name__c + dispositions.Policy_Number__r.ProductName__c)) {
                        botRequest.serviceId = mapProductNameService.get(dispositions.Policy_Number__r.Plan_Name__c + dispositions.Policy_Number__r.ProductName__c);
                    }
                    else {
                        key = dispositions.Policy_Number__r.Plan_Name__c + dispositions.Policy_Number__r.ProductName__c /*+ welcome.CMP_OPD__c + welcome.Chronic_care__c */+ dispositions.Policy_Number__r.Account.Is_Chronic__c;         
                    	botRequest.serviceId = mapProductDetService.get(key); 
                    }
                    botRequest.msisdn = dispositions.Policy_Number__r.Account.IsPersonAccount?dispositions.Policy_Number__r.Account.PersonMobilePhone:dispositions.Policy_Number__r.Account.Phone;
                    botRequest.language = 'en';
                    botRequest.group_or_retail = dispositions.Policy_Number__r.PolicyType__c;
                    botRequest.policy_holder_name = dispositions.Policy_Number__r.Account.Name;
                    botRequest.policy_type = dispositions.Policy_Number__r.PolicyType__c;
                    botRequest.policy_number = dispositions.Policy_Number__r.Policy_No__c;
                    botRequest.policy_name = dispositions.Policy_Number__r.ProductName__c+dispositions.Policy_Number__r.Plan_Name__c;
                    botRequest.customer_id = dispositions.Policy_Number__r.Account.Client_Code__c;
                    botRequest.State = dispositions.Policy_Number__r.Account.State__c;
                    botRequest.Policy_Channel = dispositions.Policy_Number__r.Channel__c;
                    botRequest.Policy_Source = dispositions.Policy_Number__r.Source__c;
                    botRequest.DispositionId = dispositions.Id;


                    //disposition.Policy_Number__r = new Asset(LAN__c = dispositions.Policy_Number__c);
                    disposition.ABHI_Retry__c = dispositions.ABHI_Retry__c + 1;
                    disposition.Status__c = ABHI_Constants.PENDING;
                    disposition.Remarks__c = ABHI_Constants.SUCCESS;
                    disposition.Id = dispositions.Id;
                    
                    mapDisposition.put(dispositions.Policy_Number__r.LAN__c, disposition);
                    
                    listWelcome.add(botRequest); 
                }
             }
            

         }
        System.debug('@@@listRequest'+mapDisposition);
        String integrationName = 'ABHI_WelcomeBot';
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata(integrationName);
        try {
            if(Schema.sObjectType.Dispositions__c.isCreateable() && Schema.sObjectType.Dispositions__c.isUpdateable()) {
                upsert(mapDisposition.values());
            }    
            for(String assetNo : mapWelcome.keyset()) {
                if(mapDisposition.containsKey(assetNo)) {
                    mapWelcome.get(assetNo).DispositionId = mapDisposition.get(assetNo).Id;
                }
                listWelcome.add(mapWelcome.get(assetNo)); 
            }
            
            System.debug('@@@listRequest'+JSON.serialize(listWelcome));
            
            //Callout
            
            
            integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,JSON.serialize(listWelcome),null);
            if(integrationResponse.StatusCode == 200) {
                //Success
            }
            else {
                ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, true);
            }
        }
        catch(Exception e) {
            System.debug('@@e'+e.getMessage());
            integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('100', ABHI_Constants.FAILURE, e.getMessage()), true);
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, true);
        }
    }


    /****************************************************************************************************************
     * @LOB - ABHI
     * @Function - finish function of batch 
     * @param bC - Batchable Context
     * @description - 
     *****************************************************************************************************************/
    global void finish(Database.BatchableContext bC) {
        //nothing to process here
    }

    /****************************************************************************************************************
     * @LOB - ABHI
     * @Function - execute function of Schedulable 
     * @param SC - Batchable Context
     * @description - Execute function of Schedulable
     *****************************************************************************************************************/    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABHI_WelcomeBot_Batch(), Integer.valueOf(Label.ABHI_WelcomeBatchSize));
    }
}
