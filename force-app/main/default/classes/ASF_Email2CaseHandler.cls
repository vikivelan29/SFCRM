/**
* @description       : Class is having all the E2C Validation of Email Boxes logic.
* @author            : virendra
* @group             : 
* @last modified on  : 05-14-2024
* @last modified by  : rsinghnagar@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   05-14-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.ClassNamingConventions')
public without sharing class ASF_Email2CaseHandler {
    public static final List<String> BU_ALLOWING_BOT_REOPENED_CASE = new List<String>{'ABHFL','Payments','ABSLI','ABSLIG'};
        /**
* @description : Exception
**/
        public class multipleEmail2CaseAddressException extends exception{}
    /**
* @description : THIS MEHTOD IS USED TO UPDATE THE MESSAGEIDENTIFIER FIELD ON CASE OBJECT.
THIS FIELD BEING MARKED AS UNIQUE, IF SINGLE EMAIL IS SENT TO MULTIPLE E2C EMAIL ADDRESSES,
ONLY ONE CASE IS CREATED. CASE CREATED WILL BE SET TO QUEUE ASSIGNED FOR HIGHEST PRIORITY EMAILADDRESS IN EMAIL TO CASE.
PRIORITY OF EMAIL ADDRESSES FOR SPECIFIC BUSINESS UNIT IS MAPPED IN CUSTOM METADATA.
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param newList 
**/
    public static void updateMessageIdentifierOnCase(List<EmailMessage> newList){
        Set<Id> caseIds = new Set<Id>();
        Set<String> winningEmailAddr = new Set<String>();
        Map<String,ASF_PriorityEmailAddressesByBU__mdt> mWinningEmailDetailMdt = new Map<String,ASF_PriorityEmailAddressesByBU__mdt>();
        
        
        for(EmailMessage msg : newList){
            if(msg.Incoming){
                if(msg.ParentId.getSObjectType() == Case.sObjectType){
                    caseIds.add(msg.ParentId);
                    if(msg.Winning_Email__c != null){
                        winningEmailAddr.add(msg.Winning_Email__c);
                    }
                }
            }
        }
        
        Map<Id,Case> mCases = new Map<Id,Case>([SELECT ID,Business_Unit__c FROM Case WHERE ID =: caseIds AND 
                                                RecordTypeId = :ASF_Constants.RT_INTERACTION]);
        
        if(mCases.size() > 0) {
            Set<String> queueDevName = new Set<String>();
            Map<String,Id> mQueueDevNameVsId = new Map<String,Id>();
            
            for(ASF_PriorityEmailAddressesByBU__mdt winningRec : [SELECT Id, Active__c, Priority_Index__c, 
                                                                  Business_Unit__c, Email2CaseAddress__c, 
                                                                  Default_Queue_Dev_Name__c, Send_to_EBOT__c,
                                                                  Case_Business_Unit__c, Case_Origin__c
                                                                  FROM ASF_PriorityEmailAddressesByBU__mdt
                                                                  WHERE Email2CaseAddress__c =: winningEmailAddr])
            {
                if(!mWinningEmailDetailMdt.containsKey(winningRec.Email2CaseAddress__c)){
                    mWinningEmailDetailMdt.put(winningRec.Email2CaseAddress__c, winningRec);
                }
                queueDevName.add(winningRec.Default_Queue_Dev_Name__c);
            }
            
            for(Group grp : [SELECT ID,DeveloperName FROM Group WHERE DeveloperName =: queueDevName AND Type ='Queue']){
                if(!mQueueDevNameVsId.containsKey(grp.DeveloperName))
                    mQueueDevNameVsId.put(grp.DeveloperName,grp.Id);
            }
            List<Case> caseToUpdate = new List<Case>();
            
            for(EmailMessage msg : newList){
                if(msg.Incoming){
                    if(msg.ParentId.getSObjectType() == Case.sObjectType){
                        if(mWinningEmailDetailMdt.containsKey(msg.Winning_Email__c)){
                            String defaultQueueName = mWinningEmailDetailMdt.get(msg.Winning_Email__c).Default_Queue_Dev_Name__c;
                            if(mCases.containsKey(msg.ParentId)){
                                Case c = new Case(Id = msg.ParentId);
                                c.EmailMessageIdentifier__c = msg.MessageIdentifier;
                                c.Winning_Email__c = msg.Winning_Email__c; // populationg this Id for reporting purpose. US-PR970457-1272
                                if(mQueueDevNameVsId.containsKey(defaultQueueName)){
                                    c.OwnerId = mQueueDevNameVsId.get(defaultQueueName);
                                }
                                if(!String.isBlank(mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Business_Unit__c)){
                                    c.Business_Unit__c = mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Business_Unit__c; 
                                }
                                if(mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Origin__c == ABFL_Constants.WMCHATCASEORIGIN){
                                    c.Origin = mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Origin__c;
                                }
                                caseToUpdate.add(c);
                            }
                        }
                    }
                }
            }
            if(caseToUpdate.size()>0){
                try{
                    ASF_TriggerSkipperUtility.markTriggerRun('Case', 'Before');
                    update caseToUpdate;
                }
                catch(exception ex){
                    throw new multipleEmail2CaseAddressException('Multiple Email-To-Case address is mentioned in the email, and hence only one case is created rest is restricted from creation.');
                }
            }          
        }
        
    }
    
    
    private static void getPriorityAddressesByBusinessUnit(List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmailMdt,
                                                           Map<String,List<ASF_PriorityEmailAddressesByBU__mdt>> mBUVsPriorityEmails)
    {
        for(ASF_PriorityEmailAddressesByBU__mdt mdt : priorityEmailMdt){
            if(!mBUVsPriorityEmails.containsKey(mdt.Business_Unit__c))
                mBUVsPriorityEmails.put(mdt.Business_Unit__c, new List<ASF_PriorityEmailAddressesByBU__mdt>());
            mBUVsPriorityEmails.get(mdt.Business_Unit__c).add(mdt);
        }
        
    }
    
    
    /**
* @description 
* @author rsinghnagar@salesforce.com | 05-14-2024 
* @param newList 
**/
    public static void setPriorityEmailAddress(List<EmailMessage> newList){
        Map<String,List<ASF_PriorityEmailAddressesByBU__mdt>> mBUVsPriorityEmails = new Map<String,List<ASF_PriorityEmailAddressesByBU__mdt>>();
        Set<Id> caseIds = new Set<Id>();
        
        Set<Id> allcaseIds = new Set<Id>();
        
        String replyEmailBusinessUnit = '';
        
        for(EmailMessage msg : newList){
            if(msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType){
                allcaseIds.add(msg.ParentId);
            }
        }
        
        Map<Id,AggregateResult> mCaseEmailMessageCount = new Map<Id,AggregateResult>([SELECT ParentId Id, COUNT(ID) countOfRec FROM EmailMessage WHERE ParentId =: allcaseIds
                                                                                      GROUP BY ParentId]);
        
        
        
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmailMdt = ASF_PriorityEmailAddressesByBU__mdt.getAll().values();
        
        for(EmailMessage msg : newList){
            if(msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType){
                boolean bReplyOnClosedCase = false;
                if(ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase){
                    bReplyOnClosedCase = ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase;
                }
                if(msg.Headers != null){
                    system.debug('msg'+msg);
                    if((!msg.Headers.contains('In-Reply-To:') ||  bReplyOnClosedCase) || mCaseEmailMessageCount.containsKey(msg.ParentId)){
                        //|| (msg.Headers.contains('In-Reply-To:') && msg.ReplyToEmailMessageId == null)) {
                        if(bReplyOnClosedCase){
                            caseIds.add(msg.ParentId);
                            // EVALUATE IF THE REPLY COMING ON CASE IS ON SAME BU EMAIL ADDRESS OR OTHERWISE.
                            String flowToConsider = findRecipientAddressesBusUnit(msg, priorityEmailMdt);
                            if(flowToConsider != 'AS_IS_FLOW'){
                                replyEmailBusinessUnit = flowToConsider;
                            }
                        }
                        else if(mCaseEmailMessageCount.containsKey(msg.ParentId)){
                            Integer iCountOfEmail = Integer.ValueOf(mCaseEmailMessageCount.get(msg.ParentId).get('countOfRec'));
                            if(iCountOfEmail == 0){
                                caseIds.add(msg.ParentId);
                            }
                        }
                        else{
                            caseIds.add(msg.ParentId);
                        }
                    }
                    else if(!mCaseEmailMessageCount.containsKey(msg.ParentId)){
                        caseIds.add(msg.ParentId);
                    }
                }
                // else if (msg.FromAddress.equals(Label.ABFL_CRMUAT_EMAIL) && msg.CcAddress.contains(Label.ABFL_DIGITAL_FINANCE)) {
                
                // }
                else{
                    caseIds.add(msg.ParentId);
                }
            }
        }
        // CHECK IF THE EMAIL IS NEW EMAIL AND NOT REPLY TO ANY SALESFORCE EMAIL.
        if(caseIds.IsEmpty()){
            return;
        }
        Map<Id,Case> mCases = new Map<Id,Case>([SELECT ID,Business_Unit__c FROM Case WHERE Id=:caseIds]);
        
        if(mCases.size() > 0) {
            // BELOW LINE OF CODE TO BE EXECUTED ONLY WHEN ATLEAST ONE MSGIDS PRESENT.
            // CREATE MAP OF BUSINESS UNIT TO METADATA.
            getPriorityAddressesByBusinessUnit(priorityEmailMdt,mBUVsPriorityEmails);
            // CREATE QUEUEDEVNAME SET, IN ORDER TO GET THE QUEUE ID AGAINST QUEUE DEVELOPER NAME.
            
            
            for(EmailMessage msg : newList){
                // ONLY CONSIDER EMAIL THOSE ARE INCOMING AND RELATED TO CASE OBJECT ONLY.
                if(msg.Incoming){
                    if(msg.ParentId.getSObjectType() == Case.sObjectType){
                        integer idx = 0;
                        string priorityEmailAddress = '';
                        boolean bSendToEbot = false;
                        
                        Case c = mCases.get(msg.ParentId);
                        String caseBusinessUnit = (replyEmailBusinessUnit != null && replyEmailBusinessUnit != '') ? replyEmailBusinessUnit : c.Business_Unit__c;
                        if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(caseBusinessUnit)){
                            caseBusinessUnit = 'ABFL';
                        }
                        
                        List<ASF_PriorityEmailAddressesByBU__mdt> tempPriorityEmailByBU = mBUVsPriorityEmails.get(caseBusinessUnit);
                        if(tempPriorityEmailByBU == null){
                            tempPriorityEmailByBU = new List<ASF_PriorityEmailAddressesByBU__mdt>();
                        }
                        
                        for(ASF_PriorityEmailAddressesByBU__mdt mdt : tempPriorityEmailByBU){
                            // TO ADDRESS - PRIORITY EMAIL CHECKS.
                            if(msg.ToAddress != null){
                                List<String> tempToAddressess = msg.ToAddress.deleteWhitespace().split(';');
                                if(tempToAddressess.contains(mdt.Email2CaseAddress__c)){
                                    if(idx >= (Integer)mdt.Priority_Index__c || (idx == 0 && (Integer)mdt.Priority_Index__c > 0)){
                                        idx = (Integer)mdt.Priority_Index__c;
                                        priorityEmailAddress = mdt.Email2CaseAddress__c;
                                        bSendToEbot = mdt.Send_to_EBOT__c;
                                        
                                    }
                                }
                            }
                            // CC ADDRESS - PRIORITY EMAIL CHECKS.
                            if(msg.CcAddress != null){
                                List<String> tempCcAddressess = msg.CcAddress.deleteWhitespace().split(';');
                                if(tempCcAddressess.contains(mdt.Email2CaseAddress__c)){
                                    if(idx >= (Integer)mdt.Priority_Index__c || (idx == 0 && (Integer)mdt.Priority_Index__c > 0)){
                                        idx = (Integer)mdt.Priority_Index__c;
                                        priorityEmailAddress = mdt.Email2CaseAddress__c;
                                        bSendToEbot = mdt.Send_to_EBOT__c;
                                        
                                    }
                                }
                            }
                        }
                        if(priorityEmailAddress != null && priorityEmailAddress != ''){
                            msg.Winning_Email__c = priorityEmailAddress;
                            msg.Send_to_Ebot__c = bSendToEbot;
                        }
                    }
                }
            }
        }
    }
    
    public static String findRecipientAddressesBusUnit(EmailMessage msg,
                                                     List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmailMdt)
    {
        List<String> allToCcAddresses = new List<String>();
        
        if(msg.ToAddress != null || msg.CcAddress !=null){
            List<String> tempToAddressess = msg.ToAddress != null ? msg.ToAddress.deleteWhitespace().split(';') : new List<String>();
            List<String> tempCcAddressess = msg.CcAddress != null ? msg.CcAddress.deleteWhitespace().split(';') : new List<String>();
            if(tempToAddressess.size()>0){
                allToCcAddresses.addAll(tempToAddressess);
            }
            if(tempCcAddressess.size()>0){
                allToCcAddresses.addAll(tempCcAddressess);
            }
        }
        String firstBU = '';
        boolean bAllAddressFromSameBU = true;
        for(ASF_PriorityEmailAddressesByBU__mdt winningRec : priorityEmailMdt)
        {
            // CHECK IF To and Cc having Cross LOB Emails.
            if(allToCcAddresses.contains(winningRec.Email2CaseAddress__c)){
                if(firstBU == '' && (winningRec.Case_Business_Unit__c != null && winningRec.Case_Business_Unit__c != '')){
                    firstBU = winningRec.Case_Business_Unit__c;
                }
                if(firstBU != null && firstBU != ''){
                    if(firstBU != winningRec.Case_Business_Unit__c){
                        // Cross Business Unit Email in To or Cc.
                        // We cannot solve this email.
                        bAllAddressFromSameBU = false;
                        break;
                    }
                }
            }
            
        }
        if(bAllAddressFromSameBU){
            return firstBU;
        }
        return 'AS_IS_FLOW';
        
        
    }
}