/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-01-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.stdCyclomaticComplexity')
public class ABSLI_PopulateRegionalEmailSMS {
     /**
     * @description This method is called from ASF_CustomerEmailInvocable to populate the Regional Email and 
     * SMS template if user has preferred language
     * @param inputWrapList from flow
     * @param allOutputs - outputWrapper with updated values
     */
    public static void getRegionalTemplate(List<ASF_CustomerEmailInvocable.EmailInputWrapper> inputWrapList, Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs){
        Set<Id> cccIdList = new Set<Id>();
        Set<String> queryFields = new Set<String>();
        List<ASF_Case_Email_Config__c> regionalTemplatesList;
        Map<String, ASF_Case_Email_Config__c> cccIdToRegTemplateMap = new Map<String, ASF_Case_Email_Config__c>();
        
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inpWrap : inputWrapList){
            ASF_Case_Category_Config__c config = (ASF_Case_Category_Config__c)inpWrap.cccRecord;
            if(!allOutputs.containsKey(inpWrap.caseId)){
                cccIdList.add(config.Id);
                queryFields.add(inpWrap.emailFieldName);
                queryFields.add(inpWrap.SmsFieldName);
            } 
        }
        if(!cccIdList.isEmpty()){
            regionalTemplatesList = ASF_EmailMessageQueryHandler.getRegionalTemplatesList(cccIdList, queryFields);
        }
        
        if(regionalTemplatesList != null && !regionalTemplatesList.isEmpty()){
         
            for(ASF_Case_Email_Config__c regTempRec : regionalTemplatesList){
                if(regTempRec.Language__c != null){
                    cccIdToRegTemplateMap.put(regTempRec.Case_Category_Config__c+'-'+regTempRec.Language__c.toLowerCase(),regTempRec);
                }
            }
            for(ASF_CustomerEmailInvocable.EmailInputWrapper inpWrap : inputWrapList){
                
                ASF_Case_Category_Config__c config = (ASF_Case_Category_Config__c)inpWrap.cccRecord;
                ASF_CustomerEmailInvocable.EmailOutputWrapper outputWrap = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
                
                if(cccIdToRegTemplateMap.containsKey(config.Id+'-'+inpWrap.LanguagePreference.toLowerCase())){
                    SObject regionalTemplateRec = (SObject)cccIdToRegTemplateMap.get(config.Id+'-'+inpWrap.LanguagePreference.toLowerCase());
                    outputWrap.SmsTemplateName = (String)regionalTemplateRec.get(inpWrap.SmsFieldName) != null ? (String)regionalTemplateRec.get(inpWrap.SmsFieldName)
                        																						: inpWrap.SmsTemplateName;
                    outputWrap.templateName = (String)regionalTemplateRec.get(inpWrap.emailFieldName) != null ? (String)regionalTemplateRec.get(inpWrap.emailFieldName)
                        																						: inpWrap.templateName;
                    outputWrap.supressEmail = false;
                    allOutputs.put(inpWrap.caseId, outputWrap);
                } 
            }
        }
    }

    /**
     * @description This method is called from ASF_CustomerEmailInvocable for newly created
     * cases when the FTR flag is set to true
     * @param inputWrapList from flow
     * @param allOutputs - outputWrapper with updated values
     */
    public static void processFTRTemplate(List<ASF_CustomerEmailInvocable.EmailInputWrapper> inputWrapList, 
                                                                                           Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs){
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inpWrap : inputWrapList){
            
            ASF_CustomerEmailInvocable.EmailOutputWrapper outputWrap = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
            Case caseRec = (Case)inpWrap.caseRecord;
            
            if(inpWrap.caseStatus == 'New' && caseRec.FTR__c == true){
                outputWrap.supressEmail = true;
                outputWrap.SmsTemplateName = inpWrap.SmsTemplateName;
                outputWrap.templateName = inpWrap.templateName;
                outputWrap.isFTR = true;
                allOutputs.put(inpWrap.caseId, outputWrap);
            }
        }
    }
}