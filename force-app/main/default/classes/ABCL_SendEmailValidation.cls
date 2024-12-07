
/*********************************************************
*Class        :  ABFL_SendEmailValidation
*Author       :  Shubham Sinha 
*Created Date :  03/01/2024
*@description  :  ABFL_SendEmailValidation validates the user's team while replying email from case and put the validation on from address according to user story PR970457-197
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABCL_SendEmailValidation {

 /****************************************************************************************************************
    * @param  newEmails List<EmailMessage> newEmails
    * @description - check the loggedin User's team and put the validation on from address while sending an email to case.
    *****************************************************************************************************************/ 
    public static void validateUsersTeam(List<EmailMessage> newEmails){
        List<EmailMessage> outgoingCaseEmails = new List<EmailMessage>();
        List<String> allowedFromAddress = new List<String>();
        List<String> allowedBusinessUnit = new List<String>();
        List<String> selectedFromAddress = new List<String>();
        Boolean isAllowedFromAddress = false;
        ///Checking if the request is coming from User Action by Clicking on Quick Action - Email.
        Request reqInfo = Request.getCurrent();
        //String currentRequestId = reqInfo.getRequestId();
        Quiddity currentType = reqInfo.getQuiddity();
       // system.debug('currentTypevalue '+currentType);
        String runningUserFullName = UserInfo.getName();
         Set<Id> caseIds = new Set<Id>(); //[START]Zahed :  PR1030924-211:   
        if((currentType != Quiddity.QUICK_ACTION && currentType != Quiddity.SYNCHRONOUS) || runningUserFullName.contains('Platform')){
            if(!Test.isRunningTest()){
                return;
            }
        } 
        for (EmailMessage email : newEmails) {                 
            if(!email.Incoming && email.ParentId != null){
                if(email.ParentId.getSObjectType() == Case.sObjectType && email.ValidatedFromAddress!=null){
                    outgoingCaseEmails.add(email);
                    selectedFromAddress.add(email.ValidatedFromAddress);
                   //  system.debug('mdtAllowedAddress '+selectedFromAddress);
                }
            }
             //[START]Zahed :  PR1030924-211:   
            if(!email.Incoming && email.ParentId != null && email.ParentId.getSObjectType() == Case.getSObjectType()){                           
                caseIds.add(email.ParentId);
            }
            //[END]
        }
        // we can extend the logic for this method by adding business unit on this custom metadata. Getting allowed business unit value.
        ABFL_Email_Validation_Configuration__mdt mdtAllowedBusinessUnit = ABFL_Email_Validation_Configuration__mdt.getInstance('Business_Unit'); 
        allowedBusinessUnit= mdtAllowedBusinessUnit.Email_Addresses_Allowed_Long__c.split(',');
       // system.debug('allowedBusinessUnit '+allowedBusinessUnit);
		List<User> userTeam = [SELECT ID ,Team__c FROM USER WHERE ID = :UserInfo.getUserID() AND Business_Unit__c IN: allowedBusinessUnit AND Profile.Name != 'System Administrator' WITH SYSTEM_MODE];

        if(!userTeam.isEmpty() && userTeam[0].Team__c!=null){
            // Getting restricted FROM address.For the restricted FROM email address email should not go to external domain.
            ABFL_Email_Validation_Configuration__mdt mdtRestrictedFromAddress = ABFL_Email_Validation_Configuration__mdt.getInstance('Restricted_From_Address'); 
            // Getting allowed FROM address according to the team assigned on user.
            // ABFL_Email_Validation_Configuration__mdt mdtAllowedFromAddress = ABFL_Email_Validation_Configuration__mdt.getInstance(userTeam[0].Team__c);
            ABFL_Email_Validation_Configuration__mdt mdtAllowedFromAddress = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Email_Addresses_Allowed_Long__c FROM ABFL_Email_Validation_Configuration__mdt where developerName =:userTeam[0].Team__c];
            // below code checks if FROM address selected is part of user's team allowed FROM address, if not throwing an error.
            if(mdtAllowedFromAddress.Email_Addresses_Allowed_Long__c != null){
                allowedFromAddress= mdtAllowedFromAddress.Email_Addresses_Allowed_Long__c.split(',');
                String loggedInUserEmail = UserInfo.getUserEmail();                
                for (String domain : allowedFromAddress) {
                    if (selectedFromAddress.contains(domain.toLowerCase())) {
                        isAllowedFromAddress = true;
                       // system.debug('isAllowedFromAddressValue '+isAllowedFromAddress);
                    }
                }
                for (EmailMessage email : outgoingCaseEmails) {
                    if(!isAllowedFromAddress && email.ValidatedFromAddress != loggedInUserEmail){
                    email.addError(system.label.Error_From_Address);
                    }
                } 
               //[START]Zahed :  PR1030924-211: below code added to validate Email.    
                Map<Id, Case> casesMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);          
                for (EmailMessage email : newEmails) {          
                    if (email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType) {                
                        Case relatedCase = casesMap.get(email.ParentId);               
                        if (relatedCase != null && relatedCase.OwnerId != UserInfo.getUserId()) {
                            email.addError(System.Label.Wellness_CaseComment_add_Err_Msg);
                        }
                    }
                }
                //[END]
            }  
             // below code checks if FROM address selected is allowed to send an email to external email ,if not then throwing an error.
             if(mdtRestrictedFromAddress.Email_Addresses_Allowed_Long__c != null){
                for (EmailMessage email : outgoingCaseEmails) {
                    if(email.ValidatedFromAddress == mdtRestrictedFromAddress.Email_Addresses_Allowed_Long__c &&  !email.ToAddress.containsIgnoreCase(system.label.Allowed_Domain)){
                    email.addError(system.label.Error_Restricted_Domain+' '+email.ValidatedFromAddress);
                    }
                } 
            } 
        }
        // if user doesnt have any team assigned , throwing the below validation.
        else if(!userTeam.isEmpty() && userTeam[0].Team__c==null){
            for (EmailMessage email : outgoingCaseEmails) {
                email.addError(system.label.Error_Team_Not_Found);
            }
        } 
    }

    /**
    * @param newEmails - the case that is created from create case page
    * @description - Restrict User to send email based on user's Team
    */
    public static void restrictUserToSendEmail(List<EmailMessage> newEmails){

        Map<String, List<String>> mapOfBussUnitToSourceCodeList = new Map<String, List<String>>();
        List<String> selectedTeamList = new List<String>();
        List<EmailMessage> outgoingCaseEmails = new List<EmailMessage>();

        Custom_Messages__mdt mdtRestrictedErrorMessage = Custom_Messages__mdt.getInstance('Restrict_to_send_email_error_message'); 
        List<User> userRecord = [SELECT ID, Business_Unit__c, Source_Code__c FROM USER WHERE ID = :UserInfo.getUserID() WITH SYSTEM_MODE];
        String userSourceCode = userRecord[0]?.Source_Code__c?.toLowerCase() ?? '';
        String userBusinessUnit = userRecord[0]?.Business_Unit__c?.toLowerCase() ?? '';
        List<String> buRestrictionList = LABEL.BU_Restrict_email.toLowerCase().split(',');

        for (String buRestricton : buRestrictionList) {
            List<String> usrSourceCode = buRestricton.split(':');
            String businessUnitName = usrSourceCode[0];
            usrSourceCode.remove(0);
            mapOfBussUnitToSourceCodeList.put(businessUnitName, usrSourceCode);
        }

        if(mapOfBussUnitToSourceCodeList.containsKey(userBusinessUnit)) {
            List<String> sourceCodeList = mapOfBussUnitToSourceCodeList.get(userBusinessUnit);
            for (EmailMessage email : newEmails) {
                if(!email.Incoming && email.ParentId != null){
                    if(email.ParentId.getSObjectType() == Case.sObjectType){ 
                        if(sourceCodeList.contains(userSourceCode)) {
                            email.addError(mdtRestrictedErrorMessage.Message__c);
                        }
                    }
                }
            }
        }
    }

   /****************************************************************************************************************
    * @author - Nikhil Dhoke (EY-ABCL) 
    * @param  newEmails List<EmailMessage> newEmails
    * @description - validate the emailtemplate id and from address.
    *****************************************************************************************************************/
    public static void verifyEmailTemplate(List<SObject> newItems) {
        
        ABCL_Emailtemplate_LOB_Mapping__mdt lob = ABCL_Emailtemplate_LOB_Mapping__mdt.getInstance('Valid_Business_Unit');
        User userObj = [SELECT Id, Name, Business_Unit__c FROM USER WHERE Id =: UserInfo.getUserId()];
        if(lob != null && userObj.Business_Unit__c != null && lob.Business_Unit__c.toUppercase().contains(userObj.Business_Unit__c.toUppercase())){

            // Retrieve all custom metadata records for email templates
            List<ABCL_EmailTemplate_Mapping__mdt> metadataRecords = [SELECT From_Address__c, Template_Id__c, Template_Name__c FROM ABCL_EmailTemplate_Mapping__mdt];
            // Create a map to store the metadata records by Template Id
            Map<String, ABCL_EmailTemplate_Mapping__mdt> templateMap = new Map<String, ABCL_EmailTemplate_Mapping__mdt>();
            Map<String, ABCL_EmailTemplate_Mapping__mdt> correctTemplateMap = new Map<String, ABCL_EmailTemplate_Mapping__mdt>();
            for (ABCL_EmailTemplate_Mapping__mdt record : metadataRecords) {
                templateMap.put(record.Template_Id__c, record);
                correctTemplateMap.put(record.From_Address__c,record);
            }
            
            // Loop through the EmailMessage records passed to the method
            for (EmailMessage em : (List<EmailMessage>)newItems) {
                if(em.Incoming == false){
                    if(em.EmailTemplateId==null){
                        em.addError('Please select the template');
                    }
                    else if(correctTemplateMap.containsKey(em.ValidatedFromAddress) && !templateMap.containsKey(em.EmailTemplateId)){
                        em.addError('Selected email template is not configured for the from address. Please select the template with name "' +correctTemplateMap.get(em.ValidatedFromAddress).Template_Name__c+'"');
                    }
                    else if(!correctTemplateMap.containsKey(em.ValidatedFromAddress) && templateMap.containsKey(em.EmailTemplateId)){
                        em.addError('Invalid from address for selected template. Please select from address "' +templateMap.get(em.EmailTemplateId).From_Address__c+'"');
                    }
                    else if (templateMap.containsKey(em.EmailTemplateId) && templateMap.get(em.EmailTemplateId).From_Address__c != em.ValidatedFromAddress) {
                        em.addError('Invalid email template for selected from address. Please select the template with name "' +correctTemplateMap.get(em.ValidatedFromAddress).Template_Name__c+'"');
                    }
                }
                
            }
        }
    }
}
