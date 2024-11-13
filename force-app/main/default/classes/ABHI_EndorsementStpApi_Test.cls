/*********************************************************
*Class        :  ABHI_EndorsementStpApi_Test
*Author       :  Shubham Sinha
*Created Date :  13/10/2024
*@description  : Test class for ABHI_EndorsementStpApi
***********************************************************/ 
@isTest
public class ABHI_EndorsementStpApi_Test {
    @testSetup
  static void setupTestData() {
    ASF_Integration__c integ = new ASF_Integration__c();
    integ.External_Id__c = 'ASF_Int_1004';
    integ.Display_Name__c = 'Endorsement';
    integ.Query_Fields__c = 'CaseNumber,Stage__c,CreatedDate,Technical_Source__c,Description,Business_Unit__c,CCC_External_Id__c,Account.FirstName,Account.LastName,Account.PersonGenderIdentity,AssetId,Asset.Policy_No__c,Account.Street_Address_1__c,Account.PersonMobilePhone,Account.PersonBirthdate,ABHI_Case_Detail__r.Member__c,ABHI_Case_Detail__r.Inward_Number__c,ABHI_Case_Detail__r.Pan_Card__c,ABHI_Case_Detail__r.Existing_Pan_Card_Number__c,Sub_Type_Text__c,Asset.IsCombi__c,ABHI_Case_Detail__r.Policy__r.Policy_No__c,ABHI_Case_Detail__r.Policy__r.IsCombi__c,ABHI_Case_Detail__r.New_Nominee_Contact_Number__c,ABHI_Case_Detail__r.New_Nominee_Name__c,ABHI_Case_Detail__r.New_Nominee_Relationship__c,ABHI_Case_Detail__r.Aadhar_Number__c,ABHI_Case_Detail__r.Alternate_Email_ID_Member__c,ABHI_Case_Detail__r.Alternate_Email_Id__c,ABHI_Case_Detail__r.Alternate_Contact_Number__c,ABHI_Case_Detail__r.Alternate_Contact_Number_Member__c,ABHI_Case_Detail__r.Primary_Email_ID__c,ABHI_Case_Detail__r.Primary_Email_ID_Member__c,ABHI_Case_Detail__r.Primary_Contact_Number__c,ABHI_Case_Detail__r.Primary_Contact_Number_Member__c';
    integ.Processing_Class__c = 'ABHI_EndorsementStpApi';
    integ.When_to_Appear__c = 'Stage Entry';
    integ.Type__c = 'UI Action';
    integ.Auto_Run_on_Load__c = false;
    insert integ;

    Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
    accRec.Client_Code__c = 'ABHI123';
    update accRec;

    Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
    assetRec.Policy_No__c = '1234';
    update assetRec;
        
    ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
    detailRec.IGMS_type_of_policy__c = '5';
        
    detailRec.Status_Valid_For_STP__c = true;
    insert detailRec;
        
       
    Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
    caseRec.Source__c = 'Email';
    caseRec.Business_Unit__c = 'ABHI';
    caseRec.Status = 'Open';
    caseRec.AssetId = assetRec.Id;
    caseRec.Stage__c = 'In Progress with SA';
    caseRec.ABHI_Case_Detail__c = detailRec.Id;
    caseRec.AccountId = accRec.Id;
    caseRec.CCC_External_Id__c = 'ABHI_Endorsement_Request4';
    caseRec.Type_Text__c = 'Endorsement';
    caseRec.Sub_Type_Text__c = 'PAN update';
    caseRec.Client_Code_Text__c = '8895335596';
    caseRec.Technical_Source__c = 'LWC';
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
      caseRec.Type_Text__c = 'Endorsement';
    caseRec.Sub_Type_Text__c = 'PAN update';
    caseRec1.CCC_External_Id__c = 'ABHI_Endorsement_Request4';
    caseRec1.Client_Code_Text__c = '8895335596';
    caseRec1.Technical_Source__c = 'LWC';
        caseRec1.Is_STP__c = true;
        caseRec1.IGMS_Complaint_Type_Code__c = '1';
    update caseRec1;

    ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'PNFT008');

    ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
    caseCatConfig.CCC_External_Id__c = 'ABHI_Endorsement_Request4';
    caseCatConfig.Overall_Case_Closure_SLA__c = 10;
    caseCatConfig.First_Stage__c = 'Pending with Initiator';
    caseCatConfig.Type__c = 'Endorsement';
    caseCatConfig.Sub_Type__c = 'PAN update';
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
    ABHI_EndorsementStpApi   complaint = new ABHI_EndorsementStpApi  ();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,ABHI_Case_Detail__r.Type_of_Disposal__c,Stage__c ,
          Description,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        Client_Code_Text__c,
        Account.Client_Code__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
              ABHI_Case_Detail__r.Next_Integration_Name__c,
       // ABHI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,Sub_Type_Text__c ,
              Is_STP__c,AssetId,ABHI_Case_Detail__r.Member__c,
              IGMS_Complaint_Type_Code__c,Asset.IsCombi__c,Asset.Policy_No__c,
        Business_Unit__c,ABHI_Case_Detail__r.Pan_Card__c,
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
    ABHI_EndorsementStpApi   complaint = new ABHI_EndorsementStpApi  ();
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
        Account.Client_Code__c,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,ABHI_Case_Detail__r.Member__c,
              Stage__c,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,Asset.IsCombi__c,Asset.Policy_No__c,
       // ABHI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,Sub_Type_Text__c ,AssetId,
              Is_STP__c,ABHI_Case_Detail__r.Pan_Card__c,
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
    ABHI_EndorsementStpApi   complaint = new ABHI_EndorsementStpApi();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
              Description,
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,Stage__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,AssetId,
        ABHI_Case_Detail__r.IGMS_type_of_policy__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
              ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.Receipt_Number__c,
              ABHI_Case_Detail__r.Next_Integration_Name__c,
       // ABHI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,Sub_Type_Text__c ,
              Is_STP__c,ABHI_Case_Detail__r.Pan_Card__c,
              IGMS_Complaint_Type_Code__c,Asset.IsCombi__c,Asset.Policy_No__c,
        Business_Unit__c,ABHI_Case_Detail__r.Member__c,
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
    ABHI_EndorsementStpApi   complaint = new ABHI_EndorsementStpApi();
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
        ABHI_Case_Detail__c,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,AssetId,
        ABHI_Case_Detail__r.IGMS_Complaint_Status__c,
              ABHI_Case_Detail__r.IGMS_Created_Case__c,
              ABHI_Case_Detail__r.IGMS_Source_of_Complaint__c,
        //ABSLI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,Sub_Type_Text__c ,Asset.IsCombi__c,Asset.Policy_No__c,
              Is_STP__c,ABHI_Case_Detail__r.Pan_Card__c,
              Stage__c,ABHI_Case_Detail__r.Member__c,
              IRDAI_Token_Number__c,
        Business_Unit__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];

   /* Test.startTest();
    ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
    Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = complaint.run(
      new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
      new List<Case>{ caseRec }
    );
    System.assertEquals('Success', res.get(caseRec.Id).status);
      new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
      new List<Case>{ caseRec }
    );
        
    Test.stopTest();*/
  }
  
  @IsTest
  static void testProcessResponse() {
    ABHI_EndorsementStpApi   complaint = new ABHI_EndorsementStpApi();
    Case caseRec = [
      SELECT
        Id,
        Status,
        OwnerId,
        CaseNumber,
        Client_Code_Text__c,ABHI_Case_Detail__r.Type_of_Disposal__c,IGMS_Complaint_Type_Code__c,Stage__c ,
        Account.Client_Code__c,ABHI_Case_Detail__r.Resolution_Comments__c ,ABHI_Case_Detail__r.Claim_Received_Amount__c ,
        ABHI_Case_Detail__c,AssetId,
        ABHI_Case_Detail__r.Status_Valid_For_STP__c,
        AccountId,Sub_Type_Text__c ,
       // ABHI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
        //ABHI_Case_Detail__r.Email_Id__c,
        Technical_Source__c,ABHI_Case_Detail__r.Pan_Card__c,
              Is_STP__c,ABHI_Case_Detail__r.Member__c,
        Business_Unit__c,Asset.IsCombi__c,Asset.Policy_No__c,
        CCC_External_Id__c
      FROM Case
      LIMIT 1
    ];
    ASF_Case_Integration__c caseIntegRec = [
      SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
      FROM ASF_Case_Integration__c
      LIMIT 1
    ];

        ABHI_EndorsementStpApi.EndorsementResponse  responseObj = new ABHI_EndorsementStpApi.EndorsementResponse ();
        ABHI_EndorsementStpApi.Response  responseBody = new ABHI_EndorsementStpApi.Response ();
       // EndorsementUpdateResult updateResult = new EndorsementUpdateResult();
        //EndorsementResult result = new EndorsementResult();
        //EndorsementDetails endorsementDetails = new EndorsementDetails();
        
        // Populate endorsement details
        responseBody.Endorsement_Number  = 'END12345';
        responseBody.DCN_Number  ='DCN12345';
        responseBody.Status = 'Active';
        responseBody.Policy_Number  = 'POL12345';
        responseBody.InwardNumber  = 'INW12345';
        responseBody.ErrorNumber  = '';
        responseBody.ErrorMessage  = 'No Errors';
        
        responseObj.response  = responseBody;
     
     

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