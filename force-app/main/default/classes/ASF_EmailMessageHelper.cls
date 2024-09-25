/****************************************************************************************************************
* @LOB - Framework
* @Description - Emailhelper for framework requirement.
* @Author - Virendra Patil
* 
*****************************************************************************************************************/
public without sharing class ASF_EmailMessageHelper {
    public static boolean bNewCaseByReplyToCloseCase = false;
    private static Map<String, String> queueDevNameToEmail = new Map<String, String>();
    private static Map<String,Id> mQueueDevNameVsId = new Map<String,Id>();
    private static List<Case> existingCases = null;
    
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
    //Query the case record based on caseIds
    public static List<Case> fetchCaseDetails(Set<Id> caseIds){
        if(existingCases == null){
            existingCases = [SELECT Id, IsClosed, Is_Reopen_Allowed__c, Reopen_Days__c, ClosedDate,
                                        CCC_External_Id__c, AccountId, Channel__c, Origin, Priority, RecordTypeId, SuppliedEmail, SuppliedName, 
                                        Technical_Source__c, Nature__c, ContactId, Business_Unit__c
                                        FROM Case 
                                        WHERE Id IN :caseIds];
        }
        return existingCases;
    }

    //Set static boolean variable to true if the reply is sent to a closed case
    public static void checkIsReplyToCloseCase(List<EmailMessage> newEmails) {
        Set<Id> caseIds = new Set<Id>();
        for(EmailMessage emRec : newEmails){
            if(emRec.Headers != null && emRec.ParentId.getSObjectType() == Case.getSObjectType()){
                //Its a reply, so evaluate
                caseIds.add(emRec.ParentId);
            }
        }
        if(!caseIds.isEmpty()){
            existingCases = fetchCaseDetails(caseIds);
            for(Case caseRec : existingCases){
                /*
                if(caseRec.IsClosed && (caseRec.Is_Reopen_Allowed__c == false || (caseRec.Is_Reopen_Allowed__c == true && 
                 !(caseRec.ClosedDate != null && caseRec.Reopen_Days__c != null 
                  && System.today().daysBetween(caseRec.ClosedDate.date()) <= caseRec.Reopen_Days__c)))){
                    bNewCaseByReplyToCloseCase = true;
                }
*/
                if(caseRec.IsClosed){
                    bNewCaseByReplyToCloseCase = true;
                }
            }
        }
    }
    
    /**
* When customer replies to an existing email2case email thread for which the original case was closed, 
* case should be reopened if certain criteria's are met, or a new case should be created in other cases.
*  LOB	        Nature	        Reply within 10 days of closure	Reply after 10 days of closure	Manually Reopen allowed by agent?
*  Non-Wealth	Complaint	    Reopen	                        New Case	                    Yes, for 10 days
*  Non-Wealth	Non-Complaint	New Case	                    New Case	                    No
*  Wealth	    Any	            New Case	                    New Case	                    No
*/
    public static void checkAndReopenClosedCases(List<EmailMessage> newEmails) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, EmailMessage> caseIdToEmailMessageMap = new Map<Id, EmailMessage>();
        Set<String> winningEmailAddr = new Set<String>();
        
        for(EmailMessage emRec : newEmails){
            System.debug('checkAndReopenClosedCases'+emRec.ParentId+emRec.Headers+emRec.Winning_Email__c);
            if(emRec.Headers != null && emRec.ParentId.getSObjectType() == Case.getSObjectType()){
                //Its a reply, so evaluate
                caseIds.add(emRec.ParentId);
                caseIdToEmailMessageMap.put(emRec.ParentId, emRec);
                winningEmailAddr.add(emRec.Winning_Email__c);
            }
        }
        if(!caseIds.isEmpty()){
            Map<Id, Case> oldCaseIdToNewCaseMap = new Map<Id, Case>();
            List<Case> casesToReopen = new List<Case>();
            Map<String, Set<Id>> firstOwnerToOldCases = new Map<String, Set<Id>>();
            Map<String, ASF_PriorityEmailAddressesByBU__mdt> mWinningEmailDetails = new Map<String,ASF_PriorityEmailAddressesByBU__mdt>();

            for(ASF_PriorityEmailAddressesByBU__mdt winningRec : [SELECT Id, Active__c, Priority_Index__c, 
                                                                  Business_Unit__c, Email2CaseAddress__c, 
                                                                  Default_Queue_Dev_Name__c, Send_to_EBOT__c,
                                                                  Case_Business_Unit__c, Case_Origin__c
                                                                  FROM ASF_PriorityEmailAddressesByBU__mdt
                                                                  WHERE Email2CaseAddress__c =: winningEmailAddr])
            {
                queueDevNameToEmail.put(winningRec.Email2CaseAddress__c,winningRec.Default_Queue_Dev_Name__c);
                if(!mWinningEmailDetails.containsKey(winningRec.Email2CaseAddress__c)){
                    mWinningEmailDetails.put(winningRec.Email2CaseAddress__c,winningRec);
                }
            }
            
            for(Group grp : [SELECT ID,DeveloperName FROM Group WHERE DeveloperName =: queueDevNameToEmail.values() AND Type ='Queue']){
                if(!mQueueDevNameVsId.containsKey(grp.DeveloperName)){
                    mQueueDevNameVsId.put(grp.DeveloperName,grp.Id);
                }
            }
            
            existingCases = fetchCaseDetails(caseIds);

            for(Case caseRec : existingCases){
                //check if closed or not
                //if(caseRec.IsClosed && caseRec.Origin != null && caseRec.Origin.contains('Email') 
                // VIRENDRA - 10 April 2024 - REMOVED THE CONDITION OF CASE ORIGIN CONTAINS EMAIL.
                if(caseRec.IsClosed){
                   //&& (caseRec.RecordTypeId == ASF_Constants.RT_FRAMEWORK){
                       //&& caseRec.Nature__c == 'Complaint'){
                       //if closed, check if reopen allowed or not
                       if(buSpecificReopenCheck(caseRec)){
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
                                  //firstOwnerToOldCases = populateMap(caseRec, firstOwnerToOldCases);
                                  // VIRENDRA - 10 April 2024 - ADDED STATIC VARIABLE TO SET TO TRUE.
                                  bNewCaseByReplyToCloseCase = true;
                              }
                       }else {
                           // else create new case and reparent EMailMessage
                           Case newCase = createNewCaseInstance(caseRec, caseIdToEmailMessageMap);
                           String winningEmailAddrOnEmail = caseIdToEmailMessageMap.get(caseRec.Id).Winning_Email__c;
                           newCase.SuppliedEmail = caseIdToEmailMessageMap.get(caseRec.Id).FromAddress;
                           if(mWinningEmailDetails.containsKey(winningEmailAddrOnEmail)){
                               ASF_PriorityEmailAddressesByBU__mdt onEmailMdt = mWinningEmailDetails.get(winningEmailAddrOnEmail);
                               //newCase.Sent_to_EBOT__c = onEmailMdt.Send_to_EBOT__c;
                           	   newCase.Origin = onEmailMdt.Case_Origin__c ;
                           }
                           
                           oldCaseIdToNewCaseMap.put(caseRec.Id, newCase);
                           //firstOwnerToOldCases = populateMap(caseRec, firstOwnerToOldCases);
                           // VIRENDRA - 10 April 2024 - ADDED STATIC VARIABLE TO SET TO TRUE.
                           bNewCaseByReplyToCloseCase = true;
                       }
                   }else {
                       //not closed, then do nothing
                   }
            }
            if(!firstOwnerToOldCases.isEmpty()){
                for(Group gObj : [SELECT Id, Type, Name FROM Group WHERE Name IN :firstOwnerToOldCases.keySet()]){
                    for(Id caseId : firstOwnerToOldCases.get(gObj.Name)){
                        Case newCase = oldCaseIdToNewCaseMap.get(caseId);
                        newCase.OwnerId = gObj.Id;
                        oldCaseIdToNewCaseMap.put(caseId, newCase);
                    }
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
                // sending acknowledgment email if it is  Wealth cases
                // Commenting this as we're sending Ack email for wealth when we're reparenting in above loop (ABFL_WealthChatGeneratedCases)
                /*for(Case newCase : oldCaseIdToNewCaseMap.values()){
                    if(newCase.Origin == ABFL_Constants.ABWMEMAIL){
                        ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(newCase, ABFL_Constants.WMEMAILTEMPLATENAME, newCase.SuppliedEmail, '', '');
                    }
                }*/
            }
        }
    }
    
   /* private static Map<String, Set<Id>> populateMap(Case caseRec, Map<String, Set<Id>> theMap){
        String firstOwner;
        if(caseRec.SR_SLA_Histories__r != null && !caseRec.SR_SLA_Histories__r.isEmpty()){
            firstOwner = caseRec.SR_SLA_Histories__r[0].Current_Owner__c;
            if(!theMap.containsKey(firstOwner)){
                theMap.put(firstOwner, new Set<Id>());
            }
            theMap.get(firstOwner).add(caseRec.Id);
        }
        return theMap;
    } */
    
    private static Case createNewCaseInstance(Case closedCase, Map<Id, EmailMessage> caseIdToEmailMessageMap) {
        Case newCase = new Case();
        //assign the winning email's queue ID as the owner of the case
        if(caseIdToEmailMessageMap.containsKey(closedCase.Id) && caseIdToEmailMessageMap.get(closedCase.Id).Winning_Email__c != null
          && queueDevNameToEmail.get(caseIdToEmailMessageMap.get(closedCase.Id).Winning_Email__c) != null){
            newCase.OwnerId = mQueueDevNameVsId.get(queueDevNameToEmail.get(caseIdToEmailMessageMap.get(closedCase.Id).Winning_Email__c));
        }
        newCase.Subject = caseIdToEmailMessageMap.get(closedCase.Id).Subject;
        newCase.Description = caseIdToEmailMessageMap.get(closedCase.Id).TextBody;
        newCase.AccountId = closedCase.AccountId;
        newCase.ContactId = closedCase.ContactId;
        newCase.Origin = closedCase.Origin;
        newCase.Priority = closedCase.Priority;
        newCase.RecordTypeId = ASF_Constants.RT_INTERACTION;
        newCase.SuppliedEmail = closedCase.SuppliedEmail;
        newCase.SuppliedName = closedCase.SuppliedName;
        //newCase.Business_Unit__c = closedCase.Business_Unit__c;
        return newCase;
    }  

    private static boolean buSpecificReopenCheck(Case caseRec){
        boolean returnVal = caseRec.Is_Reopen_Allowed__c; // default value

        if(caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU && caseRec.Nature__c == 'Complaint'){
            return false;
        }
        return returnVal;

    }
    
}
