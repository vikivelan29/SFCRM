@isTest
public class ABSLI_IGMSLWCController_Test {
	@testSetup
    static void testSetup(){

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.RecordTypeId = recordTypeId;
        objAccount.Client_Code__c = 'ABSLI001';
        insert objAccount;

        Case testCase = new Case();
        testCase.CCC_External_Id__c = 'PNFT007';
        testCase.Business_Unit__c = 'ABSLI';
        testCase.Source__c = 'Email';
        testCase.Client_Code_Text__c = 'ABSLI001';
        testCase.AccountId = objAccount.Id;
        insert testCase;
        
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c =testCase.CCC_External_Id__c,Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'ABSLI',Sub_Type__c = 'CreditCard', PPC_Change_Type__c = 'test',Send_FTR_communications__c = true,PPC_Case_Sub_TYPE__c= 'test');
        insert ccc;
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        stage1.Stage_External_Id__c='STG_1';
        
        insert stage1;
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.Processing_Class__c = 'ABSLI_InstaIssuanceAPI';
        integ.Query_Fields__c = 'CaseNumber,Source__c,LAN__c,AssetId,Asset.Application_Number__c,Asset.Policy_No__c,Business_Unit__c,ABSLI_Case_Detail__r.RCA_Comments__c,Owner.Name';
        integ.External_Id__c = 'ABSLI_ASF_INT_24_02';
        integ.STP_API_Identifier__c = 'RegisterComplaintFlow';
        integ.Case_Stage_Config__c = stage1.Id;
        insert integ;
        
        ASF_Case_Integration__c asfCaseInteg = new ASF_Case_Integration__c();
        asfCaseInteg.Case__c = testCase.Id;
        asfCaseInteg.Integration_Ext_Id__c = 'ABSLI_ASF_INT_24_02';
        asfCaseInteg.Status__c = 'Pending';
        insert asfCaseInteg;
    }
    @isTest
    static void testRegistration(){
        Case caseobj = [Select Id From Case limit 1];
        ASF_Integration__c asfint = [Select Id, Name From ASF_Integration__c limit 1];
        
        Test.starttest();
        ABSLI_IGMSLWCController.getRegistrationComplaintStatuses(asfint.Id,caseobj.Id);
        Test.stoptest();
    }
}