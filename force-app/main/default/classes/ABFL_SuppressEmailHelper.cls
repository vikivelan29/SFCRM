/*********************************************************
*Class        :  ABFL_SuppressEmailHelper
*Author       :  Virendra Patil
*Created Date :  16 Jan 2024
*@description  :  This class is used for Suppressing the outbound email notification based on ABFL requirements.
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public without sharing class ABFL_SuppressEmailHelper {
/****************************************************************************************************************
* @param inpArg
* @param allOutputs
* @description - checkSuppressionLogic
*****************************************************************************************************************/ 
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
                
        // SCENARIO 1 - WHEN CASE CREATED WITH SOURCE AS RM-NO EMAIL/ IVR-NO EMAIL/ PHONE-INBOUND AND QUERY.
        suppressRMNoEmail(caseIds,inpArg,allOutputs);
        
    }
    
    private static void suppressRMNoEmail(Set<Id> caseIds,
                                          List<ASF_CustomerEmailInvocable.EmailInputWrapper> inpArg,
                                          Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs)
    {
        //System.debug('caseIds --> '+caseIds);
        Map<Id,Case> mCases = new Map<Id,Case>([SELECT ID,Source__c,Nature__c,Winning_Email__c,FTR__c,OnCreateCloseSR__c FROM Case WHERE Id =: caseIds]);
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
                if(c.FTR__c == true || c.OnCreateCloseSR__c == true || c.Source__c =='OneABC' || c.Winning_Email__c== System.label.Restrict_Email_Address){
                    ASF_CustomerEmailInvocable.EmailOutputWrapper output = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
                    output.supressEmail = true;
                    output.templateName = inp.templateName;
                    allOutputs.put(inp.caseId,output);
                }
            }
        }
    }
}