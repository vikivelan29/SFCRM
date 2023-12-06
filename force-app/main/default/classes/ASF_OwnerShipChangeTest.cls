@isTest
public with sharing class ASF_OwnerShipChangeTest {
    @testSetUp static void setUp(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 

         ID permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'By_Pass_Flow'].Id;

        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        list<User> userList =new List<User>();
        
        for(Integer i =0;i<5;i++){
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='TestUser'+i+1, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                          UserName='standarduser@test5sr'+i+1+'.com');
            userList.add(u);
        }

        Insert userList;
        
        for(User u : userList){
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permissionSetId, AssigneeId = u.Id);
            permissionSetList.add(psa);
        }
        
        upsert permissionSetList;

        List<User> usersToUpdate =new List<User>();
        for(Integer i=0;i<4;i++){
            Integer counter =i+1; 
            User tempUser =userList[i];
            tempUser.ManagerId =userList[counter].Id;
            usersToUpdate.add(tempUser);
        }
        Update usersToUpdate;
        System.runAs(new User(Id = userList[0].Id)){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createCaseRecords(1);
        }  
    }
     @isTest static void ownerShipChnageTestMethodLvl5(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser41'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
      @isTest static void ownerShipChnageTestMethodLvl4(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser31'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
     @isTest static void ownerShipChnageTestMethodLvl3(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser21'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
    @isTest static void ownerShipChnageTestMethodLvl2(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser11'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
    @isTest static  void ownerShipChnageTestMethodLvl1(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser01'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
}