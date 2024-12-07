public with sharing class ABSLI_EmailSMSSuppressionHandler {
    public static void handleSuppressionLogic(List<ASF_CustomerEmailInvocable.EmailInputWrapper> inputWrapList, 
                                              Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs
                                             )
    {
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inpWrap : inputWrapList){
            Case caseRecord = (Case)inpWrap.caseRecord;
            if(!caseRecord.Auto_Rejected__c && caseRecord.Status == 'Unresolved'){
                ASF_CustomerEmailInvocable.EmailOutputWrapper outputWrap = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
                outputWrap.supressEmail = false;
                outputWrap.SmsTemplateName = inpWrap.SmsTemplateName;
                outputWrap.templateName = 'ABSLI_Request_Complaint_Un_Resolved_VF';
                outputWrap.isFTR = false;
                allOutputs.put(inpWrap.caseId, outputWrap);
            }
        } 
    }
    
}