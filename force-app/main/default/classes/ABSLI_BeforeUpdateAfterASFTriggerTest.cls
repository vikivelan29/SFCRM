@isTest
public class ABSLI_BeforeUpdateAfterASFTriggerTest {
    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    
    @isTest
    static void testExecuteBeforeLogic(){
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.Complaint_Category__c = 'Complaint';
        caseDetail.Resolve_case__c = 'NO';
        caseDetail.Source_Request_submitted_by__c = 'RQ';
        //caseDetail.IRDAI_Token_Number__c = 'test';
        insert caseDetail;
        Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
        Asset ast = ASF_TestDataFactory.createAsset(acc.Id, 'test');
        ast.Status = 'U/W CMPLT:PENDING';
        update ast;
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        ASF_Case_Category_Config__c cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null];
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,
                                               Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                               IRDAI_Token_Number__c,ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Source_Request_submitted_by__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        cccId.CCC_External_Id__c = 'PPAY008';
        cccId.IGMS_Code__c = '1';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Business_Unit__c = 'ABSLI';
            caseRec.Technical_Source__c = 'LWC';
            caseRec.AssetId = ast.Id;
            caseRec.CCC_External_Id__c = 'PPAY008';
            caseRec.Nature__c = 'Complaint';
            //caseRec.IRDAI_Token_Number__c = 'Test';
            cases.put(caseRec.Id,caseRec);
        }
        update cases.values();
                try{
            caseDetail.Requested_Withdrawal_Amount__c = 100;
        	caseDetail.Withdrawal_Amount_Available__c = 1;
        	caseDetail.Minimum_Withdrawal_Amount__c = 101;
            update caseDetail;
            update cases.values();
        }catch(exception ex){}
        ABSLI_BeforeUpdateAfterASFTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic(cases,cases);
        cccId.CCC_External_Id__c = 'PNFT008';
        cccId.IGMS_Code__c = '1';
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.ABSLI_Case_Detail__c = caseDetail.Id;
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Business_Unit__c = 'ABSLI';
            caseRec.Technical_Source__c = 'LWC';
            caseRec.AssetId = ast.Id;
            caseRec.CCC_External_Id__c = 'PNFT008';
            caseRec.Nature__c = 'Complaint';
            //caseRec.IRDAI_Token_Number__c = 'Test';
            cases.put(caseRec.Id,caseRec);
        }
        ABSLI_BeforeUpdateAfterASFTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic(cases,cases);
    }
    
    @Istest
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
                                  ABSLI_Case_Detail__r.IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c,IRDAI_Token_Number__c
                                  FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        ABSLI_BeforeUpdateAfterASFTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateAfterASFTriggerLogic.checkComplaintApplicability(cases.values(),cases,cases);
        cccId.IGMS_Code__c = '1';
        update cccId;
        caseDetail.Complaint_Category__c = 'Information';
        update caseDetail;
        cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,FTR__c,MoveToNext__c,Reopened_DateTime__c,Reject_Case__c,Nature__c,
                                  Is_Duplicate__c,Stage__c,pending_clarification__c,RecordTypeId,Business_Unit__c,Technical_Source__c,
                                  ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,
                                  ABSLI_Case_Detail__r.IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c,IRDAI_Token_Number__c
                                  FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        ABSLI_BeforeUpdateAfterASFTriggerLogic.absliCasesAdditionalFields = cases;
        ABSLI_BeforeUpdateAfterASFTriggerLogic.checkComplaintApplicability(cases.values(),cases,cases);
    }
}