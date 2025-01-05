/******************************************************  
* Author           - Souvik Gosh
* Date             - 27-November-2024
* Description      - Test class for ABML_Listviewcallout
********************************************************
*/
@isTest
public class ABML_Listviewcallout_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];    
    
    @testSetup
    static void setupTestData(){
        List<User> listOfUsers = new List<User>();
        for(Integer userCount = 0 ; userCount < 2; userCount++){
            User objUser = new User(Alias = 'user' + userCount , Email = 'standarduser'+ userCount +'@testorg.com', 
                                    EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', 
                                    LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey = 'America/Los_Angeles', Username = 'testUserAbml' + userCount + '@gmail.com',
                                    Business_Unit__c = 'ABML');
            listOfUsers.add(objUser);
        }
        
        insert listOfUsers;
    }

 @isTest
 static void testDocallout() {
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ABML_MockGenerator());
        ListView listView = [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType = 'Case' LIMIT 1];
        string res = ABML_Listviewcallout.doCallout(listView.id);
        System.assertEquals(2, listOfUsers.size(), 'List view callout Test!');
        Test.stopTest();
        }
    }
    
}
