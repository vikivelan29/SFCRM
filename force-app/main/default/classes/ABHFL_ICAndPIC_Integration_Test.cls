/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 20-December-2023
  * @LOB         - ABHFL
  * @description -  Test class for ABHFL_ICAndPIC_Integration class.
  *****************************************************************************************************************/

  @isTest
  public with sharing class ABHFL_ICAndPIC_Integration_Test {
    
      /****************************************************
      * @description - To setup test data for this test class
      *****************************************************/
      @testSetup
      static void setupTestData(){
		
          // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
          
         List<Asset> asstList = new List<Asset>();
         List<Case> caseList = new List<Case>();
         
         insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
			
         ASF_TestDataFactory.createCaseCategoryConfig();
         ASF_Case_Category_Config__c ccc = [Select id, Type__c, Sub_Type__c From ASF_Case_Category_Config__c Limit 1];
         ccc.Type__c = 'Statement & Documents';
         ccc.Sub_Type__c = 'Interest Schedule';
         update ccc;
          
         Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
         Account objAccount = new Account();
         objAccount.FirstName = 'TestFirstName';
         objAccount.LastName  = 'TestFirstName';
         objAccount.Line_of_Business__c = 'ABHFL';
         objAccount.RecordTypeId = recordTypeId;
         insert objAccount;

         ABHFL_Case_Detail__c abhflCaseDetRec = new ABHFL_Case_Detail__c();
         abhflCaseDetRec.Financial_Year__c = '2015-16';
         insert abhflCaseDetRec;
          
         Asset asst1 = new Asset();
         asst1.Name = 'Test Asset For IC';
         asst1.LAN__c = '23234432423';
         asst1.AccountId = objAccount.Id;
         asstList.add(asst1);

         Asset asst2 = new Asset();
         asst2.Name = 'Test Asset For PIC';
         asst2.AccountId = objAccount.Id;
         asstList.add(asst2);

         insert asstList;

         Case caseRec1 = new Case();
         caseRec1.Notes__c = 'Test Case 1';
         caseRec1.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
         caseRec1.AssetId = asstList[0].Id;
         caseRec1.AccountId = objAccount.Id;
         caseRec1.Technical_Source__c = 'Api';
         caseRec1.Type_Text__c = 'Statement & Documents';
         caseRec1.Sub_Type_Text__c = 'Interest Schedule';
         caseRec1.ABHFL_Case_Detail__c = abhflCaseDetRec.Id;
         caseList.add(caseRec1);

         Case caseRec2 = new Case();
         caseRec2.Notes__c = 'Test Case 2';
         caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
         caseRec2.AssetId = asstList[1].Id;
         caseRec2.AccountId = objAccount.Id;
         caseRec2.Technical_Source__c = 'Api';
         caseRec2.Type_Text__c = 'Statement & Documents';
         caseRec2.Sub_Type_Text__c = 'Interest Schedule';
         caseList.add(caseRec2);
		 
         Case caseRec3 = new Case();
         caseRec3.Notes__c = 'Test Case 3';
         caseRec3.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
         caseRec3.AssetId = asstList[0].Id;
         caseRec3.AccountId = objAccount.Id;
         caseRec3.Technical_Source__c = 'Api';
         caseRec3.Type_Text__c = 'Statement & Documents';
         caseRec3.Sub_Type_Text__c = 'Interest Schedule';
         caseList.add(caseRec3);
          
         Case caseRec4 = new Case();
         caseRec4.Notes__c = 'Test Case 4';
         caseRec4.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
         caseRec4.AssetId = asstList[1].Id;
         caseRec4.AccountId = objAccount.Id;
         caseRec4.Technical_Source__c = 'Api';
         caseRec4.Type_Text__c = 'Statement & Documents';
         caseRec4.Sub_Type_Text__c = 'Provisional Interest Certificate'; 
         caseList.add(caseRec4);
          
         insert caseList;
         
         ASF_Case_Integration__c caseInt1 = new ASF_Case_Integration__c();
         caseInt1.Case__c = caseRec1.Id;
         caseInt1.Status__c = 'Success';
         insert caseInt1;
          
         ASF_Case_Integration__c caseInt2 = new ASF_Case_Integration__c();
         caseInt2.Case__c = caseRec2.Id;
         caseInt2.Status__c = 'Success';
         insert caseInt2;
          
         ContentVersion cv = new ContentVersion();
         cv.Description  = 'test description';
         cv.PathOnClient ='test_file.txt';
         cv.Title = 'test file '+DateTime.now();
         cv.versiondata=Blob.valueOf('test file body');
         insert cv;
          
         // First get the content document Id from ContentVersion
         Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

         //Create ContentDocumentLink
         ContentDocumentLink cDe = new ContentDocumentLink();
         cDe.ContentDocumentId = conDoc;
         cDe.LinkedEntityId = caseInt2.Id; // you can use objectId,GroupId etc
         cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
         cDe.Visibility = 'AllUsers';
         insert cDe;

      }

      /****************************************************
       * @description - Test Method for evaluate Method
      *****************************************************/
      @isTest 
      static void evaluateTestMethod() {
        
        ABHFL_ICAndPIC_Integration icAndPicObj = new ABHFL_ICAndPIC_Integration();
        Case case1 = new Case();
        Case case2 = new Case();
        Case case3 = new Case();
        Case case4 = new Case();
          
        List<Case> caseLst = [Select id, Notes__c  From Case];
        for(Case cs : caseLst) {
            if(cs.Notes__c == 'Test Case 1') {
                case1 = cs;
            }
            else if(cs.Notes__c == 'Test Case 2') {
                case2 = cs;
            }
            else if(cs.Notes__c == 'Test Case 3') {
                case3 = cs;
            }
            else if(cs.Notes__c == 'Test Case 4') {
                case4 = cs;
            }
        }
          
        Test.startTest();
          	/* Description - Calling evaluate Method for 
           				     if condition when Both Loan Account Number and Financial Year is not Blank
			*/
            ASF_IntegrationsController.IntegrationWrapper result1 = icAndPicObj.evaluate(case1);
            System.assertEquals('Success', result1.status,'Done');
            System.assertEquals('Evaluation Success, Submit to get the Interest Certificate.', result1.response,'Done');
            
            /* Description - Calling evaluate Method for 
                                if condition when Both Loan Account Number and Financial Year is Blank
            */
            ASF_IntegrationsController.IntegrationWrapper result2 = icAndPicObj.evaluate(case2);
            System.assertEquals('Error', result2.status,'Done');
            System.assertEquals('Please fill the Financial Year and Loan Account Number also save the data before calling the STP.', result2.response,'Done');
            
            /* Description - Calling evaluate Method for 
                                if condition when Financial Year is Blank.
            */
            ASF_IntegrationsController.IntegrationWrapper result3 = icAndPicObj.evaluate(case3);
            System.assertEquals('Error', result3.status,'Done');
            System.assertEquals('Please fill the Financial Year.', result3.response,'Done');
            
            /* Description - Calling evaluate Method for 
                                if condition when Loan Account Number is Blank.
            */
            ASF_IntegrationsController.IntegrationWrapper result4 = icAndPicObj.evaluate(case4);
            System.assertEquals('Error', result4.status,'Done');
        Test.stopTest();
      }
      
      /****************************************************
       * @description - Test Method for run Method
      *****************************************************/
      @isTest 
      static void runTestMethod() {
          
      	ABHFL_ICAndPIC_Integration icAndPicObj = new ABHFL_ICAndPIC_Integration();
        Case case1 = new Case();
        ASF_Integration__c integ = new ASF_Integration__c();
          
        List<Case> caseLst = [Select id, Notes__c From Case];
        
        for(Case cs : caseLst) {
            if(cs.Notes__c == 'Test Case 1') {
                case1 = cs;
                break;
            }
        }
          
        Test.startTest();
          	ASF_IntegrationsController.IntegrationWrapper res = icAndPicObj.run(integ, case1);
		  	System.assertEquals('Success', res.status,'Done');
        Test.stopTest();
      }
      
      /****************************************************
       * @description - Test Method for processResponse Method
      *****************************************************/
      @isTest 
      static void processResponseTestMethod() {
          
      	  ABHFL_ICAndPIC_Integration icAndPicObj = new ABHFL_ICAndPIC_Integration();
          List<ASF_Case_Integration__c> caseIntegLst = [Select id, Case__c, Status__c from ASF_Case_Integration__c];
          
          Test.startTest();
              icAndPicObj.processResponse(caseIntegLst[0]);  //  when there is no files attached to Case Integration Record
          	  caseIntegLst[0].status__c = 'Failure';
          	  update caseIntegLst;
              icAndPicObj.processResponse(caseIntegLst[0]);	 //  when there is files attached to Case Integration Record
              System.assertEquals(2, caseIntegLst.size());
          Test.stopTest();
      }
  }