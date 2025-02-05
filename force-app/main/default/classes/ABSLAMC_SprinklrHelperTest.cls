@isTest
public class ABSLAMC_SprinklrHelperTest {
    
    @testSetup
    static void setupTestData() {
        
        Profile apiUserProfile = [SELECT Id FROM Profile WHERE Name = :ABSLAMC_Constants.APIUSERPROILENAME LIMIT 1];
        User apiUser = new User(
            Alias = 'apiUser',
            Email = 'apiuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = apiUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'apiuserABSLAMCTestUser@testorg.com'
        );
        insert apiUser;
        
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.CCC_External_Id__c = '123';
        ccc.Sub_Type__c = 'Type';
        ccc.Type__c = 'SubType';
        insert ccc;
        
        ASF_Case_Stage_Config__c csc = new ASF_Case_Stage_Config__c();
        csc.Case_Category_Config__c = ccc.Id;
        csc.StageName__c = 'Open';
        insert csc;
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.Display_Name__c = 'Sprinklr-UpdateFlow';
        integ.Case_Stage_Config__c = csc.Id;
        integ.Query_Fields__c = 'CaseNumber,CCC_External_Id__c,Description,Source__c,Business_Unit__c,Nature__c,LAN__c,Stage__c,Pending_Clarification__c,Sprinklr_Case_Reference_Number__c,Notes_from_Sprinklr__c,Latest_Notes__c';
        integ.Display_Order__c = 1;
        integ.Auto_Run_on_Load__c = true;
        integ.Run_Integration_From_LWC__c = true;
        
        //insert integ;
        
        Case testCase1 = new Case(
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            Source__c = 'Social Media',
            Stage__c = 'Open',
            Notes_from_Sprinklr__c = 'Initial Notes',
            Latest_Notes__c = 'Initial Latest Notes',
            OwnerId = apiUser.Id,
            CCC_External_Id__c = '123'
        );
        insert testCase1;
        
        
    }
    
    @isTest(SeeAllData = false)
    static void testCreateCaseComments() {
        
        Case testCase = [SELECT Id, Notes_from_Sprinklr__c, Latest_Notes__c, Business_Unit__c, Source__c FROM Case WHERE Source__c = 'Social Media' LIMIT 1];
        Map<Id, Case> oldMapCase = new Map<Id, Case> { testCase.Id => testCase };
            
        testCase.Notes_from_Sprinklr__c = 'Updated notes';
        testCase.Latest_Notes__c = 'New latest notes';
        update testCase;
        
        Case updatedCase = [SELECT Id, Notes_from_Sprinklr__c, Latest_Notes__c, Business_Unit__c, Source__c,OwnerId,CaseNumber,OwnerTeam__c FROM Case WHERE Source__c = 'Social Media' LIMIT 1];
        Map<Id, Case> newMapCase = new Map<Id, Case> { updatedCase.Id => updatedCase };
        User u = [SELECT Id FROM User WHERE Alias = 'apiUser' LIMIT 1];
      
        System.runAs(u) {
         
            Test.startTest();
            ABSLAMC_SprinklrHelper.caseCommentsToInsert.clear();
            ABSLAMC_SprinklrHelper.createCaseComments(newMapCase, oldMapCase);
            Test.stopTest();
           
            List<CaseComment> caseComments = [SELECT ParentId, CommentBody FROM CaseComment];
            System.assertEquals(1, caseComments.size(), 'A CaseComment should be created');
        }
    }
    
    @isTest
    static void testCallUpdateSprinklrAPI() {
        // Mock the external call response if needed or set required data
        List<Case> caseList = [SELECT Id, CCC_External_Id__c, Stage__c FROM Case WHERE Source__c = 'Social Media'];
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = ABSLAMC_SprinklrHelper.callUpdateSprinklrAPI(caseList);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Integration response should not be null');
    }
    
    @isTest
    static void testFireSystemNotification() {
              Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, CaseNumber, OwnerId, OwnerTeam__c FROM Case WHERE Source__c = 'Social Media']);
        String process = 'Notes update';
        Test.startTest();
        ABSLAMC_SprinklrHelper.fireSystemNotification(caseMap, process);
        Test.stopTest();
    }
    
    @isTest
    static void testBlankOutLatestNotes() {
        // Fetch initial and updated case data
        Map<Id, Case> oldMapCase = new Map<Id, Case>([SELECT Id,Business_Unit__c,Source__c, Latest_Notes__c FROM Case]);
        Map<Id, Case> newMapCase = new Map<Id, Case>([SELECT Id,Business_Unit__c,Source__c, Latest_Notes__c FROM Case]);
        
        Test.startTest();
        ABSLAMC_SprinklrHelper.blankOutLatestNotes(newMapCase, oldMapCase);
        Test.stopTest();
      
    }
}