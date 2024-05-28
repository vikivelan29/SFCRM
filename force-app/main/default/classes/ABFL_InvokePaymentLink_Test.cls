/**
 * @description        Test Class for ABFL_InvokePaymentLink
 * @author            : Aditee Churiwala
 * @group             : 
 * @last modified on  : 29/03/2024
 * @last modified by  : Aditee Churiwala
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   12-22-2023   achuriwala@salesforce.com   Initial Version
**/
@isTest
public class ABFL_InvokePaymentLink_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    static void makeData(){
        Group slaGroup = new Group();
        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup', Type = 'Queue');
        insert slaGroup;
        
        User superManagerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Super Manager User Test 12',
            Username='supermanageruserTest12@test.com',
            Email='supermanageruserTest12@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey='America/Los_Angeles', managerGroupId__c=slaGroup.Id
        );
        insert superManagerUser;
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='Testcdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id, managerID = superManagerUser.Id
                                    );
        insert userRecord1;
        
        Test.startTest();
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User' ];
        psa.add(new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id));
        psa.add(new PermissionSetAssignment(AssigneeId = superManagerUser.Id, PermissionSetId = ps.Id));
        
        
        insert psa;
        Test.stopTest();
        System.runAs(userRecord1) {
            Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
                        
            GroupMember gm = new GroupMember(GroupId = slaGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm;
            GroupMember gm1 = new GroupMember(GroupId = slaGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm1;
            
            List<ASF_Case_Category_Config__c> caseCat =  ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfig(caseCat[0].Id, true);

            Id  caseStageID = caseStage[0].StageName__c == 'Open'?caseStage[0].Id: caseStage[1].Id;
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageID,true,'ABFL_InvokePaymentLink', 'paymentLink ');
            /*for(ASF_Integration__c integ : intConfigList){
                integ.Query_Fields__c = 'Id,ABFL_Case_Detail__c, Account.Name, Technical_Source__c, Source__c';
            }*/
            update intConfigList;
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            caseDetList[0].From_Date__c = Date.Today();
            caseDetList[0].To_Date__c = Date.Today()+1;
            caseDetList[0].Amount__c = 1000;
            update caseDetList;
            
            Asset assetObj = new Asset();
            assetObj.Name = 'LAN-145';
            assetObj.LAN__c = 'LAN-145';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='ABFL';
            insert assetObj;
            
            // List<Case> cases = ABFL_TestDataFactory.createCaseRecords(1, caseDetList[0].Id, true);
            List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);
            
            Case c = cases.get(0);
            c.ownerid = userInfo.getuserId();
            c.AccountId = acc.ID;
            c.LAN__c = 'LAN-145';
            c.AssetId = assetObj.Id;
            c.Source__c = ABFL_Constants.RM_NO_EMAIL;
            c.ABFL_Case_Detail__c = caseDetList[0].Id;
            c.OwnerId = superManagerUser.Id;
            update c;
        }
        
    }
    @isTest
    static void testGetPaymentLink(){
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'paymentLink';
        intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
        update intg;
         List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND 
                                    Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c ='TXMVqOci812/n+cSamlDwqQEHjAcSabwr3tkFq+MPHehT5s9gASsdIb+oyyHAuocYRjaZeJoy3MLaKBc0l/mXLX5rQdWCmt/ub3yHqvZyaE55mM2tKn1TrOoxr1ui3vBGa7Xw68bFzVIobmDiidY3L+2A/sHAww/POqoOoXvz3rHJCNRgkjV6qBqb0sTdGT/DrDQTrMW2kSNTQlaZxHs7RGeurrbO4MTzGJZZWcMtkmbiCGYNnP2MAiAYg2x2b16wOzkpxqLzhXZU+qebN//CrKSpY/Yx8I6Prxpz4TlETgDdMtq0Lo+xs8yKj2671A+98htqnqijr/ZSKHG7c/OD7bhkQSSWgF9dQcngMy0yUsrEcOKHsEADgyBN39ELsksNZsTxdwwCTeREjLfEmDnXaKGyiRO7o/utgSftcgb7sI+uWl3Pf71zpu84oyAzLj+AbBKIuTrHEb2saSZaZaGRWURK6qFSn/5po/1gIkrkUy94b0GW50385rqs58uSDmD+jxRUioGDDT2kHAjJibcOV/jEzzmC5+xziGIHFJptonppQGcCfyqo2dEakHm+iBucz4krJ7z2SGAkUphiCsJoW3EkgMDLH3PX5+i/ikUSxItKtPpsGlycRpYESFJykQ8kflVoH6iWljfORbO9dmiOXwK1OZ7ihRKM+Jq0nMguQxhmNqqSIPpOuw+fMjW34499qrCQtNcjLz0P+RsYeVfsmhxJ+OiKcd0o7KEIdn+igWKaRXYCGpPr/82YFDWFl0hYaMUuY9OhVVe73DSYXLic/PelFYFCNnMPTsCWHSVF2njRLZa6ALDNqaJgHdTkE+lFwAmb0ORBjEygLyEOQkdgZdl9Jb04FjXDfuF18BZbpTgp55hYkkSr8/t9uGCSMhV59zh/GQXwvGJEPG5tL513NqTbGYL+S24cEmMqMISCqA6rLW9F1EmWR/kczHeNOgQHn3NMhClVwjFMpMhVwW2FbtyxU0TDjKRziGN7w9idiKZtVLqeuNYBkejQFLAgzKZ';
                                        listCaseIntRec.add(caseIntRec);
                                    }
       
        update listCaseIntRec;
        Test.stopTest();
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual('https://paymentloungeuat.adityabirlacapital.com/pg/api/v2/authRedirect?tranCtx=Ref177b8f-6299-4517-bf73-cf1b8f35e69a', caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Link');
    }  
    
    @isTest
    static void testGetPaymentLinkError(){
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__r.Amount__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.ABFL_Case_Detail__r.Amount__c = null;
        update caseRec.ABFL_Case_Detail__r;
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'paymentLink';
        intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
        update intg;
        List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper wrapper = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        Assert.areEqual(ABFL_Constants.EVALUATION_FAILED_AMOUNT_ERROR, wrapper.response, 'Error');
        Test.stopTest();
    }  
}