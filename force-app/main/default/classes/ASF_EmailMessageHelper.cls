/****************************************************************************************************************
* @LOB - Framework
* @Description - Emailhelper for framework requirement.
* @Author - Virendra Patil
* 
*****************************************************************************************************************/
public class ASF_EmailMessageHelper {
    
    /* Validate if the email going out is from OrgWideDefaultOnly.
*/
    public static void validateIfGoingFromAuthorizedAddress(List<EmailMessage> newEmails){
        List<EmailMessage> outgoingCaseEmails = new List<EmailMessage>();
        
        
        /* Check if the request is coming from User Action by Clicking on Quick Action - Email.
* Return if the request is not from Quick Action. All the automation to have Quiddity as SYNCHRONOUS
*/
        Request reqInfo = Request.getCurrent();
        String currentRequestId = reqInfo.getRequestId();
        Quiddity currentType = reqInfo.getQuiddity();
        if(currentType != Quiddity.QUICK_ACTION && currentType != Quiddity.SYNCHRONOUS){
            if(!Test.isRunningTest()){
                //return;
            }
        }
        
        for (EmailMessage email : newEmails) {
            if(!email.Incoming && email.ParentId != null){
                if(email.ParentId.getSObjectType() == Case.sObjectType){
                    outgoingCaseEmails.add(email);
                }
            }
        }
        
        if(outgoingCaseEmails.size()>0){
            String loggedInUserEmail = UserInfo.getUserEmail();
            
            for(EmailMessage email : outgoingCaseEmails){
                if(loggedInUserEmail == email.ValidatedFromAddress){
                    email.addError('You are trying to send email from your email address. Please select authorized email address from the list.');
                }
            }
        }
    }
 
    public static void checkAndReopenClosedCases(List<EmailMessage> newEmails) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, EmailMessage> caseIdToEmailMessageMap = new Map<Id, EmailMessage>();

        for(EmailMessage emRec : newEmails){
            System.debug('checkAndReopenClosedCases'+emRec.ParentId+emRec.Headers);
            if(emRec.Headers != null && emRec.ParentId.getSObjectType() == Case.getSObjectType()){
                //Its a reply, so evaluate
                caseIds.add(emRec.ParentId);
                caseIdToEmailMessageMap.put(emRec.ParentId, emRec);
            }
        }
        if(!caseIds.isEmpty()){
            Map<Id, Case> oldCaseIdToNewCaseMap = new Map<Id, Case>();
            List<Case> casesToReopen = new List<Case>();
            List<Case> existingCases = [SELECT Id, IsClosed, Is_Reopen_Allowed__c, Reopen_Days__c, ClosedDate,
            CCC_External_Id__c, AccountId, Channel__c, Origin, Priority, RecordTypeId, SuppliedEmail, SuppliedName, 
            Technical_Source__c, Nature__c, ContactId
            FROM Case 
            WHERE Id IN :caseIds];
            
            for(Case caseRec : existingCases){
                //check if closed or not
                if(caseRec.IsClosed && caseRec.Origin != null && caseRec.Origin.contains('Email') 
                    && caseRec.RecordTypeId == ASF_Constants.RT_FRAMEWORK
                    && caseRec.Nature__c == 'Complaint'){
                    //if closed, check if reopen allowed or not
                    if(caseRec.Is_Reopen_Allowed__c == true){
                        // if allowed, check if reopen days expired or not
                        if(caseRec.ClosedDate != null && caseRec.Reopen_Days__c != null 
                        && System.today().daysBetween(caseRec.ClosedDate.date()) <= caseRec.Reopen_Days__c){
                            // if not expired, reopen
                            caseRec.Reopen_Reason__c = Label.ASF_Default_Reopen_Reason;
                            caseRec.Reopened__c = true;
                            caseRec.Reopened_DateTime__c = System.now();
                            casesToReopen.add(caseRec);
                        }else{
                            // else create new case and reparent EmailMessage
                            Case newCase = createNewCaseInstance(caseRec, caseIdToEmailMessageMap);
                            oldCaseIdToNewCaseMap.put(caseRec.Id, newCase);
                        }
                    }else {
                        // else create new case and reparent EMailMessage
                        Case newCase = createNewCaseInstance(caseRec, caseIdToEmailMessageMap);
                        oldCaseIdToNewCaseMap.put(caseRec.Id, newCase);
                    }
                }else {
                    //not closed, then do nothing
                }
            }
            if(!casesToReopen.isEmpty()){
                update casesToReopen;
            }
            if(!oldCaseIdToNewCaseMap.isEmpty()){
                insert oldCaseIdToNewCaseMap.values();

                //reparent Email Messages
                for(Id oldCaseId : oldCaseIdToNewCaseMap.keySet()){
                    EmailMessage em = caseIdToEmailMessageMap.get(oldCaseId);
                    em.ParentId = oldCaseIdToNewCaseMap.get(oldCaseId).Id;
                }
            }
        }
    }

    private static Case createNewCaseInstance(Case closedCase, Map<Id, EmailMessage> caseIdToEmailMessageMap) {
        Case newCase = new Case();
        newCase.Subject = caseIdToEmailMessageMap.get(closedCase.Id).Subject;
        newCase.Description = caseIdToEmailMessageMap.get(closedCase.Id).TextBody;
        newCase.AccountId = closedCase.AccountId;
        newCase.ContactId = closedCase.ContactId;
        newCase.Origin = closedCase.Origin;
        newCase.Priority = closedCase.Priority;
        newCase.RecordTypeId = ASF_Constants.RT_INTERACTION;
        newCase.SuppliedEmail = closedCase.SuppliedEmail;
        newCase.SuppliedName = closedCase.SuppliedName;

        return newCase;
    }
    
}