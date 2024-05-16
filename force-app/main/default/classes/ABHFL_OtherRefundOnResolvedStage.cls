public with sharing class ABHFL_OtherRefundOnResolvedStage implements ASF_CaseStageClassInvocable {
    
    public Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retrnClass = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        sendEmailForOtherRefundCTST(caseRecords);
        return retrnClass;
    }

    public Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnClass = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        return returnClass;
    }

    public void sendEmailForOtherRefundCTST(List<Case> caseRecords) {

        Map<Id, String> emailTemplateMap = new Map<Id,String>();
        Map<String, String> stageToEmailTempNameMap = new Map<String,String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        String additionalEmailTemplate = '';
        List<Case> OtherRefundCases = new List<Case>();

        List<ASF_Case_Category_Config__c> lstOtherRefund = [SELECT Additional_Email_Templates__c
                                                            FROM ASF_Case_Category_Config__c
                                                            WHERE CCC_External_Id__c = 'RWRORHFC'];
        
        additionalEmailTemplate = lstOtherRefund[0].Additional_Email_Templates__c;
        stageToEmailTempNameMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(additionalEmailTemplate);
        
        for(Case caseRec : caseRecords){
            if(caseRec.CCC_External_Id__c == 'RWRORHFC') {
                OtherRefundCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, stageToEmailTempNameMap.get('Resolved'));
                isTransferredMap.put(caseRec.Id, false); 
            }
        }

        List<Database.SaveResult> platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(OtherRefundCases, emailTemplateMap, new Map<Id,String>(), isTransferredMap);
    }
}