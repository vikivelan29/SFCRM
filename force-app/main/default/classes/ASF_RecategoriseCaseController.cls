//Controller class for asf_RecategoriseCase LWC
//Created by JT & Santanu
public with sharing class ASF_RecategoriseCaseController {
    /* when agent wants to recategrize , there is existing CCC id.
    So agent should not see current CCC id. But other ids to change,
    Hence this method 
    */
    @AuraEnabled(Cacheable = true)
    public static ASF_CreateCaseWithTypeController.CaseDetailsWrapper getTypeSubTypeDataByCustomerType(String keyword ,string asssetProductType,string isasset,String accRecordType, String currentCCCId) {
        ASF_CreateCaseWithTypeController.CaseDetailsWrapper originalList = ASF_CreateCaseWithTypeController.getAccountDataByCustomerType(keyword,asssetProductType,isasset,accRecordType,'');
        List<ASF_Case_Category_Config__c> filteredCCCList = new List<ASF_Case_Category_Config__c>();
        for(ASF_Case_Category_Config__c ccc : originalList.lstCCCrecords){
            if (ccc.CCC_External_Id__c != currentCCCId ){
                filteredCCCList.add(ccc);
            }

        }
        /* IF Filtered List is not having any record, show the ErrorMessage e.g. No Records found for the selected search.
         */
        if(filteredCCCList.size()<=0){
            originalList.strErrorMessage = System.Label.ASF_Case_NoRecordMessage;
        }
        originalList.lstCCCrecords = filteredCCCList;
        return originalList;
    }    

    @AuraEnabled(Cacheable = true)
    public static Map<String,Object> getCaseRecordDetails( String recId){
        map<String,object> resultMap = new map<String,object>();

        Case currentRecord =  [SELECT id,
                                        RecordType.Name,
                                        CCC_External_Id__c,
                                        Stage__c,
                                        account.Business_Unit__c,
                                        account.recordtype.name,
                                        accountId,
                                        assetId,
                               			Lead__c,
                               			Lead__r.Business_Unit__c,
                               			Lead__r.recordType.name,
                                        Nature__c,
                                        Source__c,
                                        Channel__c,
                                        isClosed,
                                        Priority,
                                        (SELECT Stage__c,
                                                Stage_End_Date__c,
                                                is_Running_Record__c    
                                        FROM SR_SLA_Histories__r)  
                                    FROM Case 
                                WHERE id=:recId];
        String extensionObjecAPIname = ASF_GetCaseRelatedDetails.getCaseRelatedObjName(currentRecord.CCC_External_Id__c);
        Set<String> uniqueStages = new Set<String>();
        if(currentRecord.isClosed){
            resultMap.put('recategorizeEnabled',false);
        }else{
            resultMap.put('recategorizeEnabled',true);
        }
        // else {
        //     for(ASF_Case_SLA_History__c g: currentRecord.SR_SLA_Histories__r){
        //         uniqueStages.add(g.stage__c);
        //     }
        //     resultMap.put('recategorizeEnabled',uniqueStages.size() <= 1);
        // }
       
        resultMap.put('currentExtensionName',extensionObjecAPIname);
        resultMap.put('caseDetails',JSON.serialize(currentRecord));
        /*
         if there is more than one stage in SR history , then case is moved beyond first stage.
         hence block from recategorize.
        */
       
        return resultMap;

    }

    /*
        Old external Id is passed along with Case object which will have Nature , Product , Channel and New external Id.
        When external id is changed , there is possibility that extension object might change or new fields might be needed.
        So old external id might have diffrrent fields and now new field wil have different fields.
        If we start showing new fields , then old fields will be there , but no UI. 
        Hence its important to persist losing fields in  oldCCCIdFields__c which will have al fields in JSON
    */
    @AuraEnabled
    public static void updateCaseWithNewCCCId( String recId, String oldCCCId, String newCaseJson){
        /*
        newCaseJson looks like below
        '{"apiName":"Case","fields":{"CCC_External_Id__c":"payments_indi_206","Nature__c":"Query","Source__c":"Branch","Channel__c":"Walk in"}}'
        */

        List<ASF_Checklist__c> openCheckLists = [SELECT ID 
                                                FROM ASF_Checklist__c 
                                                WHERE Case__c = :recId 
                                                AND Systeminitiated__c = true];
        if(openCheckLists != null){                                        
            for(ASF_Checklist__c r : openCheckLists ){
                r.Status__c = 'Rejected';
            }
            update openCheckLists;
        }

        List<Task> openTasks = [SELECT ID
                                 FROM Task 
                                 WHERE WhatId = :recId 
                                 AND Systeminitiated__c = true];
        if(openTasks != null){                                                                 
            for(Task r : openTasks ){
                r.Status = 'Rejected';
            }
            update openTasks;
        }

        Map<String,Object> rawObj = (Map<String,Object>) JSON.deserializeUntyped(newCaseJson);
        Map<String,Object> caseObject =  (Map<String,Object>) rawObj.get('fields');
        Case toUpdateCase = new Case(Id=recId);
        toUpdateCase.CCC_External_Id__c = (String)caseObject.get('CCC_External_Id__c');
        toUpdateCase.Nature__c = (String)caseObject.get('Nature__c');
        toUpdateCase.Source__c = (String)caseObject.get('Source__c');
        toUpdateCase.Channel__c = (String)caseObject.get('Channel__c'); 
        toUpdateCase.Case_Stage_Change_Date__c = system.now();
        toUpdateCase.Recategorisation_Date__c = system.now();
        toUpdateCase.typeSubTypeMismatch__c = false;
        toUpdateCase.Recategorisation_Reason__c = (String)caseObject.get('Recategorisation_Reason__c');
        toUpdateCase.oldCCCIdFields__c = oldCCCId;
        ASF_Case_Category_Config__c cccRecord = [Select First_Stage__c,type__c,Sub_Type__c From ASF_Case_Category_Config__c where CCC_External_Id__c = :toUpdateCase.CCC_External_Id__c Limit 1];
        String currentstageOfCase = cccRecord.First_Stage__c;

       /*
       null check is at done at app level and not at DB level. this is because 
       when we do null check at db , indexinf will go for TOSS
       SLA history is LDV and this will become long running query.
       */
        List<ASF_Case_SLA_History__c> slaHistoryList = [SELECT id,
                                                                oldExternalId__c 
                                                        FROM ASF_Case_SLA_History__c 
                                                        WHERE Case__c = :recId];
        List<ASF_Case_SLA_History__c> slaHistoryToUpdate = new List<ASF_Case_SLA_History__c>();
        for(ASF_Case_SLA_History__c r : slaHistoryList ){
            if(r.oldExternalId__c == null){
                r.oldExternalId__c	 = oldCCCId;
                r.OldTypeSubType__c = cccRecord.type__c + ' - ' + cccRecord.Sub_Type__c;
                slaHistoryToUpdate.add(r);
            }
        }

        update slaHistoryToUpdate;
        toUpdateCase.stage__c = currentstageOfCase;
        
        /*
        Use case 1: From stage and To Stage are same. but no owner change. SLA cnange
        Use case 2: From stage and To Stage are different. but no owner change. SLA cnange.
        From Stage may not exist in new stage. 

        TBD Integrations and Approvals will remain 
        
        1. change of account and asset
        */
        update toUpdateCase; 

    }

    //Fetches required fields from CCC and Account and Asset to validate the new CCC before Save
    @AuraEnabled(cacheable=true)
    public static ASF_Case_Category_Config__c fetchCCCDetails(String cccExtId) {
        ASF_Case_Category_Config__c cccRec = [SELECT Id, Only_CRN_Mandatory__c, is_FA_Mandatory__c,
                                            Priority__c, Custom_Segment__c, CCC_External_Id__c,
                                            Is_Prospect_Related__c
                                            FROM ASF_Case_Category_Config__c 
                                            WHERE CCC_External_Id__c = :cccExtId LIMIT 1];
        return cccRec;
    }
}