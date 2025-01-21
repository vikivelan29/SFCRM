public class ABHI_EndorsementLwcController {
    
    public static final string processName = 'EndorsementFlow';
    
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
        /*for (Case caseRec: [SELECT ID,Sub_Type_Text__c FROM CASE WHERE ID = : caseId]){
            if(caseRec.Sub_Type_Text__c != null){
				cls.caseSubtype = caseRec.Sub_Type_Text__c;
                system.debug('Sub_Type_Text__c--> '+caseRec.Sub_Type_Text__c);
                system.debug('Sub_Type_Text__c--> '+cls.caseSubtype);
           }   
        }*/
        for(ASF_Case_Integration__c caseInt : [SELECT ID,Status__c,Case__r.Sub_Type_Text__c,Integration_Ext_Id__c,CreatedDate FROM ASF_Case_Integration__c WHERE
                                               Integration_Ext_Id__c =: asfIntExtIdMap.keySet() AND Case__c =: caseId ORDER BY CreatedDate DESC])
        {
            if((caseInt.Status__c == ABSLI_Constants.PENDING && System.now() < caseInt.CreatedDate.addMinutes(60)) || caseInt.Status__c != ABSLI_Constants.PENDING){
                for(String key : asfIntExtIdMap.keySet()){
                    if(String.isBlank(cls.registrationStatus) && asfIntExtIdMap.get(caseInt.Integration_Ext_Id__c).Processing_Class__c == 'ABHI_EndorsementStpApi' && key == caseInt.Integration_Ext_Id__c){
                        cls.registrationStatus = caseInt.Status__c;
                    }
                }
            }
        }
        return cls;
    }
     @AuraEnabled(cacheable=true)
    public static Case getCaseRecord(Id recordId) {
        return [SELECT Id, Sub_Type_Text__c  FROM Case WHERE Id = :recordId LIMIT 1];
    }
  
    public class returnResponse{
        @AuraEnabled
        public string registrationStatus{get;set;}
       
        
       public returnResponse(){
            this.registrationStatus = '';
                 
        }
    }
    
}