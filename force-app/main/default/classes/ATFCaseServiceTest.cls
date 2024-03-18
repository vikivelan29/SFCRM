/**
 * @description       : Test class for ATFCaseService Methods
 * @author            : shubham.sinha@salesforce.com
 * @group             : 
 * @last modified on  : 03-16-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-16-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public with sharing class ATFCaseServiceTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
		List<Group> lSLAGroup = new List<Group>();        
        lSLAGroup.add(new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup'));
        lSLAGroup.add(new Group(Name='OCC-Test-Group', type='Queue'));
		insert lSLAGroup;

		User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                managerGroupId__c=lSLAGroup[0].Id);
    	insert userRecord;

    	System.runAs(userRecord) {
            Case newCase = new Case();
            newCase.Subject = 'Test Case Creation';
            newCase.CCC_External_Id__c ='' ;
            newCase.Source__c =  'Email';
            newCase.Stage__c = 'Email';
            newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
            newCase.Business_Unit__c  = 'ABFL'; 
            insert newCase; 
        	if(newCase.Id != null){
                EmailMessage eMsg = new EmailMessage();
                eMsg.ParentId = newCase.Id;
                eMsg.ToAddress = 'abaasscl.abfl@gmail.com';
                eMsg.CCAddress = 'tesasst@test.com';
                eMsg.FromAddress  = 'test@test.com';
                eMsg.Incoming = true;
                insert eMsg;
                // deliver PE
                Test.getEventBus().deliver();
        	}
    	}
    }
    
    @isTest   
    static void updateIncomingEmailCountTestMethod(){
        List<Case> objCase = [Select Id,ABFL_Incoming_Email_Count__c From Case WHERE Subject = 'Test Case Creation' LIMIT 1];
        System.debug('***objCase:'+objCase[0].ABFL_Incoming_Email_Count__c);
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        system.runAs(usr){
        Test.startTest(); 
            // EventBus.publish();
            System.assertNotEquals(0, objCase[0].ABFL_Incoming_Email_Count__c,'Zero Count');
        Test.stopTest(); 
        }
    }
}