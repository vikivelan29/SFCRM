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
            
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
            
            
            ASF_TestDataFactory.createCaseCategoryConfig();
            ASF_TestDataFactory.createCaseRecords(1);
            
            
        }  
    }
    @isTest static void ownerShipChnageTestMethodLvl5(){
        test.startTest();
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser41'];
        BusinessHours bh = [SELECT ID FROM BusinessHours WHERE isDefault = true];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            DateTime cv = System.now();
            //c.Stage_SLA_1__c = cv.addHours(-3);
            //c.Stage_SLA_2__c = cv.addHours(2);
            //c.Stage_SLA_3__c = cv.addHours(1);
            caseRec.SLA_Target_1__c = null;
            caseRec.Stage_SLA_1__c = cv.addHours(-3);
            caseRec.Stage_SLA_2__c = cv.addHours(-2);
            caseRec.Stage_SLA_3__c = cv.addHours(1);
            caseRec.Case_Stage_Change_Date__c = System.now();
            caseRec.BusinessHoursId = bh.Id;
            update caseRec;
            
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
    @isTest static void ownerShipChnageTestMethodLvl4(){
        test.startTest();
        BusinessHours bh = [SELECT ID FROM BusinessHours WHERE isDefault = true];
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser31'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            DateTime cv = System.now();
            //c.Stage_SLA_1__c = cv.addHours(-3);
            //c.Stage_SLA_2__c = cv.addHours(2);
            //c.Stage_SLA_3__c = cv.addHours(1);
            caseRec.SLA_Target_1__c = null;
            caseRec.Stage_SLA_1__c = cv.addHours(-3);
            caseRec.Stage_SLA_2__c = cv.addHours(-2);
            caseRec.Stage_SLA_3__c = cv.addHours(1);
            caseRec.Case_Stage_Change_Date__c = System.now();
            caseRec.BusinessHoursId = bh.Id;
            update caseRec;
            
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
    @isTest static void ownerShipChnageTestMethodLvl3(){
        test.startTest();
        BusinessHours bh = [SELECT ID FROM BusinessHours WHERE isDefault = true];
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser21'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            DateTime cv = System.now();
            //c.Stage_SLA_1__c = cv.addHours(-3);
            //c.Stage_SLA_2__c = cv.addHours(2);
            //c.Stage_SLA_3__c = cv.addHours(1);
            caseRec.SLA_Target_1__c = null;
            caseRec.Stage_SLA_1__c = cv.addHours(-3);
            caseRec.Stage_SLA_2__c = cv.addHours(-2);
            caseRec.Stage_SLA_3__c = cv.addHours(1);
            caseRec.Case_Stage_Change_Date__c = System.now();
            caseRec.BusinessHoursId = bh.Id;
            update caseRec;
            
            list<User> userList =[Select Id, Name From User];
            system.assertEquals(true, userList.size()>0, 'Not able to find users');
            ASF_OwnerShipChange.checkManagerAccess(caseRec.Id);
            ASF_OwnerShipChange.changeOwnerToOtherUser(caseRec.Id,userList[0].Id); 
        }
        test.stopTest();
        
    }
    @isTest static void ownerShipChnageTestMethodLvl2(){
        test.startTest();
        BusinessHours bh = [SELECT ID FROM BusinessHours WHERE isDefault = true];
        User uRec=[Select Id,LastName FROM User WHERE LastName='TestUser11'];
        System.runAs(new User(Id =uRec.Id)){
            ASF_OwnerShipChange controller =new ASF_OwnerShipChange(); 
            Case caseRec = [Select Id,OwnerId,Subject From Case LIMIT 1];
            DateTime cv = System.now();
            //c.Stage_SLA_1__c = cv.addHours(-3);
            //c.Stage_SLA_2__c = cv.addHours(2);
            //c.Stage_SLA_3__c = cv.addHours(1);
            caseRec.SLA_Target_1__c = null;
            caseRec.Stage_SLA_1__c = cv.addHours(-3);
            caseRec.Stage_SLA_2__c = cv.addHours(-2);
            caseRec.Stage_SLA_3__c = cv.addHours(1);
            caseRec.Case_Stage_Change_Date__c = System.now();
            caseRec.BusinessHoursId = bh.Id;
            update caseRec;
            
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