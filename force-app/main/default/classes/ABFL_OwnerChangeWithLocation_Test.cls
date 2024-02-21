/*********************************************************
*Class        :  ABFL_OwnerChangeWithLocation
*Author       :  Shubham Sinha 
*Created Date :  010/01/2024
*Description  :  Test Class
*********************************************************/
@isTest
public class ABFL_OwnerChangeWithLocation_Test {
private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        Group SLAGroup = new Group();        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert SLAGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657@gmail.com'
                                    );
        insert userRecord1;
        System.runAs(userRecord) {
            ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
                ccc.Type__c = 'tes';
                ccc.First_Stage__c = 'New';
                ccc.CCC_External_Id__c = '12345';
                ccc.Business_Unit__c = 'ABFL';
                ccc.Sub_Type__c = 'Paytm';
                ccc.EBOT_Auto_Response__c = True;
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
            stage1.Default_Queue__c =g1.Id;
            insert stage1;
             Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
         Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
        insert acc;
            Asset assetObj = new Asset();
            assetObj.Name = '981726345';
            assetObj.AccountId = acc.Id;
            assetObj.RM_Code__c = 'FED12346';
            assetObj.RM_Assignment__c = 'Pending';
            assetObj.Business_Unit__c ='ABFL';
            assetObj.LAN__c = 'ABFLJOD1234';
            insert assetObj;
            
            Asset assetObj1 = new Asset();
            assetObj1.Name = '981726345';
            assetObj1.AccountId = acc.Id;
            assetObj1.RM_Code__c = 'FED12346';
            assetObj1.RM_Assignment__c = 'Pending';
            assetObj1.Business_Unit__c ='ABFL';
            assetObj1.LAN__c = 'ABJAI1234';
            insert assetObj1;
              //  Group mortgageGrp = new Group(Name='ABFL Mortgage CS', type='Queue');
                //insert mortgageGrp;
            //QueueSobject mappingObject = new QueueSobject(QueueId = mortgageGrp.Id, SobjectType = 'Case');
            //insert mappingObject;
            Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
            Case newCase = new Case();
                newCase.Subject = 'Test Case Creation';
                newCase.CCC_External_Id__c =ccc.CCC_External_Id__c ;
                newCase.Business_Unit__c  = 'ABFL';
                newCase.LAN__c = 'ABFLJOD';
                newCase.OwnerId = queueRecord.Id;
                insert newCase; 
            Case newCase1 = new Case();
                newCase1.Subject = 'Test Case Creation';
                newCase1.CCC_External_Id__c =ccc.CCC_External_Id__c ;
                newCase1.Business_Unit__c  = 'ABFL';
                newCase1.LAN__c = 'ABFLJOD1234';
                newCase1.AssetId = assetObj.Id;
                insert newCase1;
            Case newCase2 = new Case();
                newCase2.Subject = 'Test Case Creation';
                newCase2.CCC_External_Id__c =ccc.CCC_External_Id__c ;
                newCase2.Business_Unit__c  = 'ABFL';
                newCase2.LAN__c = 'ABJAI1234';
                newCase2.AssetId = assetObj1.Id;
                insert newCase2;
            ABFL_Location_Master__c  loc = new ABFL_Location_Master__c();
                loc.Code__c = 'JOD';
                loc.Location__c  = 'Jodhpur';
                loc.SPOC__c = userRecord1.Id;
                insert loc;
            ABFL_Location_Master__c  loc1 = new ABFL_Location_Master__c();
                loc1.Code__c = 'JAI';
                loc1.Location__c  = 'Jaipur';
                loc1.SPOC__c = userRecord1.Id;
                insert loc1;
        }
    }
     @isTest
    static void beforeUpdateContainsABFLTest(){
        List<Case> objCase = [Select Id,OwnerId,AssetId From Case WHERE LAN__c = 'ABFLJOD1234' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        ABFL_Location_Master__c loc = [SELECT Id,Code__c,SPOC__c FROM ABFL_Location_Master__c WHERE Code__c = 'JOD' LIMIT 1];
        Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            objCase[0].OwnerId= queueRecord.Id;
            update objCase[0]; 
            System.assertEquals(1, objCase.size());          
             Test.stopTest();            
            }
        }
    @isTest
    static void beforeUpdateContainsNotABFLTest(){
        List<Case> objCase = [Select Id,OwnerId,AssetId From Case WHERE LAN__c = 'ABJAI1234' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        ABFL_Location_Master__c loc = [SELECT Id,Code__c,SPOC__c FROM ABFL_Location_Master__c WHERE Code__c = 'JAI' LIMIT 1];
        Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            objCase[0].OwnerId= queueRecord.Id;
            update objCase[0]; 
             System.assertEquals(1, objCase.size());          
             Test.stopTest();            
         }
    }
}