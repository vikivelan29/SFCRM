@isTest
public class ABSLI_BeforeUpdateTriggerLogic_Test {

    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    @isTest
    public static void ftrRegionalTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
			insert detailRec;
            c.Business_Unit__c = 'ABSLI';
            c.Status = 'New';
            c.FTR__c = true;
            c.MoveToNext__c = true;
            c.CCC_External_Id__c = cccId;
            c.ABSLI_Case_Detail__c = detailRec.Id;
        }
        String errorMessage = '';
        try{
        	update cases;    
        }catch(Exception ex){
        	errorMessage  = ex.getMessage();
        }
        //Assert.areNotEqual(cases[0].Status, 'New','Status should be resolved');
        System.assertEquals(true,errorMessage.contains('first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Update CBS'));
    }
    
    @isTest
    static void beforeUpdateTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        List<Case> caseOld = new List<Case>();
        Case caseTemp = new Case();
        caseTemp.Stage__c = 'Resolved';
        caseTemp.pending_clarification__c = false;
        caseTemp.MoveToNext__c = false;
        caseTemp.Id = cases.values()[0].Id;
        caseTemp.CCC_External_Id__c = cases.values()[0].CCC_External_Id__c;
        caseOld.add(caseTemp);
        List<Case> caseNew = cases.values();
        caseNew[0].MoveToNext__c = false;
        caseNew[0].Business_Unit__c = 'ABSLI';
        Map<Id,Case> newMap = new Map<Id,Case>();
        newMap.put(caseNew[0].Id,caseNew[0]);
        Task tsk = new Task();
        tsk.WhatId = caseTemp.Id;
        insert tsk;
        ABSLI_BeforeUpdateTriggerLogic.validateTasks(caseOld,cases,newMap);
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.From_Date__c = system.today() + 1;
        caseDetail.To_Date__c = system.today();
        //caseDetail.Issue_Date__c = system.today() + 2;
        insert caseDetail;
        Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
        Asset ast = ASF_TestDataFactory.createAsset(acc.Id, 'test');
        ast.Issue_Date__c = System.today();
        for(Case caseRec : cases.values()){
            caseRec.CCC_External_Id__c = 'PEMT042';
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.AssetId = ast.Id;
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Technical_Source__c = 'LWC';
            cases.put(caseRec.Id,caseRec);
        }
        ASF_Case_Category_Config__c config = [Select id from ASF_Case_Category_Config__c where CCC_External_ID__c =: cccId limit 1];
        config.CCC_External_Id__c = 'PEMT042';
        update config;
        update cases.values();
        ABSLI_BeforeUpdateTriggerLogic.executeBeforeLogic(cases,newMap);
    }
    
    @isTest
    static void testCheckComplaintApplicability(){
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.Complaint_Category__c = 'Complaint';
        caseDetail.Resolve_case__c = 'NO';
        caseDetail.IRDAI_Token_Number__c = 'test';
        insert caseDetail;
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        ASF_Case_Category_Config__c cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null];
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                               ABSLI_Case_Detail__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        cccId.IGMS_Code__c = '#N/A';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Nature__c = 'Complaint';
            caseRec.IGMS_Complaint_Type_Code__c = '1';
            caseRec.IRDAI_Token_Number__c = 'test';
            caseRec.Preframework_to_Framework_FromUI__c = true;
            //caseRec.Business_Unit__c = 'ABSLI';
            cases.put(caseRec.Id,caseRec);
        }
        update cases.values();
		cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,Nature__c,
                                  Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                  ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,
                                  ABSLI_Case_Detail__r.IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c
                                  FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        ABSLI_BeforeUpdateTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateTriggerLogic.checkComplaintApplicability(cases.values(),cases,cases);
        cccId.IGMS_Code__c = '1';
        update cccId;
        caseDetail.Complaint_Category__c = 'Information';
        update caseDetail;
        cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,Nature__c,
                                  Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                  ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,
                                  ABSLI_Case_Detail__r.IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c
                                  FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        ABSLI_BeforeUpdateTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateTriggerLogic.checkComplaintApplicability(cases.values(),cases,cases);
    }
    
    @isTest
    static void testCheckCreateCaseValidations(){
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.Complaint_Category__c = 'Complaint';
        caseDetail.Resolve_case__c = 'NO';
        caseDetail.IRDAI_Token_Number__c = 'test';
        insert caseDetail;
        Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
        Asset ast = ASF_TestDataFactory.createAsset(acc.Id, 'test');
        ast.Status = 'U/W CMPLT:PENDING';
        update ast;
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        ASF_Case_Category_Config__c cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null];
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                               ABSLI_Case_Detail__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        cccId.IGMS_Code__c = '#N/A';
        cccId.CCC_External_Id__c = 'PPAY008';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Business_Unit__c = 'ABSLI';
            caseRec.Technical_Source__c = 'LWC';
            caseRec.AssetId = ast.Id;
            caseRec.CCC_External_Id__c = 'PPAY008';
            cases.put(caseRec.Id,caseRec);
        }
        update cases.values();
        cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                               AssetId,ABSLI_Case_Detail__c,Preframework_to_Framework_FromUI__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        Map<Id,Case> oldCaseMap = new Map<Id,Case>();
		List<Case> caseList = ASF_TestDataFactory.createInteractionCaseRecords();
        caseList[0].Id = cases.values()[0].Id;
        caseList[0].RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        oldCaseMap.put(caseList[0].Id,caseList[0]);
        for(Case cs : cases.values()){
            if(cs.Id != caseList[0].Id){
                oldCaseMap.put(cs.Id,cs);
            }
        }
        ABSLI_BeforeUpdateTriggerLogic.checkCreateCaseValidations(cases.values(),oldCaseMap);
        cccId.CCC_External_Id__c = 'PNFT034';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Business_Unit__c = 'ABSLI';
            caseRec.Technical_Source__c = 'LWC';
            caseRec.AssetId = ast.Id;
            caseRec.CCC_External_Id__c = 'PNFT034';
            cases.put(caseRec.Id,caseRec);
        }
        ast.Status = 'PREMIUM PAYING';
        update ast;
        ABSLI_BeforeUpdateTriggerLogic.checkCreateCaseValidations(cases.values(),oldCaseMap);
    }
    
    @isTest
    static void testValidateFromDateToDate(){
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.Complaint_Category__c = 'Complaint';
        caseDetail.Resolve_case__c = 'NO';
        caseDetail.IRDAI_Token_Number__c = 'test';
        insert caseDetail;
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        ASF_Case_Category_Config__c cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null];
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                               ABSLI_Case_Detail__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        cccId.IGMS_Code__c = '#N/A';
        cccId.CCC_External_Id__c = 'PPAY001';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Nature__c = 'Complaint';
            caseRec.IGMS_Complaint_Type_Code__c = '1';
            caseRec.IRDAI_Token_Number__c = 'test';
            caseRec.Preframework_to_Framework_FromUI__c = true;
            //caseRec.Business_Unit__c = 'ABSLI';
            caseRec.CCC_External_Id__c = 'PPAY001';
            caseRec.Stage__c = 'Open';
            cases.put(caseRec.Id,caseRec);
        }
        update cases.values();
		cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,Nature__c,
                                  Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                  ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,
                                  ABSLI_Case_Detail__r.IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c,ABSLI_Case_Detail__r.To_Date__c,
                                  ABSLI_Case_Detail__r.From_Date__c
                                  FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        ABSLI_BeforeUpdateTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateTriggerLogic.validateFromDateToDate(cases.values(),cases,cases);
    }
}