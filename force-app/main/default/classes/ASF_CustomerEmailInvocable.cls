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
        List<EmailInputWrapper> wellnessList = new List<EmailInputWrapper>();
        List<EmailInputWrapper> abhflList = new List<EmailInputWrapper>();
        List<EmailInputWrapper> paymentsList = new List<EmailInputWrapper>();
        
        for(EmailInputWrapper wrap: cases){
            
            ASF_Case_Category_Config__c config = (ASF_Case_Category_Config__c)wrap.cccRecord;
            
            switch on config.Business_unit__c{
                when 'Wellness'{
                    wellnessList.add(wrap);
                }
                when 'ABFL'{
                    abflList.add(wrap);
                }
                when 'ABHFL'{
                    abhflList.add(wrap);
                }
                when 'Payments'{
                    paymentsList.add(wrap);
                }
            }
        }
        
        Map<Id, EmailOutputWrapper> allOutputs = new Map<Id, EmailOutputWrapper>();
        
        if(!wellnessList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
            MCRM_SuppressEmailHelper.checkSuppressionLogic(cases,allOutputs);
        }
        if(!abflList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
            ABFL_SuppressEmailHelper.checkSuppressionLogic(cases,allOutputs);
        }
        if(!abhflList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
        }
        if(!paymentsList.isEmpty()){
            // Call BU Specific Class - Returns Map<Id, EmailOutputWrapper>
            //allOutputs.putAll(arg0)
        }
        
        for(EmailInputWrapper wrap: cases){
            EmailOutputWrapper resultWrap = new EmailOutputWrapper();
            if(allOutputs.containsKey(wrap.caseId)){
                resultWrap = allOutputs.get(wrap.caseId);
            }
            else {
                resultWrap.supressEmail = false;
                resultWrap.templateName = wrap.templateName;
            }

            result.add(resultWrap);
            
        }
        //system.debug('Invocable result:'+result);
        return result;
    }
/*********************************************************
*@description  :  wrapper class
*********************************************************/  
  public class EmailOutputWrapper {
        @InvocableVariable(label='Supress Email' description='Supress Email completely' required=true)
        public boolean supressEmail;
        @InvocableVariable(label='Template Name' description='Template Name' required=true)
        public String templateName;
    }
/*********************************************************
*@description  :  wrapper class
*********************************************************/
    public class EmailInputWrapper {
        @InvocableVariable(label='Case Id' description='Case Id' required=true)
        public Id caseId;
        @InvocableVariable(label='Case Status' description='Case Status' required=true)
        public String caseStatus;
        @InvocableVariable(label='CCC Record' description='Case Category Config Record' required=true)
        public sObject cccRecord;
        @InvocableVariable(label='Template Name' description='Default Template name passed' required=true)
        public String templateName;
        
    }
    
    
}