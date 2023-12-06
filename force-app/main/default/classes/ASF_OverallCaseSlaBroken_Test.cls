@isTest
public class ASF_OverallCaseSlaBroken_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setupTestData(){
        
        list<user> userList = new list<User>();
        for(integer i=0;i<3;i++){
            User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                        EmailEncodingKey='UTF-8', LastName='GroupTesting', LanguageLocaleKey='en_US', 
                                        LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                        TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk'+i+'56@gmail.com');
            userList.add(userRecord1);
        }
        
        insert userList;
        
        Group SLAGroup = new Group();
        system.runAs(userList.get(0)){
            SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert SLAGroup;
            
            for(integer i=0;i<3;i++){
                GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userList.get(i).Id);
                insert gm;
            }
            
            
        }
        
        
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
        insert userRecord1;
        
        
        
        Account acc= new Account(
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            Client_Code__c= 'abcd',
            Line_Of_Business__c = 'Payments',
            Business_Unit__c = 'Payments',
            RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId()
        );
        insert acc;  
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
        insert lob;
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
        insert ast;
        group q = new group();
        q.name = 'OCC-Test-Group';
        q.type = 'Queue';
        insert q;
        ASF_TestDataFactory.createCaseCategoryConfig(); 
       ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
       ccc.Type__c = 'tes';
       ccc.CCC_External_Id__c = '12345';
       ccc.Business_Unit__c = 'ABFL';
       ccc.Sub_Type__c = 'TDC Refund';
       ccc.Overall_Case_Closure_SLA__c = 10;
       insert ccc;
       ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
       stage1.Case_Category_Config__c = ccc.Id;
       stage1.Order__c = 1;
       stage1.StageName__c = 'New';
       stage1.Stage_SLA_1__c = 1;
       stage1.Status_Mapping__c = 'New';
       // stage1.Stage_SLA_3__c = 3;
       stage1.SLA_Target_1_Type__c = 'Manager';
       stage1.Query_Fields__c = 'Id,Stage__c';
       stage1.Manual_Stage__c = false;
       
       insert stage1;
       insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
       
    }
    
    
    @isTest
    public static void testSendEmailSLABroke(){
        
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email' , SLA_Broken__c = false, Subject = 'Test Case Creation', Stage__c = 'New',
                                SLA_Target_1__c = 'amundada@salesforce.com',CCC_External_Id__c = '12345');
        newCase.Stage_SLA_1__c = datetime.newInstance(2022, 3, 06 , 1, 30, 0);
        
        insert newCase;
        
        List<String> casesList = new List<String>();
        List<Case> caseObj = [Select Id,Status,Origin,SLA_Broken__c from Case];
        
        for(Case s:caseObj){
            casesList.add(s.Id);
        }
        
        Test.startTest();
        
        ASF_CaseSLABroken.sendEmailSLABroke(casesList);
        
        Test.stopTest();
        
        List<ASF_Case_SLA_History__c> slaHistoryList = [SELECT Id, 
                                                    Breached_User_Level1__c,
                                                    Case__c,
                                                    Case__r.Stage_SLA_1__c,
                                                    Case__r.CaseNumber,
                                                    Case__r.SLA_Target_1__c,
                                                    Stage__c,
                                                    Stage_Violation_Start_Date__c,
                                                    Current_Owner_Id__c,
                                                    Current_Owner__c,
                                                    Level__c,
                                                    is_Running_Record__c
                                                    FROM
                                                    ASF_Case_SLA_History__c ];
        
        List<Case> newCaseList = new List<Case>();
        newCaseList = [Select Id,SLA_Broken__c from case where Id =: newCase.Id];
        
        System.debug('newCaseList'+newCaseList);
        System.assert(true,newCaseList[0].SLA_Broken__c);
        System.debug('slaHistoryList'+slaHistoryList);
        
    }
    
    @isTest
    public static void testSLA1ManagerGroup(){
        
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
        Case c = CaseList.get(0);
        //c.status = 'Closed';
        c.ownerid = [SELECT Id from User where username='cdefghijk56@gmail.com'].get(0).Id;
        DateTime cv = System.now();
        //c.Stage_SLA_1__c = cv.addHours(-3);
        //c.Stage_SLA_2__c = cv.addHours(2);
        //c.Stage_SLA_3__c = cv.addHours(1);
        c.SLA_Target_1__c = null;
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(-2);
        c.Stage_SLA_3__c = cv.addHours(1);
        update c; 
        List<Id> cList = new List<Id>();
        cList.add(c.Id);
        
        
        // c.SLA_Target_1__c = 'stanrduserEmails@testorg.com';
        // c.SLA_Target_2__c = 'stanrduserEmails@testorg.com';
        Test.startTest();
        ASF_CaseSLABroken.sendEmailSLABroke(cList);
        Test.stopTest();
        Integer hisListCount = [SELECT Count() FROM ASF_Case_SLA_History__c];
        Assert.isTrue(hisListCount > 0);
    }
    
    
    @isTest
    public static void testOverallSLABroken(){
        
        
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email' , SLA_Broken__c = false, Subject = 'Test Case Creation', Stage__c = 'New',
                                SLA_Target_1__c = 'amundada@salesforce.com',CCC_External_Id__c = '12345' );
        newCase.Stage_SLA_1__c = datetime.newInstance(2022, 3, 06 , 1, 30, 0);
        
        insert newCase;
        
        List<String> casesList = new List<String>();
        
        
        casesList.add(newCase.Id);
        
        ASF_OverallCaseSlaBroken.Request req = new ASF_OverallCaseSlaBroken.Request();
        req.caseId = newCase.Id;
        req.isReopened = false;
        List<ASF_OverallCaseSlaBroken.Request> requests = new List<ASF_OverallCaseSlaBroken.Request>();
        requests.add(req);
        ASF_OverallCaseSlaBroken.ASF_OverallCaseSlaBroken(requests);
        System.assert(true,newCase.SLA_Broken__c);
        
    }
    
}