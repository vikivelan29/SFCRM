/**
* @Class name:      ASF_CaseSLAHandlerV1_Test
* @Description:     
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Rajender Kumar             1.0       23/11/2023       Class to cover test cases ASF_CaseSLAHandlerV1
*/
@isTest
public class ASF_CaseSLAHandlerV1_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    public static void setup() {
        
        String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer intRandomValue = Integer.valueOf(math.rint(math.random() * 1000000));
        String strUniqueName = strDate + intRandomValue;
        List<Case> caseList = new List<Case>();
        List<User> userList = new List<User>();
        // insert 10 accounts
        
        //  Id permissionSetId = [Select Id,Name from PermissionSet where Name ='Create_Case_Case_Framework'].get(0).Id;
        
        integer j = 1;
        // for(Integer j=0;j<2;j++){
        
        User manager2 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'manager2@salesforce.com',
                                 Username = 'manager2'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                 alias = 'manager2', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                 languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        
        insert manager2;
        
        
        User manager1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'manager1@salesforce.com',
                                 Username = 'manager1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                 alias = 'manager1', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                 languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,ManagerId=Manager2.Id);
        
        insert manager1;
        
        User objUser;
        
        objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test'+j+'@salesforce.com',
                           Username = 'Test'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,ManagerId=manager1.Id);
        
        insert objUser;   
        
        User userRecord2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles',managerID = manager1.Id, UserName='abdehijk56@gmail.com');
        insert userRecord2; 
        User userRecord3 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, managerID = manager1.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='abefghijk5@gmail.com');
        insert userRecord3;
        
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;
        
        System.runAs(manager1) {
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
            ASF_TestDataFactory.createCaseCategoryConfig();
            List<Case> caseL = ASF_TestDataFactory.createCaseRecords(1);
                    ASF_Case_Approv__c approver = new ASF_Case_Approv__c(Approver_01__c= userRecord3.Id,Approver_02__c= userRecord3.Id,
                                                             Approver_03__c= userRecord3.Id, Approver_04__c= userRecord3.Id,
                                                             Approver_05__c= userRecord3.Id,
                                                             SR__c =caseL[0].Id,Approval_Type__c ='Parallel - All to approve', Requestor_Comments__c = 'approver created');
        	insert approver;
        }
        

    }
	@isTest
    public static void moveToRequestedStageTest(){
        BusinessHours bHours =[SELECT Id, Name, IsActive FROM BusinessHours LIMIT 1];
        List<Case> cases =[SELECT Id, Owner.Name, BusinessHoursId,Status, Stage__c,Bulk_Action__c,CCC_External_Id__c,OwnerId,Reopened__c from Case];
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        for(Case c : cases){
            ASF_Case_SLA_History__c slaHistory = new ASF_Case_SLA_History__c();
            slaHistory.Current_Owner__c = c.Owner.Name;
            slaHistory.Current_Owner_Id__c = c.OwnerId;
            slaHistory.Case__c = c.Id;
            slaHistory.Stage__c = c.Stage__c;
            slaHistory.Status__c = c.Status;
            //if stage is blank , then probbaly email2Case
            if(String.isBlank(slaHistory.Stage__c)){
                slaHistory.Stage__c = slaHistory.Status__c;    
            }
            slaHistory.Stage_Start_Date__c = system.now();
            //slaHistory.Stage_Violation_Start_Date__c = system.now();
            slaHistory.is_Running_Record__c = true;
            slaHistory.BusinessHoursId__c = bHours.Id;
            
            slaHistoryList.add(slaHistory);
        }
        
        if(!slaHistoryList.isEmpty()){
            
            insert slaHistoryList;
            
        }
        test.startTest();
        	ASF_Case360Controller.moveToRequestedStage(cases[0].Id, 'In Progress', true);
        	ASF_CaseSLAHandlerV1.calculateSLAOnCaseInsert(cases);
        test.stopTest();
        List<Case> updatedCases = [SELECT Id, Owner.Name, BusinessHoursId, Status, Stage__c, Bulk_Action__c, CCC_External_Id__c, OwnerId, Reopened__c FROM Case WHERE Id = :cases[0].Id];
        System.assertNotEquals(null, updatedCases[0].Id, 'Case Id should not be null');
        System.assertEquals('In Progress', updatedCases[0].Stage__c, 'Case should be moved to the requested stage');
    }
}