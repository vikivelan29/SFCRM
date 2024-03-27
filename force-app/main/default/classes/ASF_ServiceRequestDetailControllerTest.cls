@isTest 
private class ASF_ServiceRequestDetailControllerTest {
    
    @testSetup static void setup() {
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'abc';
        ccc.Sub_Type__c = 'xyz';
        ccc.CCC_External_Id__c = '12345';
        ccc.Technical_Source__c = 'LWC';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;
        
        ASF_Case_Stage_Config__c csc = new ASF_Case_Stage_Config__c();
        csc.Case_Category_Config__c = ccc.Id;
        csc.StageName__c = 'New';
        csc.Order__c = 1;
        insert csc; 
        
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        
        Case caser = new Case();
        caser.Origin = 'Email';
        caser.Subject = 'SR Case';
        caser.Stage__c = 'New';
        caser.Business_Unit__c= 'Payments';
        caser.BusinessHoursId = bh.Id;
        caser .CCC_External_Id__c = '12345';
        insert caser;
        
        List<ASF_Checklist__c> cList = new List<ASF_Checklist__c>();
        ASF_Checklist__c check = new ASF_Checklist__c();
        check.Label__c = 'Test 1';
        check.Status__c = 'Completed';
        check.Case__c = caser.Id;
        cList.add(check);
        
        ASF_Checklist__c checkP = new ASF_Checklist__c();
        checkP.Label__c = 'Test 2';
        checkP.Status__c = 'Pending';
        checkP.Case__c = caser.Id;
        cList.add(checkP);
        insert cList;
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            //User u = createCase();
        }
    }
    
    private static User createCase(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Payment Base Profile'];
        PermissionSetGroup  ps = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName ='Super_Admin'];
        UserRole ur = [SELECT ID FROM UserRole WHERE DeveloperName='Payments_Service_Agent' LIMIT 1];
        if (ps.Status != 'Updated') {
            Test.calculatePermissionSetGroup(ps.Id);
        }
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='TestUser5srDetail', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                              UserName='standarduser@test5srDetail.com'+System.now().millisecond(), UserRoleId = ur.Id);
        Insert u;
        List<PermissionSetAssignment> psAssign = new List<PermissionSetAssignment>();
            psAssign.add(new PermissionSetAssignment(AssigneeId = u.id, PermissionSetGroupId = ps.Id));
        Insert psAssign;
        return u;
    }
    
    @isTest static void testfetchSRStages() {
        Test.startTest();
        User uRec = [Select Id From User Limit 1];
        //System.runAs(uRec){
            List<String> strLst = ASF_ServiceRequestDetailController.fetchSRStages('abc', 'xyz');
            Assert.isTrue(strLst.size() > 0);
        //}
        Test.stopTest();
    }
    
    @isTest static void testisChecklistCompleted() {
        Test.startTest();
        User uRec = [Select Id From User Limit 1];
        //System.runAs(uRec){
            Case c = [Select Id From Case Limit 1];
            Boolean isCheck = ASF_ServiceRequestDetailController.isChecklistCompleted(c.Id);
            System.assertEquals(false,isCheck,'List of Checklist');
        //}
        Test.stopTest();
    }
}