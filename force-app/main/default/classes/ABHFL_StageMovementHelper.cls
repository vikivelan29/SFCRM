public with sharing class ABHFL_StageMovementHelper implements ASF_CaseStageClassInvocable {

    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        Map<String, ASF_Case_Category_Config__c> configIdToConfigMap = new Map<String,ASF_Case_Category_Config__c>();
        Set<String> cccIds = new Set<String>();
        List<Case> casesForCreatePELogAndinvokeCommPEevent = new List<Case>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecords){
            cccIds.add(caseRec.CCC_External_Id__c);
        }
        
        for(ASF_Case_Category_Config__c cccRecord : [SELECT Id, CCC_External_Id__c, Additional_Email_Templates__c,Additional_SMS_Metadata__c FROM ASF_Case_Category_Config__c
        WHERE CCC_External_Id__c IN :cccIds ])
        {
            configIdToConfigMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
            
            //AM-PR970457-1219 && AM-PR970457-1220 comment
            if((caseRec.CCC_External_Id__c=='HFCRAREMIDC' && (caseRec.Asset.Loan_Disbursement_Status__c=='Partially' || caseRec.Asset.Loan_Disbursement_Status__c=='PARTIALLY DISBURSED')) || (caseRec.CCC_External_Id__c=='hfl029')){
                //Trigger email here
                Map<String, String> emailMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(configIdToConfigMap.get(caseRec.CCC_External_Id__c).Additional_Email_Templates__c);
                Map<String, String> smsMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(configIdToConfigMap.get(caseRec.CCC_External_Id__c).Additional_SMS_Metadata__c);
                casesForCreatePELogAndinvokeCommPEevent.add(caseRec);
                emailTemplateMap.put(caseRec.Id, emailMap.get('Resolved'));
                smsMetadataMap.put(caseRec.Id, smsMap.get('Resolved'));
                isTransferredMap.put(caseRec.Id,true);
            }
            //AM-PR970457-1266
            if(caseRec.CCC_External_Id__c=='hfl074'){
                //Trigger email here
                Map<String, String> emailMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(configIdToConfigMap.get(caseRec.CCC_External_Id__c).Additional_Email_Templates__c);
                casesForCreatePELogAndinvokeCommPEevent.add(caseRec);
                emailTemplateMap.put(caseRec.Id, emailMap.get('Resolved'));
                isTransferredMap.put(caseRec.Id,true);
            }
            // Writing condition for updating All LAN field on ABHFL case detail
            // Changes are done by Yogesh [PR970457-2288]  
            ABHFL_CTSTHelper.updateAllLanFieldOnDetailObj(caseRec);
            ABHFL_CTSTHelper.sendEmailToUpdatedEmailId(caseRec);
        }
        if(!casesForCreatePELogAndinvokeCommPEevent.isEmpty()){
           	ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(casesForCreatePELogAndinvokeCommPEevent,emailTemplateMap, smsMetadataMap, isTransferredMap);
       	}

        return returnWrapper;
    }

     public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case>eligibleCaseRecords=new List<Case>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
            // Writing condition for sending email in case of failure of address change(hfl003)
            // Changes are done by Yogesh [PR970457-2388] 
            if(caseRec.CCC_External_Id__c=='hfl003' && caseRec.ABHFL_Case_Detail__c!=null){
                string AddressChangestatus=[Select Id,Address_Change_Status__c from ABHFL_Case_Detail__c where Id=:caseRec.ABHFL_Case_Detail__c].Address_Change_Status__c;
                if(AddressChangestatus==ABHFL_Constants.REJECTED){
                    eligibleCaseRecords.add(caseRec);
                    emailTemplateMap.put(caseRec.Id,ABHFL_Constants.ADDRESSCHANGE_REJECTION_EMAIL);
                    smsMetadataMap.put(caseRec.Id,ABHFL_Constants.ADDRESSCHANGE_REJECTION_SMS);
                    isTransferredMap.put(caseRec.Id, false);
                }
            }
        }
         if(!caseRecords.isEmpty()){
             ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(eligibleCaseRecords,emailTemplateMap, 
        smsMetadataMap, isTransferredMap);
         }

        if(returnWrapper.keySet().size() > 0){
            ABHFL_CTSTHelper.checkAssetDetailStatus(returnWrapper);
        }

        if(returnWrapper.keySet().size() > 0){
            ABHFL_CTSTHelper.checkAssetDetailFileUploadStatus(returnWrapper);
        }

        return returnWrapper;
    }
}
