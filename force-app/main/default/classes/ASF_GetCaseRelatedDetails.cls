/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-23-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   09-20-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.PropertyNamingConventions,PMD.FormalParameterNamingConventions')
public without sharing class ASF_GetCaseRelatedDetails {
    
    //getAssetDetails
    @AuraEnabled(cacheable=true)
    public static Asset getAssetDetails(string accId) {
        
        Asset assObj = [SELECT id,AccountId,Price, Name from Asset where AccountId =:accId LIMIT 1];
        return assObj;   
        
    }
    
    
    //get Asset Records for the time of selection while creating Case
    @AuraEnabled(cacheable=true)
    public static List<Asset> getRelatedAssets(string recordId) {
        return [SELECT Id,Name,AccountId, Description,SerialNumber FROM Asset WHERE AccountId =: recordId AND SerialNumber != null LIMIT 3];
    }
    
    //get Case Fields Metadata
    @AuraEnabled(cacheable= true)
    public static List<CaseFieldConfigWrapper> getCaseFieldsConfig(string cccId,string status, string caseId){ 
        // Check if the values present in org cache.
        List<CaseFieldConfigWrapper> fieldsConfiglst = new List<CaseFieldConfigWrapper>(); 
        Map<Id, CaseFieldConfigWrapper> fieldConfigMap = new Map<Id, CaseFieldConfigWrapper>();
        List<ASF_Case_Category_Config__c > ccObj = new List<ASF_Case_Category_Config__c >();
        if(String.isNotBlank(cccId)){
            ccObj = [SELECT ID FROM ASF_Case_Category_Config__c  WHERE CCC_External_Id__c  =: cccId];
            String tempCCCId = ccObj[0].Id;
            
            if(Cache.Org.contains(tempCCCId)){
                
                List<CaseFieldConfigWrapper> lstCacheFieldConfig = (List<CaseFieldConfigWrapper>)Cache.Org.get(tempCCCId);
                
                for(CaseFieldConfigWrapper item : lstCacheFieldConfig){
                    if(item.UpdateAtList != null && item.UpdateAtList.size() > 0 ){ 
                        if(item.UpdateAtList.contains(status) && item.ControllingField == null){
                            item.ReadOnly = false;
                        }
                        else{
                            item.ReadOnly = true;
                        }
                    }
                    
                    if(item.RequiredAtList != null && item.RequiredAtList.size() >0 ){   
                        if(item.RequiredAtList.contains(status) && item.ControllingField == null){
                            item.Required = true;
                        }
                        else{
                            item.Required = false;
                        } 
                    }
                    fieldsConfiglst.add(item);
                }
                if(fieldsConfiglst.size()>0){
                    return fieldsConfiglst;
                }
            }
            else{
                return getCaseFieldsConfigFROMDB(cccId,status,caseId);
            }
        }
        
        
        return getCaseFieldsConfigFROMDB(cccId,status,caseId);
    }
    private static List<CaseFieldConfigWrapper> getCaseFieldsConfigFROMDB(string cccId,string status, string caseId){
        List<CaseFieldConfigWrapper> fieldsConfiglst = new List<CaseFieldConfigWrapper>(); 
        Map<Id, CaseFieldConfigWrapper> fieldConfigMap = new Map<Id, CaseFieldConfigWrapper>();
        
        List<ASF_Case_Field_Config__c > fieldConfigRecords = [SELECT id,Field_Type__c ,FieldAPIName__c , ObjectAPIName__c , ReadOnly__c,IsControllingField__c , Update__c, Mandatory__c, Controlling_field__c, Controlling_Experssion__c, Default_Value__c,Default_Type__c, Case_Category_Config__c,Display_Order__c, Sensitive_field__c,Use_Controlling_Formula__c ,Controlling_Formula__c,Searchable_Picklist__c  FROM ASF_Case_Field_Config__c  WHERE Case_Category_Config__c =:cccId ORDER BY Display_Order__c ASC];
        system.debug('orderfieldConfigRecords '+fieldConfigRecords);        
        for(ASF_Case_Field_Config__c config : fieldConfigRecords){
            
            CaseFieldConfigWrapper item = new CaseFieldConfigWrapper();
            item.FieldAPINAme  = config.FieldAPIName__c;
            item.Id  = config.Id;
            item.IsControllingField = config.IsControllingField__c;
            item.ObjectAPIName = config.ObjectAPIName__c;
            item.FieldType = config.Field_Type__c;
            item.ControllingField = config.Controlling_field__c;
            item.ControllingExpression = config.Controlling_Experssion__c;
            item.UpdateAt = config.Update__c;
            item.controllingFormula = config.Controlling_Formula__c;
            item.useControllingFormula = config.Use_Controlling_Formula__c;
            item.bSearchablePicklist = false;
            item.bMultiSelectSearchablePicklist = false;
            
            if(config.Field_Type__c == 'LOV' && config.Searchable_Picklist__c == true){
                item.bSearchablePicklist = true;
            }
            else if(config.Field_Type__c == 'Multi-Select LOV' && config.Searchable_Picklist__c == true){
                item.bMultiSelectSearchablePicklist = true;
            }

            if (config.update__c != null)
                item.UpdateAtList = config.update__c.split(',');
            else
                item.UpdateAtList = new List<String>();                
            item.RequiredAt = config.Mandatory__c;
            if (config.Mandatory__c != null)
                item.RequiredAtList = config.Mandatory__c.split(',');
            else
                item.RequiredAtList = new List<String>();
            item.DefaultValue = config.Default_Value__c;
            item.DefaultType  = config.Default_Type__c;
            item.DisplayOrder = config.Display_Order__c;
            item.isSensitive = config.Sensitive_field__c;
            item.FieldLabelName = getLabelfromAPIName(config.ObjectAPIName__c,config.FieldAPIName__c);
            // System.debug(config.Update__c + config.Update__c.contains(status));
            item.ReadOnly = false;
            if(item.UpdateAtList != null && item.UpdateAtList.size() > 0 ){ 
                if(item.UpdateAtList.contains(status) && config.Controlling_field__c == null){
                    item.ReadOnly = false;
                }
                else{
                    item.ReadOnly = true;
                }
            }
            Schema.DescribeFieldResult dfr = Schema.getGlobalDescribe().get(config.ObjectAPIName__c).getDescribe().fields.getMap().get(config.FieldAPIName__c).getDescribe();
            item.ReadOnly = item.ReadOnly?item.ReadOnly:!dfr.isUpdateable();

            if(item.RequiredAtList != null && item.RequiredAtList.size() >0 ){   
                if(item.RequiredAtList.contains(status) && config.Controlling_field__c == null){
                    item.Required = true;
                }
                else{
                    item.Required = false;
                } 
            }
            
            //tst strt
            if(config.ObjectAPIName__c == 'Case'){
                item.isCase = true;
            }
            //tst end
            fieldConfigMap.put(config.Id, item);
            fieldsConfiglst.add(item);
        }
        return fieldsConfiglst;
    }
    
    //get Case Category Metadata
    @AuraEnabled(cacheable= true)
    public static List<ASF_Case_Category_Config__c > getCaseCategoryConfig(string cccExtId){
        return [SELECT id,Type__c, Sub_Type__c, Nature__c, Business_Unit__c, Product__c,Allowed_Sources__c,First_Stage__c,UI_Cards__c, Type_Synonyms__c, Priority__c, Custom_Segment__c, CCC_External_Id__c, Reopen_Style__c  FROM ASF_Case_Category_Config__c  WHERE CCC_External_Id__c =: cccExtId];
    }
    
    //get Case Stage Metadata
    @AuraEnabled(cacheable= true)
    public static List<ASF_Case_Stage_Config__c  > getStageConfig(string cccId){
        //Virendra : 6th March 2023: Added additional fields to query - Is_Approval_Stage__c,Manual_Stage__c
        return [SELECT id,Case_Category_Config__r.Name, Name, Order__c, StageName__c,Is_Approval_Stage__c,Manual_Stage__c,Enable_Reassign_Owner__c FROM ASF_Case_Stage_Config__c  WHERE Case_Category_Config__c  =: cccId ORDER BY Order__c];
    }
    
    @AuraEnabled(cacheable=true)
    public static SObject getDefaultValues(string caseId, List<string> fieldNames, List<string> fieldValues) {
        System.debug(caseId +':' + fieldNames + fieldValues);
        
        //Map<string, string> map1 = fieldsMap.clone();
        List<string> newList = new List<string>();
        List<string> newList2 = new List<string>();
        List<string> defaultValues = new List<string>();
        for(string fieldname : fieldValues){
            newList.add(fieldname.removeStartIgnoreCase('Case.')) ;
        }
        System.debug('Revised Fields List- ' + newList);
        
        String soql = '';
        for(String rec : newList){
            //Schema.SobjectField eachField;
            if(String.isBlank(soql)){
                soql = String.escapeSingleQuotes(rec);
            }else{
                soql = String.escapeSingleQuotes(soql+', '+rec);
            }
        }
        soql = String.escapeSingleQuotes('SELECT '+ soql +' FROM Case WHERE Id =: caseId ');
        System.debug('SOQL is: '+soql);
        List<Sobject> queryResponseList = new List<Sobject>();
        queryResponseList = Database.query(soql); 
        System.debug('Query result is: '+queryResponseList);
        Sobject queryResponseRec = queryResponseList.size() > 0 ?queryResponseList.get(0) : NULL;
        
        //Removing Asset. substring from FieldNames
        for(string fieldname : newList){
            newList2.add(fieldname.removeStartIgnoreCase('Asset.')) ;
        }
        System.debug(':::' + newList2);
        if(queryResponseRec != null){
            for(string field : newList2){
                //  System.debug('Value==>' +  queryResponseRec.getSobject('Asset').get(field));
                //  defaultValues.add(String.valueOf(queryResponseRec.getSobject('Asset').get(field)));
                
            }
        }
        System.debug('Values final: ' + queryResponseRec);
        return queryResponseRec;
        
    }
    
    public class CaseFieldConfigWrapper{
        @AuraEnabled
        public String FieldAPINAme { get;set; } 
        
        @AuraEnabled
        public String FieldLabelName { get;set; }
        
        @AuraEnabled
        public String FieldType { get;set; }
        
        @AuraEnabled
        public String Id { get;set; } 
        
        @AuraEnabled
        public String value { get;set; }
        
        @AuraEnabled
        public String ObjectAPIName { get;set; } 
        
        @AuraEnabled
        public Boolean Required { get;set; } 
        
        @AuraEnabled
        public Boolean ReadOnly { get;set; } 
        
        @AuraEnabled
        public Boolean IsControllingField { get;set; } 
        
        @AuraEnabled
        public String DefaultValue  { get;set; }
        
        @AuraEnabled
        public String DefaultType  { get;set; }
        
        @AuraEnabled
        public String UpdateAt { get;set; }
        
        @AuraEnabled
        public List<String> UpdateAtList { get;set; }
        
        @AuraEnabled
        public String RequiredAt { get;set; } 
        
        @AuraEnabled
        public List<String> RequiredAtList { get;set; } 
        
        @AuraEnabled
        public String ControllingField  { get;set; } 
        
        @AuraEnabled
        public String ControllingExpression { get;set; }
        
        @AuraEnabled
        public Boolean isCase { get;set; }
        
        @AuraEnabled
        public Decimal DisplayOrder { get;set; }
        
        @AuraEnabled
        public Boolean isSensitive { get;set; }
        
        @AuraEnabled
        public Boolean useControllingFormula{get;set;}
        
        @AuraEnabled
        public string controllingFormula{get;set;}
        //Virendra : Added for searchable Picklist
        @AuraEnabled
        public boolean bSearchablePicklist{get;set;}
        @AuraEnabled
        public boolean bMultiSelectSearchablePicklist{get;set;}
    }
    
    @AuraEnabled(cacheable= true)
    public static List<Contact> fetchRelatedContacts(string accId){
        List<Contact> lstContacts = [SELECT ID,AccountId,Name FROM Contact WHERE AccountId =: accId ];
        return lstContacts;
    }
    @AuraEnabled(cacheable= true)
    public static List<Task> getPendingTasks(string caseId){
        return [SELECT id,Subject,Task_Type__c, Stage_Matched__c, Status,Description,WhatId,OwnerId,Owner.Name,Manual_Tasks__c,CreatedBy.Name,CreatedById from Task where WhatId =: caseId];
    }
    
    @AuraEnabled(cacheable= true)
    public static List<PicklistOptionWrapper> getPickListValuesIntoList(){
        List<PicklistOptionWrapper> pickListValuesList= new List<PicklistOptionWrapper>();
        Schema.DescribeFieldResult fieldResult = Task.Status.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            PicklistOptionWrapper pObj = new PicklistOptionWrapper();
            pObj.label = pickListVal.getLabel();
            pObj.value = pickListVal.getValue();
            pObj.isActive = pickListVal.isActive();
            pickListValuesList.add(pObj);
        }    
        return pickListValuesList;
    }
    @AuraEnabled
    public static string updateTasks(Object data) {
        List<Task> tasksForUpdate = (List<Task>) JSON.deserialize(
            JSON.serialize(data),
            List<Task>.class
        );
        try {
            update tasksForUpdate;
            return 'Success: Tasks updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }
    
    @AuraEnabled(cacheable= true)
    public static List<ASF_Checklist__c> getPendingChecklists(string caseId){
        return [SELECT id,Label__c,Mandatory__c, Stage_Name__c, Description__c ,Stage_Matched__c, Status__c, Comments__c, Case__c from ASF_Checklist__c where Case__c  =: caseId AND Status__c != 'Rejected'];
    }
    @AuraEnabled(cacheable= true)
    public static List< ASF_Case_Approv__c > getCaseApprovalRecords(string caseId){
        return [SELECT id, Approver_01__c ,Approver_01__r.Name,Approver_02__r.Name,Approval_Type__c, Approver_02__c , Approver_03__c , Approver_03__r.Name,
                SR__c , Approver_04__c ,Approver_04__r.Name, Approver_05__c ,Approver_05__r.name,
                Approval_Status__c 
                FROM ASF_Case_Approv__c WHERE SR__c   =: caseId];
    }
    //Tst
    @AuraEnabled(cacheable= true)
    public static String getCaseRelatedObjName(string cccId){
        List<ASF_Case_Field_Config__c > fieldConfigRecords = [SELECT id,Field_Type__c ,FieldAPIName__c , ObjectAPIName__c , ReadOnly__c,IsControllingField__c , Update__c, Mandatory__c, Controlling_field__c, Controlling_Experssion__c, Default_Value__c,Case_Category_Config__c  FROM ASF_Case_Field_Config__c  WHERE Case_Category_Config__c =:cccId]; 
        String ObjName;
        for(ASF_Case_Field_Config__c  config : fieldConfigRecords){
            if(config.ObjectAPIName__c != 'Case'){
                ObjName = config.ObjectAPIName__c;
            }
        }return ObjName;
    }
    
    public static string getLabelfromAPIName(String ObjectApi, String FieldApi){
        String fieldApiName;
        if(!String.IsBlank(ObjectApi) && !String.IsBlank(FieldApi)){
            fieldApiName = (String)Schema.getGlobalDescribe().get(ObjectApi).getDescribe().fields.getMap().get(FieldApi).getDescribe().getLabel();
        }
        return fieldApiName;
    }
    
    
    @AuraEnabled
    public static void updateCheckList(Map<Id,ASF_Checklist__c> updateChecklistRecords){
        //Map<Id,ASF_Checklist__c> updateChecklistRecords = new Map<Id,ASF_Checklist__c>();
        system.debug('receivedPara '+ updateChecklistRecords);
        // if(!recordUpdate.isEmpty()){
        //     updateChecklistRecords.putall(recordUpdate);         
        // }
        if(updateChecklistRecords.size()>0){
            update updateChecklistRecords.values();
        }
    } 
    
    
    @AuraEnabled
    public static void updateTask(Map<Id,Task> updateTaskRecords){
        // Map<Id,Task> updateTaskRecords = new Map<Id,Task>();
        // system.debug('receivedPara '+ recordUpdate);
        // if(!recordUpdate.isEmpty()){
        //     updateTaskRecords.putall(recordUpdate);         
        // }
        if(updateTaskRecords.size()>0){
            update updateTaskRecords.values();
        }
        
    } 
    @AuraEnabled
    public static void updateTaskRecordsComment(string taskId, string comments){
        List<Task> updateTaskRecord = new List<Task>();
        system.debug('cheklistId '+TaskId);
        system.debug('statusValue '+comments);
        Task updateTask = new Task();
        updateTask.Id = taskId;
        updateTask.Description = comments;        
        updateTaskRecord.add(updateTask);
        if(!updateTaskRecord.isEmpty()){
            update updateTaskRecord;    
        }
    } 
    @AuraEnabled
    public static void updateChecklistComment(string checkId, string commentsCheck){
        List<ASF_Checklist__c> updateCheckListRecord = new List<ASF_Checklist__c>();
        system.debug('checkId '+checkId);
        system.debug('commentsCheck '+commentsCheck);
        ASF_Checklist__c updateCheck = new ASF_Checklist__c();
        updateCheck.Id = checkId;
        updateCheck.Comments__c = commentsCheck;        
        updateCheckListRecord.add(updateCheck);
        if(!updateCheckListRecord.isEmpty()){
            update updateCheckListRecord;    
        }
    }
    
    
    //getLatestApprovalRecord
    @AuraEnabled(cacheable=true)
    public static string getLatestApprovalRecord(string caseId) {
        
        string approvalRecordId;
        List<ASF_Case_Approv__c> approvals = [SELECT id,SR__c,Approval_Status__c from ASF_Case_Approv__c where Approval_Status__c = 'Pending' AND SR__c =: caseId ORDER BY CreatedDate desc];
        if(approvals.size() > 0){
            
            approvalRecordId = approvals.get(0).Id;
        }
        else{
            approvalRecordId = 'NA';
        }
        System.debug('approvalRecordID--' + approvalRecordId);
        
        return approvalRecordId;
    }
    
    
    public class InfoFieldConfigWrapper{
        @AuraEnabled
        public String FieldAPINAme { get;set; } 
        
        @AuraEnabled 
        public String Label { get;set; }
        
        @AuraEnabled
        public String LOB { get;set; } 
        
        @AuraEnabled
        public String ObjectAPIName { get;set; }
        
        @AuraEnabled
        public String value { get;set; }
    }
    
    public class PicklistOptionWrapper{
        @AuraEnabled
        public String label { get;set; } 
        
        @AuraEnabled
        public String value { get;set; }
        
        @AuraEnabled
        public Boolean isActive { get;set; } 
    }
    
    
    @AuraEnabled
    public static ASF_Case_Approv__c getLatestCaseApprovalRecord(String caseId,String caseCurrentStage){
        Map<Id,ASF_Case_Approv__c> mCaseApprovals = new Map<Id,ASF_Case_Approv__c>();
        List<ASF_Case_Approv__c> caseApprovals = [SELECT ID,SR__c, Approval_Status__c  FROM ASF_Case_Approv__c WHERE SR__c =: caseId AND Case_Stage_At_Creation__c  =:caseCurrentStage ORDER BY CreatedDate DESC];
        if(caseApprovals.size()>0){
            return caseApprovals[0];
        }
        else{
            return null;
        }
    }
    @AuraEnabled
    public static List<String> getRejectionReasons(String cccExternalId){
        List<String> reasonValues = new List<String>();
        List<String> buList = new List<String>();
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        if(cccExternalId != ''){
            ccc = [SELECT Business_Unit__c, CCC_External_Id__c 
                   FROM ASF_Case_Category_Config__c
                   WHERE CCC_External_Id__c = :cccExternalId LIMIT 1];
        }
        if(ccc.Business_Unit__c != null && ccc.Business_Unit__c != '' && cccExternalId != ''){
            String bu = ccc.Business_Unit__c;
            if(bu.contains(',')){
                for(String buVal : bu.split(',')){
                    buList.add('%'+buVal.trim()+'%');
                }                    
            }else{
                buList.add('%'+bu+'%');   
            }            
            for(LOB_Rejection_Reason__mdt buReason : [SELECT LOB__c, Reason__c 
                                                      FROM LOB_Rejection_Reason__mdt 
                                                      WHERE LOB__c LIKE :buList ORDER BY Reason__c]){
                                                          reasonValues.add(buReason.Reason__c);
                                                      }
        }
        if(reasonValues.isEmpty()){
            for(LOB_Rejection_Reason__mdt buReason : [SELECT LOB__c, Reason__c 
                                                      FROM LOB_Rejection_Reason__mdt 
                                                      ORDER BY Reason__c]){
                                                          reasonValues.add(buReason.Reason__c);
                                                      }
        }
        return reasonValues;
    }
    
    /**
    * @description : PR1030924-224: Method created to get resolved & rejected reasons.
    * @author zahedali.mohammed@salesforce.com | 09-23-2024 
    * @param String cccExternalId 
    * @return List<LOB_Rejection_Reason__mdt> 
    **/
    @AuraEnabled
    public static List<LOB_Rejection_Reason__mdt> getBUReasons(String cccExternalId){
        List<LOB_Rejection_Reason__mdt> reasonValues = new List<LOB_Rejection_Reason__mdt>();
        List<String> buList = new List<String>();
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        if(cccExternalId != ''){
            ccc = [SELECT Business_Unit__c, CCC_External_Id__c 
                   FROM ASF_Case_Category_Config__c
                   WHERE CCC_External_Id__c = :cccExternalId LIMIT 1];
        }
        if(String.isNotBlank(ccc.Business_Unit__c) && cccExternalId != ''){
            String bu = ccc.Business_Unit__c;
            if(bu.contains(',')){
                for(String buVal : bu.split(',')){
                    buList.add('%'+buVal.trim()+'%');
                }                    
            }else{
                buList.add('%'+bu+'%');   
            }            
            for(LOB_Rejection_Reason__mdt buReason : [SELECT LOB__c, Reason__c ,Type__c
                                                      FROM LOB_Rejection_Reason__mdt 
                                                      WHERE LOB__c LIKE :buList ORDER BY Reason__c]){
                                                          reasonValues.add(buReason);
                                                      }
        }
        return reasonValues;
    }
}