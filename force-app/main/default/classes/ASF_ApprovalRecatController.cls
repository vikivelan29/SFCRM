public without sharing class ASF_ApprovalRecatController {
	
    @AuraEnabled
    public static void updateCCCIdBulk (Map<Id, Case> caseMap){
        
        List<ASF_Checklist__c> openCheckLists = [SELECT ID 
                                                 FROM ASF_Checklist__c 
                                                 WHERE Case__c IN: caseMap.KeySet() 
                                                 AND Systeminitiated__c = true];
        if(openCheckLists != null){                                        
            for(ASF_Checklist__c r : openCheckLists ){
                r.Status__c = 'Rejected';
            }
            update openCheckLists;
        }
        
        List<Task> openTasks = [SELECT ID
                                FROM Task 
                                WHERE WhatId IN: caseMap.KeySet() 
                                AND Systeminitiated__c = true];
        if(openTasks != null){                                                                 
            for(Task r : openTasks ){
                r.Status = 'Rejected';
            }
            update openTasks;
        }
        List<ASF_Case_SLA_History__c> slaHistoryList = [SELECT id,
                                                        oldExternalId__c 
                                                        FROM ASF_Case_SLA_History__c 
                                                        WHERE Case__c IN: caseMap.KeySet()];
        
        List<ASF_Case_SLA_History__c> slaHistoryToUpdate = new List<ASF_Case_SLA_History__c>();
        List<Case> updatedCaseList = new List<Case>();
        List<Id> casesForBotCallout = new List<Id>();

        for(Case caseRec : caseMap.values()){
            String recId = caseRec.Id;
            String oldCCCId = caseRec.CCC_External_Id__c;
            String newCaseJson = caseRec.Requested_Recat_Json__c;
            String typeSubTypeText = caseRec.Type_Text__c + ' - '+ caseRec.Sub_Type_Text__c;
            
            Map<String,Object> rawObj = (Map<String,Object>) JSON.deserializeUntyped(newCaseJson);
            Map<String,Object> caseObject =  (Map<String,Object>) rawObj.get('fields');
            Case toUpdateCase = new Case(Id=recId);
            // VIRENDRA - ADDED CASE TO UPDATE THE ACCOUNTID AND ASSETID.
            if((String)caseObject.get('AccountId') != null && (String)caseObject.get('AccountId') != ''){
                toUpdateCase.AccountId = (String)caseObject.get('AccountId');
                toUpdateCase.Lead__c = null;
                toUpdateCase.AssetId = null;
                List<Contact> contactList = [SELECT Id from Contact where AccountId = :(String)caseObject.get('AccountId') AND Primary__c = TRUE LIMIT 1];
                if(!contactList.isEmpty()){
                    toUpdateCase.ContactId = contactList[0].Id;
                }
                List<Account> accountList = [SELECT id, Client_Code__c from Account where Id =: (String)caseObject.get('AccountId')];
                if(!accountList.isEmpty()){
                    toUpdateCase.Client_Code_Text__c = accountList[0].Client_Code__c;
                }
            }
            if((String)caseObject.get('AssetId') != null && (String)caseObject.get('AssetId') != ''){
                toUpdateCase.AssetId = (String)caseObject.get('AssetId');
                toUpdateCase.Lead__c = null;
                List<Asset> assetList = [SELECT Id, LAN__c from Asset where Id =: (String)caseObject.get('AssetId')];
                if(!assetList.isEmpty()){
                    toUpdateCase.LAN__c = assetList[0].LAN__c;
                }
            }
            if((String)caseObject.get('Lead__c') != null && (String)caseObject.get('Lead__c') != ''){
                toUpdateCase.Lead__c = (String)caseObject.get('Lead__c');
                toUpdateCase.AccountId = null;
                toUpdateCase.AssetId = null;
                toUpdateCase.ContactId = null;
            }
            // VIRENDRA - ENDS HERE.
            toUpdateCase.CCC_External_Id__c = (String)caseObject.get('CCC_External_Id__c');
            toUpdateCase.Nature__c = (String)caseObject.get('Nature__c'); 
            toUpdateCase.Case_Stage_Change_Date__c = system.now();
            toUpdateCase.Recategorisation_Date__c = system.now();
            toUpdateCase.typeSubTypeMismatch__c = false;
            toUpdateCase.Type_Sub_Type_Mismatch_Reason__c = null;
            toUpdateCase.Previous_Stage__c  = '';
            toUpdateCase.moved_back__c = false;
            toUpdateCase.Pending_Clarification__c = false;
            toUpdateCase.Recategorisation_Reason__c = (String)caseObject.get('Recategorisation_Reason__c');
            toUpdateCase.oldCCCIdFields__c = (String)caseObject.get('oldCCCIdFields__c');
            toUpdateCase.Bot_Feedback__c = (String)caseObject.get('Bot_Feedback__c');
            toUpdateCase.Requested_Recat_Json__c = '';
        	toUpdateCase.Requested_CCC_Details__c = '';
            toUpdateCase.Reopen_SLA_Broken__c = false;
            toUpdateCase.Reopen_SLA_Broken_Date_Time__c = null;
            toUpdateCase.SLA_Broken__c = false;
            toUpdateCase.SLA_Broken_DateTime__c = null;
            updatedCaseList.add(toUpdateCase);

            if((Boolean)caseObject.get('Is_send_Bot_Feedback')){
                casesForBotCallout.add(recId);
            }
            
            /*
            null check is at done at app level and not at DB level. this is because 
            when we do null check at db , indexinf will go for TOSS
            SLA history is LDV and this will become long running query.
            */
            for(ASF_Case_SLA_History__c r : slaHistoryList){
                if(r.oldExternalId__c == null){
                    r.oldExternalId__c = oldCCCId;
                    r.OldTypeSubType__c = typeSubTypeText;
                    slaHistoryToUpdate.add(r);
                }
            }    
        } 
        ASF_RecategoriseCaseController.requestFromRecat = true;
        update updatedCaseList;
        update slaHistoryToUpdate; 
        if(!casesForBotCallout.isEmpty()){
            for(Id caseId : casesForBotCallout){
                ABCL_EBotFeedback.callEbotFeedbackApi(caseId);
                system.debug('ebot callout success');
            }
        }   
    }
}