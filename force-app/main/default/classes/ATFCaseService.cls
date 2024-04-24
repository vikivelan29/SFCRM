/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 03-16-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-14-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ATFCaseService implements Callable {
    // Actual method
    /****************************************************************************************************************
    * @param  - List<EmailMessage> newEmails
    * @return - void .
    * @Description - This method is used to update the Incoming Email Count field of Case when an email comes to case even if the case is closed.
    *****************************************************************************************************************/ 
    public String updateIncomingEmailCount(String jsonEMIds){
        try{

            Set<Id> sEMIds = (Set<Id>) JSON.deserialize(jsonEMIds, Set<Id>.CLASS);
            System.debug('***sEMIDs:'+sEMIds);

            List<EmailMessage> lstEmail = [select id,ParentId,Incoming from EmailMessage where Id IN : sEMIds];
            Set<Id> caseIds = new Set<Id>();
            for(EmailMessage emMsg : lstEmail){
                caseIds.add(emMsg.ParentId);
            }

            List<Case> lstUpdateCase;
             if (!caseIds.isEmpty()) {
                lstUpdateCase = new List<Case>();
                Map<Id, Integer> caseIdToCount = new Map<Id, Integer>();
                for (AggregateResult result : [SELECT ParentId, COUNT(Id) cnt FROM EmailMessage WHERE Incoming = True AND ParentId IN :caseIds GROUP BY ParentId]) {
                    Id caseId = (Id) result.get('ParentId');
                    Integer count = (Integer) result.get('cnt');
                    caseIdToCount.put(caseId, count);
                }
                for (Id caseId : caseIdToCount.keySet()) {
                    Case recCase = new Case(Id = caseId);
                    recCase.ABFL_Incoming_Email_Count__c  = caseIdToCount.get(caseId);
                    lstUpdateCase.add(recCase);
                }
            }

            if(lstUpdateCase!=null){
               	ASF_TriggerSkipperUtility.markTriggerRun('Case');
                Database.SaveResult[] updateResult = Database.update(lstUpdateCase,false); 
            }
        }   
        catch (Exception e){ 
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_EmailCase_Logic.updateIncomingEmailCount');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
        
        // default message to return
        return 'SUCCESS';
    }

    // Dispatch actual methods
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'updateIncomingEmailCount' {
                return this.updateIncomingEmailCount((String)args.get('jsonEMIds'));
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
    }
    
    public class ExtensionMalformedCallException extends Exception {}
}