/****************************************************************************************************************
* Author       - Neeraj Kumar
* Date         - 21/08/2024
* @description -  Test class for ABSLAMC_CaseAssignmentHelper class.
*****************************************************************************************************************/
@isTest
public class ABSLAMC_CaseAssignmentHelperTest {
    
    @testSetup
    static void setupTestData() {
        Group queue = new Group(
            Name = ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT, 
            Type = 'Queue'
        );
        insert queue;
        
        QueueSobject mappingObject = new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert mappingObject;
        }
        
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            Date_of_App_Support_Response__c = DateTime.now(),
            Date_of_Reply_back_to_App_Support__c = DateTime.now(),
            No_of_iterations__c = 0,
            Reply_Type_for_CAMS__c = 'S'
        );
        insert caseDetail;
        
        
        Case testCase = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.OPEN_STAGE,
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert testCase;
        
        
        Case testCaseForStageUpdate = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.OPEN_STAGE,
            ABSLAMC_Case_Detail__c = caseDetail.Id,
            FTR__c = false
        );
        insert testCaseForStageUpdate;
        
        
        ABSLAMC_Case_Detail__c caseDetailForCams = new ABSLAMC_Case_Detail__c(
            Date_of_App_Support_Response__c = DateTime.now(),
            CAMS_Ticket_Reference_Number__c = 'REF12345',
            CAMS_Ticket_Status__c = ABSLAMC_Constants.CAMSCLOSEDSTATUS,
            No_of_iterations__c = 0,
            Reply_Type_for_CAMS__c = ABSLAMC_Constants.SATISFACTORYREPLYTYPE,
            Additional_Remarks_for_CAMS__c = 'Test remarks'
        );
        insert caseDetailForCams;
        
        
        Case testCaseforCams = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.OPEN_STAGE,
            ABSLAMC_Case_Detail__c = caseDetailForCams.Id
        );
        insert testCaseforCams;
        
        
        
        
        ASF_Case_SLA_History__c slaHistory = new ASF_Case_SLA_History__c(
            Case__c = testCase.Id,
            Stage__c = ABSLAMC_Constants.OPEN_STAGE,
            Current_Owner_Id__c = UserInfo.getUserId()
        );
        insert slaHistory;
    }
    
    @isTest
    static void testUpdateAssignmentOnStageChange() {
        
        Case testCase = [SELECT Id, Stage__c, Source__c, Business_Unit__c, OwnerId FROM Case LIMIT 1];
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            
            testCase.Stage__c = ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateAssignmentOnStageChange(newMapCase, oldMapCase);
        Test.stopTest();
        
        
        Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, updatedCase.OwnerId, 'The owner should have been updated');
    }
    
    @isTest
    static void testUpdateCaseExtensionFields() {
        Case testCase = [SELECT Id, ABSLAMC_Case_Detail__c,Business_Unit__c, Stage__c FROM Case LIMIT 1];
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            testCase.Stage__c = ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFields(newMapCase, oldMapCase);
        Test.stopTest();
        
        ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT Date_of_App_Support_Response__c FROM ABSLAMC_Case_Detail__c WHERE Id = :testCase.ABSLAMC_Case_Detail__c];
        System.assertNotEquals(null, updatedCaseDetail.Date_of_App_Support_Response__c, 'Date_of_App_Support_Response__c should have been updated');
    }
    
    
    @isTest
    static void testUpdateCaseStage() {
        Case testCase = [SELECT Id, FTR__c, Stage__c, Business_Unit__c FROM Case WHERE FTR__c = false LIMIT 1];
        Case oldTestCase = testCase.clone(false);
        oldTestCase.FTR__c = false;
        oldTestCase.Stage__c = ABSLAMC_Constants.OPEN_STAGE;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => oldTestCase };
            testCase.FTR__c = true;
        update testCase;
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseStage(newMapCase, oldMapCase);
        Test.stopTest();
        Case updatedCase = [SELECT Stage__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(ABSLAMC_Constants.RESOLVED_STAGE, updatedCase.Stage__c, 'The case stage should update to resolved');
    }
    
    @isTest
    static void testUpdateCaseStatusToReplyFromCAMS() {
        
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            CAMS_Ticket_Reference_Number__c = '12345',
            CAMS_Ticket_Status__c = ABSLAMC_Constants.CAMSCLOSEDSTATUS
            
        );
        insert caseDetail;
        Case testCase = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.REPLYFROMCAMS,
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert testCase;
        
        
        
        Case oldCase = [SELECT Id, Stage__c FROM Case WHERE Id = :testCase.Id];
        oldCase.Stage__c = ABSLAMC_Constants.CAMSPENDINGSTATUS;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => oldCase };
            testCase.Stage__c = ABSLAMC_Constants.REPLYFROMCAMS;
        update testCase;
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFieldsForCams(newMapCase, oldMapCase);
        Test.stopTest();
        ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT CAMS_Ticket_Reference_Number__c
                                                    FROM ABSLAMC_Case_Detail__c WHERE Id = :caseDetail.Id];
        System.assertEquals(null, updatedCaseDetail.CAMS_Ticket_Reference_Number__c, 
                            'CAMS ticket number should be blank');
    }
    
    @isTest
    static void testUpdateNoOfIterations() {
        
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            CAMS_Ticket_Reference_Number__c = '12345',
            CAMS_Ticket_Status__c = ABSLAMC_Constants.CAMSOPENSTATUS
        );
        insert caseDetail;
        Case testCase = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.REPLYFROMCAMS,
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert testCase;
        testCase.Stage__c = ABSLAMC_Constants.REPLYFROMCAMS;
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Case oldCase = [SELECT Id, Stage__c FROM Case WHERE Id = :testCase.Id];
        oldCase.Stage__c = ABSLAMC_Constants.CAMSPENDINGSTATUS;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => oldCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFieldsForCams(newMapCase, oldMapCase);
        Test.stopTest();
        ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT No_of_iterations__c
                                                    FROM ABSLAMC_Case_Detail__c WHERE Id = :caseDetail.Id];
        System.assertEquals(1, updatedCaseDetail.No_of_iterations__c, 
                            'No_of_iterations__c should be incremented.');
    }
    
    @isTest
    static void testUpdateMandatoryFieldsForReplyFromCAMS() {
        
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            Reply_Type_for_CAMS__c = '',
            Additional_Remarks_for_CAMS__c = ''
        );
        insert caseDetail;
        
        Case testCase = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.CAMSPENDINGSTATUS,
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert testCase;
     
            
            Case oldCase = [SELECT Id, Stage__c FROM Case WHERE Id = :testCase.Id];
        oldCase.Stage__c = ABSLAMC_Constants.REPLYFROMCAMS;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => oldCase };
            
               testCase.Stage__c = ABSLAMC_Constants.CAMSPENDINGSTATUS;
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
        Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFieldsForCams(newMapCase, oldMapCase);
        Test.stopTest();
        
        ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT Reply_Type_for_CAMS__c,Additional_Remarks_for_CAMS__c
                                                    FROM ABSLAMC_Case_Detail__c WHERE Id = :caseDetail.Id];
        System.assertEquals(true, String.isEmpty(updatedCaseDetail.Reply_Type_for_CAMS__c), 
                            'Reply Type should be blank.');
         System.assertEquals(true, String.isEmpty(updatedCaseDetail.Additional_Remarks_for_CAMS__c), 
                            'Additional Remarks should be blank.');
        
    }
    
    @isTest
    static void testUpdateInvalidReplyTypeForResolvedStage() {
        
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            Reply_Type_for_CAMS__c = 'Y'
            
        );
        insert caseDetail;
        Case testCase = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Stage__c = ABSLAMC_Constants.REPLYFROMCAMS,
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert testCase;
        testCase.Stage__c = ABSLAMC_Constants.RESOLVED_STAGE;
        
        Map<Id, Case> newMapCase = new Map<Id, Case>{ testCase.Id => testCase };
            
            Case oldCase = [SELECT Id, Stage__c FROM Case WHERE Id = :testCase.Id];
        oldCase.Stage__c = ABSLAMC_Constants.REPLYFROMCAMS;
        Map<Id, Case> oldMapCase = new Map<Id, Case>{ testCase.Id => oldCase };
            
            Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFieldsForCams(newMapCase, oldMapCase);
        Test.stopTest();
         ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT Reply_Type_for_CAMS__c
                                                    FROM ABSLAMC_Case_Detail__c WHERE Id = :caseDetail.Id];
        System.assertEquals('Y', updatedCaseDetail.Reply_Type_for_CAMS__c, 
                            'Reply Type should not be S');
    }
}