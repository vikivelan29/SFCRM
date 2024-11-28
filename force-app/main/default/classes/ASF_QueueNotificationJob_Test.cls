@isTest 
public class ASF_QueueNotificationJob_Test {
    public static List<String> caseList;
    public static Map<String, Case> caseNumberRecordMap;

    @testSetup 
    static void setup() {
        // Create Parent Group
        Group testGroup = new Group();
        testGroup.name = 'Test SR Queue';
        testGroup.Type = 'Queue'; 
        testGroup.Email = 'abc@testsr.com';
        Insert testGroup; 
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
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
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        insert stage1;
        
        Datetime currentTime = Datetime.now();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        
        Case caser = new Case();
        caser.Origin = 'Email';
        caser.Subject = 'SR Case';
        caser.Stage__c = 'New';
        caser.BusinessHoursId = bh.Id;
        caser.CCC_External_Id__c = '12345';
        caser.Last_Owner_Change_Date__c = system.now().addHours(-5);
        caser.OwnerId = testGroup.Id;
        insert caser; 
        
        Case testCase1 = new Case();
        testCase1.Origin = 'Email';
        testCase1.Subject = 'SR Case1';
        testCase1.Stage__c = 'New';
        testCase1.BusinessHoursId = bh.Id;
        testCase1.CCC_External_Id__c = '12345';
        testCase1.Last_Owner_Change_Date__c = System.now();
        testCase1.OwnerId = testGroup.Id;
        insert testCase1; 
        
        Case testCase2 = new Case();
        testCase2.Origin = 'Email';
        testCase2.Subject = 'SR Case2';
        testCase2.Stage__c = 'New';
        testCase2.BusinessHoursId = bh.Id;
        testCase2.CCC_External_Id__c = '12345';
        testCase2.Last_Owner_Change_Date__c =Datetime.newInstance(System.now().date().addDays(-70),System.now().time());
        testCase2.OwnerId = testGroup.Id;
        insert testCase2;
        
        testCase2.Last_Owner_Change_Date__c =Datetime.newInstance(System.now().date().addDays(-70),System.now().time());
        update testCase2;
        
        caseList = new List<String>();
        caseList.add(string.valueof(testCase1.Id));
        caseList.add(string.valueof(testCase2.Id));
        
        caseNumberRecordMap = new Map<String, Case>();
        caseNumberRecordMap.put(testCase1.Id, testCase1);
        caseNumberRecordMap.put(testCase2.Id, testCase2);
        
        ASF_Case_SLA_History__c his = new ASF_Case_SLA_History__c();
        his.Case__c = caser.Id;
        his.Stage_Start_Date__c = currentTime.addDays(-2);
        his.BusinessHoursId__c = bh.Id;
        his.Breached_User_Id__c = testGroup.Id;
        his.Stage__c = 'New';
        insert his;
    }
    
    @isTest 
    static void testfetchSRStages() {
        List<Case> fetchedCaseList = [select id, CaseNumber, Type_Text__c, Sub_Type_Text__c, Last_Owner_Change_Date__c from case where Subject = 'SR Case1' OR Subject = 'SR Case2' ];
        List<String> Caseid = new List<String>();
        Map<String, Case> fetchcaseMap = new Map<String,Case>();
        
        for (case cs : fetchedCaseList) {
            Caseid.add(cs.id);
            fetchcaseMap.put(cs.id, cs);
        }
        // Assert that the fetched cases have the expected fields populated
        for (Case cs : fetchedCaseList) {
            System.assertNotEquals(null, cs.CaseNumber, 'Case Number should not be null');
            System.assertNotEquals(null, cs.Last_Owner_Change_Date__c, 'Last Owner Change Date should not be null');
        }
        
        Map<String, Case> fetchedCaseNumberRecordMap = ASF_QueueNotificationJob_Test.caseNumberRecordMap;
        // Assertion to check the size of fetchedCaseList
        System.assertEquals(2, fetchedCaseList.size(), 'Incorrect number of cases retrieved');
        
        Test.startTest();
        ASF_QueueNotificationJob obj = new ASF_QueueNotificationJob();
        ASF_QueueNotificationJob.getTableEmailBody(Caseid, fetchcaseMap);
        obj.execute(null);
        Test.stopTest();
        
        
    }
}