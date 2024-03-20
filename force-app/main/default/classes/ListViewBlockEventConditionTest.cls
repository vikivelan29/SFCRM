@isTest
public class ListViewBlockEventConditionTest {
    
    
    @isTest
    public static void testListViewEvent(){
        User u = createCase();
        System.RunAs(u){
            Test.startTest();
            ListViewBlockEventCondition cond = new ListViewBlockEventCondition();
            ListViewEvent listEvent = new ListViewEvent();
            listEvent.UserId = u.Id;
            listEvent.ColumnHeaders = 'MobilePhone';
            system.assertEquals(true, cond.evaluate((sObject)listEvent));
            Test.stopTest();   
        }
    }
    
    @isTest
    public static void testReportViewEvent(){
        User u = createCase();
        System.RunAs(u){
            Test.startTest();
            ListViewBlockEventCondition cond = new ListViewBlockEventCondition();
            ReportEvent rEvent = new ReportEvent();
            rEvent.UserId = u.Id;
            rEvent.ColumnHeaders = 'MobilePhone';
            system.assertEquals(true, cond.evaluate((sObject)rEvent));
            Test.stopTest();  
        }
    }
    
    private static User createCase(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Payment Base Profile'];
        PermissionSetGroup  ps = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName ='Super_Admin'];
        UserRole ur = [SELECT ID FROM UserRole WHERE DeveloperName='Payments_Service_Agent' LIMIT 1];
        if (ps.Status != 'Updated') {
            //Test.calculatePermissionSetGroup(ps.Id);
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
    
}