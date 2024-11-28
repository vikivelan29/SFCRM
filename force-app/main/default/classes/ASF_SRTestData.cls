/*********************************************************
*Class        :  ASF_SRTestData
*Author       :  Salesforce.com
*Description  :  Test data factory for SR data
*********************************************************/
@isTest
public class ASF_SRTestData {
    public static list<User> createUsers(String permissionsetName, Integer numberOfRecords){
        list<User> userList =new List<user>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Payment Base Profile'];
        PermissionSetGroup  ps = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName =: permissionsetName];
        if (ps.Status != 'Updated') {
      Test.calculatePermissionSetGroup(ps.Id);
        }
        for(Integer i =0; i<numberOfRecords; i++){
           User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='TestUser5srDetail'+i, LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                              UserName='standarduser@test5srDetail'+i+'.com'+System.now().millisecond());
           userList.add(u);
        }
        Insert userList;
         List<PermissionSetAssignment> psAssign = new List<PermissionSetAssignment>();
        for(User u :userList){
            psAssign.add(new PermissionSetAssignment(AssigneeId = u.id, PermissionSetGroupId = ps.Id));
        }
        Insert psAssign;
        return userList;
    } 
}