/*
*********************************************************
Apex Class Name    : ABFL_SuppressEmailHelper
Created Date       : 16 Jan 2024
@description       : This class is used for Suppressing the outbound email notification based on ABFL requirements.
@author            : Virendra Patil
Modification Log:
Ver   Date         Author                               Modification
1.0   16 Jan 2024   Virendra Patil                      Initial Version
*********************************************************
*/
public without sharing class ABFL_SuppressEmailHelper {
    public static void checkSuppressionLogic(List<ASF_CustomerEmailInvocable.EmailInputWrapper> inpArg,
                                             Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs)
    {
        Set<Id> caseIdsForEBOTResolution = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        
        
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inp : inpArg){
            if(ASF_Constants.RESOLVEDSTAGES.contains(inp.caseStatus)){
                caseIdsForEBOTResolution.add(inp.caseId);
            }
            // CREATE A DEFAULT STRUCTURE.
            ASF_CustomerEmailInvocable.EmailOutputWrapper output = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
            output.supressEmail = false;
            output.templateName = inp.templateName;
            allOutputs.put(inp.caseId,output);
            caseIds.add(inp.caseId);
        }
        
        // SCENARIO 1 - EBOT - EMAIL ALREADY SENT AS PART OF PROCESS. - ONLY RUN WHEN CASE IS RESOLVED.
        if(caseIdsForEBOTResolution.size()>0)
           // suppressEBOTResolutionEmail(caseIdsForEBOTResolution,inpArg,allOutputs);
        
        // SCENARIO 2 - WHEN CASE CREATED WITH SOURCE AS RM-NO EMAIL/ IVR-NO EMAIL/ PHONE-INBOUND AND QUERY.
        suppressRMNoEmail(caseIds,inpArg,allOutputs);
        
    }
    
    private static void suppressEBOTResolutionEmail(Set<Id> caseIds,
                                                    List<ASF_CustomerEmailInvocable.EmailInputWrapper> inpArg,
                                                    Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs)
    {
        List<ABFL_Case_Detail__c > abflCaseExtension = [SELECT ID,Case__c  FROM ABFL_Case_Detail__c WHERE Case__c = :caseIds LIMIT 1];
        Map<Id,boolean> mCaseResolutionEmailSent = new Map<Id,boolean>();
        
        for(ABFL_Case_Detail__c caseExt : abflCaseExtension){
            if(!mCaseResolutionEmailSent.containsKey(caseExt.Case__c)){
                boolean bResolutionCommunicationSent = false;
                mCaseResolutionEmailSent.put(caseExt.Case__c,bResolutionCommunicationSent);
            }
        }
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inp : inpArg){
            if(allOutputs.containsKey(inp.caseId)){
                if(mCaseResolutionEmailSent.containsKey(inp.caseId)){
                    boolean bResolEmailSent = mCaseResolutionEmailSent.get(inp.caseId);
                    ASF_CustomerEmailInvocable.EmailOutputWrapper output = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
                    output.supressEmail = bResolEmailSent;
                    output.templateName = inp.templateName;
                    allOutputs.put(inp.caseId,output);
                }
            }
        }
    }
    
    private static void suppressRMNoEmail(Set<Id> caseIds,
                                          List<ASF_CustomerEmailInvocable.EmailInputWrapper> inpArg,
                                          Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs)
    {
		System.debug('caseIds --> '+caseIds);
        Map<Id,Case> mCases = new Map<Id,Case>([SELECT ID,Source__c,Nature__c FROM Case WHERE Id =: caseIds]);
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inp : inpArg){
            if(mCases.containsKey(inp.caseId)){
                Case c = mCases.get(inp.caseId);
                if(c.Source__c != null){
                    if(c.Source__c.trim().toUpperCase() == 'RM-NO EMAIL' || c.Source__c.trim().toUpperCase() == 'IVR-NO EMAIL' || 
                       (c.Source__c.trim().toUpperCase() == 'PHONE-INBOUND' && c.Nature__c == 'Query'))
                    {
                        ASF_CustomerEmailInvocable.EmailOutputWrapper output = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
                        output.supressEmail = true;
                        output.templateName = inp.templateName;
                        allOutputs.put(inp.caseId,output);
                    }
                }
            }
        }
    }
}