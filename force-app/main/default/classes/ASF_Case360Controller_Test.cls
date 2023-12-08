/**
* @Class name:      ASF_Case360Controller_Test
* @Description:     
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee Churiwala             1.0       22/11/2023       Class to cover test cases ASF_Case360Controller
*/
@isTest
public class ASF_Case360Controller_Test {
     private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
	/********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      setup
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
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
            List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);
                    ASF_Case_Approv__c approver = new ASF_Case_Approv__c(Approver_01__c= userRecord3.Id,Approver_02__c= userRecord3.Id,
                                                             Approver_03__c= userRecord3.Id, Approver_04__c= userRecord3.Id,
                                                             Approver_05__c= userRecord3.Id,
                                                             SR__c =cases[0].Id,Approval_Type__c ='Parallel - All to approve', Requestor_Comments__c = 'approver created');
        insert approver;
        }
        

    }
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      fetchUserAndCaseDetailsTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void fetchUserAndCaseDetailsTest(){
        List<Case> cases = [select id from Case limit 1];
        
        test.startTest();
			ASF_Case360Controller.UserAndCaseWrapper wrapper = ASF_Case360Controller.fetchUserAndCaseDetails(cases[0].Id);
        test.stopTest();
        system.assertEquals(wrapper.isSuccess, true);
    }
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      moveToRequestedStageTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void moveToRequestedStageTest(){
        List<Case> cases = [select id from Case limit 1];
        
        test.startTest();
        	ASF_Case360Controller.moveToRequestedStage(cases[0].Id, 'In Progress', true);
        	List<Case> casesAfterUpdate = [select id,Stage__c from Case limit 1];
        	system.assertEquals(casesAfterUpdate[0].Stage__c, 'In Progress');
        test.stopTest();
    }
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      moveToNextStageTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void moveToNextStageTest(){
        List<Case> cases = [select id,PAY_Payment_Detail__c from Case limit 1];
        id currentUserId = UserInfo.getUserId();
        ASF_Case_Approv__c ca = new ASF_Case_Approv__c();
            ca.Approver_01__c  = currentUserId;
            ca.Approver_02__c  = currentUserId;
            ca.Approver_03__c  = currentUserId;
            ca.Approver_04__c  = currentUserId;
            ca.Approver_05__c  = currentUserId;
            ca.Approval_Type__c  = 'Parallel - All to approve';
            ca.SR__c  = cases[0].Id;
        	 try{
                insert ca;
            }
            catch(exception e){
                throw e;
            }
        test.startTest();
        String nextStage = ASF_Case360Controller.moveToNextStage(cases[0].Id);
        
        system.assertEquals(nextStage, 'Pending with Initiator');
        test.stopTest();
    }
    
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      moveToNextStageTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void updateCaseWithCaseExtnTest(){
        List<Case> cases = [select id,PAY_Payment_Detail__c from Case limit 1];
        
        test.startTest();
			SObject newCase = Case.SObjectType.newSObject();
            try {
                ASF_Case360Controller.updateCaseWithCaseExtn(cases[0], newCase);
            }
            catch(Exception e) {
                System.assertEquals(true,e.getMessage().contains('Id not specified'),'Success');
            }
        test.stopTest();
    }
}