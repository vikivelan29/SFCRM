/*******************************************************************************************
* @Name         ASF_CloneCaseActionController
* @Author       Santanu Halder
* @Description  This apex class is used as a controller class for the component asf_cloneCaseActionWebComp.
* @Test class   ASF_CloneCaseActionControllerTest
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description            Coverage
*-------------------------------------------------------------------------------------------
*  1.0          Santanu Halder      23/10/2023          Initial Creation        95%
*******************************************************************************************/

public with sharing class ASF_CloneCaseActionController {
    /****************************************************************************************************************
    * @Function - isCaseCloneable
    * @param caseId -  Input case id.
    * @return -  BooleanWithReasonWrapper  - The method returns boolean value inside the Wrapper 
                indicating whether the case is cloneable or not. True = cloneable.
                In case its not cloneable, the return wrapper contains user friendly message also.
    * @Description - This method checks whether the Case Category Config associated with 
                    the input case Id is configured with ASF_Is_Cloneable__c = true
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static BooleanWithReasonWrapper isCaseCloneable(Id caseId){
        BooleanWithReasonWrapper wrap = new BooleanWithReasonWrapper();
        try {
            Case caseRec = [SELECT Id, ASF_Is_Cloneable__c FROM Case WHERE Id =: caseId LIMIT 1];
            wrap.resultFlag = caseRec.ASF_Is_Cloneable__c;
            if(wrap.resultFlag == false){
                wrap.reasonIfFalse = 'Case is not configured as cloneable, please contact System Administrator';
            }
            return wrap;
        } catch (Exception e) {
            System.debug(e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }


    /****************************************************************************************************************
    * @Function - fetchCommonFieldsToCopy
    * @param none
    * @return -  FieldListWrapper - The method returns a list of fields with their object API names 
                from the custom metadata ASF_CaseCloneCommonField__mdt without any filters applied.
    * @Description - This method fetches all the entries from ASF_CaseCloneCommonField__mdt custom metadata 
                in a wrapper containing field API name and related object API Name.
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static FieldListWrapper fetchCommonFieldsToCopy(){
        FieldListWrapper outerWrap = new FieldListWrapper();
        outerWrap.fieldList = new List<FieldWrapper>();
        try {
            List<ASF_CaseCloneCommonField__mdt> commonFields = ASF_CaseCloneCommonField__mdt.getAll().values();
            for(ASF_CaseCloneCommonField__mdt field : commonFields){
                FieldWrapper wrap = new FieldWrapper();
                wrap.objectAPIName = field.ASF_ObjectAPIName__c;
                wrap.fieldAPIName = field.ASF_FieldAPIName__c;
                outerWrap.fieldList.add(wrap);
            }
            return outerWrap;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    /****************************************************************************************************************
    * @Function - fetchCCCSpecificFieldsToCopy
    * @param caseId - Input caseId
    * @return - FieldListWrapper - The method returns a list of fields with their object API names 
                from the ASF_Case_Field_Config__c table (with filter ASF_Is_Cloneable__c = TRUE) related to 
                the ASF_Case_Category_Config__c of the input Case Id.
    * @Description - This method fetches all the entries from ASF_Case_Field_Config__c table (with 
                filter ASF_Is_Cloneable__c = TRUE) related to the ASF_Case_Category_Config__c of the input Case Id.
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static FieldListWrapper fetchCCCSpecificFieldsToCopy(Id caseId){
        FieldListWrapper outerWrap = new FieldListWrapper();
        outerWrap.fieldList = new List<FieldWrapper>();
        try {
            Case caseRec = [SELECT Id, CCC_External_Id__c FROM Case WHERE Id =: caseId LIMIT 1];
            List<ASF_Case_Category_Config__c> cccRecs = [SELECT Id, is_FA_Mandatory__c,
                                                (SELECT Id, FieldAPIName__c, ObjectAPIName__c FROM Case_Main_Configs__r
                                                WHERE ASF_Is_Cloneable__c = TRUE) 
                                                FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c];
            if(cccRecs.isEmpty()){
                AuraHandledException e = new AuraHandledException('Case Category Config is invalid');
                e.setMessage('Case Category Config is invalid');
                throw e;
            }
            
            outerWrap.isFAMandatory = cccRecs[0].is_FA_Mandatory__c;

            for(ASF_Case_Field_Config__c field : cccRecs[0].Case_Main_Configs__r){
                FieldWrapper wrap = new FieldWrapper();
                wrap.objectAPIName = field.ObjectAPIName__c;
                wrap.fieldAPIName = field.FieldAPIName__c;
                outerWrap.fieldList.add(wrap);
            }
            return outerWrap;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    /****************************************************************************************************************
    * @Function - fetchCaseDetailsWithExtension
    * @param caseId - Input caseId
    * @param fieldsToCopy - Consolidated list of all the fields to be copied from original case to the cloned case.
    * @return - CaseDetailWrapper - The method returns (1) a Case record (2) a map of Case extension records 
                with their Object API Name as map key (3) Boolean indicating whether the method was successful or not 
                (4) Any message to be passed to client.
    * @Description - This method first forms the dynamic SOQL queries using the fieldsToCopy and then fetches the 
                Case record and all its extension records(max 2) and returns to client in a single wrapper.
    *****************************************************************************************************************/
    @AuraEnabled
    public static CaseDetailWrapper fetchCaseDetailsWithExtension(List<FieldWrapper> fieldsToCopy, Id caseId){
        CaseDetailWrapper wrap = new CaseDetailWrapper();
        System.debug('fieldsToCopy'+fieldsToCopy);
        try {
            String caseQuery = 'SELECT ';
            Map<String, String> extnObjectToQueryMap = new Map<String, String>();
            
            for(FieldWrapper field : fieldsToCopy){
                if(field.objectAPIName == 'Case'){
                    caseQuery += String.escapeSingleQuotes(field.fieldAPIName)+', ';
                }else{
                    if(!extnObjectToQueryMap.containsKey(field.objectAPIName)){
                        extnObjectToQueryMap.put(field.objectAPIName, 'SELECT ');
                    }
                    String query = extnObjectToQueryMap.get(field.objectAPIName);
                    query += String.escapeSingleQuotes(field.fieldAPIName)+', ';
                    extnObjectToQueryMap.put(field.objectAPIName, query);
                }
            }
            //Assuming that the relationship field api name would always be same as the relatedTo object api name.
            for(String objectAPIName : extnObjectToQueryMap.keySet()){
                if(!caseQuery.contains(objectAPIName)){
                    caseQuery += String.escapeSingleQuotes(objectAPIName)+', ';
                }
            }
            caseQuery += 'Id FROM Case WHERE Id =:caseId';

            Case caseRecord = Database.query(String.escapeSingleQuotes(caseQuery));
            wrap.caseRecord = caseRecord;

            if(extnObjectToQueryMap.size() <= 1){ //Safety check - Maximum 1 SOQL queries are considered inside for loop.
                for(String objectAPIName : extnObjectToQueryMap.keySet()){
                    Id extnId = (Id)caseRecord.get(objectAPIName);
                    if(extnId != null){
                        String query = extnObjectToQueryMap.get(objectAPIName);
                        query += 'Id ';
                        query += 'FROM '+String.escapeSingleQuotes(objectAPIName)+' WHERE Id =:extnId';

                        //Justification: SOQL query inside a for loop
                        //Considering that one case can have maximum 2 extension records
                        //Most cases will have only one extension record only.
                        //So total SOQL consumed by the below line would be 1 or 2.
                        SObject extnRecord = Database.query(String.escapeSingleQuotes(query));
                        if(wrap.extnRecords == null){
                            wrap.extnRecords = new Map<String, SObject>();
                        }
                        wrap.extnRecords.put(objectAPIName, extnRecord);
                    }
                }
            }else{
                AuraHandledException e = new AuraHandledException('More than 1 case extension records exist. Please contact System Administrator with this error.');
                e.setMessage('More than 1 case extension records exist. Please contact System Administrator with this error.');
                throw e;
            }
            wrap.resultFlag = true;
            return wrap;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    /****************************************************************************************************************
    * @Function - createCloneCase
    * @param originalCaseId - Original Case Id which is being cloned.
    * @param cloneCaseRecord - All cloneable fields populated instance of the cloned Case.
    * @param clonedCaseExtnRecords - Map of case's extension object api name to cloneable fields populated instance of the extension record.
    * @return - CaseDetailWrapper - The method returns (1) newly created cloned Case record (2) Boolean indicating whether the method was successful or not 
                (3) Any message to be passed to client.
    * @Description - This method first inserts the cloned extension records first, then populates few technical 
                fields on Case from Case Category Config record and then inserts the cloned Case and returns 
                the newly created Case record.
    *****************************************************************************************************************/
    @AuraEnabled
    public static CaseDetailWrapper createCloneCase(Case cloneCaseRecord, Map<String, SObject> clonedCaseExtnRecords, Id originalCaseId){
        CaseDetailWrapper wrap = new CaseDetailWrapper();
        try {

            insert clonedCaseExtnRecords.values();

            Case caseRec = [SELECT Id, CCC_External_Id__c, Origin, Nature__c, AccountId, BusinessHoursId, RecordTypeId,Stage__c
                            //, Customer_Friendly_Verbiage__c 
                            FROM Case WHERE Id =: originalCaseId LIMIT 1];
            List<ASF_Case_Category_Config__c> cccRecs = [SELECT Id, First_Stage__c, 
                                                    //Reopen_Days__c, Customer_Friendly_Name__c, 
                                                    ASF_Is_Cloneable__c, Type__c, Sub_Type__c  
                                                    FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c];
            
            cloneCaseRecord.Cloned_From__c = originalCaseId;
            //cloneCaseRecord.ASF_Is_Cloneable__c = cccRecs[0].ASF_Is_Cloneable__c; - Moved to case trigger
            //cloneCaseRecord.Stage__c = cccRecs[0].First_Stage__c; - Moved to case trigger
            /** Commented the below lines as the fields are not present in ABCL Dev org */
            //cloneCaseRecord.Reopen_Days__c = cccRecs[0].Reopen_Days__c;
            //cloneCaseRecord.Type__c = cccRecs[0].Type__c;
            //cloneCaseRecord.Sub_Type__c = cccRecs[0].Sub_Type__c;
            //cloneCaseRecord.Customer_Friendly_Verbiage__c = cccRecs[0].Customer_Friendly_Name__c;
            cloneCaseRecord.ASF_Is_Clone__c = true;
            cloneCaseRecord.AccountId = caseRec.AccountId;
            cloneCaseRecord.BusinessHoursId = caseRec.BusinessHoursId;
           
            cloneCaseRecord.RecordTypeId = caseRec.RecordTypeId;
            for(String objectAPIName : clonedCaseExtnRecords.keySet()){
                cloneCaseRecord.put(objectAPIName, (Id)clonedCaseExtnRecords.get(objectAPIName).get('Id'));
            }
            insert cloneCaseRecord;

            wrap.caseRecord = cloneCaseRecord;
            wrap.resultFlag = true;
            return wrap;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    @AuraEnabled
    public static CaseDetailWrapper createCloneCaseV2(Case cloneCaseRecord, Map<String, SObject> clonedCaseExtnRecords, Id originalCaseId, String assetId){
        CaseDetailWrapper wrap = new CaseDetailWrapper();
        try {

            insert clonedCaseExtnRecords.values();

            Case caseRec = [SELECT Id, CCC_External_Id__c, Origin, Nature__c, AccountId, BusinessHoursId, RecordTypeId,Stage__c
                            //, Customer_Friendly_Verbiage__c 
                            FROM Case WHERE Id =: originalCaseId LIMIT 1];
            List<ASF_Case_Category_Config__c> cccRecs = [SELECT Id, First_Stage__c, 
                                                    //Reopen_Days__c, Customer_Friendly_Name__c, 
                                                    ASF_Is_Cloneable__c, Type__c, Sub_Type__c  
                                                    FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c];
            
            cloneCaseRecord.Cloned_From__c = originalCaseId;
            //cloneCaseRecord.ASF_Is_Cloneable__c = cccRecs[0].ASF_Is_Cloneable__c; - Moved to case trigger
            //cloneCaseRecord.Stage__c = cccRecs[0].First_Stage__c; - Moved to case trigger
            /** Commented the below lines as the fields are not present in ABCL Dev org */
            //cloneCaseRecord.Reopen_Days__c = cccRecs[0].Reopen_Days__c;
            //cloneCaseRecord.Type__c = cccRecs[0].Type__c;
            //cloneCaseRecord.Sub_Type__c = cccRecs[0].Sub_Type__c;
            //cloneCaseRecord.Customer_Friendly_Verbiage__c = cccRecs[0].Customer_Friendly_Name__c;
            cloneCaseRecord.ASF_Is_Clone__c = true;
            cloneCaseRecord.AccountId = caseRec.AccountId;
            cloneCaseRecord.BusinessHoursId = caseRec.BusinessHoursId;
            if (assetId != 'NA'){
                cloneCaseRecord.assetId = assetId;
            }
           
            cloneCaseRecord.RecordTypeId = caseRec.RecordTypeId;
            for(String objectAPIName : clonedCaseExtnRecords.keySet()){
                cloneCaseRecord.put(objectAPIName, (Id)clonedCaseExtnRecords.get(objectAPIName).get('Id'));
            }
            insert cloneCaseRecord;

            wrap.caseRecord = cloneCaseRecord;
            wrap.resultFlag = true;
            return wrap;
        } catch (DMLException e) { 
            String errMsg = '';
             for (Integer i = 0; i < e.getNumDml(); i++) {
               AuraHandledException ex = new AuraHandledException(e.getDmlMessage(i));
               errMsg += e.getDmlMessage(i);
               ex.setMessage(errMsg);
               throw ex;
            }
            throw e;
        }
    }    

    @AuraEnabled(Cacheable=true)
    public static BooleanWithReasonWrapper isCaseCloneableV2(Id caseId){
        BooleanWithReasonWrapper wrap = new BooleanWithReasonWrapper();
        try {
            Case caseRec = [SELECT Id, CCC_External_Id__c,accountId FROM Case WHERE Id =: caseId LIMIT 1];
            List<ASF_Case_Category_Config__c> cccRecs = [SELECT Id, ASF_Is_Cloneable__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c];
            if(cccRecs.isEmpty()){
                AuraHandledException e = new AuraHandledException('Case Category Config is invalid');
                e.setMessage('Case Category Config is invalid');
                throw e;
            }
            wrap.resultFlag = cccRecs[0].ASF_Is_Cloneable__c;
            wrap.accountId = caseRec.accountId; 
            if(wrap.resultFlag == false){
                wrap.reasonIfFalse = 'Case is not configured as cloneable, please contact System Administrator';
            }
            return wrap;
        } catch (Exception e) {
            System.debug(e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    /** Wrapper classes */
    @TestVisible class BooleanWithReasonWrapper{
        @AuraEnabled public Boolean resultFlag{get;set;}
        @AuraEnabled public String reasonIfFalse{get;set;}
        @AuraEnabled public String accountId{get;set;}
    }

    @TestVisible class FieldWrapper{
        @AuraEnabled public String objectAPIName{get;set;}
        @AuraEnabled public String fieldAPIName{get;set;}
    }

    @TestVisible class FieldListWrapper{
        @AuraEnabled public List<FieldWrapper> fieldList{get;set;}
        @AuraEnabled public String messageIfListIsEmpty{get;set;}
        @AuraEnabled public Boolean isFAMandatory{get;set;}
    }

    @TestVisible class CaseDetailWrapper{
        @AuraEnabled public Case caseRecord{get;set;}
        @AuraEnabled public Map<String, SObject> extnRecords{get;set;}
        @AuraEnabled public String messageIfAny{get;set;}
        @AuraEnabled public Boolean resultFlag{get;set;}
    }
    
}