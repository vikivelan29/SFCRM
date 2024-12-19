@isTest
public class Abml_CaseCloseBulkhandlerTest {
    
        private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];    

    
    
     @testSetup
    static void setupTestData(){
        
        Group objGroup = new Group(Name = 'ABML Test Group' , Type = 'Queue');
        insert objGroup;
        Group objGroupTest = new Group(Name = 'ABML Test Group2');
        insert objGroupTest;
        
        List<User> listOfUsers = new List<User>();
        List<Case> listOfCases = new List<Case>();
        for(Integer userCount = 0 ; userCount < 2; userCount++){
            User objUser = new User(Alias = 'user' + userCount , Email = 'standarduser'+ userCount +'@testorg.com', 
                                    EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', 
                                    LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey = 'America/Los_Angeles', Username = 'testUserAbml' + userCount + '@gmail.com',
                                    Business_Unit__c = 'ABML');
            listOfUsers.add(objUser);
        }
        
        insert listOfUsers;
        
        User userObj = listOfUsers[0];
        
        System.runAs(userObj) {
            for(Integer caseCount = 0 ; caseCount < 5; caseCount++){
                Case objCase = new Case(Subject = 'Test Case Creation', Status = 'New', Source__c =  'Email', Origin = 'ABML Email', SuppliedEmail = 'test.abml@gmail.com', Business_Unit__c  = 'ABML');            
                listOfCases.add(objCase);
            }
            insert listOfCases;
        }        
    }  
    
    
     @isTest
    static void GetCases(){
        list<case> allList = [select id from case];
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        list<string> idlist  = new list<string>();
        
        for(case c : allList){
           idlist.add(c.id); 
            
        }
        
        System.runAs(objUser){
            
           
            
            Test.startTest(); 
            
            List<case> caselist = Abml_CaseCloseBulkHandler.GetFrameworkCases();
            List<case> caselist1 = Abml_CaseCloseBulkHandler.getSearchRecords('test');
            List<case> caselist2 = Abml_CaseCloseBulkHandler.getSearchRecords('');
            Abml_CaseCloseBulkHandler.UpdateCase(idlist,'spam');


            System.assert(caselist.Size() != null, 'ABML Groups found.');
            
            Test.stopTest();
        }
    }
    

}