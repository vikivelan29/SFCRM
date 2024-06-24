@isTest
public class ABSLI_MobileUpdateIntegration_Test {
    
    @testSetup
    static void testSetup(){

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.RecordTypeId = recordTypeId;
        objAccount.Client_Code__c = 'ABSLI001';
        insert objAccount;

        ASF_Integration__c integ = new ASF_Integration__c();
        integ.Processing_Class__c = 'ABSLI_MobileUpdateIntegration';
        integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Mobile_Number__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,Business_Unit__c';
        integ.External_Id__c = 'ABSLI_ASF_INT_24_02';
        insert integ;

        ABSLI_Case_Detail__c absliCaseDet = new ABSLI_Case_Detail__c();
        absliCaseDet.Status_Valid_For_STP__c = true;
        insert absliCaseDet;

        Case testCase = new Case();
        testCase.CCC_External_Id__c = 'PNFT007';
        testCase.ABSLI_Case_Detail__c = absliCaseDet.Id;
        testCase.Business_Unit__c = 'ABSLI';
        testCase.Client_Code_Text__c = 'ABSLI001';
        testCase.AccountId = objAccount.Id;
        insert testCase;

        ASF_Case_Integration__c asfCaseInteg = new ASF_Case_Integration__c();
        asfCaseInteg.Case__c = testCase.Id;
        asfCaseInteg.Integration_Ext_Id__c = 'ABSLI_ASF_INT_24_02';
        asfCaseInteg.Status__c = 'Pending';
        insert asfCaseInteg;
        
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c =testCase.CCC_External_Id__c,Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'ABFL',Sub_Type__c = 'CreditCard', Overall_Case_Closure_SLA__c = 1,Send_FTR_communications__c = true);
        insert ccc;
    }

    @isTest
    static void testRun(){
        
        ASF_IntegrationsController.IntegrationWrapper integrationWrapperList = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRec = [SELECT Id, Account.Client_Code__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, ABSLI_Case_Detail__r.Mobile_Number__c,
                        Client_Code_Text__c, Business_Unit__c
                        FROM Case];
        ASF_Integration__c integ = [SELECT id, Processing_Class__c, Query_Fields__c, External_Id__c FROM ASF_Integration__c];

        Test.startTest();
            ABSLI_MobileUpdateIntegration mobileUpdate = new ABSLI_MobileUpdateIntegration();
            ASF_IntegrationsController.IntegrationWrapper result = ASF_IntegrationsController.runIntegration(integ, caseRec);
        Test.stopTest();

        System.assertEquals(result.status, ABSLI_Constants.SUCCESS);
    }
    @IsTest
	static void testProcessResponse() {
		ABSLI_MobileUpdateIntegration mobileint = new ABSLI_MobileUpdateIntegration();
        Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
            	CaseNumber,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                CCC_External_Id__c,
                ContactId,
                AccountId, No_Auto_Communication__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_MobileUpdateIntegration.MobileUpdateResponse responseObj = new ABSLI_MobileUpdateIntegration.MobileUpdateResponse();
		responseObj.TRANS_NO = caseRec.CaseNumber;
		responseObj.ProcessMessage = 'test mesage';
		responseObj.ProcessCode = '00';
        
		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		mobileint.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}
}