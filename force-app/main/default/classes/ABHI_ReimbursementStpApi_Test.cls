/**
 * @description       : Test Class for ABHI_ReimbursementStpApi_Test
 * @author            : Amrit Preet Singh
 * @group             : 
 * @last modified on  : 11/11/2024
 * @last modified by  : Amrit Preet Singh
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   20-09-2024   amritpreet.singh@salesforce.com   Initial Version
**/
@isTest 
class ABHI_ReimbursementStpApi_Test {
    
    @TestSetup
    static void makeData(){
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account acc = new Account(
            FirstName = 'TestABHi',
            LastName= 'TestLastName',
            Line_of_Business__c = 'ABHI',
            Business_Unit__c = 'ABHI',
            Aadhar_No__c = '989878767878',
            Client_Code__c = '8709',
            RecordTypeId = recordTypeId,
            SumInsured__c = '1200'
        );
        insert acc;
        Asset ass = new Asset(
            AccountId = acc.Id,
            Policy_No__c = '56567',
            SerialNumber = '445637',
            Name = 'TestABC'
        );
        
        insert ass;
        Health_Provider__c hp = new Health_Provider__c(
            Business_Unit__c = 'ABHI',
            Provider_Name__c = 'Apollo',
            Provider_Code__c = '3454'
        );
        insert hp;
        Cover__c cov= new Cover__c(
            Cover_Name__c = 'Test',
            Cover_Code__c = '3454'
        );
        insert cov;
        ASF_Case_Category_Config__c ccInst = new ASF_Case_Category_Config__c(
            Type__c = 'Endorsement',
            Sub_Type__c = 'PAN update',
            Business_Unit__c = 'ABHI',
            CCC_External_Id__c = 'ABHI_Endorsement_Request4',
            Overall_Case_Closure_SLA__c = 63,
            Nature__c = 'Request'
        );
        insert ccInst;
        ASF_Case_Stage_Config__c cscInst = new ASF_Case_Stage_Config__c(
            Case_Category_Config__c = ccInst.Id,
            Query_Fields__c = 'Stage__c,Asset.PolicyType__c,Asset.Type__c,Asset.IntermediaryName__c',
            StageName__c = 'Open',
            Status_Mapping__c = 'Open'
        );
        insert cscInst;
        ASF_Integration__c intRec = new ASF_Integration__c(
            Case_Stage_Config__c = cscInst.Id,
            Do_Not_Retry_Integration__c = false,
            External_Id__c = 'ASF_Int1-CSC1-10001',
            Query_Fields__c = 'CaseNumber,Stage__c,CreatedDate,Customer_name_formula__c,Type_Text__c,Technical_Source__c,Description,Business_Unit__c,CCC_External_Id__c,Account.FirstName,Account.LastName,Account.PersonGenderIdentity,AssetId,Asset.Policy_No__c,Account.Street_Address_1__c,Account.PersonMobilePhone,Account.Client_Code__c,Account.PersonBirthdate,ABHI_Case_Detail__r.Member__c,ABHI_Case_Detail__r.Inward_Number__c,ABHI_Case_Detail__r.Pan_Card__c,ABHI_Case_Detail__r.Existing_Pan_Card_Number__c,Sub_Type_Text__c,Asset.IsCombi__c,ABHI_Case_Detail__r.Policy__r.Policy_No__c,ABHI_Case_Detail__r.Policy__r.IsCombi__c,ABHI_Case_Detail__r.New_Nominee_Contact_Number__c,ABHI_Case_Detail__r.New_Nominee_Name__c,ABHI_Case_Detail__r.New_Nominee_Relationship__c,ABHI_Case_Detail__r.Aadhar_Number__c,ABHI_Case_Detail__r.Alternate_Email_ID_Member__c,ABHI_Case_Detail__r.Alternate_Email_Id__c,ABHI_Case_Detail__r.Alternate_Contact_Number__c,ABHI_Case_Detail__r.Alternate_Contact_Number_Member__c,ABHI_Case_Detail__r.Primary_Email_ID__c,ABHI_Case_Detail__r.Primary_Email_ID_Member__c,ABHI_Case_Detail__r.Primary_Contact_Number__c,ABHI_Case_Detail__r.Primary_Contact_Number_Member__c,Claim__r.Claim_Amount__c,ABHI_Case_Detail__r.Cover_Name__r.Cover_Code__c,ABHI_Case_Detail__r.Cover_Name__r.Cover_Name__c,ABHI_Case_Detail__r.Hospital__r.Name,ABHI_Case_Detail__r.Hospital__r.Provider_Code__c,ABHI_Case_Detail__r.Date_of_Admission__c,ABHI_Case_Detail__r.Date_of_Discharge__c,ABHI_Case_Detail__r.Claim_Amount__c,ABHI_Case_Detail__r.Patient_Name__r.Member_Name__c,ABHI_Case_Detail__r.Patient_Name__c,ABHI_Case_Detail__r.Hospital_Name__c',
            When_to_Appear__c = 'During Stage',
            Processing_Class__c = 'ABHI_ReimbursementStpApi',
            Type__c = 'Process',
            Display_Order__c=1,
            Display_Name__c = 'Intimation'
        );
        insert intRec;
        Customer_Member_Mapping__c cmRec = new Customer_Member_Mapping__c(
            Client_Id__c = acc.Id,
            Business_Unit__c = 'ABHI',
            Customer_Type__c = 'VIP',
            MemberExternalId__c = '28282192',
            MemberId__c = acc.Id,
            Policy_Number__c = ass.Id
        );
        insert cmRec;
        ABHI_Case_Detail__c cdRec = new ABHI_Case_Detail__c(
            Complaint_Category__c = 'Complaint',
            Existing_Pan_Card_Number__c = 'LT906382G',
            Policy__c = ass.Id,
            Sub_Type__c = 'Endorsement:PAN update',
            Member__c = cmRec.Id,
            Hospital__c = hp.Id,
            Cover_Name__c = cov.Id,
            Date_of_Admission__c = Datetime.now(),
            Date_of_Discharge__c = Datetime.now()+1
        );
        insert cdRec;
        Case c = new Case(
            AccountId = acc.Id,
            AssetId = ass.Id,
            Stage__c = 'Open',
            Business_Unit__c = 'ABHI',
            ABHI_Case_Detail__c = cdRec.Id,
            Subject = 'Case - Endorsement',
            Source__c = 'Social Media',
            CCC_External_Id__c = 'ABHI_Endorsement_Request4',
            Technical_Source__c = 'LWC',
            Type_Text__c = 'Cashless',
            Sub_Type_Text__c = 'Claims status'
        );
        insert c;

        ASF_IntegrationsController.getAllIntegrations(intRec.C3ExternalId__c,'Open');
        ASF_IntegrationsController.runIntegration(intRec,c);
        
    }

    @isTest 
    static void testRunMethod() {
        Case caseRec = [SELECT Id from Case LIMIT 1];
        Id caseId = caseRec.Id;
        ASF_Integration__c afInt = [SELECT id, External_Id__c, Processing_Class__c, Query_Fields__c from ASF_Integration__c LIMIT 1];
        Set<String> allFields = new Set<String>{'id'};
            if(afInt.Query_Fields__c != null){
                allFields.addAll(afInt.Query_Fields__c.toLowerCase().split(','));
            }
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>((List<Case>)Database.query(
                'SELECT ' +
                String.join(allFields, ',') +
                ' FROM Case WHERE Id = : caseId'
            ));
        ABHI_ReimbursementStpApi apInst = new ABHI_ReimbursementStpApi();
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = apInst.run(afInt,caseRec);
        System.assertEquals('IGMS Sync Request Successful!', result.response, 'Response not correct');
    }

    @isTest
    static void testProcessResponse() {
        Case caseRec = [SELECT Id, Stage__c, Description from Case LIMIT 1];
        ASF_Case_Integration__c acInt = new ASF_Case_Integration__c(
            Case__c = caseRec.Id,
            Integration_Ext_Id__c = 'ASF_Int1-CSC1-10001',
            Is_Validation_Success__c = true,
            Request__c = '{"attributes":{"type":"Case_Integration_Outbound__e","url":"/services/data/v62.0/sobjects/Case_Integration_Outbound__e/64709253"},"Business_Unit__c":"ABHI","CreatedById":"005Bl000003v4UTIAY","ReplayId":"64709253","Request_Payload__c":"{\"PreexistingObj\":[{\"Status\":null,\"Sincewhen\":null,\"Remarks\":null,\"Preexisting_Deases\":\"\"}],\"PreAuthObj\":[{\"Time_of_Discharge\":null,\"Time_of_Admission\":null,\"Test_ConductedToEstablishThis\":null,\"Source_System_Code\":null,\"Service_flag\":null,\"Room_Type\":null,\"ReportedtoPolice\":null,\"ReleventClinicalFinding\":null,\"ProvisionalDiagnosis\":null,\"Proposed_line_of_treatment\":null,\"Policy_Number\":\"12345678\",\"Patient_Name\":null,\"P\":null,\"Other_Ind\":null,\"Name_Of_Treating_Doctor\":null,\"Name_Of_Surgery\":null,\"L\":null,\"IsPreexisting\":null,\"IsNaturalCalamityCase\":null,\"IsMaternity\":null,\"IsItRTA\":null,\"IRDA_Code_Of_surgery\":null,\"Investigation_MedicalManagementDetails\":null,\"Intimation_Type\":null,\"Injury_Disease_Alcohalconsumption\":null,\"How_did_injury_occur\":null,\"Hospital_WebSite\":null,\"Hospital_StdCode\":null,\"Hospital_State\":null,\"Hospital_PinCode\":null,\"Hospital_PhoneNo\":null,\"Hospital_Nm\":null,\"Hospital_Name\":null,\"Hospital_MobileNo\":null,\"Hospital_Mail\":null,\"Hospital_LandMark\":null,\"Hospital_FaxNo\":null,\"Hospital_District\":null,\"Hospital_Country\":null,\"Hospital_Code\":null,\"Hospital_City\":null,\"Hospital_Address\":null,\"G\":null,\"FirNo\":null,\"FamilyId\":\"352344\",\"Emergency_Planned_Event\":null,\"Duration_Of_Present_Ailment\":null,\"Document_Received_Time\":null,\"Document_Received_Date\":null,\"Doctor_Registration_No\":null,\"Doctor_Contact_No\":null,\"Diagnosis\":null,\"DeaseasWithPresentingComplaints\":null,\"DateOfFirstConsultation\":null,\"Date_Of_Inhury\":null,\"Date_of_Discharge\":null,\"Date_Of_Delivery\":null,\"Date_of_Admission\":null,\"Cover_Name\":null,\"Cover_code\":null,\"Co_morbidities\":null,\"Claim_Intimation_Through\":null,\"Claim_Intimation_Source\":null,\"Claim_Amount\":null,\"Case_Of_accident\":null,\"AnyOtherAilments\":null,\"AnyHivorStdRelatedAilments\":null,\"AlcohalordrugAbuse\":null,\"A\":null}],\"PCSObj\":null,\"ICDObj\":null,\"DocObj\":null}","EventUuid":"21664ecb-c252-455b-a3e5-3aca00ac4b10","CreatedDate":"2024-11-05T04:13:39.000+0000","ServiceName__c":"ClaimIntimation","Case_Integration_ID__c":"ASF_CInt_751810","Integration_Name__c":"ClaimIntimation"}',
            Response__c = '{"Code":"101","Message":"Entered Policy Number : GHI-HB-22-2095784-V2 doesnt exists. Please check the Health Card and submit the Request again.","Claim_Number":"7576","Pre_Auth_Id":""}',
            Status__c = 'Success'
        );
        insert acInt;
        ABHI_ReimbursementStpApi apInst = new ABHI_ReimbursementStpApi();
        Test.startTest();
        apInst.processResponse(acInt);
        Test.stopTest();
        List<Case> caseList = [SELECT id from Case];
        System.assertNotEquals(0, caseList.size(), 'Error in fetching Case');
    }

    @isTest
    static void testProcessFailureResponse() {
        Case caseRec = [SELECT Id, Stage__c, Description from Case LIMIT 1];
        ASF_Case_Integration__c acInt = new ASF_Case_Integration__c(
            Case__c = caseRec.Id,
            Integration_Ext_Id__c = 'ASF_Int1-CSC1-10001',
            Is_Validation_Success__c = true,
            Request__c = '{"attributes":{"type":"Case_Integration_Outbound__e","url":"/services/data/v62.0/sobjects/Case_Integration_Outbound__e/64709253"},"Business_Unit__c":"ABHI","CreatedById":"005Bl000003v4UTIAY","ReplayId":"64709253","Request_Payload__c":"{\"PreexistingObj\":[{\"Status\":null,\"Sincewhen\":null,\"Remarks\":null,\"Preexisting_Deases\":\"\"}],\"PreAuthObj\":[{\"Time_of_Discharge\":null,\"Time_of_Admission\":null,\"Test_ConductedToEstablishThis\":null,\"Source_System_Code\":null,\"Service_flag\":null,\"Room_Type\":null,\"ReportedtoPolice\":null,\"ReleventClinicalFinding\":null,\"ProvisionalDiagnosis\":null,\"Proposed_line_of_treatment\":null,\"Policy_Number\":\"12345678\",\"Patient_Name\":null,\"P\":null,\"Other_Ind\":null,\"Name_Of_Treating_Doctor\":null,\"Name_Of_Surgery\":null,\"L\":null,\"IsPreexisting\":null,\"IsNaturalCalamityCase\":null,\"IsMaternity\":null,\"IsItRTA\":null,\"IRDA_Code_Of_surgery\":null,\"Investigation_MedicalManagementDetails\":null,\"Intimation_Type\":null,\"Injury_Disease_Alcohalconsumption\":null,\"How_did_injury_occur\":null,\"Hospital_WebSite\":null,\"Hospital_StdCode\":null,\"Hospital_State\":null,\"Hospital_PinCode\":null,\"Hospital_PhoneNo\":null,\"Hospital_Nm\":null,\"Hospital_Name\":null,\"Hospital_MobileNo\":null,\"Hospital_Mail\":null,\"Hospital_LandMark\":null,\"Hospital_FaxNo\":null,\"Hospital_District\":null,\"Hospital_Country\":null,\"Hospital_Code\":null,\"Hospital_City\":null,\"Hospital_Address\":null,\"G\":null,\"FirNo\":null,\"FamilyId\":\"352344\",\"Emergency_Planned_Event\":null,\"Duration_Of_Present_Ailment\":null,\"Document_Received_Time\":null,\"Document_Received_Date\":null,\"Doctor_Registration_No\":null,\"Doctor_Contact_No\":null,\"Diagnosis\":null,\"DeaseasWithPresentingComplaints\":null,\"DateOfFirstConsultation\":null,\"Date_Of_Inhury\":null,\"Date_of_Discharge\":null,\"Date_Of_Delivery\":null,\"Date_of_Admission\":null,\"Cover_Name\":null,\"Cover_code\":null,\"Co_morbidities\":null,\"Claim_Intimation_Through\":null,\"Claim_Intimation_Source\":null,\"Claim_Amount\":null,\"Case_Of_accident\":null,\"AnyOtherAilments\":null,\"AnyHivorStdRelatedAilments\":null,\"AlcohalordrugAbuse\":null,\"A\":null}],\"PCSObj\":null,\"ICDObj\":null,\"DocObj\":null}","EventUuid":"21664ecb-c252-455b-a3e5-3aca00ac4b10","CreatedDate":"2024-11-05T04:13:39.000+0000","ServiceName__c":"ClaimIntimation","Case_Integration_ID__c":"ASF_CInt_751810","Integration_Name__c":"ClaimIntimation"}',
            Response__c = '{"Code":"101","Message":"Entered Policy Number : GHI-HB-22-2095784-V2 doesnt exists. Please check the Health Card and submit the Request again.","Claim_Number":"","Pre_Auth_Id":""}',
            Status__c = 'Failure'
        );
        insert acInt;
        ABHI_ReimbursementStpApi apInst = new ABHI_ReimbursementStpApi();
        Test.startTest();
        apInst.processResponse(acInt);
        Test.stopTest();
        List<Case> caseList = [SELECT id from Case];
        System.assertNotEquals(0, caseList.size(), 'Error in fetching Case');
    }

    @isTest
    static void testCancelPendingInt(){
        List<Case> rec =  [SELECT Id FROM Case LIMIT 1];
        List<ASF_Case_Integration__c> acIntList = new List<ASF_Case_Integration__c>();
        ASF_Case_Integration__c acInt1 = new ASF_Case_Integration__c(
            Case__c = rec[0].Id,
            Integration_Ext_Id__c = 'ASF_Int1-CSC1-10001',
            Is_Validation_Success__c = true,
            Request__c = '{"attributes":{"type":"Case_Integration_Outbound__e","url":"/services/data/v62.0/sobjects/Case_Integration_Outbound__e/64709253"},"Business_Unit__c":"ABHI","CreatedById":"005Bl000003v4UTIAY","ReplayId":"64709253","Request_Payload__c":"{\"PreexistingObj\":[{\"Status\":null,\"Sincewhen\":null,\"Remarks\":null,\"Preexisting_Deases\":\"\"}],\"PreAuthObj\":[{\"Time_of_Discharge\":null,\"Time_of_Admission\":null,\"Test_ConductedToEstablishThis\":null,\"Source_System_Code\":null,\"Service_flag\":null,\"Room_Type\":null,\"ReportedtoPolice\":null,\"ReleventClinicalFinding\":null,\"ProvisionalDiagnosis\":null,\"Proposed_line_of_treatment\":null,\"Policy_Number\":\"12345678\",\"Patient_Name\":null,\"P\":null,\"Other_Ind\":null,\"Name_Of_Treating_Doctor\":null,\"Name_Of_Surgery\":null,\"L\":null,\"IsPreexisting\":null,\"IsNaturalCalamityCase\":null,\"IsMaternity\":null,\"IsItRTA\":null,\"IRDA_Code_Of_surgery\":null,\"Investigation_MedicalManagementDetails\":null,\"Intimation_Type\":null,\"Injury_Disease_Alcohalconsumption\":null,\"How_did_injury_occur\":null,\"Hospital_WebSite\":null,\"Hospital_StdCode\":null,\"Hospital_State\":null,\"Hospital_PinCode\":null,\"Hospital_PhoneNo\":null,\"Hospital_Nm\":null,\"Hospital_Name\":null,\"Hospital_MobileNo\":null,\"Hospital_Mail\":null,\"Hospital_LandMark\":null,\"Hospital_FaxNo\":null,\"Hospital_District\":null,\"Hospital_Country\":null,\"Hospital_Code\":null,\"Hospital_City\":null,\"Hospital_Address\":null,\"G\":null,\"FirNo\":null,\"FamilyId\":\"352344\",\"Emergency_Planned_Event\":null,\"Duration_Of_Present_Ailment\":null,\"Document_Received_Time\":null,\"Document_Received_Date\":null,\"Doctor_Registration_No\":null,\"Doctor_Contact_No\":null,\"Diagnosis\":null,\"DeaseasWithPresentingComplaints\":null,\"DateOfFirstConsultation\":null,\"Date_Of_Inhury\":null,\"Date_of_Discharge\":null,\"Date_Of_Delivery\":null,\"Date_of_Admission\":null,\"Cover_Name\":null,\"Cover_code\":null,\"Co_morbidities\":null,\"Claim_Intimation_Through\":null,\"Claim_Intimation_Source\":null,\"Claim_Amount\":null,\"Case_Of_accident\":null,\"AnyOtherAilments\":null,\"AnyHivorStdRelatedAilments\":null,\"AlcohalordrugAbuse\":null,\"A\":null}],\"PCSObj\":null,\"ICDObj\":null,\"DocObj\":null}","EventUuid":"21664ecb-c252-455b-a3e5-3aca00ac4b10","CreatedDate":"2024-11-05T04:13:39.000+0000","ServiceName__c":"ClaimIntimation","Case_Integration_ID__c":"ASF_CInt_751810","Integration_Name__c":"ClaimIntimation"}',
            Response__c = '{"Code":"101","Message":"Entered Policy Number : GHI-HB-22-2095784-V2 doesnt exists. Please check the Health Card and submit the Request again.","Claim_Number":"7576","Pre_Auth_Id":""}',
            Status__c = 'Pending'
        );
        ASF_Case_Integration__c acInt2 = new ASF_Case_Integration__c(
            Case__c = rec[0].Id,
            Integration_Ext_Id__c = 'ASF_Int1-CSC1-10001',
            Is_Validation_Success__c = true,
            Request__c = '{"attributes":{"type":"Case_Integration_Outbound__e","url":"/services/data/v62.0/sobjects/Case_Integration_Outbound__e/64709253"},"Business_Unit__c":"ABHI","CreatedById":"005Bl000003v4UTIAY","ReplayId":"64709253","Request_Payload__c":"{\"PreexistingObj\":[{\"Status\":null,\"Sincewhen\":null,\"Remarks\":null,\"Preexisting_Deases\":\"\"}],\"PreAuthObj\":[{\"Time_of_Discharge\":null,\"Time_of_Admission\":null,\"Test_ConductedToEstablishThis\":null,\"Source_System_Code\":null,\"Service_flag\":null,\"Room_Type\":null,\"ReportedtoPolice\":null,\"ReleventClinicalFinding\":null,\"ProvisionalDiagnosis\":null,\"Proposed_line_of_treatment\":null,\"Policy_Number\":\"12345678\",\"Patient_Name\":null,\"P\":null,\"Other_Ind\":null,\"Name_Of_Treating_Doctor\":null,\"Name_Of_Surgery\":null,\"L\":null,\"IsPreexisting\":null,\"IsNaturalCalamityCase\":null,\"IsMaternity\":null,\"IsItRTA\":null,\"IRDA_Code_Of_surgery\":null,\"Investigation_MedicalManagementDetails\":null,\"Intimation_Type\":null,\"Injury_Disease_Alcohalconsumption\":null,\"How_did_injury_occur\":null,\"Hospital_WebSite\":null,\"Hospital_StdCode\":null,\"Hospital_State\":null,\"Hospital_PinCode\":null,\"Hospital_PhoneNo\":null,\"Hospital_Nm\":null,\"Hospital_Name\":null,\"Hospital_MobileNo\":null,\"Hospital_Mail\":null,\"Hospital_LandMark\":null,\"Hospital_FaxNo\":null,\"Hospital_District\":null,\"Hospital_Country\":null,\"Hospital_Code\":null,\"Hospital_City\":null,\"Hospital_Address\":null,\"G\":null,\"FirNo\":null,\"FamilyId\":\"352344\",\"Emergency_Planned_Event\":null,\"Duration_Of_Present_Ailment\":null,\"Document_Received_Time\":null,\"Document_Received_Date\":null,\"Doctor_Registration_No\":null,\"Doctor_Contact_No\":null,\"Diagnosis\":null,\"DeaseasWithPresentingComplaints\":null,\"DateOfFirstConsultation\":null,\"Date_Of_Inhury\":null,\"Date_of_Discharge\":null,\"Date_Of_Delivery\":null,\"Date_of_Admission\":null,\"Cover_Name\":null,\"Cover_code\":null,\"Co_morbidities\":null,\"Claim_Intimation_Through\":null,\"Claim_Intimation_Source\":null,\"Claim_Amount\":null,\"Case_Of_accident\":null,\"AnyOtherAilments\":null,\"AnyHivorStdRelatedAilments\":null,\"AlcohalordrugAbuse\":null,\"A\":null}],\"PCSObj\":null,\"ICDObj\":null,\"DocObj\":null}","EventUuid":"21664ecb-c252-455b-a3e5-3aca00ac4b10","CreatedDate":"2024-11-05T04:13:39.000+0000","ServiceName__c":"ClaimIntimation","Case_Integration_ID__c":"ASF_CInt_751810","Integration_Name__c":"ClaimIntimation"}',
            Response__c = '{"Code":"101","Message":"Entered Policy Number : GHI-HB-22-2095784-V2 doesnt exists. Please check the Health Card and submit the Request again.","Claim_Number":"7576","Pre_Auth_Id":""}',
            Status__c = 'Success'
        );
        acIntList.add(acInt1);
        acIntList.add(acInt2);
        insert acIntList;
        List<ASF_Integration__c> intList = [SELECT External_Id__c, Processing_Class__c, Query_Fields__c from ASF_Integration__c];
        Map<Id,List<ASF_Integration__c>> intMap = new Map<Id,List<ASF_Integration__c>>();
        intMap.put(rec[0].Id,intList);
        ABHI_ReimbursementStpApi apInst = new ABHI_ReimbursementStpApi();
        Test.startTest();
        apInst.cancelPendingCaseIntegrationRequests(intMap, rec);
        Test.stopTest();
        List<Case> caseList = [SELECT id from Case];
        System.assertNotEquals(0, caseList.size(), 'Error in fetching Case');
    }
}