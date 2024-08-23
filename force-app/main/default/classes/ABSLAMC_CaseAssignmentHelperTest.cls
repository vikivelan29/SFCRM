/****************************************************************************************************************
* Author       - Neeraj Kumar
* Date         - 21/08/2024
* @description -  Test class for ABSLAMC_CaseAssignmentHelper class.
*****************************************************************************************************************/
@IsTest
private class ABSLAMC_CaseAssignmentHelperTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Queue
        Group queue = new Group(
            Name = ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT, 
            Type = 'Queue'
        );
        insert queue;
        
        QueueSobject mappingObject = new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert mappingObject;
        }
        
        // Create test Case Detail records
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            Date_of_App_Support_Response__c = DateTime.now(),
            Date_of_Reply_back_to_App_Support__c = DateTime.now(),
            No_of_iterations__c = 0
        );
        insert caseDetail;
        
        Case case3 = new Case(
            Business_Unit__c = 'ABSLAMC',
            Stage__c = ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT,
            Source__c = 'Email',
            OwnerId = UserInfo.getUserId(),
            Escalation_Comment__c  = 'secondStageCase',
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert case3;
        
        // Insert ASF_Case_SLA_History__c records
        ASF_Case_SLA_History__c history = new ASF_Case_SLA_History__c(
            Case__c = case3.Id,
            Current_Owner_Id__c = queue.Id,
            Stage__c = 'Open'
        );
        insert history;
    }
    
    @IsTest
    static void testUpdateAssignmentOnStageChange() {
        
        Case caseRec1 = [SELECT Id, Stage__c,Business_Unit__c,OwnerId FROM Case WHERE Business_Unit__c = 'ABSLAMC' LIMIT 1];
        Map<Id, Case> newMapCase = new Map<Id, Case>([SELECT Id, Stage__c, Source__c, Business_Unit__c, OwnerId FROM Case WHERE Business_Unit__c = 'ABSLAMC']);
        Map<Id, Case> oldMapCase = new Map<Id, Case>([SELECT Id, Stage__c FROM Case WHERE Id IN :newMapCase.keySet()]);
        
        System.debug('Newcase: '+newMapCase.values());
        
        // Change the stage in newMapCase
        for (Case caseRec : newMapCase.values()) {
            caseRec.Stage__c = ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT;
        }
        System.debug('afterupdate: '+newMapCase.values());
        update newMapCase.values();
        // Call the method to be tested
        Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateAssignmentOnStageChange(newMapCase, oldMapCase);
        Test.stopTest();
        
        // Validate the result
        Case updatedCase = [SELECT OwnerId FROM Case WHERE Id =: caseRec1.Id];
        System.debug('final: '+updatedCase);
        System.assertNotEquals(caseRec1.OwnerId, updatedCase.OwnerId, 'Owner should have been updated.');
    }
    
    @IsTest
    static void testUpdateCaseExtensionFields() {
        // Retrieve the test data
        Case case1 = [SELECT Id, ABSLAMC_Case_Detail__c, Stage__c,Business_Unit__c FROM Case WHERE Business_Unit__c = 'ABSLAMC' LIMIT 1];
        Map<Id, Case> newMapCase = new Map<Id, Case>([SELECT Id, ABSLAMC_Case_Detail__c,Business_Unit__c, Stage__c FROM Case WHERE Business_Unit__c = 'ABSLAMC']);
        Map<Id, Case> oldMapCase = new Map<Id, Case>([SELECT Id, Stage__c FROM Case WHERE Id IN :newMapCase.keySet()]);
        
        // Change the stage in newMapCase
        for (Case caseRec : newMapCase.values()) {
            caseRec.Stage__c = 'Awaiting Response from App Support';
        }
        
        
        // Call the method to be tested
        Test.startTest();
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFields(newMapCase, oldMapCase);
        Test.stopTest();
        
        // Validate the result
        ABSLAMC_Case_Detail__c updatedCaseDetail = [SELECT Date_of_Reply_back_to_App_Support__c, No_of_iterations__c FROM ABSLAMC_Case_Detail__c WHERE Id = :case1.ABSLAMC_Case_Detail__c];
        System.assertNotEquals(null, updatedCaseDetail.Date_of_Reply_back_to_App_Support__c, 'Date_of_Reply_back_to_App_Support__c should have been updated.');
    }
     
}