/*********************************************************
* Class        : ASF_Email2CaseHandler
* Author       : Virendra Patil
* Created Date : 05/01/2024
* Last Modified: 05/01/2024
* Description  : Class is having all the E2C Validation of Email Boxes logic.
*********************************************************/
@SuppressWarnings('PMD.ClassNamingConventions')
public without sharing class ASF_Email2CaseHandler {
    public class multipleEmail2CaseAddressException extends exception{}
    
    /* THIS MEHTOD IS USED TO UPDATE THE MESSAGEIDENTIFIER FIELD ON CASE OBJECT.
* THIS FIELD BEING MARKED AS UNIQUE, IF SINGLE EMAIL IS SENT TO MULTIPLE E2C EMAIL ADDRESSES,
* ONLY ONE CASE IS CREATED. CASE CREATED WILL BE SET TO QUEUE ASSIGNED FOR HIGHEST PRIORITY EMAILADDRESS IN EMAIL TO CASE.
* PRIORITY OF EMAIL ADDRESSES FOR SPECIFIC BUSINESS UNIT IS MAPPED IN CUSTOM METADATA.
*/
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
        
        Map<Id,Case> mCases = new Map<Id,Case>([SELECT ID,Business_Unit__c FROM Case WHERE ID =: caseIds]);
        Set<String> queueDevName = new Set<String>();
        Map<String,Id> mQueueDevNameVsId = new Map<String,Id>();
        
        for(ASF_PriorityEmailAddressesByBU__mdt winningRec : [SELECT Id, Active__c, Priority_Index__c, 
                                                              Business_Unit__c, Email2CaseAddress__c, 
                                                              Default_Queue_Dev_Name__c, Send_to_EBOT__c 
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
                            if(mQueueDevNameVsId.containsKey(defaultQueueName)){
                                c.OwnerId = mQueueDevNameVsId.get(defaultQueueName);
                            }
                            if(!String.isBlank(mWinningEmailDetailMdt.get(msg.Winning_Email__c).Business_Unit__c)){
                                c.Business_Unit__c = mWinningEmailDetailMdt.get(msg.Winning_Email__c).Business_Unit__c;
                                if(mWinningEmailDetailMdt.get(msg.Winning_Email__c).Business_Unit__c == ABFL_Constants.WMCHATCASEORIGIN){
                                    c.Origin = mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Origin__c;
                                }
                            }/*else{
                                
                            }
                            if(String.isBlank(mWinningEmailDetailMdt.get(msg.Winning_Email__c).Case_Origin__c)){
                                
                            }*/
                            caseToUpdate.add(c);
                        }
                    }
                }
            }
        }
        if(caseToUpdate.size()>0){
            try{
                ASF_TriggerSkipperUtility.markTriggerRun('Case');
                update caseToUpdate;
            }
            catch(exception ex){
                throw new multipleEmail2CaseAddressException('Multiple Email-To-Case address is mentioned in the email, and hence only one case is created rest is restricted from creation.');
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
    
    
    public static void setPriorityEmailAddress(List<EmailMessage> newList){
        Map<String,List<ASF_PriorityEmailAddressesByBU__mdt>> mBUVsPriorityEmails = new Map<String,List<ASF_PriorityEmailAddressesByBU__mdt>>();
        Set<Id> caseIds = new Set<Id>();
        
        for(EmailMessage msg : newList){
            if(msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType){
                System.debug('@@@msg.FromAddress'+msg.FromAddress);
                                System.debug('@@@msg.CcAddress'+msg.CcAddress);
                if(msg.Headers != null){
                    if(!msg.Headers.contains('In-Reply-To:')){
                            caseIds.add(msg.ParentId);
                    }
                }
                else if (msg.FromAddress.equals(Label.ABFL_CRMUAT_EMAIL) && msg.CcAddress.contains(Label.ABFL_DIGITAL_FINANCE)) {

                }
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
        
        // BELOW LINE OF CODE TO BE EXECUTED ONLY WHEN ATLEAST ONE MSGIDS PRESENT.
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmailMdt = ASF_PriorityEmailAddressesByBU__mdt.getAll().values();
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
                    String caseBusinessUnit = c.Business_Unit__c;
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