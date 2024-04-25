/*********************************************************
 *Class        :  ABCL_BaseViewController_Test
 *Author       :  Udit Singhal
 *Created Date :  14/03/2024
 *Last Modified:
 *Description  :  Test Class for ABCL_BaseViewController
 *********************************************************/
@isTest
public class ABCL_BaseViewController_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id
                                                        FROM Profile
                                                        WHERE name = 'System Administrator'
                                                        LIMIT 1];
    @TestSetup
    static void makeData(){
        Group slaGroup = new Group();

        slaGroup = new Group(
            Name = 'SLAManagerGroup', 
            DeveloperName = 'SLAManagerGroup'
        );
        insert slaGroup;
        User userRecord1 = new User(
            Alias = 'standt', 
            Email = 'stanrduserEmails@testorg.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567@gmail.com', 
            managerGroupId__c = slaGroup.Id
        );
        insert userRecord1;

        Test.startTest();
        PermissionSet ps = [SELECT Id
                            FROM PermissionSet
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(
            AssigneeId = userRecord1.Id, 
            PermissionSetId = ps.Id
        );
        Test.stopTest();
    }

    @isTest
    static void testGetDynamicScreen(){
        Test.startTest();
        ABCL_BaseViewController.ResponseWrapper res = ABCL_BaseViewController.getDynamicScreen('RTL_RealTime_LoanMIS');
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }
    
    @isTest
    static void testGetDynamicScreen2(){
        Test.startTest();
        ABCL_BaseViewController.ResponseWrapper res = ABCL_BaseViewController.getDynamicScreen('RTL_RealTime_GetCRMDetails');
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }
}