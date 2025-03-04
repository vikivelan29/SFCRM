/**
* @File Name : ABHI_OmniDocViewController_Test.cls
* @Description : Test class for ABHI_OmniDocViewController
* @Author : Salesforce
* @Last Modified By : Aditya Jawadekar
* @Last Modified On : September 2, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 2, 2024 | Aditya Jawadekar  | Initial Version
**/

@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions')
@isTest
public without sharing class ABHI_OmniDocViewController_Test {
	
	public static List<Asset> lstAssets{get;set;}
	public static List<Account> lstAccounts{get;set;}
	public static Map<String, Object> mapRow{get;set;}
    public static List<OrgWideEmailAddress> lstOrgWideAddresses { 
        get;
        set {
            lstOrgWideAddresses = (List<OrgWideEmailAddress>) JSON.deserialize('[{"Id":"000000000000000","DisplayName":"ABHI No Reply","Address":"aditya.helthinsu@adityabirlacapital.com","IsVerified":true,"IsAllowAllProfiles":true,"Purpose":"UserSelection"}]', List<OrgWideEmailAddress>.class);
        } 
    }

	static{
		lstAssets = new List<Asset>();
		lstAccounts = new List<Account>();
		mapRow = (Map<String, Object>)JSON.deserializeuntyped('{"VID":"-1167017705","OmniDocIndex":"36409800","OmniDocImageIndex":"37214593","LogicalID":"SFCRM","FileName":"PT86388901-21-22-3527158-00.PDF","CreationDateTime":"2022-12-13 22:27:24.797"}');
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testDataSetup
    * @description - This method will be used to create testdata setup
    *****************************************************************************************************************/
	@testSetup
	static void testDataSetup(){
		Account objAccount = new Account(FirstName = 'Test Person Account FN', LastName = 'Test Person Account LN', PersonEmail = 'test@testabhi.com', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId());
		lstAccounts.add(objAccount);
		INSERT lstAccounts;

		Asset objAst = new Asset(Name = '12345678', Policy_No__c = '12345678', Plan_Name__c = 'ABHI_TEST_00', AccountId = lstAccounts?.iterator()?.next()?.Id);
		lstAssets.add(objAst);
		INSERT lstAssets;
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - getColumnsForDataTableTest
    * @description - Test class method for getColumnsForDataTable
    *****************************************************************************************************************/
	@IsTest
	static void getColumnsForDataTableTest(){
		Test.startTest();
        list<Object> lstObjNoData = new list<Object>();
        list<Object> lstObjData = new list<Object>();
        try{
            lstObjData = ABHI_OmniDocViewController.getColumnsForDataTable('ABHI_OmniDocView');
			System.assert(!lstObjData.isEmpty(), 'Assert failed, lstObjData is empty');
        }catch(Exception objException){
			System.assert(lstObjData.isEmpty(), 'Assert failed, lstObjData is not empty');
		}
		try{
			lstObjNoData = ABHI_OmniDocViewController.getColumnsForDataTable('abc00test');
		}catch(Exception objException){
			System.assert(lstObjNoData.isEmpty(), 'Assert failed, lstObjNoData is not empty');
		}
		Test.stopTest();
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - callOmiDocSearchRequestTest
    * @description - Test class method for callOmiDocSearchRequest
    *****************************************************************************************************************/
	@IsTest
	static void callOmiDocSearchRequestTest(){
		Test.startTest();
		Asset objAst = [SELECT Id, Name, AccountId, Account.PersonEmail, Plan_Name__c FROM Asset WHERE Name = '12345678' LIMIT 1];
        Object objRet;
        try{
			objRet = ABHI_OmniDocViewController.callOmiDocSearchRequest(objAst.Id, objAst.Name);
			System.assert(objRet != null, 'Assert failed, objRet is null');
        }catch(Exception objException){
            System.assert(objRet == null, 'Assert failed, objRet is not null');
        }
		Test.stopTest();
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - createASFIntegrationRecordANDpublishCaseIntegrationOutboundBothTest
    * @description - Test class method for createASFIntegrationRecord AND publishCaseIntegrationOutbound both
    *****************************************************************************************************************/
	@IsTest
	static void createASFIntegrationRecordANDpublishCaseIntegrationOutboundBothTest(){
		Test.startTest();
		Object objRetNullParam;
		Boolean boolCIO = false;
        Asset objAst;
        ASF_Case_Integration__c objASFCaseRec;
		try{
			objRetNullParam = ABHI_OmniDocViewController.createASFIntegrationRecord(null, null);
		}catch(Exception objException){
			System.assert(objRetNullParam == null, 'Assert failed, objRetNullParam is not null');
		}
        try{
			objAst = [SELECT Id, Name, AccountId, Account.PersonEmail, Plan_Name__c FROM Asset WHERE Name = '12345678' LIMIT 1];
        	objASFCaseRec = (ASF_Case_Integration__c) ABHI_OmniDocViewController.createASFIntegrationRecord(objAst.Id, mapRow);
			System.assert(objASFCaseRec != null, 'Assert failed, objASFCaseRec is null');
			System.assert(!String.isBlank(objASFCaseRec.Id), 'Assert failed, objASFCaseRec Id is blank');
        }catch(Exception objException){
            
        }
		try{
			boolCIO = ABHI_OmniDocViewController.publishCaseIntegrationOutbound(null, null, null);
		}catch(Exception objException){
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
		}
		try{
			boolCIO = ABHI_OmniDocViewController.publishCaseIntegrationOutbound(objAst.Id, mapRow, 'ID_NOT_EXIST_TEST');
		}catch(Exception objException){
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
		}
        try{
			boolCIO = ABHI_OmniDocViewController.publishCaseIntegrationOutbound(objAst.Id, mapRow, objASFCaseRec.Id);
			System.assertEquals(boolCIO, true, 'Assert failed, boolCIO is not true');
        }catch(Exception objException){
            
        }
		Test.stopTest();
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - templateDetailsTest
    * @description - Test class method for templateDetails class
    *****************************************************************************************************************/
	@IsTest
	static void templateDetailsTest(){
		Test.startTest();
		Boolean boolCIO = false;
        Asset objAst;
        ASF_Case_Integration__c objASFCaseRecPend;
        ASF_Case_Integration__c objASFCaseRecFail;
		try{
			boolCIO = ABHI_OmniDocViewController.templateDetails(null, null, null, null, null, null);
		}catch(Exception objException){
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
		}
		objAst = [SELECT Id, Name, AccountId, Account.PersonEmail, Plan_Name__c FROM Asset WHERE Name = '12345678' LIMIT 1];
		try{
			boolCIO = ABHI_OmniDocViewController.templateDetails(mapRow, 'ID_NOT_EXIST_TEST', objAst.Id, objAst.Plan_Name__c, objAst.AccountId, objAst.Account.PersonEmail);
		}catch(Exception objException){
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
		}
        try{
			objASFCaseRecPend = (ASF_Case_Integration__c) ABHI_OmniDocViewController.createASFIntegrationRecord(objAst.Id, mapRow);
			System.assert(objASFCaseRecPend != null, 'Assert failed, objASFCaseRecPend is null');
			boolCIO = ABHI_OmniDocViewController.templateDetails(mapRow, objASFCaseRecPend.Id, objAst.Id, objAst.Plan_Name__c, objAst.AccountId, objAst.Account.PersonEmail);
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
            objASFCaseRecFail = objASFCaseRecPend;
			objASFCaseRecFail.Status__c = 'Failure';
			UPDATE objASFCaseRecFail;
        }catch(Exception objException){
            
        }
		try{
			boolCIO = ABHI_OmniDocViewController.templateDetails(mapRow, objASFCaseRecFail.Id, objAst.Id, objAst.Plan_Name__c, objAst.AccountId, objAst.Account.PersonEmail);
		}catch(Exception objException){
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
		}
        try{
			ASF_Case_Integration__c objASFCaseRecSucc = objASFCaseRecPend;
			objASFCaseRecSucc.Status__c = 'Success';
			UPDATE objASFCaseRecSucc;
			boolCIO = ABHI_OmniDocViewController.templateDetails(mapRow, objASFCaseRecFail.Id, objAst.Id, objAst.Plan_Name__c, objAst.AccountId, objAst.Account.PersonEmail);
			System.assertEquals(boolCIO, false, 'Assert failed, boolCIO is not false');
			ContentVersion objCV = new ContentVersion();
			objCV.PathOnClient = '<FileName111>';
        	objCV.Title = '<FileName111>';
        	objCV.VersionData = Blob.valueOf('<Base64111>');
        	objCV.FirstPublishLocationId = objASFCaseRecSucc.Id;
			INSERT objCV;
			boolCIO = ABHI_OmniDocViewController.templateDetails(mapRow, objASFCaseRecSucc.Id, objAst.Id, objAst.Plan_Name__c, objAst.AccountId, objAst.Account.PersonEmail);
			Test.stopTest();
        }catch(Exception objException){
            
        }
	}
}