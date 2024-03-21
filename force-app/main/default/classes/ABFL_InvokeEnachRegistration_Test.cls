/*********************************************************
*Class        :  ABFL_InvokeEnachRegistration_Test
*Author       :  Aditee Churiwala
*Created Date :  18/03/2024
*Last Modified:  
*Description  :  Test Class for ABFL_InvokeEnachRegistration
*********************************************************/
@isTest
public class ABFL_InvokeEnachRegistration_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
	@TestSetup
    static void makeData(){
        Group SLAGroup = new Group();
        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup', Type = 'Queue');
        insert SLAGroup;
        
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
            TimeZoneSidKey='America/Los_Angeles', managerGroupId__c=SLAGroup.Id
        );
        insert superManagerUser;
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='Testcdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id, managerID = superManagerUser.Id
                                    );
        insert userRecord1;
        // ASF_TestDataFactory.createC3IntegrationsAndCase();
        
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
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
                        
            GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm;
            GroupMember gm1 = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm1;
            
            List<ASF_Case_Category_Config__c> caseCat =  ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfig(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStage[0].Id,true,'ABFL_InvokeEnachRegistration', 'eNachRegistration ');
            /*for(ASF_Integration__c integ : intConfigList){
                integ.Query_Fields__c = 'Id,ABFL_Case_Detail__c, Account.Name, Technical_Source__c, Source__c';
            }*/
            update intConfigList;
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            caseDetList[0].From_Date__c = Date.Today();
            caseDetList[0].To_Date__c = Date.Today()+1;
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
    static void testUpdateSTPFlowIVR_NoEmail(){
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_Foreclosure_Retail';
        intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
       // ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        ASF_IntegrationsController.IntegrationWrapper retVal =  ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = 'zj/F0rESaCibd/nKNMZVNhQG3psoaogrlEWuyWD/B80bE1uJP17RXXRjOG/32+bstHZnB74h1CrUNfAXtPz6Ct3qO4GqJBbJUvIt4mUU3zc/chzjufLQLtDTRoqvnBZr2zGwYE0nz8JfL2nUl6yTl0cjfjyRVhlD4X18XUWS/xwXqby5RAwfhDYLJu6NNS6X2W9Jh2XNCtJ1aHl3+LAeD9E0WaTpOXJNO5W9rNNhfsfFR0wS7P2Gc2F1926wIEHXWHQiAKHzazcmIDxxrVuhCuLpnk1mDFMMn+b5A0Ft5uFz4l20mQtcJqH3gO9HbafRll4jNsnh0KVZGPIrEhwtIKMayCqPz+vth2WihL3XP3XgcpMOgfpGqr9GpvKiudCSIEeJKRJB0GZyqTN9dYjBGehCkjRVIOV1d2gEvmDhEjNogQZUF0vTCpkKhpUrz9DfuAQcNOr223t2UJTSsn2rT9QjIoBAvLdXLjIbHYmtkL1XBwSJmJkBFXm3zlLZomGSNmJKh9WEtxzuRONpq4jTREOanlRPyFiNMbQk8W4JK7TbqX0jKJc4BD1TMULUnV19/9vQbXfWEufSDPh8aY44Rf6/El6p6eMYmweqfeIR2ReiOqzlfCtOJisuj8ZhWgFrkx3/C1d6JoDWP38QopbMwXkWTF6DWmRUKd9GQy9ApZWVkDQSpzEM+2Yu6C49RdrpnFTdkUsP1aYQOyDw6rgxwn6CA+KOoqRwATz+xPhm54tpHn8V7BqrcyReA8hWCdlQYlRN23+ApUm8hcCe3BVIX5BuPz232XX7tvxgesJoQuhObEKsQMuVpuSq2YU+THkUL/hEFSa1uvPVS9ysogTbPdjQVM7m+iufvIqbP4fqu5gCro00Km5LiEvvZypqi6IB6S3gthJRvN6WKtRsy1v3uA1IkFsHDxokhuwqjQhHhZxL76jbiJAi6FuXfLSPD5TaadW2XdJXhH+YExkJ3zsA2Np8jgqH8sgxN9YM1u+XTNUfQDms73gLwZuyhJNfUZmOf2LYJRJl0YAtEPRDo00YxjaxQcBUWfRKQI+PYi2Um9wcEoMGSIjVp1ruwQCpLsB9BpsgmIaXZ5uPP/TtRloeVA==';                                     
                                        listCaseIntRec.add(caseIntRec);
                                                  }
       
        update listCaseIntRec;
        Test.stopTest();
        Integer caseDetCount = [SELECT count() FROM ABFL_Case_Detail__c];
        ////Assert.areEqual(2, caseDetCount);
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      // Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
    }
    
}