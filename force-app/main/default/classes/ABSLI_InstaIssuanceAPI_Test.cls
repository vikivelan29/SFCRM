@isTest
public class ABSLI_InstaIssuanceAPI_Test {
    
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
        integ.Processing_Class__c = 'ABSLI_InstaIssuanceAPI';
        integ.Query_Fields__c = 'CaseNumber,Source__c,LAN__c,AssetId,Asset.Application_Number__c,Asset.Policy_No__c,Business_Unit__c,ABSLI_Case_Detail__r.RCA_Comments__c,Owner.Name';
        integ.External_Id__c = 'ABSLI_ASF_INT_24_02';
        insert integ;

        Case testCase = new Case();
        testCase.CCC_External_Id__c = 'PNFT007';
        testCase.Business_Unit__c = 'ABSLI';
        testCase.Source__c = 'Email';
        testCase.Client_Code_Text__c = 'ABSLI001';
        testCase.AccountId = objAccount.Id;
        insert testCase;

        ASF_Case_Integration__c asfCaseInteg = new ASF_Case_Integration__c();
        asfCaseInteg.Case__c = testCase.Id;
        asfCaseInteg.Integration_Ext_Id__c = 'ABSLI_ASF_INT_24_02';
        asfCaseInteg.Status__c = 'Pending';
        insert asfCaseInteg;
        
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c =testCase.CCC_External_Id__c,Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'ABSLI',Sub_Type__c = 'CreditCard', PPC_Change_Type__c = 'test',Send_FTR_communications__c = true,PPC_Case_Sub_TYPE__c= 'test');
        insert ccc;
    }

    @isTest
    static void testRun(){
        
        ASF_IntegrationsController.IntegrationWrapper integrationWrapperList = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRec = [SELECT Id, Asset.Application_Number__c,Asset.Policy_No__c, CaseNumber, Source__c,
                        Client_Code_Text__c, Business_Unit__c,CCC_External_Id__c,LAN__c
                        FROM Case];
        ASF_Integration__c integ = [SELECT id, Processing_Class__c, Query_Fields__c, External_Id__c FROM ASF_Integration__c];

        Test.startTest();
            ABSLI_InstaIssuanceAPI instissuance = new ABSLI_InstaIssuanceAPI();
            ASF_IntegrationsController.IntegrationWrapper result = ASF_IntegrationsController.runIntegration(integ, caseRec);
        Test.stopTest();

        System.assertEquals(result.status, ABSLI_Constants.SUCCESS);
    }
    @IsTest
	static void testProcessResponse() {
		ABSLI_InstaIssuanceAPI instissuance = new ABSLI_InstaIssuanceAPI();
        Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
            	CaseNumber,
				Asset.Policy_No__c,
            	Asset.Application_Number__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                CCC_External_Id__c,
            	LAN__c,
                ContactId,
                AccountId, 
            	No_Auto_Communication__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		 // Create an instance of the response wrapper
        ABSLI_InstaIssuanceAPI.InstaIssuanceResponseWrapper responseObj = new ABSLI_InstaIssuanceAPI.InstaIssuanceResponseWrapper();
        
        // Create an instance of the response success
        ABSLI_InstaIssuanceAPI.InstaIssuanceResponseSuccess res = new ABSLI_InstaIssuanceAPI.InstaIssuanceResponseSuccess();
        
        // Set values for the response success object
        res.CASE_ID = '53'; // Example case number
        res.descstr = 'Case Successfully processed';
        res.code = '200'; // Ensure the variable name matches exactly
        
        // Assign the response success object to the wrapper
        responseObj.ressuccess = res;
        
        // Perform assertions to verify the behavior
        System.assertEquals('53', responseObj.ressuccess.CASE_ID);
        System.assertEquals('Case Successfully processed', responseObj.ressuccess.descstr);
        System.assertEquals('200', responseObj.ressuccess.code);
        
		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		instissuance.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}
}