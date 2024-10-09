/*********************************************************
*@description  :  This class is called by the Flow for Case Email 
* for Customers. It can return a custom email template
* in case of supression / exception scenarios
* The BU classes will be called from here, and
*********************************************************/
public without sharing class ASF_CustomerEmailInvocable {
    /****************************************************************************************************************
    * @Function - getEmailTemplateName
    * @param cases 
    * @return  List<EmailOutputWrapper>
    * @description - The Flow must pass the case record id,
* Based on the BU stamped, the BU class is called
* If Blank or Null is returned, the Flow takes the usual route of finding the template
* names from CC and sends email 
   *****************************/
    @InvocableMethod(label='Customer Email Invocable' description='Returns Template names from BU')
    public static List<EmailOutputWrapper> getEmailTemplateName(List<EmailInputWrapper> cases) {
        List<EmailOutputWrapper> result = new List<EmailOutputWrapper>();
        List<EmailInputWrapper> abflList = new List<EmailInputWrapper>();
        List<EmailInputWrapper> abhflList = new List<EmailInputWrapper>();
        List<EmailInputWrapper> paymentsList = new List<EmailInputWrapper>();
        List<EmailInputWrapper> absliList = new List<EmailInputWrapper>();
        
        for(EmailInputWrapper wrap: cases){
            
            ASF_Case_Category_Config__c config = (ASF_Case_Category_Config__c)wrap.cccRecord;
            
            switch on config.Business_unit__c{
                when 'ABFL'{
                    abflList.add(wrap);
                }
                when 'ABHFL'{
                    abhflList.add(wrap);
                }
                when 'Payments'{
                    paymentsList.add(wrap);
                }
                 when 'ABSLI' {
                    absliList.add(wrap);
                }
            }
        }
        
        Map<Id, EmailOutputWrapper> allOutputs = new Map<Id, EmailOutputWrapper>();
        
        if(!abflList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
            ABFL_SuppressEmailHelper.checkSuppressionLogic(cases,allOutputs);
        }
        /*if(!abhflList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
        }
        if(!paymentsList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
        } */
        if(!absliList.isEmpty()){
        
            List<EmailInputWrapper> ftrCaseList = new List<EmailInputWrapper>();
            List<EmailInputWrapper> regionalTemplateList = new List<EmailInputWrapper>();
            List<EmailInputWrapper> unresolvedCaseList = new List<EmailInputWrapper>();
            
            for(EmailInputWrapper inpWrap : absliList){
                if(inpWrap.CaseStatus == 'Unresolved'){
                    unresolvedCaseList.add(inpWrap);
                    continue;
                }
                else if(inpWrap.caseStatus == 'New'){
                    ftrCaseList.add(inpWrap);
                }
                if(inpWrap.LanguagePreference != null && inpWrap.LanguagePreference != '' && inpWrap.LanguagePreference.toLowerCase() != 'english'){
                    regionalTemplateList.add(inpWrap);
                }
            }
            if(!ftrCaseList.isEmpty()){
               ABSLI_PopulateRegionalEmailSMS.processFTRTemplate(absliList, allOutputs);
            }
            if(!regionalTemplateList.isEmpty()){
                ABSLI_PopulateRegionalEmailSMS.getRegionalTemplate(absliList, allOutputs);
            }
            if(!unresolvedCaseList.isEmpty()){
                ABSLI_EmailSMSSuppressionHandler.handleSuppressionLogic(absliList, allOutputs);
            }
        }
        
        for(EmailInputWrapper wrap: cases){
            EmailOutputWrapper resultWrap = new EmailOutputWrapper();
            if(allOutputs.containsKey(wrap.caseId)){
                resultWrap = allOutputs.get(wrap.caseId);
            }
            else {
                resultWrap.supressEmail = false;
                resultWrap.templateName = wrap.templateName;
                resultWrap.smsTemplateName = wrap.smsTemplateName;
            }

            result.add(resultWrap);
            
        }
        return result;
    }
/*********************************************************
*@description  :  wrapper class
*********************************************************/  
    public class EmailOutputWrapper {
        @InvocableVariable(label='Supress Email' description='Supress Email completely' required=true)
        public boolean supressEmail;
        @InvocableVariable(label='Email Template Name' description='Template Name' required=true)
        public String templateName;
        @InvocableVariable(label='SMS Template Name' description='SMS Template name' required=true)
        public String smsTemplateName;
        public boolean isFTR;
    }
/*********************************************************
*@description  :  wrapper class
*********************************************************/
    public class EmailInputWrapper {
        @InvocableVariable(label='Case Id' description='Case Id' required=true)
        public Id caseId;
        @InvocableVariable(label='Language Preference' description='Language Preference' required=false)
        public String languagePreference;
        @InvocableVariable(label='Case Status' description='Case Status' required=true)
        public String caseStatus;
        @InvocableVariable(label='Case Record' description='Case Record' required=false)
        public sObject caseRecord;
        @InvocableVariable(label='CCC Record' description='Case Category Config Record' required=true)
        public sObject cccRecord;
        @InvocableVariable(label='Email Template Name' description='Default Template name passed' required=false)
        public String templateName;
        @InvocableVariable(label='SMS Template Name' description='Default SMS Template name passed' required=false)
        public String smsTemplateName;
        @InvocableVariable(label='Email Template Field Name' description='Email Template Field Name' required=false)
        public String emailFieldName;
        @InvocableVariable(label='SMS Template Field Name' description='SMS Template Field Name' required=false)
        public String smsFieldName;
        
    }
    
    
}