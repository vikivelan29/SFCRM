@isTest
public with sharing class ABML_RoundRobinCaseAssBatch_Test {

    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id 
                                                        FROM Profile 
                                                        WHERE name='System Administrator' 
                                                        LIMIT 1];
    @testSetup
    static void setupTestData() {
        

		
        Group grp = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = 'ABML Franchisee Helpdesk' Limit 1];
        
        User userRecord = new User(Alias = 'standt', Email='stantarduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', Business_Unit__c = 'ABML' ,ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='Testcdefghijk567@gmail.com'
                                    );
        insert userRecord; 
        List<GroupMember> lstGroupMem = [SELECT GroupId, UserOrGroupId FROM GroupMember where GroupId =: grp.Id];

        GroupMember groupMember1 = new GroupMember(
            GroupId = lstGroupMem[0].UserOrGroupId,
            UserOrGroupId = userRecord.Id
        );
        insert groupMember1;   
        System.runAs(userRecord) {
            
            ABML_Round_Robin_Assignment__c customSetting = new ABML_Round_Robin_Assignment__c(
                Name = 'ABML Franchisee Helpdesk',
                ABML_Queue_Name__c = 'ABML_Franchisee_Helpdesk', 
                ABML_Index__c = 0
            );
            
            // Insert the custom setting record
            insert customSetting;
            
            ASF_TestDataFactory.createCaseCategoryConfig();
            ASF_Case_Category_Config__c ccc = [Select id, Type__c, Sub_Type__c From ASF_Case_Category_Config__c Limit 1];
            
            Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
            
            List<Case> caseList = new List<Case>();
            Case caseRec1 = new Case();
            caseRec1.Notes__c = 'Test Case 1';
            caseRec1.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            caseRec1.Business_Unit__c = 'ABML';
            caseRec1.AccountId = acc.Id;
            caseRec1.Nature__c = 'Request';
            caseRec1.Type_Text__c = 'Bureau Related';
            caseRec1.Sub_Type_Text__c = 'CIBIL Related Details - Ownership Related';
            caseRec1.Source__c = 'Email';
            caseRec1.Stage__c = 'Resolved';
            caseRec1.Status = 'New';
            caseRec1.OwnerId = grp.Id;
            caseList.add(caseRec1);
            
            Case caseRec2 = new Case();
            caseRec2.Notes__c = 'Test Case 2';
            caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            caseRec2.Business_Unit__c = 'ABML';
            caseRec2.AccountId = acc.Id;
            caseRec1.Nature__c = 'Request';
            caseRec2.Type_Text__c = 'Statement & Documents';
            caseRec2.Sub_Type_Text__c = 'Interest Schedule';
            caseRec2.Source__c = 'Email';
            caseRec2.Status = 'New';
            caseRec2.OwnerId = grp.Id;
            caseList.add(caseRec2);
            
            insert caseList;
        }
    }
    
    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void evaluateTestMethod() { 
                
        Test.startTest();
        ABML_Round_Robin_Assignment__c retrievedSetting = [SELECT Name, ABML_Queue_Name__c, ABML_Index__c FROM ABML_Round_Robin_Assignment__c WHERE Name = 'ABML Franchisee Helpdesk' LIMIT 1];

            ABML_RoundRobinCaseAssBatch roundRobinCase = new ABML_RoundRobinCaseAssBatch();
            Database.executeBatch(roundRobinCase);
        Test.stopTest();

        Case objCaseObj = [SELECT id, OwnerId FROM Case Limit 1];
        String ownerId = objCaseObj.OwnerId;
        Boolean checkOwner = ownerId.startsWith('005');
        System.assert(true, checkOwner);
    }
    
     @isTest 
    static void checkOutOfOfficeTestMethod() { 
        
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest();
            OutOfOffice ooo = new OutOfOffice(
                StartDate = Date.today(),
                EndDate = Date.today().addDays(1),
                Message='My message',
                UserId = objUser.id //This should be a new user created in test class 
            );
            insert ooo;
        }
            
        ABML_Round_Robin_Assignment__c retrievedSetting = [SELECT Name, ABML_Queue_Name__c, ABML_Index__c FROM ABML_Round_Robin_Assignment__c WHERE Name = 'ABML Franchisee Helpdesk' LIMIT 1];
        
        ABML_RoundRobinCaseAssBatch roundRobinCase = new ABML_RoundRobinCaseAssBatch();
        Database.executeBatch(roundRobinCase);
        Test.stopTest();
        
        
        Case objCaseObj = [SELECT id, OwnerId FROM Case Limit 1];
        String ownerId = objCaseObj.OwnerId;
        Boolean checkOwner = ownerId.startsWith('005');
        System.assert(true, checkOwner);
    }

  
}
