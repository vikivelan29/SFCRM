/*********************************************************
*Class        :  ABHI_RegisterIGMSComplaint_Test 
*Author       :  Shubham Sinha
*Created Date :  14/10/2024
*@description  : Test class for ABHI_RegisterIGMSComplaintIntegration  
***********************************************************/ 

@IsTest
public class ABHI_RegisterIGMSComplaint_Test {
  /**
   * @description Test Data Setup for this Test Class
   */
  @testSetup
  static void setupTestData() {
    ASF_Integration__c integ = new ASF_Integration__c();
    integ.External_Id__c = 'PNFT008';
    integ.Display_Name__c = 'Register IGMS Complaint';
    integ.Query_Fields__c = 'ABHI_Case_Detail__r.Status_Valid_For_STP__c,IGMS_Complaint_Type_Code__c ,ABHI_Case_Detail__r.Type_of_Disposal__c CaseNumber,Account.Client_Code__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ.Processing_Class__c = 'ABHI_RegisterIGMSComplaintIntegration';
    integ.When_to_Appear__c = 'Stage Entry';
    integ.Type__c = 'Process';
    integ.Auto_Run_on_Load__c = true;
    insert integ;

    Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
    accRec.Client_Code__c = 'ABHI123';
        accRec.PersonMobilePhone = '1234567890';
    update accRec;

    Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
    assetRec.Policy_No__c = '1234';
    update assetRec;
        
    ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
    detailRec.IGMS_type_of_policy__c = '5';
        detailRec.IGMS_Source_of_Complaint__c = '4';
        detailRec.Receipt_Number__c = 'ABHI0001';
        detailRec.IGMS_Complaint_Status__c = '2';
        detailRec.IGMS_Created_Case__c = true;
        detailRec.Complaint_Category__c = 'Complaint';
        detailRec.IRDAI_Token_Number__c = '43546512';
        detailRec.New_Registration_Date__c = System.today();
        detailRec.Next_Integration_Name__c = 'ABHI_AckIGMSComplaintIntegration'; 
      	detailRec.Status_Valid_For_STP__c = true;
    insert detailRec;
        
        ABHI_Case_Detail__c detailRec2 = new ABHI_Case_Detail__c();
    	detailRec2.IGMS_type_of_policy__c = '';
        detailRec2.IGMS_Source_of_Complaint__c = '';
        detailRec2.Receipt_Number__c = '';
        detailRec2.IRDAI_Token_Number__c = '';
        detailRec2.Complaint_Category__c = 'Complaint';
        detailRec2.IGMS_Complaint_Status__c = '1';
        detailRec2.IGMS_Created_Case__c = true;
        detailRec2.Status_Valid_For_STP__c = true;
        insert detailRec2;

    Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
    caseRec.Source__c = 'Email';
    caseRec.Business_Unit__c = 'ABHI';
    caseRec.Status = 'Open';
    caseRec.AssetId = assetRec.Id;
        caseRec.Stage__c = 'In Progress with SA';
    caseRec.ABHI_Case_Detail__c = detailRec.Id;
    caseRec.AccountId = accRec.Id;
    caseRec.CCC_External_Id__c = 'PNFT008';
    caseRec.Client_Code_Text__c = '8895335596';
    caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
        caseRec.IGMS_Complaint_Type_Code__c = '1';
    update caseRec;
        
        Case caseRec1 = ASF_TestDataFactory.createInteractionCaseRecords()[0];
    caseRec1.Source__c = 'Email';
    caseRec1.Business_Unit__c = 'ABHI';
    caseRec1.Status = 'Open';
    caseRec1.AssetId = assetRec.Id;
        caseRec1.Stage__c = 'Resolved';
    caseRec1.ABHI_Case_Detail__c = detailRec2.Id;
    caseRec1.AccountId = accRec.Id;
    caseRec1.CCC_External_Id__c = 'PNFT008';
    caseRec1.Client_Code_Text__c = '8895335596';
    caseRec1.Technical_Source__c = 'API';
        caseRec1.Is_STP__c = true;
        caseRec1.IGMS_Complaint_Type_Code__c = '1';
    update caseRec1;

    ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'PNFT008');

    ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
    caseCatConfig.CCC_External_Id__c = 'PNFT008';
    caseCatConfig.Overall_Case_Closure_SLA__c = 10;
    caseCatConfig.First_Stage__c = 'Pending with Initiator';
    caseCatConfig.Type__c = 'Bureau Related';
    caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
    caseCatConfig.Overall_Case_Closure_SLA__c = 56;
    caseCatConfig.Nature__c = 'Request';
    caseCatConfig.Source__c = 'CEC';
    caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
    insert caseCatConfig;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Status__c = 'Failure';
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseInt.Id;
        insert caseInt;
        
        ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
        caseIntUpdate.Id = caseInt.Id;
        caseIntUpdate.Integration_Ext_Id__c = integ.External_Id__c;
        caseIntUpdate.Status__c = 'Success';
        caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';

  }

  @isTest
  static void evaluate_Test_Method() {
    ABHI_RegisterIGMSComplaintIntegration  complaint = new ABHI_RegisterIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
              AssetId,
        Status,
        OwnerId,
        CaseNumber,
              Description,
        Client_Code_Text__c,
        Account.Client_Code__c,
              Account.PersonMobilePhone,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
              ABHI_Case_Detail__r.Complaint_Category__c,
        AccountId,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
        Technical_Source__c,
              Is_STP__c,
              IGMS_Complaint_Type_Code__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    ASF_IntegrationsController.IntegrationWrapper result = complaint.evaluate(caseRec);
    //System.assertEquals('Success', result.status);
    Test.stopTest();
  }
  @isTest
  static void run_Test_Method() {
    ABHI_RegisterIGMSComplaintIntegration complaint = new ABHI_RegisterIGMSComplaintIntegration();
    ASF_Integration__c integ = [
      SELECT Id, Processing_Class__c, External_Id__c
      FROM ASF_Integration__c
      LIMIT 1
    ];
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
        Client_Code_Text__c,
        Account.Client_Code__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,
              Stage__c,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
        Technical_Source__c,
              Is_STP__c,
        Business_Unit__c,
              IRDAI_Token_Number__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    ASF_IntegrationsController.IntegrationWrapper res = complaint.run(integ, caseRec);
    //System.assertEquals('Success', res.status);
    Test.stopTest();
  }
  
  @isTest
  static void evaluate_Test_MethodBulk() {
    ABHI_RegisterIGMSComplaintIntegration  complaint = new ABHI_RegisterIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
              AssetId,
        Status,
        OwnerId,
        CaseNumber,
              Description,
        Client_Code_Text__c,
        Account.Client_Code__c,
              Account.PersonMobilePhone,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
              ABHI_Case_Detail__r.Complaint_Category__c,
        AccountId,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
        Technical_Source__c,
              Is_STP__c,
              IGMS_Complaint_Type_Code__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = complaint.evaluate(
      new List<Case>{ caseRec }
    );
    //System.assertEquals('Success', result.get(caseRec.Id).status);
    Test.stopTest();
  }
  @isTest
  static void run_Test_MethodBulk() {
    ABHI_RegisterIGMSComplaintIntegration  complaint = new ABHI_RegisterIGMSComplaintIntegration ();
    ASF_Integration__c integ = [
      SELECT Id, Processing_Class__c, External_Id__c
      FROM ASF_Integration__c
      LIMIT 1
    ];

    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
        Client_Code_Text__c,
        Account.Client_Code__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
        Technical_Source__c,
              Is_STP__c,
              Stage__c,
        Business_Unit__c,
              IRDAI_Token_Number__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];
        ABHI_RegisterIGMSComplaintIntegration.objReq req = new ABHI_RegisterIGMSComplaintIntegration.objReq();
            req.User_Type = 'I';
            req.Complaint_Against_Type_Id = '1';
            req.Addressed_To_Insurer = 'Y';
            req.State_Id = '1';
            req.Complaint_Status_Id = '1';
            req.Insurance_Type_Id = '2';
            req.Status_Change_Date = '';
            req.District_Id = '1';
            req.Identifier_Type = '1';
            req.Trans_Login_Id = 'abhiadmin';
            req.Option = '1';
            req.Mode = '1';
          //req.First_Name = 'test';
        //req.Last_Name = 'test';
        req.Sex = 'male';
        req.Address1 = 'address';
        req.Entity_Complaint_Ref_Number= '123';
        req.Complaint_Details= 'testdetail';
        req.Date_Of_Birth= '04/04/2024';
        req.Complaint_Date= '04/04/2024';
        req.Complaint_Receipt_Date= '04/04/2024';
        req.Policy_Type_Id= '4321';
        req.Complaint_Type_Id= '4321'; 
        req.Complaint_Description_Id= '4321';
        req.Source_Of_Complaint= '4321';
        req.Receipt_Number= '4321'; 
        req.Policy_Number= '4321'; 
        req.Mobile_Number= '4321';
        req.Policy_Proposal_Cert_ClaimNumber= '4321'; 
        

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = complaint.run(
      new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
      new List<Case>{ caseRec }
    );
    //System.assertEquals('Success', res.get(caseRec.Id).status);
    Test.stopTest();
  }
  
  @IsTest
  static void testProcessResponse() {
    ABHI_RegisterIGMSComplaintIntegration  complaint = new ABHI_RegisterIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
        Client_Code_Text__c,
        Account.Client_Code__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,
        Technical_Source__c,
              Is_STP__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];
    ASF_Case_Integration__c caseIntegRec = [
      SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
      FROM ASF_Case_Integration__c
      LIMIT 1
    ];

   ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponseWrapper   responseObj = new ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponseWrapper();
 ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponseBody  responseBody = new ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponseBody();
        ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponse  updateComplaintResponse = new ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResponse();
        ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResult  updateComplaintResult = new ABHI_RegisterIGMSComplaintIntegration.RegisterComplaintResult();
        ABHI_RegisterIGMSComplaintIntegration.Result result = new ABHI_RegisterIGMSComplaintIntegration.Result();
        ABHI_RegisterIGMSComplaintIntegration.ComplaintDetails complaintDetails = new ABHI_RegisterIGMSComplaintIntegration.ComplaintDetails();
        
        // Populate complaint details
        complaintDetails.IRDA_TOKEN_NUMBER = 'IRDA12345';
        complaintDetails.ENTITY_COMPLAINT_REF_NUMBER = 'REF12345';
        complaintDetails.ERROR_CODES = '';
        
        // Assign the complaint details to result, then to the update result
        result.COMPLAINTDETAILS = complaintDetails;
        updateComplaintResult.RESULT = result;
        
        // Assign the update response to the update complaint response
        updateComplaintResponse.RegisterComplaintResult = updateComplaintResult;
        
        // Assign the update complaint response to the body
        responseBody.RegisterComplaintResponse = updateComplaintResponse;
        
        // Assign the body to the response wrapper
        responseObj.Body = responseBody;
      responseObj.TRANSFORMED_ERROR_MESSAGE = 'SAV';

    caseIntegRec.Response__c = JSON.serialize(responseObj);
    caseIntegRec.Status__c = 'Success';
    update caseIntegRec;

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    complaint.processResponse(caseIntegRec);
    System.assertEquals(caseIntegRec.Status__c, 'Success');
    Test.stopTest();
  }

}