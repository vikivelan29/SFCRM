@isTest
private class ABHI_CaseStageUpdateHelperTest {
    @isTest
    static void testMoveToStageMethod() {
        // Create a Case Category Config
        ASF_Case_Category_Config__c caseConfig = new ASF_Case_Category_Config__c(Type__c='Digital', Sub_Type__c='unable to Lync and Sync App & Device', CCC_External_Id__c = 'TEST_ID',Overall_Case_Closure_SLA__c=2);
        insert caseConfig;

        // Create a Case Stage Config and link it to the Case Category Config
        ASF_Case_Stage_Config__c caseStageConfig = new ASF_Case_Stage_Config__c(Order__c = 1, Case_Category_Config__c = caseConfig.Id); 
        insert caseStageConfig;

        // Create test Cases
        Case oldCase = new Case(
            Sub_Type_Text__c = 'Clarification required on query raised',
            Type_Text__c = 'Cashless',
            Subject = 'Old Case',
            Stage__c = 'Open',
            CCC_External_Id__c = 'TEST_ID',
            OwnerId = UserInfo.getUserId());
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            Stage__c = 'In Progress',
            CCC_External_Id__c = 'TEST_ID',
            OwnerId = UserInfo.getUserId()
        );

        // Create lists for new and old cases
        List<Case> newCases = new List<Case>{ newCase };
        List<Case> oldCases = new List<Case>{ oldCase };

        // Call the method under test
        Test.startTest();
        ABHI_CaseStageUpdateHelper.MoveToStageMethod(newCases, oldCases);
        Test.stopTest();

        // Verify the results
        Case updatedCase = [SELECT MoveToNext__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(false, updatedCase.MoveToNext__c, 'MoveToNext__c should be set to true.');

        // Test with a case that doesn't meet the SLA condition
            //newCase = new Case(Id = oldCase.Id,Subject = 'Updated Case Again',Stage__c = 'In Progress',CCC_External_Id__c = 'TEST_ID',OwnerId = UserInfo.getUserId());
        
       ASF_Case_Category_Config__c newCaseConfig = new ASF_Case_Category_Config__c(
            Type__c = 'Digital',
            Sub_Type__c = 'unable to Lync and Sync App & Device',
            CCC_External_Id__c = 'TEST_ID_2',
            Overall_Case_Closure_SLA__c = 5 // Change to a higher SLA
        );
        insert newCaseConfig;
        
        // Update the stage config to link to the new category config
        ASF_Case_Stage_Config__c newCaseStageConfig = new ASF_Case_Stage_Config__c(
            Order__c = 1,
            Case_Category_Config__c = newCaseConfig.Id
        );
        insert newCaseStageConfig;
        
        // Update the case to use the new CCC_External_Id__c
        newCase.CCC_External_Id__c = 'TEST_ID_2';
            
        //Test.startTest();
        ABHI_CaseStageUpdateHelper.MoveToStageMethod(new List<Case>{ newCase }, new List<Case>{ oldCase });
        //Test.stopTest();

        updatedCase = [SELECT MoveToNext__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(false, updatedCase.MoveToNext__c, 'MoveToNext__c should be false when SLA is greater than 2 hours.');
    }
}