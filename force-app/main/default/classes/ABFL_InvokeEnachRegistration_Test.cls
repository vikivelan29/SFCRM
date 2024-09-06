/**
 * @description        Test Class for ABFL_InvokeEnachRegistration
 * @author            : Aditee Churiwala
 * @group             : 
 * @last modified on  : 18/03/2024
 * @last modified by  : Aditee Churiwala
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   12-22-2023   achuriwala@salesforce.com   Initial Version
**/
@isTest
public class ABFL_InvokeEnachRegistration_Test {
    private static Map<String, Object> dummyInPayloadWrap = new Map<String, Object>{ 
        'pl_merchant_id'=>'MRC8821',
        'customer_Id'=>'7406498698',
        'customer_mobile_no'=>'7498791441',
        'customer_name'=>'Vaibhav',
        'customer_email_id'=>'guest@phicommerce.com',
        'customer_bank_ifsc'=>'UTIB0000305',
        'customer_bank_acc_no'=>'921010038015673',
        'amount'=>'10.00',
        'start_date'=>'20240224',
        'end_date'=>'20240816',
        'frequency'=>'V',
        'debit_type'=>'MAXAMOUNT',
        'return_url'=>'http://localhost:8090/resultpage'
    };
    private static Map<String, Object> dummyPayloadWrap = new Map<String, Object>{ 
        'enach_data' => dummyInPayloadWrap
    };

    private static Map<String, Object> dummyInResponseWrap = new Map<String, Object>{ 
        'pl_enach_id'=>'7406498698',
        'created_date'=>'20240205',
        'registration_link'=>
        'https://paymentloungeuat.adityabirlacapital.com/pg/portal/pay/enachRequest?requestID=7406498698&actionType=viewRequest&merchantid=T_88821',
        'return_code'=>'0000',
        'resp_description'=>'Request Processed Successfully'    
    };
    private static Map<String, Object> dummyResponseWrap = new Map<String, Object>{ 
        'registration_data' => dummyInResponseWrap
    };
        
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
     /**
    * @description 
    * @author achuriwala@salesforce.com | 22-12-2023
    **/
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
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageID,true,'ABFL_InvokeEnachRegistration', 'eNachRegistration ');
            
            /*for(ASF_Integration__c integ : intConfigList){
                integ.Query_Fields__c = 'Id,ABFL_Case_Detail__c, Account.Name, Technical_Source__c, Source__c';
            }*/
            update intConfigList;
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            caseDetList[0].From_Date__c = Date.Today()+3;
            caseDetList[0].To_Date__c = Date.Today()+15;
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
    static void testEnachRegistrationFlow(){        
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        Test.startTest();
       // ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
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
        ////Assert.areEqual(2, caseDetCount);
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual('https://paymentloungeuat.adityabirlacapital.com/pg/portal/pay/enachRequest?requestID=74064986998&actionType=viewRequest&merchantid=T_11017', caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Registartion link');
    }
    @isTest
    static void testEnachRegistrationFlowError(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.ABFL_Case_Detail__r.EMI_Amount__c = null;
        update caseRec.ABFL_Case_Detail__r;
       
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);    
        Test.stopTest();
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual(null, caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Registration link');
    }   
    @isTest
    static void testEnachRegistrationFlowErrorDate(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.ABFL_Case_Detail__r.To_Date__c = null;
        update caseRec.ABFL_Case_Detail__r;
        
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        caseRec.ABFL_Case_Detail__r.From_Date__c = null;
        update caseRec.ABFL_Case_Detail__r;
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);

        Test.stopTest();
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual(null, caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Registration');
    }  
    @isTest
    static void testEnachRegistrationFlowErrorAccount(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.ABFL_Case_Detail__r.New_Bank_Account_No__c = null;
        update caseRec.ABFL_Case_Detail__r;
       
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);    
        Test.stopTest();
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual(null, caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Registartion');
    }   
    @isTest
    static void testEnachRegistrationFlowErrorIFSC(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.ABFL_Case_Detail__r.Bank_IFSC_Code__c = null;
        update caseRec.ABFL_Case_Detail__r;
       
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);    
        Test.stopTest();
        Case caseRecord = [SELECT Id, IsClosed, Status, ABFL_Case_Detail__r.Registration_Link__c
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
      Assert.areEqual(null, caseRecord.ABFL_Case_Detail__r.Registration_Link__c, 'Registartion');
    }   
    @isTest
    static void testEnachRegistrationFlowException(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c,ABFL_Case_Detail__r.EMI_Amount__c, ABFL_Case_Detail__r.Frequency__c,
            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
            ABFL_Case_Detail__r.Bank_IFSC_Code__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        
        Test.startTest();
        ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = 'ittiuigjihgrrjngjgjgj=';                                     
                                        listCaseIntRec.add(caseIntRec);
                                    }
       
        update listCaseIntRec;
        
        ABFL_EnachRegistrationResponse req = ABFL_EnachRegistrationResponse.parse(JSON.serialize(dummyPayloadWrap));
        ABFL_EnachRegistrationResponse res = ABFL_EnachRegistrationResponse.parse(JSON.serialize(dummyResponseWrap));
        
        Test.stopTest();
        List<ABCLLogRecording__c> abclLogsList = [SELECT Id
                                                  FROM ABCLLogRecording__c];
        Assert.isTrue(abclLogsList.size() > 0, 'ABCL Log Recording records should have been created');
    }   

}