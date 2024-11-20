/*********************************************************
** Class        :  MCRM_TestDataFactory
** Author       :  Zahed
** Description  :  Data Factory for Test Class
** Created Date :  19/Nov/2024
** Modified By :  
** Modified Date :  
** Parent Story Number : NA
*********************************************************/
public class MCRM_TestDataFactory {
    
    private final static Profile WELLNESS_PROFILE = [SELECT Id FROM Profile WHERE name='Wellness CRM Base Profile' LIMIT 1];
   
    
    /****************************************************
     * @Description - Create Wellness User
     * @param  -  NA
     * @return - User       
    *****************************************************/
    public static User createWellnessUser(){
        Group slaGroup = new Group();        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        insert slaGroup;

        User superManagerUser = new User(
            IsActive = true,
            FirstName = 'Test',
            LastName='Super Manager User Test 12',
            Username='supermanageruserTest12@test.com',
            Email='supermanageruserTest12@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = WELLNESS_PROFILE.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            managerGroupId__c=slaGroup.Id,
            Business_Unit__c = System.Label.Wellness_BU
        );
        insert superManagerUser;

        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = WELLNESS_PROFILE.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657123456@gmail.com',
                                   managerID = superManagerUser.Id, 
                                   Business_Unit__c = System.Label.Wellness_BU,
                                   managerGroupId__c=slaGroup.Id);
        insert userRecord;

        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        List<PermissionSet> permissionSetList = [SELECT Id
                            FROM PermissionSet
                            WHERE Name = 'Admin_User' Or Name = 'Wellness_CRM_User_PS'];
        for(PermissionSet ps : permissionSetList){
            psa.add(new PermissionSetAssignment(AssigneeId = userRecord.Id, PermissionSetId = ps.Id));
            psa.add(new PermissionSetAssignment(AssigneeId = superManagerUser.Id, PermissionSetId = ps.Id));
        }
        Insert psa;

        return userRecord;
    }
}