/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-30-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2024   rsinghnagar@salesforce.com   Initial Version
**/
//Controller class for asf_RecategoriseCase LWC
//Created by JT & Santanu
public with sharing class ASF_RecategoriseCaseController {
    
    public static boolean requestFromRecat = false;
    /* when agent wants to recategrize , there is existing CCC id.
    So agent should not see current CCC id. But other ids to change,
    Hence this method 
    */
    @AuraEnabled(Cacheable = true)
    public static ASF_CreateCaseWithTypeController.CaseDetailsWrapper getTypeSubTypeDataByCustomerType(String keyword ,string asssetProductType,string isasset,String accRecordType, String currentCCCId, String assetLOB) {
        ASF_CreateCaseWithTypeController.CaseDetailsWrapper originalList = ASF_CreateCaseWithTypeController.getAccountDataByCustomerType(keyword,asssetProductType,isasset,accRecordType,assetLOB);
        List<ASF_Case_Category_Config__c> filteredCCCList = new List<ASF_Case_Category_Config__c>();
        for(ASF_Case_Category_Config__c ccc : originalList.lstCCCrecords){
            if(ccc.Business_Unit__c == ASF_Constants.ABSLI_BU){
                if(ccc.CCC_External_Id__c != currentCCCId && (ccc.Nature__c == 'Complaint' || ccc.Nature__c == 'Query')){
                    filteredCCCList.add(ccc);
                }
                else if(ccc.CCC_External_Id__c == currentCCCId && ccc.Allowed_Issue_Types__c != null && (ccc.Nature__c == 'Complaint' || ccc.Nature__c == 'Query')){
                    filteredCCCList.add(ccc);
                }
            }else{
                if(ccc.CCC_External_Id__c != currentCCCId){
                    filteredCCCList.add(ccc);
                }
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

    @AuraEnabled(Cacheable = false) 
    public static String updateRequestedCCC(String recId, String newCaseJson, String typeVal, String subType, String nature){
        String result = 'Success';
        Map<String,Object> rawObj = (Map<String,Object>) JSON.deserializeUntyped(newCaseJson);
        Map<String,Object> caseObject =  (Map<String,Object>) rawObj.get('fields');
        Case caseRec = new Case(Id=recId);
        caseRec.Requested_Recat_Json__c = newCaseJson;
        caseRec.Requested_CCC_Details__c = 'Nature - '+nature+'\n Type - '+typeVal+'\n Sub Type - '+subType+'\n Recategorization Reason - '+(String)caseObject.get('Recategorisation_Reason__c');
        List<Account> accountList = [SELECT id, Name from Account where Id =: (String)caseObject.get('AccountId')];
        List<Asset> assetList = [SELECT id, Name from Asset where Id =: (String)caseObject.get('AssetId')];
        List<Lead> prospectList = [SELECT id, Name from Lead where Id =: (String)caseObject.get('Lead__c')];
        if(!accountList.isEmpty()){
            caseRec.Requested_CCC_Details__c += '\n Account - '+accountList[0].Name;
        }
        if(!assetList.isEmpty()){
            caseRec.Requested_CCC_Details__c += '\n LAN - '+assetList[0].Name;
        }
        if(!prospectList.isEmpty()){
            caseRec.Requested_CCC_Details__c += '\n Prospect - '+prospectList[0].Name;
        }
        try{
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update caseRec;
            result = caseRec.Requested_CCC_Details__c;
        }catch (Exception e){
            result = 'Error - '+e;
        }
        return result;
    } 

    @AuraEnabled(Cacheable = false)
    public static Map<String,Object> getCaseRecordDetails( String recId){
        map<String,object> resultMap = new map<String,object>();
		
        Case currentRecord =  [SELECT id,
                                RecordType.Name,
                                CCC_External_Id__c,
                                Stage__c,
                                account.Business_Unit__c,
                                account.recordtype.name,
                                accountId,
                                account.Client_Code__c,
                                assetId,
                                asset.LAN__c,
                               	asset.Policy_No__c,
                                asset.LOB__c,
                                Lead__c,
                                Lead__r.Business_Unit__c,
                                Lead__r.recordType.name,
                                Nature__c,
                                Source__c,
                                Channel__c,
                                isClosed,
                                Priority,
                                Is_Recategorise_Allowed__c,
                                oldCCCIdFields__c,
                                Type_Text__c,
                                Sub_Type_Text__c,
                                Issue_Type__c,
                                (SELECT Stage__c,
                                    Stage_End_Date__c,
                                    is_Running_Record__c    
                                    FROM SR_SLA_Histories__r)  
                                FROM Case 
                                WHERE id=:recId];
        String extensionObjecAPIname = ASF_GetCaseRelatedDetails.getCaseRelatedObjName(currentRecord.CCC_External_Id__c);
        Set<String> uniqueStages = new Set<String>();
        List<ASF_Case_Approv__c> approvalList = [select Id from ASF_Case_Approv__c where SR__c =: recId
                                                and Approval_Status__c = 'Pending'];
        resultMap.put('recategorizeEnabled',false);
        resultMap.put('approvalPending',false);
        if(!currentRecord.isClosed && currentRecord.Is_Recategorise_Allowed__c == true){
            resultMap.put('recategorizeEnabled',true);
        }
        if(!approvalList.isEmpty()){
            resultMap.put('approvalPending',true);
        }
        /*
        if there is more than one stage in SR history , then case is moved beyond first stage.
        hence block from recategorize.
        */
        // else {
        //     for(ASF_Case_SLA_History__c g: currentRecord.SR_SLA_Histories__r){
        //         uniqueStages.add(g.stage__c);
        //     }
        //     resultMap.put('recategorizeEnabled',uniqueStages.size() <= 1);
        // }
        resultMap.put('currentExtensionName',extensionObjecAPIname);
        resultMap.put('caseDetails',JSON.serialize(currentRecord));
        resultMap.put('currentUserName', UserInfo.getName());
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
    public static void updateCaseWithNewCCCId( String recId, String oldCCCId, String newCaseJson, String typeSubTypeText){
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
        // VIRENDRA - ADDED CASE TO UPDATE THE ACCOUNTID AND ASSETID.
        if((String)caseObject.get('AccountId') != null && (String)caseObject.get('AccountId') != ''){
            toUpdateCase.AccountId = (String)caseObject.get('AccountId');
            toUpdateCase.Lead__c = null;
            toUpdateCase.AssetId = null;
            List<Contact> contactList = [SELECT Id from Contact where AccountId = :(String)caseObject.get('AccountId') AND Primary__c = TRUE LIMIT 1];
            if(!contactList.isEmpty()){
                toUpdateCase.ContactId = contactList[0].Id;
            }
            List<Account> accountList = [SELECT Id, Client_Code__c from Account where Id =: (String)caseObject.get('AccountId')];
            if(!accountList.isEmpty()){
                toUpdateCase.Client_Code_Text__c = accountList[0].Client_Code__c;
            }
        }
        if((String)caseObject.get('AssetId') != null && (String)caseObject.get('AssetId') != ''){
            toUpdateCase.AssetId = (String)caseObject.get('AssetId');
            toUpdateCase.Lead__c = null;
            List<Asset> assetList = [SELECT Id, LAN__c, Policy_No__c from Asset where Id =: (String)caseObject.get('AssetId')];
            if(!assetList.isEmpty()){
                if(ASF_Constants.BUSpecificLANKey.contains((String)caseObject.get('Business_Unit__c'))){
                    toUpdateCase.LAN__c = assetList[0].Policy_No__c;
                }else{
                    toUpdateCase.LAN__c = assetList[0].LAN__c;
                }
            }
        }
        if((String)caseObject.get('Lead__c') != null && (String)caseObject.get('Lead__c') != ''){
            toUpdateCase.Lead__c = (String)caseObject.get('Lead__c');
            toUpdateCase.AccountId = null;
            toUpdateCase.AssetId = null;
            toUpdateCase.ContactId = null;
        }
        // VIRENDRA - ENDS HERE.
       /* if((String)caseObject.get('CCC_External_Id__c') != null && (String)caseObject.get('CCC_External_Id__c') != ''){
            List<ASF_Case_Category_Config__c> caseCatList = [select Id, No_Owner_Change_on_Recat__c from ASF_Case_Category_Config__c
                                                            where CCC_External_Id__c =: (String)caseObject.get('CCC_External_Id__c')];
            if(!caseCatList.isEmpty()){
                ASF_RecategoriseCaseController.noOwnerChangeOnRecat = caseCatList[0].No_Owner_Change_on_Recat__c;
            }
        } */
        toUpdateCase.CCC_External_Id__c = (String)caseObject.get('CCC_External_Id__c');
        toUpdateCase.Nature__c = (String)caseObject.get('Nature__c');
        //toUpdateCase.Source__c = (String)caseObject.get('Source__c');
        //toUpdateCase.Channel__c = (String)caseObject.get('Channel__c'); 
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
        toUpdateCase.Reopen_SLA_Broken__c = false;
        toUpdateCase.Reopen_SLA_Broken_Date_Time__c = null;
        toUpdateCase.SLA_Broken__c = false;
        toUpdateCase.SLA_Broken_DateTime__c = null;
        toUpdateCase.Issue_Type__c = (String)caseObject.get('Issue_Type__c');
        //ASF_Case_Category_Config__c cccRecord = [Select First_Stage__c,type__c,Sub_Type__c From ASF_Case_Category_Config__c where CCC_External_Id__c = :oldCCCId Limit 1];
        // String currentstageOfCase = cccRecord.First_Stage__c;
        // toUpdateCase.stage__c = currentstageOfCase;
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
                r.oldExternalId__c = oldCCCId;
                r.OldTypeSubType__c = typeSubTypeText;
                slaHistoryToUpdate.add(r);
            }
        }
        update slaHistoryToUpdate;
        
        
        /*
        Use case 1: From stage and To Stage are same. but no owner change. SLA cnange
        Use case 2: From stage and To Stage are different. but no owner change. SLA cnange.
        From Stage may not exist in new stage. 

        TBD Integrations and Approvals will remain 

        1. change of account and asset
        */
        ASF_RecategoriseCaseController.requestFromRecat = true;
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
    
    @AuraEnabled(cacheable=true)
    public static List<ASF_CaseUIController.searchResponse> getMatchingAccount(string userInp, boolean accPreSelected,String currentCaseId) {
        List<ASF_CaseUIController.searchResponse> lstResponse = new List<ASF_CaseUIController.searchResponse>();
        if(userInp!=null){
            Set<id> accIdSet = new Set<id>();
            if(!accPreSelected){
                List<contact> conList = New List<contact>();//database.query(queryField);
                String searchString = '*'+String.escapeSingleQuotes(userInp)+'*';
                userInp = '%'+userInp+'%';
                
                System.debug('userInp-'+userInp);
                List<List<SObject>> searchList = 
                    [FIND :searchString IN ALL FIELDS 
                     RETURNING 
                     Contact (Id, AccountId, email WHERE email LIKE :userInp OR mobilePhone LIKE : userInp OR Name Like : userInp),
                     Account (Id, Name, PersonEmail,RecordType.Name WHERE Client_Code__c  LIKE : userInp OR Name LIKE : userInp OR PersonEmail LIKE : userInp OR PAN__c LIKE : userInp OR PersonMobilePhone LIKE : userInp),
                     Asset (Id, AccountId WHERE Name  LIKE : userInp OR LAN__c LIKE : userInp OR Policy_No__c LIKE : userInp OR Application_Number__c LIKE : userInp),
                     Lead (Id,Name,mobilePhone,Email,PANNO__c WHERE Name LIKE : userInp OR mobilePhone LIKE : userInp OR Email LIKE : userInp)
                    ];
                
                if(searchList[0].size()>0){
                    conList = (List<contact>)searchList[0];
                    for(Contact con: conList)
                        accIdSet.add(con.AccountId);
                    
                }
                if(searchList[1].size()>0){
                    List<Account> accList = (List<Account>)searchList[1];
                    for(Account acc: accList)
                        accIdSet.add(acc.Id);
                }
                if(searchList[2].size()>0){
                    List<Asset> assList = (List<Asset>)searchList[2];
                    for(Asset ass: assList)
                        accIdSet.add(ass.AccountId);
                }
                if(searchList[3].size()>0){
                    for(Lead prospect : (List<Lead>)searchList[3]){
                        ASF_CaseUIController.searchResponse resp = new ASF_CaseUIController.searchResponse(prospect.Id,'Prospect',prospect.Name,'-NA-',prospect.Email,prospect.mobilePhone,prospect.PANNO__c,'','');
                        
                        lstResponse.add(resp);
                    }     
                }
            } else{
                //Id accId = [select Id from account where Client_Code__c =: userInp].Id;
                Case currentCase = [SELECT ID,AccountId FROM Case WHERE Id =: currentCaseId];
                Id accId = (currentCase.AccountId != null) ? currentCase.AccountId : null;
                accIdSet.add(accId);
            }
            
            List<account> accList = [select id,name,Client_Code__c,PersonEmail,PAN__c,PersonMobilePhone,Office_Email__c,IsPersonAccount,RecordType.Name from account where ID IN:accIdSet];
            Map<Id,contact> accIdConMap = new Map<Id,contact>();
            Set<Id> businessAccIdSet = new Set<Id>();
            for(Account accRec : accList){
                if(!accRec.IsPersonAccount){
                    businessAccIdSet.add(accRec.Id);
                }
            }
            for(contact conRec : [select Id, mobilePhone, email, AccountId from contact where AccountId IN: businessAccIdSet and Primary__c = true]){
                accIdConMap.put(conRec.AccountId,conRec);
            }
            for(Account customer : accList){
                ASF_CaseUIController.searchResponse custResp;
                if(customer.IsPersonAccount){
                    custResp = new ASF_CaseUIController.searchResponse(customer.Id,'Customer',customer.Name,customer.Client_Code__c,customer.PersonEmail,String.valueOf(customer.PersonMobilePhone),customer.PAN__c,customer.RecordType.Name,'');
                }else{
                    String phone = accIdConMap.containsKey(customer.Id)? String.valueOf(accIdConMap.get(customer.Id).mobilePhone) : '';
                    String email = accIdConMap.containsKey(customer.Id)? accIdConMap.get(customer.Id).email : '';
                    
                    custResp = new ASF_CaseUIController.searchResponse(customer.Id,'Customer',customer.Name,customer.Client_Code__c,email,phone,customer.PAN__c,customer.RecordType.Name,'');
                }
                
                lstResponse.add(custResp);
            }
            for(integer i=0;i<lstResponse.size();i++){
                System.debug(lstResponse);
            }
            return lstResponse;
        }
        else{ return null; }
    }
    
    /* Validate if the Current Asset is eligible for the existing CTST or not.
    */
    @AuraEnabled
    public static boolean validateIfCurrentCTSTForAccountAndAsset(String accountId, String assetId, String cccId){
        
        Account newCustomerSelected = [SELECT ID,Business_Unit__c,Line_Of_Business__c,RecordType.Name FROM Account WHERE Id =: accountId LIMIT 1];
        List<Asset> newAssetSelected = [SELECT ID,Business_Unit__c,LOB__c FROM Asset WHERE ID =: assetId AND AccountId =: accountId];
        
        String customerBU = newCustomerSelected.Business_Unit__c;
        String customerLOB = newCustomerSelected.Line_of_Business__c;
        String customerRecordType = newCustomerSelected.RecordType.Name;
        
        String assetBU = '';
        String assetLOB ='';
        if(newAssetSelected.size()>0){
            assetBU = newAssetSelected[0].Business_Unit__c;
            assetLOB = newAssetSelected[0].LOB__c;
        }
        
        
        ASF_Case_Category_Config__c cccRecord = [SELECT ID,Business_Unit__c,LOB__c,Custom_Segment__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = : cccId];
        
        if(ASF_Constants.BU_WITHOUT_LOB.contains(customerBU) || ASF_Constants.BU_WITHOUT_LOB.contains(assetBU)){
            if(customerBU.equalsIgnoreCase(cccRecord.Business_Unit__c) ||
               assetBU.equalsIgnoreCase(cccRecord.Business_Unit__c))
            {
                return true;
            }
        }
        else if(customerBU == 'ABFL' || assetBU =='ABFL' || customerBU == 'ABWM' || assetBU == 'ABWM'){
            customerBU = 'ABFL';
            assetBU = 'ABFL';
            if(customerBU.equalsIgnoreCase(cccRecord.Business_Unit__c)  || assetBU.equalsIgnoreCase(cccRecord.Business_Unit__c)){
                if(assetLOB != null && assetLOB != ''){
                    if(cccRecord.LOB__c.equalsIgnoreCase(assetLOB)){
                        return true;
                    }
                }
                else if(cccRecord.LOB__c.equalsIgnoreCase(customerLOB) && cccRecord.LOB__c == 'Wealth'){
                    return true;
                }
            }
        }
        else if(customerBU == 'Payments'){
            if(customerBU.equalsIgnoreCase(cccRecord.Business_Unit__c)  || assetBU.equalsIgnoreCase(cccRecord.Business_Unit__c)){
                if(customerRecordType != null && customerRecordType != ''){
                    if(cccRecord.Custom_Segment__c.equalsIgnoreCase(customerRecordType)){
                        return true;
                    }
                }
            }
        }
        return false;
        
        
    }
    @AuraEnabled
    public static boolean validateIfCurrentCTSTForAccountAndPropect(String recordId,String cccId){
        if(recordId == null && recordId == ''){
            return false;
        }
        boolean bReturnVal = false;
        try{
            Id recId = Id.valueOf(recordId);
            String recordBU = '';
            String recordLOB = '';
            String selectedrecordRTName = '';
            string objType = '';
            if(recId.getSObjectType() == Account.sObjectType){
                Account newCustomerSelected = [SELECT ID,Business_Unit__c,Line_Of_Business__c,RecordType.Name FROM Account WHERE Id =: recId LIMIT 1];
                recordBU = newCustomerSelected.Business_Unit__c;
                recordLOB = newCustomerSelected.Line_of_Business__c;
                selectedrecordRTName = newCustomerSelected.RecordType.Name;
                objType = 'Account';
            }
            if(recId.getSObjectType() == Lead.sObjectType){
                Lead newProspectSelected = [SELECT ID,Business_Unit__c, RecordType.Name FROM Lead WHERE Id =: recId LIMIT 1];
                recordBU = newProspectSelected.Business_Unit__c;
                recordLOB = newProspectSelected.Business_Unit__c;
                selectedrecordRTName = newProspectSelected.RecordType.Name;
                objType = 'Lead';
            }
            ASF_Case_Category_Config__c cccRecord = [SELECT ID,Business_Unit__c,LOB__c,Custom_Segment__c,Is_Prospect_Related__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = : cccId];
            if(ASF_Constants.BU_WITHOUT_LOB.contains(recordBU)){
                if(recordBU.equalsIgnoreCase(cccRecord.Business_Unit__c) && (objType =='Account' || (objType == 'Lead' && cccRecord.Is_Prospect_Related__c)))
                {
                    bReturnVal = true;
                }
            }
            else if(recordBU == 'ABFL' || recordBU == 'ABWM'){
                recordBU = 'ABFL';
                recordBU = 'ABFL';
                if(recordBU.equalsIgnoreCase(cccRecord.Business_Unit__c) && (objType =='Account' || (objType == 'Lead' && cccRecord.Is_Prospect_Related__c)))
                {
                    if(recordLOB != null && recordLOB != ''){
                        if(cccRecord.LOB__c.equalsIgnoreCase(recordLOB) && recordLOB == 'Wealth'){
                            bReturnVal = true;
                        }
                        else if(objType == 'Lead' && cccRecord.Is_Prospect_Related__c){
                        	bReturnVal = true;
                    	}
                    }
                }
            }
            else if(recordBU == 'Payments'){
                if(recordBU.equalsIgnoreCase(cccRecord.Business_Unit__c)){
                    if(selectedrecordRTName != null && selectedrecordRTName != ''){
                        if(cccRecord.Custom_Segment__c.equalsIgnoreCase(selectedrecordRTName)){
                            bReturnVal = true;
                        }
                    }
                }
            }
        }
        catch(exception ex){
            bReturnVal = false;
        } 
        return bReturnVal;            
    }
}