/*********************************************************
*Class        :  ABFL_WealthChatGeneratedCases
*Author       :  Salesforce 
*Created Date :  23/02/2024
*Last Modified:  28/02/2024
*description  :  To update the Email Id and mobile on the Case.SuppliedEmail & Case.SuppliedPhone and then send and acknowledgement Email and SMS to Customer
*********************************************************/

@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
public with sharing class ABFL_WealthChatGeneratedCases {
    /**
    * @param emailMessageList - list of EmailMessage records 
    * @description - this method extracts the Email & mobile from the Email Body & assign these to the Case.suppliedEmail & case.SuppliedPhone to send an Acknowledgment Email & SMS to the provided Email & Phone when the Case.Origin is ABWM Email
    */
    public static void execute(list<EmailMessage> emailMessageList){
        Map<Id,String> mapCaseIdToEmailId = new  Map<Id,String>(); // Map to hold Case Ids with the EmailId
        Map<Id,String> mapCaseIdToMobile = new  Map<Id,String>(); // Map to hold Case Ids with the EmailId
        Set<Id> caseIdsToSendAcknowledgement = new Set<Id>();
        for(EmailMessage msg : emailMessageList){
            if( msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType ){
                boolean bEligible = false;
                if((msg.Headers != null && msg.Headers.contains('In-Reply-To:') && msg.ReplyToEmailMessageId == null )){
                    bEligible = true;
                }
                else if(msg.Headers != null && msg.Headers.contains('In-Reply-To:')){
                    bEligible = false;
                }
                else{
                    bEligible = true;
                }
                if(bEligible){
                    String inputText = msg.TextBody;
                    String extractedEmail;
                    String extractedMobile;
                    if(inputText != null && inputText != ''){
                        extractedEmail = extractEmail(inputText);
                        extractedMobile = extractMobile(inputText);
                    }
                    if(extractedEmail != null || extractedEmail !=''){
                        mapCaseIdToEmailId.put(msg.ParentId, extractedEmail);
                    }
                    if(extractedMobile != null || extractedMobile != ''){
                        mapCaseIdToMobile.put(msg.ParentId, extractedMobile);
                    }
                    //CHECK IF THE WINNING ADDRESS IS SCENARIO 4 EMAIL ADDRESS - 
                    // CREATE SET OF CASE ID OF SUCH EMAILS.
                    caseIdsToSendAcknowledgement.add(msg.ParentId);
                } 
            }
        }

        List<Case> casesToUpdate = new List<Case>();
        for(Case c : ASF_EmailMessageQueryHandler.getCaseRecords(mapCaseIdToEmailId.Keyset())){
            if(c.Origin == ABFL_Constants.WMCHATCASEORIGIN){
                c.SuppliedEmail = mapCaseIdToEmailId.get(c.Id) !=null ? mapCaseIdToEmailId.get(c.Id) : c.SuppliedEmail ;
                c.SuppliedPhone = mapCaseIdToMobile.get(c.Id) !=null ? mapCaseIdToMobile.get(c.Id) : c.SuppliedPhone;
                casesToUpdate.add(c);
            }
            
        }
        // CHECK IF THE CASE ORIGIN is ABWM Email if true then send Acknowledgement email.
        if(caseIdsToSendAcknowledgement.size()>0){
            for(case caseobj: ASF_EmailMessageQueryHandler.getCaseRecords(caseIdsToSendAcknowledgement)){
                if(caseobj.Origin == ABFL_Constants.ABWMEMAIL){
                    ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(caseobj, ABFL_Constants.WMEMAILTEMPLATENAME, caseobj.SuppliedEmail, '', '');
                }
            }
        }
            
        //try{-- Commented as email address validation should happen at chatbot end
            //Check if the casesToUpdate list is empty or not
            if(!casesToUpdate.isEmpty() && casesToUpdate.size()>0){
                ASF_TriggerSkipperUtility.markTriggerRun('Case'); // to disable the trigger
                if(Schema.sObjectType.Case.isUpdateable()){ 
                    update casesToUpdate;
                }
                for(Case c: casesToUpdate){
                    // Platform Event trigger to send Email and SMS to the Supplied Email & Phone
                    ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(c, ABFL_Constants.WMEMAILTEMPLATENAME, c.SuppliedEmail, ABFL_Constants.WMSMSTEMPLATENAME, c.SuppliedPhone);
                } 
            } 
        /*
        }catch(Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_WealthChatGeneratedCases: Case Generation failed');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }*/
    }
    
    // Added By EY-Nikhil for INC000000073049
    // To send the Unregister email to customer when email is blank on case Account 
    public static void sendEmailWhenNotRegisteredCustomer(List<EmailMessage> emailMessageList) {
        Set<Id> caseIdsToSendEmail = new Set<Id>();
        Map<Id, String> mCaseEmailTemplateName = new Map<Id, String>();
        Map<String, String> mEmailAddressToTemplate = new Map<String, String>();
        
        
        for (EmailMessage msg : emailMessageList) {
            if (msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType) {
                boolean bEligible = false;
                
                if ((msg.Headers != null && msg.Headers.contains('In-Reply-To:') && msg.ReplyToEmailMessageId == null)) {
                    bEligible = true;
                } else if (msg.Headers != null && msg.Headers.contains('In-Reply-To:')) {
                    bEligible = false;
                } else {
                    bEligible = true;
                }
                
                if (bEligible) {
                    caseIdsToSendEmail.add(msg.ParentId);
                    if (mEmailAddressToTemplate.containsKey(msg.Winning_Email__c)) {
                        mCaseEmailTemplateName.put(msg.ParentId, mEmailAddressToTemplate.get(msg.Winning_Email__c));
                    }
                }
            }
        }
        
        if (caseIdsToSendEmail.size() > 0) {
            // Query child objects ABFL_Case_Detail__c to check the IsRegisteredCustomer__c field
            Map<Id, ABFL_Case_Detail__c> caseDetailMap = new Map<Id, ABFL_Case_Detail__c>();
            
            for(ABFL_Case_Detail__c asfCaseDetail : [SELECT Id, Case__c, IsRegisteredCustomer__c FROM ABFL_Case_Detail__c WHERE Case__c IN :caseIdsToSendEmail]){
                caseDetailMap.put(asfCaseDetail.Case__c,asfCaseDetail);
            }
            
            for (Case caseObj : ASF_EmailMessageQueryHandler.getCaseRecords(caseIdsToSendEmail)) {
                if (caseObj.Origin == 'ABFL Email' && caseObj.Business_unit__c == 'ABFL') {
                    // Check if the case has a detail record with IsRegisteredCustomer__c set to "No"
                    if (caseDetailMap.containsKey(caseObj.Id) && 
                        caseDetailMap.get(caseObj.Id).IsRegisteredCustomer__c == 'No') {
                            
                  String templateDevName = 'ABFL_ACCOUNT_RELATED';
                            
                  // Send the communication
                  ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(caseObj, templateDevName, caseObj.SuppliedEmail, '', '');
                   }
                }
            }
        }
    }

    
    /**
    * @param inputText - String text (Email body)
    * @return - String - Email Id if found in body.
    * @description - this method extracts the Email Id and return the same 
    */
    public static String extractEmail(String inputText) {
        String patternString = 'Email ID: (\\S+@\\S+)';
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(inputText);
        
        if (matcher.find()) {
            return matcher.group(1);
        } else {
            return null; // No match found
        }
    }
    
    /**
    * @param inputText - String text (Email body)
    * @return - String - Mobile if found in body.
    * @description - this method extracts the Mobile and return the same 
    */  
    public static String extractMobile(String inputText) {
        String patternString = 'Mobile No\\.\\s*:\\s*(\\d{10})';
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(inputText);
        
        if (matcher.find()) {
            return matcher.group(1);
        } else {
            return null; // No match found
        }
    }
    
}
