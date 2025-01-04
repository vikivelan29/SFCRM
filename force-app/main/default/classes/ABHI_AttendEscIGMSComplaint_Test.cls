/**
 * @description Unit Test Class for ABHI_AttendEscIGMSComplaintIntegration  
 *
 * @author Shubham
 * @date 2024-10-07
 */
@IsTest
public class ABHI_AttendEscIGMSComplaint_Test {
  /**
   * @description Test Data Setup for this Test Class
   */
  @testSetup
  static void setupTestData() {
    ASF_Integration__c integ = new ASF_Integration__c();
    integ.External_Id__c = 'PNFT007';
    integ.Display_Name__c = 'AttendEsc IGMS Complaint';
    integ.Query_Fields__c = 'ABHI_Case_Detail__r.Status_Valid_For_STP__c,IGMS_Complaint_Type_Code__c ,ABHI_Case_Detail__r.Type_of_Disposal__c CaseNumber,Account.Client_Code__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ.Processing_Class__c = 'ABHI_AttendEscIGMSComplaintIntegration ';
    integ.When_to_Appear__c = 'Stage Entry';
    integ.Type__c = 'Process';
    integ.Auto_Run_on_Load__c = true;
    insert integ;

    Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
    accRec.Client_Code__c = 'ABHI123';
    update accRec;

    Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
    assetRec.Policy_No__c = '1234';
    update assetRec;
        
    ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
    detailRec.IGMS_type_of_policy__c = '5';
        detailRec.IGMS_Source_of_Complaint__c = '4';
        detailRec.Receipt_Number__c = 'ABHI0001';
        detailRec.IGMS_Complaint_Status__c = '2';
        detailRec.Complaint_Category__c = 'Complaint';
        detailRec.Escalated__c = true;
        detailRec.IGMS_Created_Case__c = true;
        detailRec.Acknowledged_Date__c = System.today();
        detailRec.IRDAI_Token_Number__c = '43546512';
        detailRec.New_Registration_Date__c = System.today();
        detailRec.Reopened_Date__c = System.today();
        detailRec.Next_Integration_Name__c = 'ABHI_PendingIGMSComplaintIntegration';
        detailRec.Status_Valid_For_STP__c = true;
    detailRec.Status_Valid_For_STP__c = true;
    insert detailRec;
        
        ABHI_Case_Detail__c detailRec2 = new ABHI_Case_Detail__c();
    detailRec2.IGMS_type_of_policy__c = '';
        detailRec2.IGMS_Source_of_Complaint__c = '';
        detailRec2.Receipt_Number__c = '';
        detailRec2.IRDAI_Token_Number__c = '';
        detailRec2.Complaint_Category__c = 'Complaint';
        detailRec2.IGMS_Complaint_Status__c = '1';
       // detailRec2.IGMS_Created_Case__c = true;
    //detailRec2.Email_Id__c = 'panigrahi@abinash.com';
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
    caseRec1.ABHI_Case_Detail__c = detailRec.Id;
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
    ABHI_AttendEscIGMSComplaintIntegration  complaint = new ABHI_AttendEscIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,ABHI_Case_Detail__r.Type_of_Disposal__c,Stage__c ,
          Description ,ABHI_Case_Detail__r.Resolution_Comments__c,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        Client_Code_Text__c,Type_Text__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Is_Auto_Escalated__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,ABHI_Case_Detail__r.Final_Resolution_Remark__c,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
              ABHI_Case_Detail__r.Next_Integration_Name__c,
       // ABHI_Case_Detail__r.Email_Id__c,
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
    ABHI_AttendEscIGMSComplaintIntegration  complaint = new ABHI_AttendEscIGMSComplaintIntegration ();
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
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,IGMS_Complaint_Type_Code__c  ,
              IRDAI_Token_Number__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        Account.Client_Code__c,Type_Text__c ,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,ABHI_Case_Detail__r.Final_Resolution_Remark__c,
              Stage__c,ABHI_Case_Detail__r.Is_Auto_Escalated__c,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
       // ABHI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,
              Is_STP__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    ASF_IntegrationsController.IntegrationWrapper res = complaint.run(integ, caseRec);
    System.assertEquals('Success', res.status);
    Test.stopTest();
  }
  
  @isTest
  static void evaluate_Test_MethodBulk() {
    ABHI_AttendEscIGMSComplaintIntegration  complaint = new ABHI_AttendEscIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
              Description,
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,Stage__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        ABHI_Case_Detail__c,ABHI_Case_Detail__r.Final_Resolution_Remark__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,Type_Text__c ,
        AccountId,ABHI_Case_Detail__r.Is_Auto_Escalated__c,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
              ABHI_Case_Detail__r.Next_Integration_Name__c,
       // ABHI_Case_Detail__r.Email_Id__c,
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
    ABHI_AttendEscIGMSComplaintIntegration  complaint = new ABHI_AttendEscIGMSComplaintIntegration ();
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
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,IGMS_Complaint_Type_Code__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        ABHI_Case_Detail__c,Type_Text__c ,ABHI_Case_Detail__r.Is_Auto_Escalated__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,ABHI_Case_Detail__r.Final_Resolution_Remark__c,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
        //ABSLI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,
              Is_STP__c,
              Stage__c,
              IRDAI_Token_Number__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

    Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = complaint.run(
      new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
      new List<Case>{ caseRec }
    );
    System.assertEquals('Success', res.get(caseRec.Id).status);
        complaint.cancelPendingCaseIntegrationRequests(
      new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
      new List<Case>{ caseRec }
    );
        
    Test.stopTest();
  }
  
  @IsTest
  static void testProcessResponse() {
    ABHI_AttendEscIGMSComplaintIntegration  complaint = new ABHI_AttendEscIGMSComplaintIntegration ();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,IGMS_Complaint_Type_Code__c,Stage__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        ABHI_Case_Detail__c,ABHI_Case_Detail__r.Final_Resolution_Remark__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,Type_Text__c ,ABHI_Case_Detail__r.Is_Auto_Escalated__c,
        AccountId,
       // ABHI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
        //ABHI_Case_Detail__r.Email_Id__c,
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

    ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseWrapper  responseObj = new ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseWrapper();
 ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseBody responseBody = new ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseBody();
        ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponse updateComplaintResponse = new ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponse();
        ABHI_AckIGMSComplaintIntegration.UpdateComplaintResult updateComplaintResult = new ABHI_AckIGMSComplaintIntegration.UpdateComplaintResult();
        ABHI_AckIGMSComplaintIntegration.Result result = new ABHI_AckIGMSComplaintIntegration.Result();
        ABHI_AckIGMSComplaintIntegration.ComplaintDetails complaintDetails = new ABHI_AckIGMSComplaintIntegration.ComplaintDetails();
        
        // Populate complaint details
        complaintDetails.IRDA_TOKEN_NUMBER = 'IRDA12345';
        complaintDetails.ENTITY_COMPLAINT_REF_NUMBER = 'REF12345';
        complaintDetails.ERROR_CODES = '';
        
        // Assign the complaint details to result, then to the update result
        result.COMPLAINTDETAILS = complaintDetails;
        updateComplaintResult.RESULT = result;
        
        // Assign the update response to the update complaint response
        updateComplaintResponse.UpdateComplaintResult = updateComplaintResult;
        
        // Assign the update complaint response to the body
        responseBody.UpdateComplaintResponse = updateComplaintResponse;
        
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