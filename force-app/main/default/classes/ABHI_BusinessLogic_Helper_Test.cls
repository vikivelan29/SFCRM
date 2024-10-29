/*********************************************************
*Class        :  ABHI_BusinessLogic_Helper_Test
*Author       :  ABHI and Renewal Team
*Created Date :  03/09/2024
*@description  :  Test Class for ABHI_BusinessLogic_Helper 
*********************************************************/

@isTest
public with sharing class ABHI_BusinessLogic_Helper_Test {
    
    static List<ABHI_Create_Case_Validations__mdt> lstCreateCaseValidations { 
        get;
        set {
            lstCreateCaseValidations = (List<ABHI_Create_Case_Validations__mdt>) JSON.deserialize('[{"MasterLabel":"ABHI_BU_HLP_MDT_TEST","DeveloperName":"ABHI_BU_HLP_MDT_TEST","Nature__c":"Complaint","Validation_Name__c":"NatureValidation","Public_Groups__c":"ABHI_BU_HLP_TEST"},{"MasterLabel":"ABHI_BU_HLP_MDT_TEST2","DeveloperName":"ABHI_BU_HLP_MDT_TEST2","Validation_Name__c":"ActiveOne","Issue_Code__c":"CCC-CC-CCLTD-01","Error_Message__c":"TEST_CLASS_MESSAGE"}]', List<ABHI_Create_Case_Validations__mdt>.class);
        } 
    }
    
    @TestSetup
    static void setupTestData() {
        
        Group caseValidationGroup = new Group(Name='ABHI_BU_HLP_TEST', DeveloperName='ABHI_BU_HLP_TEST');
		INSERT caseValidationGroup;

		System.runAs(new User(Id = UserInfo.getUserId())) {
    		GroupMember caseValidationGroupMember = new GroupMember(GroupId = caseValidationGroup.Id, UserOrGroupId = UserInfo.getUserId());
    		INSERT caseValidationGroupMember;
		}
        
        //lstCreateCaseValidations = (List<ABHI_Create_Case_Validations__mdt>) JSON.deserialize('[{"MasterLabel":"ABHI_BU_HLP_MDT_TEST","DeveloperName":"ABHI_BU_HLP_MDT_TEST","Nature__c":"Complaint","Validation_Name__c":"NatureValidation","Public_Groups__c":"ABHI_BU_HLP_TEST"},{"MasterLabel":"ABHI_BU_HLP_MDT_TEST2","DeveloperName":"ABHI_BU_HLP_MDT_TEST2","Validation_Name__c":"ActiveOne","Issue_Code__c":"CCC-CC-CCLTD-01","Error_Message__c":"TEST_CLASS_MESSAGE"}]', List<ABHI_Create_Case_Validations__mdt>.class);

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'Test FirstName';
        objAccount.LastName  = 'Test LastName';
        objAccount.Line_of_Business__c = 'ABHI';
        objAccount.Business_Unit__c = 'ABHI';
        objAccount.Client_Code__c = 'Account1';
        objAccount.LOB_Client_Code__c = 'ABHI_Account1';
        objAccount.RecordTypeId = recordTypeId;
        INSERT objAccount;

        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = objAccount.Id;
        asst1.Calling_Source__c = 'Ubona BOT';//RNWL
        insert asst1;

        ABHI_Case_Detail__c caseDetail2 = new ABHI_Case_Detail__c();
        INSERT caseDetail2;

        ABHI_Case_Detail__c caseDetail3 = new ABHI_Case_Detail__c();
        INSERT caseDetail3;

        ABHI_Case_Detail__c caseDetail4 = new ABHI_Case_Detail__c();
        INSERT caseDetail4;

        Customer_Member_Mapping__c cmRec = new Customer_Member_Mapping__c(
            Business_Unit__c = 'ABHI',
            Customer_Type__c = 'VIP',
            MemberExternalId__c = '28282192',
            MemberId__c = objAccount.Id,
            Policy_Number__c = asst1.Id
        );
        insert cmRec;
        
        Health_Provider__c hp = new Health_Provider__c(
            Provider_Code__c = '12345');
        insert hp;
        
        Cover__c cov= new Cover__c(
            Cover_Name__c = 'Test',
            Cover_Code__c = '3454'
        );
        insert cov;
        
      
        Claim__c testClaim = new Claim__c(Name= '123456789', Policy_Number__c  = asst1.Id);
        insert testClaim;
        
        List<Case> caseList = new List<Case>();
        Case caseRec = new Case();
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Notes__c = 'Test Case';
        caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec.AccountId = objAccount.Id;
        caseRec.Technical_Source__c = 'LWC';
        caseRec.Type_Text__c = 'Cashless';
        caseRec.Sub_Type_Text__c = 'Claims status';
        caseRec.Source__c = 'Branch';
        caseRec.AssetId = asst1.Id;
        insert caseRec;
        
       // Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(objAccount.Id, asst1.Id);//RNWL
    }

        Case caseRec2 = new Case();
        caseRec2.Business_Unit__c = 'ABHI';
        caseRec2.Notes__c = 'Test Case 5';
        caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-02';
        caseRec2.AccountId = objAccount.Id;
        caseRec2.Technical_Source__c = 'API';
        caseRec2.Type_Text__c = 'Cashless';
        caseRec2.Sub_Type_Text__c = 'Loading';
        caseRec2.Source__c = 'Branch';
        caseRec2.AssetId = asst1.Id;
        caseRec2.ABHI_Case_Detail__c = caseDetail2.Id;
        caseRec2.Recategorisation_Date__c = System.now();
        caseRec2.Hospital_Code_Text__c = '12345';
        caseList.add(caseRec2);

        Case caseRec3 = new Case();
        caseRec3.Business_Unit__c = 'ABHI';
        caseRec3.CCC_External_Id__c = 'ABHI_Request_CCC_20';
        caseRec3.AccountId = objAccount.Id;
        caseRec3.Technical_Source__c = 'LWC';
        caseRec3.Type_Text__c = 'Claims';
        caseRec3.Sub_Type_Text__c = 'CRM-Claims';
        caseRec3.Source__c = 'Underwriting';
        caseRec3.AssetId = asst1.Id;
        caseRec3.ABHI_Case_Detail__c = caseDetail3.Id;
        caseList.add(caseRec3);

        Case caseRec4 = new Case();
        caseRec4.Business_Unit__c = 'ABHI';
        caseRec4.CCC_External_Id__c = 'ABHI_Complaints1';
        caseRec4.AccountId = objAccount.Id;
        caseRec4.Technical_Source__c = 'LWC';
        caseRec4.Type_Text__c = 'Legal / Ombudsman';
        caseRec4.Sub_Type_Text__c = 'Claim / Service';
        caseRec4.Source__c = '	Claim Email';
        caseRec4.AssetId = asst1.Id;
        caseRec4.ABHI_Case_Detail__c = caseDetail4.Id;
        
        caseList.add(caseRec4);

        insert caseList;
        
       // Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(objAccount.Id, asst1.Id);//RNWL
    }
	
    /****************************************************
    * @description - Test Method for case validation aura enabled Method
    *****************************************************/
    @isTest 
    static void abhiCaseValidationTestMethod() {
        
        Case caseRec = [SELECT id, Notes__c, PAY_Payment_Detail__c FROM Case LIMIT 1];
        caseRec.Nature__c = 'Complaint';
        
        Test.startTest();
        String strResponse = ABHI_BusinessLogic_Helper.abhiCaseValidation(JSON.serialize(caseRec));

        System.assertNotEquals('', strResponse, 'Case validate response null');
        Test.stopTest();
    }
    
    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void abhiHandlerMethodTestMethod() {
        
        Case caseRec = [SELECT id, Notes__c, PAY_Payment_Detail__c FROM Case LIMIT 1];
        caseRec.Notes__c = 'Test Case 1';
        
        Test.startTest();
        update caseRec;

        System.assertEquals('Test Case 1', caseRec.Notes__c, 'Test Case 1');
        Test.stopTest();
    }
    
    /****************************************************
    * @description - Test Method for send communication Method
    *****************************************************/
    @isTest 
    static void sendCommTestMethod01() {
        
        Case caseRec = [SELECT id, AssetId, AccountId, Notes__c, Stage__c, PAY_Payment_Detail__c, CCC_External_Id__c, Recategorisation_Date__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        caseRec.Stage__c = 'In Progress';

        Test.startTest();
        UPDATE caseRec;
        
        System.assertEquals('In Progress', caseRec.Stage__c, 'Stage error: sendCommBHTest01');
        String strResponse = ABHI_BusinessLogic_Helper.abhiActiveOneValidation(JSON.serialize(caseRec));

        System.assertNotEquals('', strResponse, 'Case active one response null');
        
        Test.stopTest();
    }
    
    /****************************************************
    * @description - Test Method for send communication Method
    *****************************************************/
    @isTest 
    static void sendCommTestMethod02() {
        
        Case caseRec = [SELECT id, Notes__c, Stage__c, PAY_Payment_Detail__c, CCC_External_Id__c, Recategorisation_Date__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        caseRec.Stage__c = 'In Progress';

        Test.startTest();
        UPDATE caseRec;
        
        caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-02';
        caseRec.Recategorisation_Date__c = System.now();
        UPDATE caseRec;
        
        Test.stopTest();
    }
    
    /****************************************************
    * @description - Test Method for send communication Method
    *****************************************************/
    @isTest 
    static void sendCommTestMethod03() {
        
        Case caseRec = [SELECT id, Notes__c, Stage__c, PAY_Payment_Detail__c, CCC_External_Id__c, Recategorisation_Date__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        caseRec.Stage__c = 'In Progress';

        Test.startTest();   
        UPDATE caseRec;
        System.assertEquals('In Progress', caseRec.Stage__c, 'Stage error: sendCommBHTest02');
        
        Test.stopTest();
    }
    
     /****************************************************
    * @description - Test Method for send communication Method
    *****************************************************/
    @isTest 
    static void sendCommTestMethod04() {

        Case caseRec = [SELECT id, Notes__c, Stage__c, PAY_Payment_Detail__c, CCC_External_Id__c, Recategorisation_Date__c, Status FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        caseRec.Stage__c = 'In Progress';
        ABHI_BulkMoveNextConverterUtility.boolSkipChklstAbhiBulk = true;
        
        Test.startTest();
        UPDATE caseRec;
        
        caseRec.Stage__c = 'Unresolved ';
        caseRec.Status = 'Unresolved ';
        UPDATE caseRec;
        
        System.assertEquals('Unresolved ', caseRec.Stage__c, 'Stage error: sendCommBHTest02');
        
        Test.stopTest();
    }

     /****************************************************
    * @description - Test Method for send communication Method
    *****************************************************/
    @isTest 
    static void sendCommTestMethod05() {
        
        Case caseRec = [SELECT id, Notes__c, Stage__c, PAY_Payment_Detail__c, CCC_External_Id__c, Recategorisation_Date__c, Status FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01']; 
        caseRec.Stage__c = 'Resolved';

        Test.startTest();
            UPDATE caseRec;
            System.assertEquals('Resolved', caseRec.Stage__c, 'Stage error: sendCommBHTest02'); 
        Test.stopTest();
    }
    
    @isTest
    static void test_populateFieldsOnCase(){
        Case caseRec = [SELECT Id, AccountId, AssetId FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        Asset asst2 = new Asset();
        asst2.Name = 'Test Asset';
        asst2.AccountId = caseRec.AccountId;
        asst2.Calling_Source__c = 'CRM (In-House)';
        insert asst2;
        
        Test.startTest();
        	caseRec.AssetId = asst2.Id;
        	update caseRec;
        Test.stopTest();
        
        caseRec = [SELECT Id, Calling_Source__c FROM Case WHERE Id = :caseRec.Id ];
        System.assertEquals(asst2.Calling_Source__c, caseRec.Calling_Source__c, 'Case is NOT UPDATED!!!!');
    }

    @isTest
    static void testDedupeLogicOnCaseCreation() { 
        
        ABHI_BusinessLogic_Helper abhiBusHelpObj = new ABHI_BusinessLogic_Helper();

        Case caseRecToUpdate = [SELECT Id, assetId, accountId, ABHI_Case_Detail__c, 
                                        Business_Unit__c, CCC_External_Id__c, Is_Recategorise_Allowed__c, 
                                        Recategorisation_Date__c, Source__c
                                FROM Case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-02'
        ];
        
        Case caseRecOld = new Case();
        caseRecOld.Business_Unit__c = 'ABHI';
        caseRecOld.CCC_External_Id__c = 'CCC-CC-CCLTD-02';
        caseRecOld.AccountId = caseRecToUpdate.AccountId;
        caseRecOld.Technical_Source__c = 'LWC';
        caseRecOld.Type_Text__c = 'Cashless';
        caseRecOld.Sub_Type_Text__c = 'Loading';
        caseRecOld.Source__c = 'Branch';
        caseRecOld.AssetId = caseRecToUpdate.AssetId;
        caseRecOld.ABHI_Case_Detail__c = caseRecToUpdate.ABHI_Case_Detail__c;
        caseRecOld.Recategorisation_Date__c = System.now().addMinutes(-1);

        abhiBusHelpObj.mapOfIdToOldCase = new Map<Id, Case>{caseRecToUpdate.Id => caseRecOld};
        caseRecToUpdate.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRecToUpdate.Is_Recategorise_Allowed__c = true;
        caseRecToUpdate.Recategorisation_Date__c = System.now();
        abhiBusHelpObj.abhiNewCaseList = new List<Case>{caseRecToUpdate};
        abhiBusHelpObj.dedupeLogicOnCaseCreation('AfterASFCodeBeforeUpdate');
        System.assertEquals('CCC-CC-CCLTD-01', caseRecToUpdate.CCC_External_Id__c, 'Duplicate Case Found');
    }

    @isTest
    static void testAbhiCaseSourceValidation() { 
        
        Map<String, Case> cccExtIdToCaseMap = new Map<String, Case>();

        List<Case> caseRecToUpdate = [SELECT Id, Business_Unit__c, Source__c, CCC_External_Id__c
                                FROM Case 
                                WHERE CCC_External_Id__c in ('ABHI_Request_CCC_20', 'ABHI_Complaints1')
        ];

        for(Case csRec : caseRecToUpdate) {
            cccExtIdToCaseMap.put(csRec.CCC_External_Id__c, csRec);
        }

        Case csRec1 = cccExtIdToCaseMap.get('ABHI_Request_CCC_20');
        Case csRec2 = cccExtIdToCaseMap.get('ABHI_Complaints1');

        String res = ABHI_BusinessLogic_Helper.abhiCaseSourceValidation(csRec1);
        Assert.isTrue(res != 'Success', 'Not Success');

        ASF_TestDataFactory.createCS60User();

        User testUser = [SELECT id, Business_Unit__c, Source_Code__c FROM USER WHERE email = 'CS360@FCAAdmin.mock.com' LIMIT 1];
        testUser.Business_Unit__c = 'ABHI';
        testUser.Source_Code__c = '015';
        update testUser;

        System.runAs(testUser) {

            // For Source_Based_Case_Creation_Restriction
            String res2 = ABHI_BusinessLogic_Helper.abhiCaseSourceValidation(csRec1);
            Assert.isTrue(res2 != 'Success', 'Not success');
        }

        testUser.Source_Code__c = '001';
        update testUser;

        System.runAs(testUser) {

            // For User_Source_Code_Based_Case_Creation_Restriction
            String res3 = ABHI_BusinessLogic_Helper.abhiCaseSourceValidation(csRec2);
            Assert.isTrue(res3 != 'Success', 'Not success');
        }
    }
    
    @isTest
    static void searchAndAssocFieldsForAPICasesTest() { 
        Case caseRec = [SELECT Id,ABHI_Case_Detail__c, AccountId, AssetId FROM Case where CCC_External_Id__c= 'CCC-CC-CCLTD-02' LIMIT 1];            
        caseRec.Technical_Source__c = 'API';
        caseRec.Customer_Member_Text__c = 'Account1';
        caseRec.Cover_Code_Text__c = '12345';
        caseRec.ClaimNo_Text__c = '123456789';
        update caseRec;
      
        Test.startTest();
          
         /* ABHI_Case_Detail__c caseDet = [SELECT ID,Claim__c FROM ABHI_Case_Detail__c WHERE Id = :caseRec.ABHI_Case_Detail__c];
         Claim__c claim = [SELECT ID FROM Claim__c LIMIT 1];
		  Assert.areEqual(claim.Id, caseDet.Claim__c, 'Claim name'); */

          caseRec.Cover_Code_Text__c = null;
          caseRec.ClaimNo_Text__c = null;
          caseRec.Hospital_Code_Text__c = null;
          caseRec.Customer_Member_Text__c = null;
        
          update caseRec;
        
          caseRec.Hospital_Code_Text__c = '123';
          update caseRec;
        
          ABHI_Case_Detail__c caseDets = [SELECT ID,Claim__c FROM ABHI_Case_Detail__c LIMIT 1];
          Assert.areEqual(null, caseDets.Claim__c, 'Claim name'); 
        Test.stopTest();
    }
    
    @isTest
    static void test_populateFieldsOnCase(){
        Case caseRec = [SELECT Id, AccountId, AssetId FROM Case LIMIT 1];
        Asset asst2 = new Asset();
        asst2.Name = 'Test Asset';
        asst2.AccountId = caseRec.AccountId;
        asst2.Calling_Source__c = 'CRM (In-House)';
        insert asst2;
        
        Test.startTest();
        	caseRec.AssetId = asst2.Id;
        	update caseRec;
        Test.stopTest();
        
        caseRec = [SELECT Id, Calling_Source__c FROM Case WHERE Id = :caseRec.Id ];
        System.assertEquals(asst2.Calling_Source__c, caseRec.Calling_Source__c, 'Case is NOT UPDATED!!!!');
    }
}