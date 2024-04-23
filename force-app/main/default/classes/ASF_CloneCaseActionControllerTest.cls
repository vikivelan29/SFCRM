/*******************************************************************************************
* @Name         ASF_CloneCaseActionControllerTest
* @Author       Santanu Halder
* @Description  Test class for ASF_CloneCaseActionController
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0          Santanu Halder      28/10/2023          Initial Creation
*******************************************************************************************/
@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public with sharing class ASF_CloneCaseActionControllerTest {
    @testSetup
    static void setupTestData(){
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account acc= new Account(
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            RecordTypeId = recordTypeId
            //,CRN__c= 'abcd'
        );
        insert acc;
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
        insert lob;
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100
        //,Financial_Account_Number__c = '0123456789123'
        );
        ast.Name = 'aas';
        ast.Aggrement_Date__c = Date.newInstance(2023, 06, 09);
        ast.Application_Number__c = '12345';
        ast.Approved_Date__c = Date.newInstance(2023, 06, 10);
        ast.Approved_Limit__c = 200;
        ast.Branch_Code__c = 'AST';
        insert ast;
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'ABHFL',Sub_Type__c = 'CreditCard',Source__c='CEC', 
                                                                Process__c='Case', Only_CRN_Mandatory__c=true, Overall_Case_Closure_SLA__c = 10,First_Stage__c = 'New',
                                                                //Reopen_Days__c=5, 
                                                                ASF_Is_Cloneable__c=true
                                                                //, Customer_Friendly_Name__c='Credit Card'
                                                                );
        insert ccc;

        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
	        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        List<ASF_Case_Field_Config__c> fieldConfigs = new List<ASF_Case_Field_Config__c>();
        ASF_Case_Field_Config__c fieldConfig = new ASF_Case_Field_Config__c();
        //fieldConfig.Name = 'TAN_Number__c';
        fieldConfig.Case_Main_Config__c = ccc.Id;
        fieldConfig.ObjectAPIName__c = 'Case';
        fieldConfig.FieldAPIName__c = 'Comments';
        fieldConfig.ASF_Is_Cloneable__c = true;
        fieldConfigs.add(fieldConfig);

        ASF_Case_Field_Config__c fieldConfig1 = new ASF_Case_Field_Config__c();
        //fieldConfig1.Name = 'Credit_Card_Number__c';
        fieldConfig1.Case_Main_Config__c = ccc.Id;
        fieldConfig1.ObjectAPIName__c = 'PAY_Payment_Detail__c';
        fieldConfig1.FieldAPIName__c = 'Nature_Of_Transaction__c';
        fieldConfig1.ASF_Is_Cloneable__c = true;
        fieldConfigs.add(fieldConfig1);
        insert fieldConfigs;

        PAY_Payment_Detail__c payRec = new PAY_Payment_Detail__c();
        payRec.Merchant_Biller_Name__c = 'Amazon';
        insert payRec;

        Case cs = new Case();
        cs.AccountId = acc.Id;
        cs.CCC_External_Id__c = 'CCC-CC-RC-01';
        cs.Technical_Source__c = 'LWC';
        cs.Status = 'New';
        cs.Stage__c='New';
        cs.ASF_Is_Cloneable__c = ccc.ASF_Is_Cloneable__c;
        cs.PAY_Payment_Detail__c = payRec.Id;
        insert cs;
        
        /*Case caseRec = new Case();
        caseRec.PAY_Payment_Detail__c = payRec.Id;
        caseRec.Origin = 'Phone';
        caseRec.Subject = 'SR : '+ccc.Type__c;
        caseRec.AssetId = ast.Id;
        caseRec.CCC_External_Id__c = 'CCC-CC-RC-01';
        caseRec.Stage__c = 'New';
        caseRec.Status = 'New';
        //caseRec.Type__c = ccc.Type__c;
        caseRec.Type_Text__c = ccc.Type__c;
        //caseRec.Sub_Type__c = ccc.Sub_Type__c;
        caseRec.Sub_Type_Text__c = ccc.Sub_Type__c;
        //caseRec.Origin__c = 'RL';
        caseRec.Nature__c = 'Query';
        //caseRec.Reopen_Days__c = ccc.Reopen_Days__c;
        caseRec.ASF_Is_Cloneable__c = ccc.ASF_Is_Cloneable__c; //Functionality Clone SR - Santanu Oct27,2023
        
        caseRec.AccountId = acc.Id;
        //caseRec.Branch_Master__c = acc.Home_Branch__c;
        //caseRec.FA_Number__c = 'NA';
        
        caseRec.Source__c = ccc.Source__c;
        //caseRec.Customer_Friendly_Verbiage__c = ccc.Customer_Friendly_Name__c;
        caseRec.Channel__c = '';
        
        caseRec.Technical_Source__c = 'LWC';
        caseRec.Business_Unit__c = 'ABHFL'; 
        //caseRec.Complaint_Level__c = 'L1';
        insert caseRec;*/

    }

    @isTest
    static void test_isCaseCloneable_1(){
        Case caseRec = [Select id from Case limit 1];
        Test.startTest();
        ASF_CloneCaseActionController.BooleanWithReasonWrapper result = ASF_CloneCaseActionController.isCaseCloneable(caseRec.Id);
        Test.stopTest();
        Assert.isTrue(result.resultFlag, 'Expected true');
    }

    @isTest
    static void test_isCaseCloneable_2(){
        Case caseRec = [Select id from Case limit 1];
        caseRec.CCC_External_Id__c = 'Invalid';
        update caseRec;
        
        try{
            Test.startTest();
            ASF_CloneCaseActionController.BooleanWithReasonWrapper result = ASF_CloneCaseActionController.isCaseCloneable(caseRec.Id);
            Test.stopTest();
        }
        catch(Exception e){
            Assert.areEqual('Case Category Config is invalid', e.getMessage(), 'Expected Case Category Config is invalid');
        }
    }

    @isTest
    static void test_isCaseCloneable_3(){
        Case caseRec = [Select id from Case limit 1];
        ASF_Case_Category_Config__c config = [select id from ASF_Case_Category_Config__c limit 1];
        caseRec.ASF_Is_Cloneable__c = false;
        update caseRec;
        
        Test.startTest();
        ASF_CloneCaseActionController.BooleanWithReasonWrapper result = ASF_CloneCaseActionController.isCaseCloneable(caseRec.Id);
        Test.stopTest();
        Assert.isNotNull(result.reasonIfFalse, 'Expected some value in reason');
    }

    @isTest
    static void test_fetchCommonFieldsToCopy_1(){
        Test.startTest();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCommonFieldsToCopy();
        Test.stopTest();
        Assert.isNotNull(wrap.fieldList, 'Expected fieldList to be populated');
    }

    @isTest
    static void test_fetchCCCSpecificFieldsToCopy_1(){
        Case caseRec = [Select id from Case limit 1];

        Test.startTest();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
        Test.stopTest();
        Assert.isNotNull(wrap.fieldList, 'Expected fieldList to be populated');
    }

    @isTest
    static void test_fetchCCCSpecificFieldsToCopy_2(){
        Case caseRec = [Select id from Case limit 1];
        caseRec.CCC_External_Id__c = 'Invalid';
        update caseRec;
        
        try{
            Test.startTest();
            ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
            Test.stopTest();
        }
        catch(Exception e){
            Assert.areEqual('Case Category Config is invalid', e.getMessage(), 'Expected Case Category Config is invalid');
        }
        
    }

    @isTest
    static void test_fetchCaseDetailsWithExtension_1(){
        Case caseRec = [Select id from Case limit 1];

        List<ASF_CloneCaseActionController.FieldWrapper> fieldList = new List<ASF_CloneCaseActionController.FieldWrapper>();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
        fieldList.addAll(wrap.fieldList);
        ASF_CloneCaseActionController.FieldListWrapper wrap2 = ASF_CloneCaseActionController.fetchCommonFieldsToCopy();
        fieldList.addAll(wrap2.fieldList);
        Test.startTest();
        ASF_CloneCaseActionController.CaseDetailWrapper result = ASF_CloneCaseActionController.fetchCaseDetailsWithExtension(fieldList, caseRec.Id);
        Test.stopTest();
        Assert.isTrue(result.resultFlag, 'Expected true');
    }

    @isTest
    static void test_fetchCaseDetailsWithExtension_2(){
        Case caseRec = [Select id from Case limit 1];
        ASF_Case_Category_Config__c ccc = [select id from ASF_Case_Category_Config__c limit 1];
        List<ASF_Case_Field_Config__c> fieldConfigs = new List<ASF_Case_Field_Config__c>();
        ASF_Case_Field_Config__c fieldConfig = new ASF_Case_Field_Config__c();
        //fieldConfig.Name = 'Amount__c';
        fieldConfig.Case_Main_Config__c = ccc.Id;
        fieldConfig.ObjectAPIName__c = 'PAY_Payment_Detail__c';
        fieldConfig.FieldAPIName__c = 'Txn_amount__c';
        fieldConfig.ASF_Is_Cloneable__c = true;
        fieldConfigs.add(fieldConfig);
        /*ASF_Case_Field_Config__c fieldConfig1 = new ASF_Case_Field_Config__c();
        //fieldConfig1.Name = 'Beneficiary_Account_Number__c';
        fieldConfig1.Case_Main_Config__c = ccc.Id;
        fieldConfig1.ObjectAPIName__c = 'Asset';
        fieldConfig1.FieldAPIName__c = 'SerialNumber';
        fieldConfig1.ASF_Is_Cloneable__c = true;
        fieldConfigs.add(fieldConfig1);*/
        insert fieldConfigs;
        
        List<ASF_CloneCaseActionController.FieldWrapper> fieldList = new List<ASF_CloneCaseActionController.FieldWrapper>();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
        fieldList.addAll(wrap.fieldList);
        ASF_CloneCaseActionController.FieldListWrapper wrap2 = ASF_CloneCaseActionController.fetchCommonFieldsToCopy();
        fieldList.addAll(wrap2.fieldList);
        try {
            Test.startTest();
            ASF_CloneCaseActionController.CaseDetailWrapper result = ASF_CloneCaseActionController.fetchCaseDetailsWithExtension(fieldList, caseRec.Id);
            Test.stopTest();
        } catch (Exception e) {
            Assert.areEqual('More than 2 case extension records exist. Please contact System Administrator with this error.', e.getMessage(), 'Expected More than 2 case extension records exist. Please contact System Administrator with this error.');
        }
    }

    @isTest
    static void test_createCloneCase_1(){
        Case caseRec = [Select id from Case limit 1];

        List<ASF_CloneCaseActionController.FieldWrapper> fieldList = new List<ASF_CloneCaseActionController.FieldWrapper>();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
        fieldList.addAll(wrap.fieldList);
        ASF_CloneCaseActionController.FieldListWrapper wrap2 = ASF_CloneCaseActionController.fetchCommonFieldsToCopy();
        fieldList.addAll(wrap2.fieldList);
        ASF_CloneCaseActionController.CaseDetailWrapper result = ASF_CloneCaseActionController.fetchCaseDetailsWithExtension(fieldList, caseRec.Id);
        Test.startTest();
        Case cloneCaseRecord = result.caseRecord.clone(false, true, false, false);
        SObject cloneExtnRecord = result.extnRecords.get('PAY_Payment_Detail__c').clone(false, true, false, false);
        ASF_CloneCaseActionController.CaseDetailWrapper cloneresult = ASF_CloneCaseActionController.createCloneCase(cloneCaseRecord, new Map<String,SObject>{'PAY_Payment_Detail__c'=>cloneExtnRecord}, caseRec.Id);
        Test.stopTest();
        Assert.isNotNull(cloneresult.caseRecord.Id, 'Id should not be null');
    }

    @isTest
    static void test_createCloneCase_2(){
        Case caseRec = [Select id from Case limit 1];
        
        List<ASF_CloneCaseActionController.FieldWrapper> fieldList = new List<ASF_CloneCaseActionController.FieldWrapper>();
        ASF_CloneCaseActionController.FieldListWrapper wrap = ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy(caseRec.Id);
        fieldList.addAll(wrap.fieldList);
        ASF_CloneCaseActionController.FieldListWrapper wrap2 = ASF_CloneCaseActionController.fetchCommonFieldsToCopy();
        fieldList.addAll(wrap2.fieldList);
        ASF_CloneCaseActionController.CaseDetailWrapper result = ASF_CloneCaseActionController.fetchCaseDetailsWithExtension(fieldList, caseRec.Id);
        caseRec.CCC_External_Id__c = 'Invalid';
        update caseRec;
        try{
            Test.startTest();
            Case cloneCaseRecord = result.caseRecord.clone(false, true, false, false);
            SObject cloneExtnRecord = result.extnRecords.get('PAY_Payment_Detail__c').clone(false, true, false, false);
            ASF_CloneCaseActionController.CaseDetailWrapper cloneresult = ASF_CloneCaseActionController.createCloneCase(cloneCaseRecord, new Map<String,SObject>{'PAY_Payment_Detail__c'=>cloneExtnRecord}, caseRec.Id);
            Test.stopTest();
        }
        catch(Exception e){
            //Assert.areEqual('List index out of bounds: 0', e.getMessage(), 'Expected List index out of bounds');
        }
    }
}
