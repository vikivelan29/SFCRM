public with sharing class ABSLI_IGMSLWCController {
    
    public static final string processName = 'RegisterComplaintFlow';
    
    @AuraEnabled (cacheable = false)
    public static returnResponse getRegistrationComplaintStatuses(String asfIntExtId,String caseId){
        Map<String,ASF_Integration__c> asfIntExtIdMap = new Map<String,ASF_Integration__c>();
        
        ASF_Integration__c asfIntg = [SELECT ID,Case_Stage_Config__c
                                                          FROM ASF_Integration__c 
                                                          WHERE Id =:asfIntExtId LIMIT 1];
        
        for(ASF_Integration__c registrationProcessFlow : [SELECT ID,External_Id__c,Processing_Class__c 
                                                          FROM ASF_Integration__c 
                                                          WHERE STP_API_Identifier__c =:processName
                                                          AND Case_Stage_Config__c =: asfIntg.Case_Stage_Config__c])
        {
            asfIntExtIdMap.put(registrationProcessFlow.External_Id__c,registrationProcessFlow);          
        }
        returnResponse cls = new returnResponse();
        for(ASF_Case_Integration__c caseInt : [SELECT ID,Status__c,Integration_Ext_Id__c,CreatedDate FROM ASF_Case_Integration__c WHERE
                                               Integration_Ext_Id__c =: asfIntExtIdMap.keySet() AND Case__c =: caseId ORDER BY CreatedDate DESC])
        {
            if((caseInt.Status__c == ABSLI_Constants.PENDING && System.now() < caseInt.CreatedDate.addMinutes(60)) || caseInt.Status__c != ABSLI_Constants.PENDING){
                for(String key : asfIntExtIdMap.keySet()){
                    if(String.isBlank(cls.registrationStatus) && asfIntExtIdMap.get(caseInt.Integration_Ext_Id__c).Processing_Class__c == 'ABSLI_RegisterIGMSComplaintIntegration' && key == caseInt.Integration_Ext_Id__c){
                        cls.registrationStatus = caseInt.Status__c;
                    }
                    else if(String.isBlank(cls.acknowledgeStatus) && asfIntExtIdMap.get(caseInt.Integration_Ext_Id__c).Processing_Class__c == 'ABSLI_AckIGMSComplaintIntegration' && key == caseInt.Integration_Ext_Id__c){
                        cls.acknowledgeStatus = caseInt.Status__c;
                    }
                    else if(String.isBlank(cls.pendingStatus)){
                        cls.pendingStatus = caseInt.Status__c;
                    }
                }
            }
        }
        return cls;
    }
    
    public class returnResponse{
        @AuraEnabled
        public string registrationStatus{get;set;}
        @AuraEnabled
        public string acknowledgeStatus{get;set;}
        @AuraEnabled
        public string pendingStatus{get;set;}
        
        public returnResponse(){
            this.registrationStatus = '';
            this.acknowledgeStatus = '';
            this.pendingStatus = '';            
        }
    }
    
}