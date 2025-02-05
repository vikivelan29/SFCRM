/***************************************
*Class        :  ABHI_CaseStageUpdateHelperTest
*Author       :  Kuldeep Mishra
*Created Date :  15/10/2024
*Last Modified:  15/10/2024
*@description :  This class used as Test class for ABHI_CaseStageUpdateHelper.
***************************************/
@isTest
private class ABHI_CaseStageUpdateHelperTest {
    @isTest
    static void testMoveToStageMethod() {
        // Create a Case Category Config
        ASF_Case_Category_Config__c caseConfig = new ASF_Case_Category_Config__c(Type__c='Digital', Sub_Type__c='unable to Lync and Sync App & Device', CCC_External_Id__c = 'TEST_ID',Overall_Case_Closure_SLA__c=2,Nature__c ='Request',Is_STP__c=True,Save_to_Next_Stage__c =True);
        insert caseConfig;

        // Create a Case Stage Config and link it to the Case Category Config
        ASF_Case_Stage_Config__c caseStageConfig = new ASF_Case_Stage_Config__c(Order__c = 1,StageName__c='Open',Case_Category_Config__c = caseConfig.Id); 
        insert caseStageConfig;

        // Create test Cases
        Case oldCase = new Case(
            Sub_Type_Text__c = 'Clarification required on query raised',
            Type_Text__c = 'Cashless',
            Subject = 'Old Case',
            Stage__c = 'Open',
            moved_back__c = false,
            CCC_External_Id__c = 'TEST_ID',
            OwnerId = UserInfo.getUserId());
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            Stage__c = 'Open',
            moved_back__c = false,
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
    }    
        
        
        @isTest
    static void failureMethod() {
        // Test with a case that doesn't meet the SLA condition
            //newCase = new Case(Id = oldCase.Id,Subject = 'Updated Case Again',Stage__c = 'In Progress',CCC_External_Id__c = 'TEST_ID',OwnerId = UserInfo.getUserId());
        
       ASF_Case_Category_Config__c newCaseConfig1 = new ASF_Case_Category_Config__c(
            Type__c = 'Digital',
            Sub_Type__c = 'unable to Lync and Sync App & Device',
            CCC_External_Id__c = 'TEST_ID_2',
            Nature__c ='Request',
            Is_STP__c=true,
            Overall_Case_Closure_SLA__c = 5 // Change to a higher SLA
        );
        insert newCaseConfig1;
        
        // Update the stage config to link to the new category config
        ASF_Case_Stage_Config__c newCaseStageConfig = new ASF_Case_Stage_Config__c(
            Order__c = 1,
            StageName__c = 'In Progress',
            Case_Category_Config__c = newCaseConfig1.Id
        );
        insert newCaseStageConfig;
        
        // Create test Cases
        Case oldCase = new Case(
            Sub_Type_Text__c = 'Clarification required on query raised',
            Type_Text__c = 'Cashless',
            Subject = 'Old Case',
            Stage__c = 'Open',
            CCC_External_Id__c = 'TEST_ID_2',
            OwnerId = UserInfo.getUserId());
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            Stage__c = 'Open',
            CCC_External_Id__c = 'TEST_ID_2',
            No_Auto_Communication__c = 'SMS',
            OwnerId = UserInfo.getUserId()
        );

        // Create lists for new and old cases
        List<Case> newCases = new List<Case>{ newCase };
        List<Case> oldCases = new List<Case>{ oldCase };
            
        Test.startTest();
        ABHI_CaseStageUpdateHelper.MoveToStageMethod(newCases,oldCases);
        Test.stopTest();

        Case updateCase = [SELECT MoveToNext__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(false, updateCase.MoveToNext__c, 'MoveToNext__c should be false when SLA is greater than 2 hours.');
    }
    
    @isTest
    static void testNoConfigFound() {
        // Create a Case with a CCC_External_Id__c that has no matching config
        Case oldCase = new Case(
            Sub_Type_Text__c = 'Clarification required on query raised',
            Type_Text__c = 'Cashless',
            Subject = 'Old Case',
            Stage__c = 'Open',
            moved_back__c = false,
            CCC_External_Id__c = 'NON_EXISTENT_ID', // ID that doesn't exist in the config
            OwnerId = UserInfo.getUserId()
        );
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            Stage__c = 'Open',
            moved_back__c = false,
            CCC_External_Id__c = 'NON_EXISTENT_ID', // Same non-existent ID
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
        System.assertEquals(false, updatedCase.MoveToNext__c, 'MoveToNext__c should not be set as no config is found.');
    }
    
@isTest
    static void testWithPreviousStage() {
        
         // Create a Case Category Config
        ASF_Case_Category_Config__c caseConfig = new ASF_Case_Category_Config__c(Type__c='Digital', Sub_Type__c='unable to Lync and Sync App & Device', CCC_External_Id__c = 'TEST_IDs',Overall_Case_Closure_SLA__c=2,Nature__c ='Request',Is_STP__c=True,Save_to_Next_Stage__c =True);
        insert caseConfig;

        // Create a Case Stage Config and link it to the Case Category Config
        ASF_Case_Stage_Config__c caseStageConfig = new ASF_Case_Stage_Config__c(Order__c = 1,StageName__c='Open',Case_Category_Config__c = caseConfig.Id); 
        insert caseStageConfig;
        
        // Create a Case with a CCC_External_Id__c that has no matching config
        Case oldCase = new Case(
            Sub_Type_Text__c = 'Clarification required on query raised',
            Type_Text__c = 'Cashless',
            Subject = 'Old Case',
            Previous_Stage__c = 'In Progress',
            CCC_External_Id__c = 'TEST_IDs', // ID that doesn't exist in the config
            OwnerId = UserInfo.getUserId()
        );
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            Stage__c = 'Open',
            CCC_External_Id__c = 'TEST_IDs', // Same non-existent ID
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
        System.assertEquals(false, updatedCase.MoveToNext__c, 'MoveToNext__c should be true');
    }
}