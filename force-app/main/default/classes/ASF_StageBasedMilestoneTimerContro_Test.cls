/******************************************************  
* Author           - Shubham Sinha
* Date             - 27-Jan-2023
* Description      - Test class for ASF_StageBasedMilestoneTimerController
********************************************************
*/
@isTest
public class ASF_StageBasedMilestoneTimerContro_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    static void setupTestData() {
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                 LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                 TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
            insert userRecord;
        BusinessHours stdBusinessHours = [select Id From BusinessHours where IsDefault=true];
         List<Case> caseList = new List<Case>();
        for(Integer i=0;i<5;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email' ,BusinessHoursId =stdBusinessHours.Id, Subject = 'Test Case Creation', Stage__c = 'In Progress with CEC',
                                SLA_Target_1__c = 'test'+i+'@salesforce.com' );
            newCase.Stage_SLA_1__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            caseList.add(newCase);        
        }     
         for(Integer i=0;i<5;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email' ,BusinessHoursId =stdBusinessHours.Id, Subject = 'Test Case Over', Stage__c = 'New',
                                SLA_Target_1__c = 'test'+i+'@salesforce.com' );
            newCase.Stage_SLA_1__c = System.now()-2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            caseList.add(newCase);        
        }            
        insert caseList;
    }
    @isTest
    public static void testSLATest(){
        Case caseRecord = [SELECT Id,Stage__c FROM Case WHERE Stage__c = 'In Progress with CEC' LIMIT 1];
        Case caseRecordOver = [SELECT Id,Stage__c FROM Case WHERE Stage__c = 'New' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
        system.runAs(usr)
        {
        Test.startTest();          
        ASF_StageBasedMilestoneTimerController.getDataOnLoad(caseRecord.Id);
        //ASF_StageBasedMilestoneTimerController.fetchCustomMetadataStageSla();
        ASF_StageBasedMilestoneTimerController.getDataOnLoad(caseRecordOver.Id);
        Case cs = [SELECT Id,Subject,Stage__c
                    FROM Case WHERE Stage__c = 'New' LIMIT 1];
        Test.stopTest();     
        System.assertEquals('New', cs.Stage__c);        
        }
    }    

}