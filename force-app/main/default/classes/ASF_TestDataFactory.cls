/*********************************************************
** Class        :  ASF_TestDataFactory
** Author       :  Shreya Mathur
** Description  :  Data Factory for Test Class
** Created Date :  Dec 8 10, 2022
** Modified By :  Chaynnitt Agarwal
** Modified Date :  Dec 22, 2022
** Parent Story Number : NA
*********************************************************/
@SuppressWarnings(
    'PMD.ExcessiveParameterList'
)

@isTest
public with sharing class ASF_TestDataFactory {

    /****************************************************
     * @Description - Create User with CS360 Profile.      
    *****************************************************/

    public static void createCS60User() {
        String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer intRandomValue = Integer.valueOf(math.rint(math.random() * 1000000));
        String strUniqueName = strDate + intRandomValue;
        User objUser;
        String strProfileId = [select Id from Profile where Name = 'System Administrator'].Id;
        objUser = new User(profileId = strProfileId, email = 'CS360@FCAAdmin.mock.com',
                     Username = strUniqueName + '@CS360@' + strUniqueName +  'mock.com',
                     alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                     languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        if(strProfileId != null){
            objUser.profileId = strProfileId;
        }
        if(Schema.sObjectType.User.isCreateable()){
            insert objUser;
        }
        System.assertNotEquals(NULL, objUser, 'Creating a User record is failed.');
    }

    /****************************************************
     * @Description - Assign user with Permission Set
     * @param idUser -  Contains detail of User Id 
     * @param strPermissionSetName -  Contains Permission Set Name to be assigned
    *****************************************************/

    public static void givePermissions(Id idUser, String strPermissionSetName) {
        if (String.isNotBlank(strPermissionSetName) && idUser != null) {
            PermissionSet objPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :strPermissionSetName WITH SECURITY_ENFORCED];
            PermissionSetAssignment objPSetAssignment = new PermissionSetAssignment(AssigneeId = idUser, PermissionSetId = objPermissionSet.Id);
            if(Schema.sObjectType.PermissionSetAssignment.isCreateable()){
                insert objPSetAssignment;
            }            
            System.assertNotEquals(NULL, objPSetAssignment, 'Permission set assignment is failed.');
        }
    }

    /****************************************************
     * @Description - Insert Person Account
     * @param strFirstName-  Contains First name
     * @param strLastName -  Contains Last name
     * @param strCRN -  Contains CRN Number
     * @return - Account       
    *****************************************************/

    public static Account insertPersonAccount(String strFirstName, String strLastName,String strCRN) {
       Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
       Account objAccount = new Account();
       objAccount.FirstName = String.isNotBlank(strFirstName)?strFirstName:'TestFirstName';
       objAccount.LastName = String.isNotBlank(strLastName)?strLastName:'TestFirstName';
       objAccount.Client_Code__c = String.isNotBlank(strCRN)? strCRN: String.valueOf( Integer.valueof((Math.random() * 100)));
       objAccount.RecordTypeId = recordTypeId;
       if(Schema.sObjectType.Account.isCreateable()){
            insert objAccount;
       }
       return objAccount;
    }

     /****************************************************
     * @Description - Insert Business Account
     * @param strCompanyName -  Contains CompanyName
     * @param strCRN -  Contains CRN Number
     * @return - Account       
    *****************************************************/
    
    public static Account insertBusinessAccount(String strCompanyName, String strCRN) {
        //Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.Name = String.isNotBlank(strCompanyName)?strCompanyName:'TestCompanyName';
        //objAccount.CRN__c =  String.isNotBlank(strCRN)? strCRN: String.valueOf( Integer.valueof((Math.random() * 100)));
        //objAccount.RecordTypeId = recordTypeId;
        if(Schema.sObjectType.Account.isCreateable()){
            insert objAccount;
        }
        
        return objAccount;
     }
        
     /****************************************************
     * @Description - Insert Field Configuration Record
     * @param strGroupName -  Contains Group Name
     * @param strLabelName - Contains Label Name
     * @param strAPIName - Contains API Name
     * @param strExtId - Contains External Id
     * @return - ASF_FieldConfigurationRecord__c       
    *****************************************************/

    public static ASF_FieldConfigurationRecord__c insertFieldConfigRecord(String strGroupName,String strLabelName,String strAPIName,String strExtId) {
        ASF_FieldConfigurationRecord__c configRec = new ASF_FieldConfigurationRecord__c();
        configRec.ASF_GroupName__c = strGroupName;
        configRec.ASF_FieldName__c = strLabelName;
        configRec.ASF_FieldApi__c = strAPIName;
        configRec.ASF_IsActive__c = true;
        configRec.ASF_ExternalId__c = strExtId;
        configRec.ASF_ProfilesVisibility__c = 'System Administrator;Payment Base Profile';
        return configRec;
    }

     /****************************************************
     * @Description - Get mock Response JSON from Static Resource 
     * @param mdtDevNAme -  DevName of ksc_IntegrationDetails__mdt record
     * @return - String
    ****************************************************
    public static String getStaticResourceDataTest(String mdtDevNAme){
        String respMockBody = '{"example":"test"}'; 
        if(!String.isBlank(mdtDevNAme)){
            ksc_IntegrationDetails__mdt mdtData = ksc_IntegrationDetails__mdt.getInstance(mdtDevNAme);
            if(mdtData != null && !String.isBlank(mdtData.ksc_StaticResourceName__c)){
                StaticResource objStaticResource = new StaticResource();
                List<StaticResource> lstSR = [Select Id, Body FROM StaticResource where Name = :mdtData.ksc_StaticResourceName__c WITH SECURITY_ENFORCED];
                if(lstSR != null && !lstSR.isEmpty()){
                    objStaticResource = lstSR[0]; 
                }
                if(objStaticResource !=null && objStaticResource.Body != null && objStaticResource.Body.toString() != null){                                
                    respMockBody = objStaticResource.Body.toString();
                }
            }
        }
        return respMockBody;
    } 
    
    Commented out due to reference to ksc_ metadata */

     /****************************************************
     * @Description - Create User with CS360 Profile With C360 PermSet.
     * @return - User       
    *****************************************************/

    public static User createCS60UserWithPermissions() {
        String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer intRandomValue = Integer.valueOf(math.rint(math.random() * 1000000));
        String strUniqueName = strDate + intRandomValue;
        User objUser;
        String strProfileId = [select Id from Profile where Name = 'System Administrator'].Id;
        objUser = new User(profileId = strProfileId, email = 'CS360@FCAAdmin.mock.com',
                     Username = strUniqueName + '@CS360@' + strUniqueName +  'mock.com',
                     alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_IN',
                     languagelocalekey = 'en_US', timezonesidkey = 'Asia/Kolkata',IsActive = true,Type__c='Team Lead');
        if(strProfileId != null){
            objUser.profileId = strProfileId;
        }
        
        insert objUser;
        ASF_TestDataFactory.givePermissions(objUser.Id, ASF_Constants.C360_PERM_SET_APINAME);
        System.assertNotEquals(NULL, objUser, 'Creating a User record is failed.');
        return objUser;
    }

     /****************************************************
     * @Description - Create Asset record 
     * @param accountId -  Contain Account Id for which asset is created
     * @param strType -  Contain Type
     * @return - Asset
    *****************************************************/

    public static Asset createAsset(Id accountId,String strType) {
        Asset asset = new Asset();
        //Id recordTypeId =Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Credit_Cards').getRecordTypeId();
        asset.Name = 'Test Asset';
        //asset.recordTypeId = recordTypeId;
        //asset.Financial_Account_Number__c = ASF_UtilityClass.generateTransactionId();
        asset.AccountId =accountId;
        asset.Type__c = strType;
        if(Schema.sObjectType.Asset.isCreateable()){
            insert asset;
        }
        return asset;
    }

	 /****************************************************
     * @Description - Insert Field Configuration Record
     * @param  strGroupName - Contain Group Name
     * @param strLabelName - Contain Label Name
     * @param strAPIName - Contain API Name
     * @param strExtId - Contain External Id
     * @param StrFieldPositioning - Contain Field Positioning details
     * @param strDataType - Contain field DataType
     * @param strProfilesVisibility - Contain field's profile visibility details
     * @param strPicklistValues - Contain picklist values if any
     * @return - ASF_FieldConfigurationRecord__c       
    *****************************************************/

    public static ASF_FieldConfigurationRecord__c insertFieldConfigRecordForDataTable(String strGroupName,String strLabelName,String strAPIName,
					String strExtId,String strFieldPositioning,String strDataType,String strProfilesVisibility,String strPicklistValues) {
        ASF_FieldConfigurationRecord__c configRec = new ASF_FieldConfigurationRecord__c();
        configRec.ASF_GroupName__c = strGroupName;
        configRec.ASF_FieldName__c = strLabelName;
        configRec.ASF_FieldApi__c = strAPIName;
        configRec.ASF_IsActive__c = true;
        configRec.ASF_ExternalId__c = strExtId;
        configRec.ASF_FieldPositioning__c = strFieldPositioning;
        configRec.ASF_Data_Type__c = strDataType;
        configRec.ASF_ProfilesVisibility__c = strProfilesVisibility;  
        configRec.ASF_PicklistValues__c = strPicklistValues;              
        return configRec;
    }

     /****************************************************
     * @Description - Insert Field Configuration Record
     * @param  strGroupName - Contain Group Name
     * @param strLabelName - Contain Label Name
     * @param strAPIName - Contain API Name
     * @param strExtId - Contain External Id
     * @param strDataType - Contain field DataType
     * @return - ASF_FieldConfigurationRecord__c       
    *****************************************************/

    public static ASF_FieldConfigurationRecord__c insertFieldConfigRecord(String strGroupName,String strLabelName,String strAPIName,String strExtId,String dataType) {
        Schema.DescribeFieldResult fieldResult = ASF_FieldConfigurationRecord__c.ASF_ProfilesVisibility__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        String pickVal = '';
        for( Schema.PicklistEntry v : values) {
            pickVal = v.getValue() + ';' +pickVal ;
        }
        ASF_FieldConfigurationRecord__c configRec = new ASF_FieldConfigurationRecord__c();
        configRec.ASF_GroupName__c = strGroupName;
        configRec.ASF_FieldName__c = strLabelName;
        configRec.ASF_FieldApi__c = strAPIName;
        configRec.ASF_IsActive__c = true;
        configRec.ASF_ExternalId__c = strExtId;
        configRec.ASF_Data_Type__c = dataType;
        configRec.ASF_ProfilesVisibility__c = pickVal; 
        return configRec;
    }
    
    /****************************************************
     * @Description - Create Case 
     * @return - List of Case       
    *****************************************************/
    public static List<Case> createCaseRecords(Integer noOfCase) {

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<noOfCase;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test'+i+'@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            caseList.add(newCase);
        
        }
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            newCase.pending_clarification__c = true;
            
        	
        caseList.add(newCase);
        insert caseList;

        return caseList;
    }


    public static List<Case> createInteractionCaseRecords() {

        List<Case> caseList = new List<Case>();
        
        Case newCase = new Case(Status = 'Open', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Open',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
            newCase.pending_clarification__c = true;
            
        caseList.add(newCase);
        insert caseList;

        return caseList;
    }

     /****************************************************
     * @Description - Create Case Configs 
     * return - Map of Case Configs       
    *****************************************************/
    public static void createCaseCategoryConfig() {
         
    Map<String,List<SObject>> mapOfCaseConfigs = new Map<String,List<SObject>>();   
    List<ASF_Case_Category_Config__c> listCaseCatConfig = new List<ASF_Case_Category_Config__c>();
    List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>();
    List<ASF_Case_Rule_Entry__c> caseRuleEntryList = new List<ASF_Case_Rule_Entry__c>();
    ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

    list<ASF_Work_Item__c> workItemsList = new list<ASF_Work_Item__c>();
    caseCatConfig.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
    caseCatConfig.Overall_Case_Closure_SLA__c = 10;
    caseCatConfig.First_Stage__c = 'Pending with Initiator';
    caseCatConfig.Type__c = 'Bureau Related';
    caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
    caseCatConfig.Overall_Case_Closure_SLA__c = 56;
    caseCatConfig.Nature__c = 'Request';
    caseCatConfig.Source__c = 'CEC';  // Branch
    caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
    caseCatConfig.Resolved_Case_Email_Template__c = 'dev_01';
    caseCatConfig.Resolved_Case_SMS_Metadata__c ='Dev_02';
    
    insert caseCatConfig;

    PAY_Payment_Detail__c paymentRecord = new PAY_Payment_Detail__c (Payment_mode__c = 'Online', Status_of_Transaction__c = 'Success');
    insert paymentRecord;

    listCaseCatConfig.add(caseCatConfig);
    mapOfCaseConfigs.put('categoryConfig', listCaseCatConfig);
        

        
    List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
	
    ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
    stage1.Case_Category_Config__c = caseCatConfig.Id;
    stage1.Order__c = 1;
    stage1.StageName__c  = 'Pending with Initiator';
    stage1.Stage_SLA_1__c = 1;
    stage1.Status_Mapping__c = 'New';
    // stage1.Stage_SLA_2__c = 2;
    // stage1.Stage_SLA_3__c = 3;
    stage1.SLA_Target_1_Type__c = 'Manager';
    stage1.Query_Fields__c = 'Id,Stage__c,CSAT__c';
    stage1.Manual_Stage__c = false;
    stageConfigList.add(stage1);

   

    ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
    stage2.Case_Category_Config__c = caseCatConfig.Id;
    stage2.Order__c = 2;
    stage2.Stage_SLA_1__c = 1;
    stage2.Stage_SLA_2__c = 2;
    stage2.Stage_SLA_3__c = 3;
    stage2.SLA_Target_1_Type__c = 'Manager';
    stage2.SLA_Target_2_Type__c = 'Manager';
    stage2.SLA_Target_3_Type__c = 'Manager';
    stage2.StageName__c  = 'In Progress with Recovery';
    stage2.Status_Mapping__c = 'In Progress';
    stage2.Query_Fields__c = 'Id,Stage__c,CSAT__c';
    stageConfigList.add(stage2);

    ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
    stage3.Case_Category_Config__c = caseCatConfig.Id;
    stage3.Order__c = 3;
    stage3.Stage_SLA_1__c = 1;
    // stage3.Stage_SLA_2__c = 2;
    // stage3.Stage_SLA_3__c = 3;
    stage3.SLA_Target_1_Type__c = 'Manager';
    // stage3.SLA_Target_2_Type__c = 'Manager';
    // stage3.SLA_Target_3_Type__c = 'Manager';
    stage3.StageName__c  = 'Pending NCM Approval';
    stage3.Is_Approval_Stage__c = true;
    stage3.Manual_Approval__c = true;
    stage3.Status_Mapping__c = 'In Progress';
    stage3.Query_Fields__c = 'Id,Stage__c';
    stageConfigList.add(stage3);

    ASF_Case_Stage_Config__c stage4 = new ASF_Case_Stage_Config__c();
    stage4.Case_Category_Config__c = caseCatConfig.Id;
    stage4.Order__c = 3;
    stage4.Stage_SLA_1__c = 1;
    // stage3.Stage_SLA_2__c = 2;
    // stage3.Stage_SLA_3__c = 3;
    stage4.SLA_Target_1_Type__c = 'Manager';
    // stage3.SLA_Target_2_Type__c = 'Manager';
    // stage3.SLA_Target_3_Type__c = 'Manager';
    stage4.StageName__c  = 'Closed';
    stage4.Is_Approval_Stage__c = true;
    stage4.Manual_Approval__c = true;
    stage4.Status_Mapping__c = 'Closed';
    stage4.Query_Fields__c = 'Id,Stage__c';
    stageConfigList.add(stage4);

    insert stageConfigList;
    
     ASF_Case_Stage_Config__c stage5 = new ASF_Case_Stage_Config__c();
    stage5.Case_Category_Config__c = caseCatConfig.Id;
    stage5.Case_Category_Config__c = caseCatConfig.Id;
    stage5.Order__c = 2;
    stage5.Stage_SLA_1__c = 1;
    stage5.Stage_SLA_2__c = 2;
    stage5.Stage_SLA_3__c = 3;
    stage5.SLA_Target_1_Type__c = 'Manager';
    stage5.SLA_Target_2_Type__c = 'Manager';
    stage5.SLA_Target_3_Type__c = 'Manager';
    stage5.StageName__c  = 'In Progress with Recovery';
    stage5.Status_Mapping__c = 'In Progress';
    stage5.Query_Fields__c = 'Id,Stage__c';
    stageConfigList.add(stage5);

    ASF_Case_Rule__c stage1_StageMovement_Rule = new ASF_Case_Rule__c();

    stage1_StageMovement_Rule.Case_Stage_Config__c = stage1.Id;
    stage1_StageMovement_Rule.Logical_Condition__c = '1';
    stage1_StageMovement_Rule.Order__c = 1;
    stage1_StageMovement_Rule.Type__c = 'Stage Movement';

    // caseRuleList.add(stage1_StageMovement_Rule);
    insert stage1_StageMovement_Rule;
    
    ASF_Case_Rule__c stage1_Assignment_Rule = new ASF_Case_Rule__c();

    stage1_Assignment_Rule.Case_Stage_Config__c = stage1.Id;
    stage1_Assignment_Rule.Logical_Condition__c = '1';
    stage1_Assignment_Rule.Order__c = 2;
    stage1_Assignment_Rule.Type__c = 'Assignment';

    // caseRuleList.add(stage1_StageMovement_Rule);
    insert stage1_Assignment_Rule;


    ASF_Case_Rule__c stage2_StageMovement_Rule = new ASF_Case_Rule__c();

    stage2_StageMovement_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_StageMovement_Rule.Logical_Condition__c = '1 AND 2 AND 3 AND (4 OR 5) AND 6 AND 7';
    stage2_StageMovement_Rule.Order__c = 1;
    stage2_StageMovement_Rule.Type__c = 'Approval';

    insert stage2_StageMovement_Rule;
	
    ASF_Case_Rule__c stage2_StageMovement2_Rule = new ASF_Case_Rule__c();
    stage2_StageMovement2_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_StageMovement2_Rule.Logical_Condition__c = '1';
    stage2_StageMovement2_Rule.Order__c = 1;
    stage2_StageMovement2_Rule.Type__c = 'Approval';
        
    insert stage2_StageMovement2_Rule;

    ASF_Case_Rule__c stage2_Work_Rule = new ASF_Case_Rule__c();

    stage2_Work_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_Work_Rule.Logical_Condition__c = '1';
    stage2_Work_Rule.Order__c = 1;
    stage2_Work_Rule.Type__c = 'Work';

    // caseRuleList.add(stage2_Work_Rule);
    insert stage2_Work_Rule;

    ASF_Case_Rule__c stage2_Assignment_Rule = new ASF_Case_Rule__c();
    stage2_Assignment_Rule.Case_Stage_Config__c = stage3.Id;
    stage2_Assignment_Rule.Logical_Condition__c = '1';
    stage2_Assignment_Rule.Order__c = 1;
    stage2_Assignment_Rule.Type__c = 'Assignment';
    stage2_Assignment_Rule.Assign_to_Initiator__c = true;
    insert stage2_Assignment_Rule;
    
    ASF_Case_Rule__c stage2_checklist_Rule = new ASF_Case_Rule__c();
    stage2_checklist_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_checklist_Rule.Logical_Condition__c = '1';
    stage2_checklist_Rule.Order__c = 1;
    stage2_checklist_Rule.Type__c = 'Checklists';
    insert stage2_checklist_Rule; 
        
    ASF_Case_Rule__c stage3_StageMovement_Rule = new ASF_Case_Rule__c();

    stage3_StageMovement_Rule.Case_Stage_Config__c = stage3.Id;
    stage3_StageMovement_Rule.Logical_Condition__c = '1';
    stage3_StageMovement_Rule.Order__c = 1;
    stage3_StageMovement_Rule.Type__c = 'Stage Movement';

    // caseRuleList.add(stage3_StageMovement_Rule);

    insert stage3_StageMovement_Rule;

    ASF_Case_Rule__c stage2_Validation_Rule = new ASF_Case_Rule__c();

    stage2_Validation_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_Validation_Rule.Logical_Condition__c = '1';
    stage2_Validation_Rule.Order__c = 1;
    stage2_Validation_Rule.Type__c = 'Validation';

    insert stage2_Validation_Rule;
   

    ASF_Case_Rule__c stage4_StageMovement_Rule = new ASF_Case_Rule__c();

    stage4_StageMovement_Rule.Case_Stage_Config__c = stage4.Id;
    stage4_StageMovement_Rule.Logical_Condition__c = '1';
    stage4_StageMovement_Rule.Order__c = 1;
    stage4_StageMovement_Rule.Type__c = 'Stage Movement';

    // caseRuleList.add(stage4_StageMovement_Rule);

    // insert caseRuleList;
    insert stage4_StageMovement_Rule;
    
    ASF_Case_Rule_Entry__c stage2_Approval11_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval11_RuleEntry.Number__c = 1;
    stage2_Approval11_RuleEntry.Case_Rule__c = stage2_StageMovement2_Rule.Id;
    stage2_Approval11_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_Approval11_RuleEntry.Operator__c = '=';
    stage2_Approval11_RuleEntry.Data_Type__c = 'STRING';
    stage2_Approval11_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_Approval11_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-311';
    caseRuleEntryList.add(stage2_Approval11_RuleEntry);


    ASF_Case_Rule_Entry__c stage2_Work_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Work_RuleEntry.Number__c = 1;
    stage2_Work_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Work_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_Work_RuleEntry.Operator__c = '=';
    stage2_Work_RuleEntry.Data_Type__c = 'STRING';
    stage2_Work_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_Work_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-001';

    caseRuleEntryList.add(stage2_Work_RuleEntry);
        
    ASF_Case_Rule_Entry__c stage2_Validation_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Validation_RuleEntry.Number__c = 1;
    stage2_Validation_RuleEntry.Case_Rule__c = stage2_Validation_Rule.Id;
    stage2_Validation_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_Validation_RuleEntry.Operator__c = '=';
    stage2_Validation_RuleEntry.Data_Type__c = 'STRING';
    stage2_Validation_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_Validation_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-900';
    caseRuleEntryList.add(stage2_Validation_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_approval2_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_approval2_RuleEntry.Number__c = 2;
    stage2_approval2_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_approval2_RuleEntry.Field_Api_Name__c = 'PAY_Payment_Detail__r.Payment_mode__c';
    stage2_approval2_RuleEntry.Operator__c = '!=';
    stage2_approval2_RuleEntry.Data_Type__c = 'STRING';
    stage2_approval2_RuleEntry.Value__c = 'FALSE';
    stage2_approval2_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-911';
    caseRuleEntryList.add(stage2_approval2_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_Approval3_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval3_RuleEntry.Number__c = 3;
    stage2_Approval3_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Approval3_RuleEntry.Field_Api_Name__c = 'SLA_Target_1__c';
    stage2_Approval3_RuleEntry.Operator__c = 'contains';
    stage2_Approval3_RuleEntry.Data_Type__c = 'STRING';
    stage2_Approval3_RuleEntry.Value__c = 'Test';
    stage2_Approval3_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-101';
    caseRuleEntryList.add(stage2_Approval3_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_Approval4_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval4_RuleEntry.Number__c = 4;
    stage2_Approval4_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Approval4_RuleEntry.Field_Api_Name__c = 'CSAT__c';
    stage2_Approval4_RuleEntry.Operator__c = '!=';
    stage2_Approval4_RuleEntry.Data_Type__c = 'DECIMAL';
    stage2_Approval4_RuleEntry.Value__c = '1';
    stage2_Approval4_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-111';
    caseRuleEntryList.add(stage2_Approval4_RuleEntry);
        
    ASF_Case_Rule_Entry__c stage2_Approval5_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval5_RuleEntry.Number__c = 5;
    stage2_Approval5_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Approval5_RuleEntry.Field_Api_Name__c = 'DB_Hours__c';
    stage2_Approval5_RuleEntry.Operator__c = '=';
    stage2_Approval5_RuleEntry.Data_Type__c = 'DECIMAL';
    stage2_Approval5_RuleEntry.Value__c = '5';
    stage2_Approval5_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-216';
    caseRuleEntryList.add(stage2_Approval5_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_Approval6_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval6_RuleEntry.Number__c = 6;
    stage2_Approval6_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Approval6_RuleEntry.Field_Api_Name__c = 'has_CheckLists__c';
    stage2_Approval6_RuleEntry.Operator__c = '=';
    stage2_Approval6_RuleEntry.Data_Type__c = 'BOOLEAN';
    stage2_Approval6_RuleEntry.Value__c = 'TRUE';
    stage2_Approval6_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-217';
    caseRuleEntryList.add(stage2_Approval6_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_Approval7_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_Approval7_RuleEntry.Number__c = 7;
    stage2_Approval7_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
    stage2_Approval7_RuleEntry.Field_Api_Name__c = 'Has_Open_Tasks__c';
    stage2_Approval7_RuleEntry.Operator__c = '!=';
    stage2_Approval7_RuleEntry.Data_Type__c = 'BOOLEAN';
    stage2_Approval7_RuleEntry.Value__c = 'TRUE';
    stage2_Approval7_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-211';
    caseRuleEntryList.add(stage2_Approval7_RuleEntry);
          
    ASF_Case_Rule_Entry__c stage2_checklist_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_checklist_RuleEntry.Number__c = 1;
    stage2_checklist_RuleEntry.Case_Rule__c = stage2_checklist_Rule.Id;
    stage2_checklist_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_checklist_RuleEntry.Operator__c = '=';
    stage2_checklist_RuleEntry.Data_Type__c = 'STRING';
    stage2_checklist_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_checklist_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-002';
    caseRuleEntryList.add(stage2_checklist_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_work1_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_work1_RuleEntry.Number__c = 1;
    stage2_work1_RuleEntry.Case_Rule__c = stage2_Work_Rule.Id;
    stage2_work1_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_work1_RuleEntry.Operator__c = 'in';
    stage2_work1_RuleEntry.Data_Type__c = 'STRING';
    stage2_work1_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_work1_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-013';
    caseRuleEntryList.add(stage2_work1_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage2_assignment_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_assignment_RuleEntry.Number__c = 1;
    stage2_assignment_RuleEntry.Case_Rule__c = stage2_Assignment_Rule.Id;
    stage2_assignment_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_assignment_RuleEntry.Operator__c = '=';
    stage2_assignment_RuleEntry.Data_Type__c = 'STRING';
    stage2_assignment_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_assignment_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-704';
    caseRuleEntryList.add(stage2_assignment_RuleEntry);
    
    ASF_Case_Rule_Entry__c stage1_assignment_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage1_assignment_RuleEntry.Number__c = 1;
    stage1_assignment_RuleEntry.Case_Rule__c = stage1_Assignment_Rule.Id;
    stage1_assignment_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage1_assignment_RuleEntry.Operator__c = '=';
    stage1_assignment_RuleEntry.Data_Type__c = 'STRING';
    stage1_assignment_RuleEntry.Value__c = 'Pending with Initiator';
    stage1_assignment_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-706';
    caseRuleEntryList.add(stage1_assignment_RuleEntry);
        
    ASF_Case_Rule_Entry__c stage2_movement_RuleEntry = new ASF_Case_Rule_Entry__c();
    stage2_movement_RuleEntry.Number__c = 1;
    stage2_movement_RuleEntry.Case_Rule__c = stage1_StageMovement_Rule.Id;
    stage2_movement_RuleEntry.Field_Api_Name__c = 'Stage__c';
    stage2_movement_RuleEntry.Operator__c = '=';
    stage2_movement_RuleEntry.Data_Type__c = 'STRING';
    stage2_movement_RuleEntry.Value__c = 'Pending with Initiator';
    stage2_movement_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-805';
    caseRuleEntryList.add(stage2_movement_RuleEntry);
       

    insert caseRuleEntryList;


    ASF_Work_Item__c stage2_Work_WorkItem = new ASF_Work_Item__c();
    //Assigned_Queue__c = '00GHE0000003Qm42AE'
    stage2_Work_WorkItem.Task_Title__c = 'Service Request - Clarification from Credit';
    stage2_Work_WorkItem.Task_Description__c = 'Check the accuracy of the Credit report submitted to bureau for Ownership Dispute';
    stage2_Work_WorkItem.Completion_Time__c = 4;
    stage2_Work_WorkItem.Case_Rule__c= stage2_Work_Rule.Id;
    stage2_Work_WorkItem.Work_Item_External_ID__c='Workitem-CIBIL-OD-001';

    workItemsList.add(stage2_Work_WorkItem);

    insert workItemsList;

    ASF_Case_Checklist_Master__c checklistRecord = new ASF_Case_Checklist_Master__c();
    checklistRecord.Case_Rule__c = stage2_checklist_Rule.Id;
    checklistRecord.name = 'Test checklist';
    checklistRecord.Mandatory__c = true;
    checklistRecord.Description__c = 'test from test class';
    checklistRecord.Type__c = '	Manual';
    
    insert checklistRecord;
   
    ///-----------------------------///


    // ASF_Case_Stage_Config__c approvalStage = new ASF_Case_Stage_Config__c();
    // approvalStage.Case_Category_Config__c = caseCatConfig.Id;
    // approvalStage.Order__c = 3;
    // approvalStage.Stage_SLA_1__c = 1;
    // approvalStage.Stage_SLA_2__c = 2;
    // approvalStage.Stage_SLA_3__c = 3;
    // approvalStage.StageName__c  = 'In Progress with CEC1';
    // approvalStage.Query_Fields__c = 'Id,Stage__c';
    // stageConfigList.add(approvalStage);


    // ASF_Case_Stage_Config__c stage1Two = new ASF_Case_Stage_Config__c();
    // stage1Two.Case_Category_Config__c = caseCatConfig.Id;
    // stage1Two.Order__c = 4;
    // stage1Two.Query_Fields__c = 'Id,Stage__c';
    // stage1Two.StageName__c  = 'Closed';

    // stageConfigList.add(stage1Two);
      
    // insert stageConfigList;

    // mapOfCaseConfigs.put('stageConfig', stageConfigList);

    

    // ASF_Case_Rule__c stage1WorkRule = new ASF_Case_Rule__c();

    // stage1WorkRule.ASF_Case_Stage_Config__c = stage1.Id;
    // stage1WorkRule.Logical_Condition__c = '1';
    // stage1WorkRule.Order__c = 1;
    // stage1WorkRule.Type__c = 'Work';

    // caseRuleList.add(stage1WorkRule);


    // ASF_Case_Rule__c stage1ChecklistRule = new ASF_Case_Rule__c();

    // stage1ChecklistRule.ASF_Case_Stage_Config__c = stage1.Id;
    // stage1ChecklistRule.Logical_Condition__c = '1';
    // stage1ChecklistRule.Order__c = 1;
    // stage1ChecklistRule.Type__c = 'Checklists';

    // caseRuleList.add(stage1ChecklistRule);

    // ASF_Case_Rule__c caseRule1 = new ASF_Case_Rule__c();

    // caseRule1.ASF_Case_Stage_Config__c = stage1One.Id;
    // caseRule1.Logical_Condition__c = '1';
    // caseRule1.Order__c = 1;
    // caseRule1.Type__c = 'Stage Movement';

    // caseRuleList.add(caseRule1);


    // ASF_Case_Rule__c AssignmentRule = new ASF_Case_Rule__c();

    // AssignmentRule.ASF_Case_Stage_Config__c = stage1One.Id;
    // AssignmentRule.Logical_Condition__c = '1';
    // AssignmentRule.Order__c = 1;
    // AssignmentRule.Assign_to_Initiator__c = true;
    // AssignmentRule.Type__c = 'Assignment';

    // caseRuleList.add(AssignmentRule);

    // ASF_Case_Rule__c ValidationRule = new ASF_Case_Rule__c();

    // ValidationRule.ASF_Case_Stage_Config__c = stage1One.Id;
    // ValidationRule.Logical_Condition__c = '1';
    // ValidationRule.Order__c = 1;
    // ValidationRule.Validation_Message__c = 'Testing exception';
    // ValidationRule.Type__c = 'Validation';

    // caseRuleList.add(ValidationRule);


    // ASF_Case_Rule__c approvalRules = new ASF_Case_Rule__c();

    // approvalRules.ASF_Case_Stage_Config__c = stage1One.Id;
    // approvalRules.Logical_Condition__c = '1';
    // approvalRules.Order__c = 1;
    // approvalRules.Type__c = 'Approval';

    // caseRuleList.add(approvalRules);

    // ASF_Case_Rule__c caseRule2 = new ASF_Case_Rule__c();

    // caseRule2.ASF_Case_Stage_Config__c = stage1Two.Id;
    // caseRule2.Logical_Condition__c = '1';
    // caseRule2.Order__c = 1;
    // caseRule2.Type__c = 'Stage Movement';

    // caseRuleList.add(caseRule2);


    // ASF_Case_Rule__c caseRule3 = new ASF_Case_Rule__c();

    // caseRule3.ASF_Case_Stage_Config__c = stage1One.Id;
    // caseRule3.Logical_Condition__c = '1';
    // caseRule3.Order__c = 1;
    // caseRule3.Type__c = 'Work';

    // caseRuleList.add(caseRule3);


    // ASF_Case_Rule__c checkListRule = new ASF_Case_Rule__c();

    // checkListRule.ASF_Case_Stage_Config__c = stage1One.Id;
    // checkListRule.Logical_Condition__c = '1';
    // checkListRule.Order__c = 1;
    // checkListRule.Type__c = 'Checklists';

    // caseRuleList.add(checkListRule);

    // insert caseRuleList;

    // ASF_Case_Rule_Entry__c stage1workItemRuleEntry = new ASF_Case_Rule_Entry__c();
    // stage1workItemRuleEntry.Number__c = 1;
    // stage1workItemRuleEntry.Parent_Rule__c = stage1WorkRule.Id;
    // stage1workItemRuleEntry.Field_Api_Name__c = 'Stage__c';
    // stage1workItemRuleEntry.Operator__c = '=';
    // stage1workItemRuleEntry.Data_Type__c = 'STRING';
    // stage1workItemRuleEntry.Value__c = 'Pending with Initator';

    // insert stage1workItemRuleEntry;


    // ASF_Case_Rule_Entry__c stage1ChecklistRuleEntry = new ASF_Case_Rule_Entry__c();
    // stage1ChecklistRuleEntry.Number__c = 1;
    // stage1ChecklistRuleEntry.Parent_Rule__c = stage1ChecklistRule.Id;
    // stage1ChecklistRuleEntry.Field_Api_Name__c = 'Stage__c';
    // stage1ChecklistRuleEntry.Operator__c = '=';
    // stage1ChecklistRuleEntry.Data_Type__c = 'STRING';
    // stage1ChecklistRuleEntry.Value__c = 'Pending with Initator';

    // insert stage1ChecklistRuleEntry;

    

    // // caseRuleList.add(caseRule1);
    

    // ASF_Case_Rule_Entry__c caseRuleEntry = new ASF_Case_Rule_Entry__c();
    // caseRuleEntry.Number__c = 1;
    // caseRuleEntry.Parent_Rule__c = caseRule1.Id;
    // caseRuleEntry.Field_Api_Name__c = 'Stage__c';
    // caseRuleEntry.Operator__c = '=';
    // caseRuleEntry.Data_Type__c = 'STRING';
    // caseRuleEntry.Value__c = 'In Progress with CEC';


    // insert caseRuleEntry;


    // ASF_Case_Rule_Entry__c validationRuleEntry = new ASF_Case_Rule_Entry__c();
    // validationRuleEntry.Number__c = 1;
    // validationRuleEntry.Parent_Rule__c = ValidationRule.Id;
    // validationRuleEntry.Field_Api_Name__c = 'Origin';
    // validationRuleEntry.Operator__c = '=';
    // validationRuleEntry.Data_Type__c = 'STRING';
    // validationRuleEntry.Value__c = 'Phone';


    // insert validationRuleEntry;


    // ASF_Case_Rule_Entry__c caseRuleEntry1 = new ASF_Case_Rule_Entry__c();
    // caseRuleEntry1.Number__c = 1;
    // caseRuleEntry1.Parent_Rule__c = caseRule1.Id;
    // caseRuleEntry1.Field_Api_Name__c = 'Stage__c';
    // caseRuleEntry1.Operator__c = '=';
    // caseRuleEntry1.Data_Type__c = 'STRING';
    // caseRuleEntry1.Value__c = 'In Progress with CEC';

    // insert caseRuleEntry1;


    // ASF_Case_Rule_Entry__c checklistRuleEntry1 = new ASF_Case_Rule_Entry__c();
    // checklistRuleEntry1.Number__c = 1;
    // checklistRuleEntry1.Parent_Rule__c = checkListRule.Id;
    // checklistRuleEntry1.Field_Api_Name__c = 'Stage__c';
    // checklistRuleEntry1.Operator__c = '=';
    // checklistRuleEntry1.Data_Type__c = 'STRING';
    // checklistRuleEntry1.Value__c = 'In Progress with CEC';

    // insert checklistRuleEntry1;

    // ASF_Case_Rule_Entry__c workItemRuleEntry = new ASF_Case_Rule_Entry__c();
    // workItemRuleEntry.Number__c = 1;
    // workItemRuleEntry.Parent_Rule__c = caseRule3.Id;
    // workItemRuleEntry.Field_Api_Name__c = 'Stage__c';
    // workItemRuleEntry.Operator__c = '=';
    // workItemRuleEntry.Data_Type__c = 'STRING';
    // workItemRuleEntry.Value__c = 'In Progress with CEC';

    // insert workItemRuleEntry;


    // ASF_Case_Rule_Entry__c approvalRuleEntry = new ASF_Case_Rule_Entry__c();
    // approvalRuleEntry.Number__c = 1;
    // approvalRuleEntry.Parent_Rule__c = approvalRules.Id;
    // approvalRuleEntry.Field_Api_Name__c = 'Stage__c';
    // approvalRuleEntry.Operator__c = '=';
    // approvalRuleEntry.Data_Type__c = 'STRING';
    // approvalRuleEntry.Value__c = 'In Progress with CEC';

    // insert approvalRuleEntry;

    
    // ASF_Case_Rule_Entry__c AssignmentRuleEntry = new ASF_Case_Rule_Entry__c();
    // AssignmentRuleEntry.Number__c = 1;
    // AssignmentRuleEntry.Parent_Rule__c = AssignmentRule.Id;
    // AssignmentRuleEntry.Field_Api_Name__c = 'Stage__c';
    // AssignmentRuleEntry.Operator__c = '=';
    // AssignmentRuleEntry.Data_Type__c = 'STRING';
    // AssignmentRuleEntry.Value__c = 'In Progress with CEC';

    // insert AssignmentRuleEntry;

    // ASF_Work_Item__c wi = new ASF_Work_Item__c();
    // wi.Task_Title__c = 'Test Task';
    // wi.Task_Description__c = 'Test Description';
    // wi.Completion_Time__c = 2;
    // wi.Case_Rule__c=caseRule3.Id;
    // wi.Work_Item_External_ID__c='WI-TEST-1';

    // insert wi;


    // CaseChecklistMaster__c ccm = new CaseChecklistMaster__c();
    // ccm.Name ='Test';
    // ccm.Mandatory__c = true;
    // ccm.Description__c  = 'Test';
    // ccm.Case_Rule__c=checkListRule.Id;
    // ccm.Type__c = 'Manual';
    // ccm.Checklist_External_Id__c = 'CHEKCLIST-TEST-1';
    
    // insert ccm;

    // ASF_Work_Item__c wi2 = new ASF_Work_Item__c();
    // wi2.Task_Title__c = 'Test Task';
    // wi2.Task_Description__c = 'Test Description';
    // wi2.Completion_Time__c = 2;
    // wi2.Case_Rule__c=stage1WorkRule.Id;
    // wi2.Work_Item_External_ID__c='WI-TEST-2';

    // insert wi2;


    // CaseChecklistMaster__c ccm2 = new CaseChecklistMaster__c();
    // ccm2.Name ='Test';
    // ccm2.Mandatory__c = true;
    // ccm2.Description__c  = 'Test';
    // ccm2.Case_Rule__c=stage1ChecklistRule.Id;
    // ccm2.Type__c = 'Manual';
    // ccm2.Checklist_External_Id__c = 'CHEKCLIST-TEST-2';
    
    // insert ccm2;

    
    
   // return mapOfCaseConfigs;
    }

    /****************************************************
     * @Description - Create Branch banking PS user 
     * return - user       
    *****************************************************/
    public static User createBranchUserWithPermissions() {
        String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer intRandomValue = Integer.valueOf(math.rint(math.random() * 1000000));
        String strUniqueName = strDate + intRandomValue;
        User objUser;
        String strProfileId = [select Id from Profile where Name = 'Payment Base Profile'].Id;
        UserRole ur = [SELECT ID FROM UserRole WHERE DeveloperName = 'Payments_Service_Agent'];
        objUser = new User(profileId = strProfileId, email = 'CS360@FCAAdmin.mock.com', UserRoleId=ur.Id,
                     Username = strUniqueName + '@CS360@' + strUniqueName +  'mock.com',
                     alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                     languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,Type__c = 'Team Lead', LOB__c = 'Payments',Business_Unit__c = 'Payments');
        if(strProfileId != null){
            objUser.profileId = strProfileId;
        }
        
        insert objUser;
        //ASF_TestDataFactory.givePermissions(objUser.Id, 'Create Case');
        ASF_TestDataFactory.givePermissions(objUser.Id, ASF_Constants.C360_PERM_SET_APINAME);
        System.assertNotEquals(NULL, objUser, 'Creating a User record is failed.');
        return objUser;
    }

    /****************************************************
     * @Description - Insert Contact Record
     * @param lastName -  Contains last name
     * @param email -  Contains email
     * @return - Contact       
    *****************************************************/
    
    public static Contact insertContact(String lastName, String email) {
        Contact objContact = new Contact();
        objContact.LastName = String.isNotBlank(lastName)?lastName:'TestContactName';
        objContact.Email =  String.isNotBlank(email)? email: 'Test@test.com';
        if(Schema.sObjectType.Contact.isCreateable()){
            insert objContact;
        }
        
        return objContact;
     }
        
     /****************************************************
     * @Description - Create Asset record 
     * @param accountId -  Contain Account Id for which asset is created
     * @param strType -  Contain Type
     * @return - Asset
    *****************************************************/

    public static Asset createAssetWithoutInsert(Id accountId,String strType,String strStatus) {
        Asset asset = new Asset();
        asset.Name = 'Test Asset';
        //asset.Financial_Account_Number__c = ASF_UtilityClass.generateTransactionId();
        asset.AccountId =accountId;
        asset.Type__c = strType;
        asset.Status = strStatus;
        return asset;
    }
    
    /****************************************************
     * @Description - Insert Field Configuration Record
     * @param  strGroupName - Contain Group Name
     * @param strLabelName - Contain Label Name
     * @param strAPIName - Contain API Name
     * @param strExtId - Contain External Id
     * @param StrFieldPositioning - Contain Field Positioning details
     * @param strDataType - Contain field DataType
     * @param strProfilesVisibility - Contain field's profile visibility details
     * @param strPicklistValues - Contain picklist values if any
     * @param strAddTxt - Contain AdditionalTxt Values values if any
     * @return - ASF_FieldConfigurationRecord__c       
    *****************************************************/

    public static ASF_FieldConfigurationRecord__c insertFieldConfigRecordForPresentPastHolding(String strGroupName,String strLabelName,String strAPIName,
		String strExtId,String strFieldPositioning,String strDataType,String strProfilesVisibility,String strPicklistValues,String strAddTxt) {
        ASF_FieldConfigurationRecord__c configRec = new ASF_FieldConfigurationRecord__c();
        configRec.ASF_GroupName__c = strGroupName;
        configRec.ASF_FieldName__c = strLabelName;
        configRec.ASF_FieldApi__c = strAPIName;
        configRec.ASF_IsActive__c = true;
        configRec.ASF_ExternalId__c = strExtId;
        configRec.ASF_FieldPositioning__c = strFieldPositioning;
        configRec.ASF_Data_Type__c = strDataType;
        configRec.ASF_ProfilesVisibility__c = strProfilesVisibility;  
        configRec.ASF_PicklistValues__c = strPicklistValues;  
        configRec.ASF_AdditionalText__c = strAddTxt;
        return configRec;
    }

    /****************************************************
     * @Description - Create User with Base Profile and specified Permission Set.
     * @return - User       
    *****************************************************/

    public static User createCS60UserWithGivenPermissionSet(String permissionSetApiName) {
        String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer intRandomValue = Integer.valueOf(math.rint(math.random() * 1000000));
        String strUniqueName = strDate + intRandomValue;
        User objUser;
        String strProfileId = [select Id from Profile where Name = 'Payment Base Profile'].Id;
        objUser = new User(profileId = strProfileId, email = 'CS360@FCAAdmin.mock.com',
                     Username = strUniqueName + '@CS360@' + strUniqueName +  'mock.com',
                     alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_IN',
                     languagelocalekey = 'en_US', timezonesidkey = 'Asia/Kolkata',IsActive = true);
        if(strProfileId != null){
            objUser.profileId = strProfileId;
        }
        
        insert objUser;
        if(!String.isBlank(permissionSetApiName)){
            ASF_TestDataFactory.givePermissions(objUser.Id, permissionSetApiName);
            // ASF_TestDataFactory.givePermissions(objUser.Id,ASF_Constants.C360_PERM_SET_APINAME);
        }
        System.assertNotEquals(NULL, objUser, 'Creating a User record is failed.');
        return objUser;
    }

    /****************************************************
     * @Description - Creates a Person Account
     * @param strFirstName-  Contains First name
     * @param strLastName -  Contains Last name
     * @param strCRN -  Contains CRN Number
     * @return - Account       
    *****************************************************/

    public static Account createPersonAccountWithoutInsert(String strFirstName, String strLastName,String strCRN) {
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = String.isNotBlank(strFirstName)?strFirstName:'TestFirstName';
        objAccount.LastName = String.isNotBlank(strLastName)?strLastName:'TestFirstName';
        //objAccount.CRN__c = String.isNotBlank(strCRN)? strCRN: String.valueOf( Integer.valueof((Math.random() * 100)));
        objAccount.RecordTypeId = recordTypeId;
        // if(Schema.sObjectType.Account.isCreateable()){
        //      insert objAccount;
        // }
        return objAccount;
    }


    public static void createC3WithPrePopulateIntegrations(){
        Map<String,List<SObject>> mapOfCaseConfigs = new Map<String,List<SObject>>();   
        List<ASF_Case_Category_Config__c> listCaseCatConfig = new List<ASF_Case_Category_Config__c>();
        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

        caseCatConfig.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseCatConfig.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig.First_Stage__c = 'Pending with Initiator';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Source__c = 'CEC';
        caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
        
        insert caseCatConfig;
        
        listCaseCatConfig.add(caseCatConfig);
        mapOfCaseConfigs.put('categoryConfig', listCaseCatConfig);


        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
	
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = caseCatConfig.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'Pending with Initiator';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        // stage1.Stage_SLA_2__c = 2;
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;

        stageConfigList.add(stage1);
        
        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
        stage2.Case_Category_Config__c = caseCatConfig.Id;
        stage2.Order__c = 2;
        stage2.Stage_SLA_1__c = 1;
        stage2.Stage_SLA_2__c = 2;
        stage2.Stage_SLA_3__c = 3;
        stage2.SLA_Target_1_Type__c = 'Manager';
        stage2.SLA_Target_2_Type__c = 'Manager';
        stage2.SLA_Target_3_Type__c = 'Manager';
        stage2.StageName__c  = 'In Progress with Recovery';
        stage2.Status_Mapping__c = 'In Progress';
        stage2.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage2);


        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
        stage3.Case_Category_Config__c = caseCatConfig.Id;
        stage3.Order__c = 2;
        stage3.Stage_SLA_1__c = 1;
        stage3.Stage_SLA_2__c = 2;
        stage3.Stage_SLA_3__c = 3;
        stage3.SLA_Target_1_Type__c = 'Manager';
        stage3.SLA_Target_2_Type__c = 'Manager';
        stage3.SLA_Target_3_Type__c = 'Manager';
        stage3.StageName__c  = 'Closed';
        stage3.Status_Mapping__c = 'Closed';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);


        insert stageConfigList;

        List<ASF_Integration__c> intConfigList = new List<ASF_Integration__c>();

        ASF_Integration__c prePopInt1 = new ASF_Integration__c();
        prePopInt1.External_Id__c = 'ASF_INT_01';
        prePopInt1.Case_Stage_Config__c = stageConfigList[0].Id;
        prePopInt1.Type__c = 'Pre Populate';
        prePopInt1.When_to_Appear__c = 'Stage Entry';
        prePopInt1.Visibility_Class__c = 'ASF_IntegrationInvocableTest';
        prePopInt1.Processing_Class__c = 'ASF_IntegrationInvocableTest';
        prePopInt1.Display_Name__c = 'Fetch Field';

        intConfigList.add(prePopInt1);


        ASF_Integration__c processInt2 = new ASF_Integration__c();
        processInt2.External_Id__c = 'ASF_INT_02';
        processInt2.Case_Stage_Config__c = stageConfigList[0].Id;
        processInt2.Type__c = 'Process';
        processInt2.Auto_Run_on_Load__c = true;
        processInt2.Mandatory_At_Stage_Movement__c= true;
        processInt2.When_to_Appear__c = 'Stage Entry';
        processInt2.Visibility_Class__c = 'ASF_IntegrationInvocableTest1';
        processInt2.Processing_Class__c = 'ASF_IntegrationInvocableTest1';
        processInt2.Display_Name__c = 'Update CBS';

        intConfigList.add(processInt2);

        ASF_Integration__c uiInt3 = new ASF_Integration__c();
        uiInt3.External_Id__c = 'ASF_INT_03';
        uiInt3.Mandatory_At_Stage_Movement__c= false;
        uiInt3.Case_Stage_Config__c = stageConfigList[0].Id;
        uiInt3.Type__c = 'UI Card';
        uiInt3.When_to_Appear__c = 'Stage Entry';
        uiInt3.UI_Component__c = 'c/sometestcomponent';
        uiInt3.Visibility_Class__c = 'ASF_IntegrationInvocableTest';
        uiInt3.Processing_Class__c = 'ASF_IntegrationInvocableTest';
        uiInt3.Display_Name__c = 'View Transactions';

        intConfigList.add(uiInt3);

        insert intConfigList;

    }

    /****************************************************
     * @Description - Create Case Configs 
     * return - Map of Case Configs       
    *****************************************************/
    public static void createC3IntegrationsAndCase() {
        Map<String,List<SObject>> mapOfCaseConfigs = new Map<String,List<SObject>>();   
        List<ASF_Case_Category_Config__c> listCaseCatConfig = new List<ASF_Case_Category_Config__c>();
        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

        caseCatConfig.CCC_External_Id__c = 'CCC-CC-CCLTD-05';
        caseCatConfig.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig.First_Stage__c = 'Pending with Initiator';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Source__c = 'CEC';
        caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
        caseCatConfig.New_Case_Email_Template__c = 'Generic_SR_Created';
        
        insert caseCatConfig;

        listCaseCatConfig.add(caseCatConfig);
        mapOfCaseConfigs.put('categoryConfig', listCaseCatConfig);


        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
	
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = caseCatConfig.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'Pending with Initiator';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        // stage1.Stage_SLA_2__c = 2;
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;

        stageConfigList.add(stage1);
        
        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
        stage2.Case_Category_Config__c = caseCatConfig.Id;
        stage2.Order__c = 2;
        stage2.Stage_SLA_1__c = 1;
        stage2.Stage_SLA_2__c = 2;
        stage2.Stage_SLA_3__c = 3;
        stage2.SLA_Target_1_Type__c = 'Manager';
        stage2.SLA_Target_2_Type__c = 'Manager';
        stage2.SLA_Target_3_Type__c = 'Manager';
        stage2.StageName__c  = 'In Progress with Recovery';
        stage2.Status_Mapping__c = 'In Progress';
        stage2.Query_Fields__c = 'Id,Stage__c';
        stage2.BeforeStageApexClass__c = 'ASF_CaseStageClassInvocable_Test';
        stage2.AfterStageApexClass__c = 'ASF_CaseStageClassInvocable_Test';
        stageConfigList.add(stage2);


        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
        stage3.Case_Category_Config__c = caseCatConfig.Id;
        stage3.Order__c = 2;
        stage3.Stage_SLA_1__c = 1;
        stage3.Stage_SLA_2__c = 2;
        stage3.Stage_SLA_3__c = 3;
        stage3.SLA_Target_1_Type__c = 'Manager';
        stage3.SLA_Target_2_Type__c = 'Manager';
        stage3.SLA_Target_3_Type__c = 'Manager';
        stage3.StageName__c  = 'Closed';
        stage3.Status_Mapping__c = 'Closed';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);


        insert stageConfigList;

        List<ASF_Integration__c> intConfigList = new List<ASF_Integration__c>();

        ASF_Integration__c prePopInt1 = new ASF_Integration__c();
        prePopInt1.External_Id__c = 'ASF_INT_01';
        prePopInt1.Case_Stage_Config__c = stageConfigList[0].Id;
        prePopInt1.Type__c = 'Pre Populate';
        prePopInt1.When_to_Appear__c = 'Stage Entry';
        prePopInt1.Visibility_Class__c = 'ASF_IntegrationInvocableTest';
        prePopInt1.Processing_Class__c = 'ASF_IntegrationInvocableTest';
        prePopInt1.Display_Name__c = 'Fetch Field';

        intConfigList.add(prePopInt1);


        ASF_Integration__c processInt2 = new ASF_Integration__c();
        processInt2.External_Id__c = 'ASF_INT_02';
        processInt2.Case_Stage_Config__c = stageConfigList[0].Id;
        processInt2.Type__c = 'Process';
        processInt2.Mandatory_At_Stage_Movement__c= true;
        processInt2.When_to_Appear__c = 'Stage Entry';
        processInt2.Visibility_Class__c = 'ASF_IntegrationInvocableTest';
        processInt2.Processing_Class__c = 'ASF_IntegrationInvocableTest';
        processInt2.Display_Name__c = 'Update CBS';

        intConfigList.add(processInt2);

        ASF_Integration__c uiInt3 = new ASF_Integration__c();
        uiInt3.External_Id__c = 'ASF_INT_03';
        uiInt3.Mandatory_At_Stage_Movement__c= false;
        uiInt3.Case_Stage_Config__c = stageConfigList[0].Id;
        uiInt3.Type__c = 'UI Card';
        uiInt3.When_to_Appear__c = 'Stage Entry';
        uiInt3.UI_Component__c = 'c/sometestcomponent';
        uiInt3.Visibility_Class__c = 'ASF_IntegrationInvocableTest';
        uiInt3.Processing_Class__c = 'ASF_IntegrationInvocableTest';
        uiInt3.Display_Name__c = 'View Transactions';

        intConfigList.add(uiInt3);

        insert intConfigList;

        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-05';
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            //newCase.pending_clarification__c = true;
            
        insert newCase;


    }
    /****************************************************
     * @Description - Create Case 
     * @return - List of Case       
    *****************************************************/
    public static List<Case> icreateCaseRecords(Integer noOfCase) {

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<noOfCase;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test'+i+'@salesforce.com' );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.Subject = 'CC-TEST-0'+i;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            caseList.add(newCase);
        
        }
        
        insert caseList;

        return caseList;
    }
    /****************************************************
     * @Description - Create Case Integration Records      
    *****************************************************/
    public static void createCaseIntegration(Id caseId, string intExtId){
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Status__c = 'Pending';
        caseInt.Integration_Ext_Id__c = intExtId;
        caseInt.Case__c = caseId;
        insert caseInt;
    }


    //Santanu
    public static List<Case> createCaseRecordsWithoutInsert() {
        List<Case> caseList = new List<Case>();
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        newCase.Stage_SLA_1__c = System.now();
        newCase.Stage_SLA_2__c = System.now()+1;
        newCase.Stage_SLA_3__c = System.now()+2;
        newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            
        caseList.add(newCase);
        return caseList;
    }

    public static List<Case> createCaseRecordsWithoutInsertSTP() {
        List<Case> caseList = new List<Case>();
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        newCase.Stage_SLA_1__c = System.now();
        newCase.Stage_SLA_2__c = System.now()+1;
        newCase.Stage_SLA_3__c = System.now()+2;
        newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            
        caseList.add(newCase);
        return caseList;
    }

    public static void createCaseCategoryConfigWithSTP() {
               
        Map<String,List<SObject>> mapOfCaseConfigs = new Map<String,List<SObject>>();   
        List<ASF_Case_Category_Config__c> listCaseCatConfig = new List<ASF_Case_Category_Config__c>();
        List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>();
        List<ASF_Case_Rule_Entry__c> caseRuleEntryList = new List<ASF_Case_Rule_Entry__c>();
        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
    
        list<ASF_Work_Item__c> workItemsList = new list<ASF_Work_Item__c>();
        caseCatConfig.CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        caseCatConfig.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig.First_Stage__c = 'Pending with Initiator';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Source__c = 'CEC';  // Branch
        caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
        caseCatConfig.Process__c='Case';
        caseCatConfig.is_FA_Mandatory__c = true;
        caseCatConfig.Business_Unit__c = 'ABHFL';
        insert caseCatConfig;
    
        PAY_Payment_Detail__c paymentRecord = new PAY_Payment_Detail__c (Payment_mode__c = 'Online', Status_of_Transaction__c = 'Success');
        insert paymentRecord;
    
        listCaseCatConfig.add(caseCatConfig);
        mapOfCaseConfigs.put('categoryConfig', listCaseCatConfig);
        
        List<ASF_Case_Field_Config__c> fieldConfigs = new List<ASF_Case_Field_Config__c>();
        ASF_Case_Field_Config__c field1 = new ASF_Case_Field_Config__c();
        field1.Case_Main_Config__c = caseCatConfig.Id;
        field1.ObjectAPIName__c = 'Case';
        field1.FieldAPIName__c = 'Description';
        field1.Display_Order__c = 1;
        fieldConfigs.add(field1);
        ASF_Case_Field_Config__c field2 = new ASF_Case_Field_Config__c();
        field2.Case_Main_Config__c = caseCatConfig.Id;
        field2.ObjectAPIName__c = 'PAY_Payment_Detail__c';
        field2.FieldAPIName__c = 'Payment_mode__c';
        field2.Display_Order__c = 2;
        fieldConfigs.add(field2);
        insert fieldConfigs;
    
        Group testGroup = [Select Id from Group where DeveloperName ='Payments_Service_Desk' LIMIT 1];
        Group testGroupError = [Select Id from Group where DeveloperName ='DefaultErrorQueue' LIMIT 1];
            
        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = caseCatConfig.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'Pending with Initiator';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        // stage1.Stage_SLA_2__c = 2;
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        stage1.Default_Queue__c = testGroup.Id;
        stage1.Default_Error_Queue__c = testGroupError.Id;
        stage1.Owner_Check_Stages__c = 'Pending with Initiator';
        stage1.Has_Same_Owner_Check__c = false;
        stageConfigList.add(stage1);
    
       
    
        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
        stage2.Case_Category_Config__c = caseCatConfig.Id;
        stage2.Order__c = 2;
        stage2.Stage_SLA_1__c = 1;
        stage2.Stage_SLA_2__c = 2;
        stage2.Stage_SLA_3__c = 3;
        stage2.SLA_Target_1_Type__c = 'Manager';
        stage2.SLA_Target_2_Type__c = 'Manager';
        stage2.SLA_Target_3_Type__c = 'Manager';
        stage2.StageName__c  = 'In Progress with Recovery';
        stage2.Status_Mapping__c = 'In Progress';
        stage2.Query_Fields__c = 'Id,Stage__c,CSAT__c,SLA_Target_1__c,DB_Hours__c,has_CheckLists__c,Has_Open_Tasks__c';
        stageConfigList.add(stage2);
    
        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
        stage3.Case_Category_Config__c = caseCatConfig.Id;
        stage3.Order__c = 3;
        stage3.Stage_SLA_1__c = 1;
        // stage3.Stage_SLA_2__c = 2;
        // stage3.Stage_SLA_3__c = 3;
        stage3.SLA_Target_1_Type__c = 'Manager';
        // stage3.SLA_Target_2_Type__c = 'Manager';
        // stage3.SLA_Target_3_Type__c = 'Manager';
        stage3.StageName__c  = 'Pending NCM Approval';
        stage3.Status_Mapping__c = 'In Progress';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);
    
        ASF_Case_Stage_Config__c stage4 = new ASF_Case_Stage_Config__c();
        stage4.Case_Category_Config__c = caseCatConfig.Id;
        stage4.Order__c = 3;
        stage4.Stage_SLA_1__c = 1;
        // stage3.Stage_SLA_2__c = 2;
        // stage3.Stage_SLA_3__c = 3;
        stage4.SLA_Target_1_Type__c = 'Manager';
        // stage3.SLA_Target_2_Type__c = 'Manager';
        // stage3.SLA_Target_3_Type__c = 'Manager';
        stage4.StageName__c  = 'Resolved';
        stage4.Status_Mapping__c = 'Closed';
        stage4.Query_Fields__c = 'Id,Stage__c';
        stage4.Default_Queue__c = testGroup.Id;
        stage4.Default_Error_Queue__c = testGroupError.Id;
        stageConfigList.add(stage4);
    

        ASF_Case_Stage_Config__c stage5 = new ASF_Case_Stage_Config__c();
        stage5.Case_Category_Config__c = caseCatConfig.Id;
        stage5.Case_Category_Config__c = caseCatConfig.Id;
        stage5.Order__c = 2;
        stage5.Stage_SLA_1__c = 1;
        stage5.Stage_SLA_2__c = 2;
        stage5.Stage_SLA_3__c = 3;
        stage5.SLA_Target_1_Type__c = 'Manager';
        stage5.SLA_Target_2_Type__c = 'Manager';
        stage5.SLA_Target_3_Type__c = 'Manager';
        stage5.StageName__c  = 'In Progress with Recovery';
        stage5.Status_Mapping__c = 'In Progress';
        stage5.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage5);

        ASF_Case_Stage_Config__c stage6 = new ASF_Case_Stage_Config__c();
        stage6.Case_Category_Config__c = caseCatConfig.Id;
        stage6.Order__c = 6;
        stage6.Stage_Reopen_SLA_1__c = 1;
        stage6.Stage_Reopen_SLA_2__c = 2;
        stage6.Stage_Reopen_SLA_3__c = 3;
        stage6.SLA_Target_1_Type__c = 'Manager';
        stage6.SLA_Target_2_Type__c = 'Manager';
        stage6.SLA_Target_3_Type__c = 'Manager';
        stage6.StageName__c  = 'Reopened';
        stage6.Status_Mapping__c = 'Open';
        stage6.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage6);

        insert stageConfigList;
        
        
    
        // ASF_Case_Rule__c stage1_StageMovement_Rule = new ASF_Case_Rule__c();
    
        // stage1_StageMovement_Rule.Case_Stage_Config__c = stage1.Id;
        // stage1_StageMovement_Rule.Logical_Condition__c = '1';
        // stage1_StageMovement_Rule.Order__c = 1;
        // stage1_StageMovement_Rule.Type__c = 'Stage Movement';
    
        // // caseRuleList.add(stage1_StageMovement_Rule);
        // insert stage1_StageMovement_Rule;
        
        ASF_Case_Rule__c stage1_Assignment_Rule = new ASF_Case_Rule__c();
    
        stage1_Assignment_Rule.Case_Stage_Config__c = stage1.Id;
        stage1_Assignment_Rule.Logical_Condition__c = '1';
        stage1_Assignment_Rule.Order__c = 2;
        stage1_Assignment_Rule.Type__c = 'Assignment';
    
        // caseRuleList.add(stage1_StageMovement_Rule);
        insert stage1_Assignment_Rule;
    
    
        ASF_Case_Rule__c stage2_StageMovement_Rule = new ASF_Case_Rule__c();
    
        stage2_StageMovement_Rule.Case_Stage_Config__c = stage2.Id;
        stage2_StageMovement_Rule.Logical_Condition__c = '1 AND 2 AND 3 AND (4 OR 5) AND 6 AND 7';
        stage2_StageMovement_Rule.Order__c = 1;
        stage2_StageMovement_Rule.Type__c = 'Approval';
    
        insert stage2_StageMovement_Rule;
        
        ASF_Case_Rule__c stage2_StageMovement2_Rule = new ASF_Case_Rule__c();
        stage2_StageMovement2_Rule.Case_Stage_Config__c = stage2.Id;
        stage2_StageMovement2_Rule.Logical_Condition__c = '1';
        stage2_StageMovement2_Rule.Order__c = 1;
        stage2_StageMovement2_Rule.Type__c = 'Approval';
            
        insert stage2_StageMovement2_Rule;
    
        ASF_Case_Rule__c stage2_Work_Rule = new ASF_Case_Rule__c();
    
        stage2_Work_Rule.Case_Stage_Config__c = stage2.Id;
        stage2_Work_Rule.Logical_Condition__c = '1';
        stage2_Work_Rule.Order__c = 1;
        stage2_Work_Rule.Type__c = 'Work';
    
        // caseRuleList.add(stage2_Work_Rule);
        insert stage2_Work_Rule;
    
        ASF_Case_Rule__c stage2_Assignment_Rule = new ASF_Case_Rule__c();
        stage2_Assignment_Rule.Case_Stage_Config__c = stage3.Id;
        stage2_Assignment_Rule.Logical_Condition__c = '1';
        stage2_Assignment_Rule.Order__c = 1;
        stage2_Assignment_Rule.Type__c = 'Assignment';
        stage2_Assignment_Rule.Assign_to_Initiator__c = true;
        insert stage2_Assignment_Rule;
        
        ASF_Case_Rule__c stage2_checklist_Rule = new ASF_Case_Rule__c();
        stage2_checklist_Rule.Case_Stage_Config__c = stage2.Id;
        stage2_checklist_Rule.Logical_Condition__c = '1';
        stage2_checklist_Rule.Order__c = 1;
        stage2_checklist_Rule.Type__c = 'Checklists';
        insert stage2_checklist_Rule; 
            
        ASF_Case_Rule__c stage3_StageMovement_Rule = new ASF_Case_Rule__c();
    
        stage3_StageMovement_Rule.Case_Stage_Config__c = stage3.Id;
        stage3_StageMovement_Rule.Logical_Condition__c = '1';
        stage3_StageMovement_Rule.Order__c = 1;
        stage3_StageMovement_Rule.Type__c = 'Stage Movement';
    
        // caseRuleList.add(stage3_StageMovement_Rule);
    
        insert stage3_StageMovement_Rule;
    
        ASF_Case_Rule__c stage2_Validation_Rule = new ASF_Case_Rule__c();
    
        stage2_Validation_Rule.Case_Stage_Config__c = stage2.Id;
        stage2_Validation_Rule.Logical_Condition__c = '1';
        stage2_Validation_Rule.Order__c = 1;
        stage2_Validation_Rule.Type__c = 'Validation';
        stage2_Validation_Rule.Validation_Message__c = 'Stage entry rule not meeting';
        insert stage2_Validation_Rule;
       
    
        ASF_Case_Rule__c stage4_StageMovement_Rule = new ASF_Case_Rule__c();
    
        stage4_StageMovement_Rule.Case_Stage_Config__c = stage4.Id;
        stage4_StageMovement_Rule.Logical_Condition__c = '1';
        stage4_StageMovement_Rule.Order__c = 1;
        stage4_StageMovement_Rule.Type__c = 'Stage Movement';
    
        // caseRuleList.add(stage4_StageMovement_Rule);
    
        // insert caseRuleList;
        insert stage4_StageMovement_Rule;
        
        ASF_Case_Rule_Entry__c stage2_Approval11_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval11_RuleEntry.Number__c = 1;
        stage2_Approval11_RuleEntry.Case_Rule__c = stage2_StageMovement2_Rule.Id;
        stage2_Approval11_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_Approval11_RuleEntry.Operator__c = '=';
        stage2_Approval11_RuleEntry.Data_Type__c = 'STRING';
        stage2_Approval11_RuleEntry.Value__c = 'Pending with Initiator';
        stage2_Approval11_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-3129';
        caseRuleEntryList.add(stage2_Approval11_RuleEntry);
    
    
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry.Number__c = 1;
        stage2_Work_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Work_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_Work_RuleEntry.Operator__c = '=';
        stage2_Work_RuleEntry.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry.Value__c = 'Pending with Initiator';
        stage2_Work_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-0029';
    
        caseRuleEntryList.add(stage2_Work_RuleEntry);
            
        ASF_Case_Rule_Entry__c stage2_Validation_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Validation_RuleEntry.Number__c = 1;
        stage2_Validation_RuleEntry.Case_Rule__c = stage2_Validation_Rule.Id;
        stage2_Validation_RuleEntry.Field_Api_Name__c = 'CSAT__c';
        stage2_Validation_RuleEntry.Operator__c = '<';
        stage2_Validation_RuleEntry.Data_Type__c = 'DECIMAL';
        stage2_Validation_RuleEntry.Value__c = '100';
        stage2_Validation_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-9029';
        caseRuleEntryList.add(stage2_Validation_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_approval2_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_approval2_RuleEntry.Number__c = 2;
        stage2_approval2_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_approval2_RuleEntry.Field_Api_Name__c = 'PAY_Payment_Detail__r.Payment_mode__c';
        stage2_approval2_RuleEntry.Operator__c = '!=';
        stage2_approval2_RuleEntry.Data_Type__c = 'STRING';
        stage2_approval2_RuleEntry.Value__c = 'FALSE';
        stage2_approval2_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-9139';
        caseRuleEntryList.add(stage2_approval2_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_Approval3_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval3_RuleEntry.Number__c = 3;
        stage2_Approval3_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Approval3_RuleEntry.Field_Api_Name__c = 'SLA_Target_1__c';
        stage2_Approval3_RuleEntry.Operator__c = 'contains';
        stage2_Approval3_RuleEntry.Data_Type__c = 'STRING';
        stage2_Approval3_RuleEntry.Value__c = 'Test';
        stage2_Approval3_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-1029';
        caseRuleEntryList.add(stage2_Approval3_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_Approval4_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval4_RuleEntry.Number__c = 4;
        stage2_Approval4_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Approval4_RuleEntry.Field_Api_Name__c = 'CSAT__c';
        stage2_Approval4_RuleEntry.Operator__c = '!=';
        stage2_Approval4_RuleEntry.Data_Type__c = 'DECIMAL';
        stage2_Approval4_RuleEntry.Value__c = '1';
        stage2_Approval4_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-1129';
        caseRuleEntryList.add(stage2_Approval4_RuleEntry);
            
        ASF_Case_Rule_Entry__c stage2_Approval5_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval5_RuleEntry.Number__c = 5;
        stage2_Approval5_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Approval5_RuleEntry.Field_Api_Name__c = 'DB_Hours__c';
        stage2_Approval5_RuleEntry.Operator__c = '=';
        stage2_Approval5_RuleEntry.Data_Type__c = 'DECIMAL';
        stage2_Approval5_RuleEntry.Value__c = '5';
        stage2_Approval5_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-2179';
        caseRuleEntryList.add(stage2_Approval5_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_Approval6_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval6_RuleEntry.Number__c = 6;
        stage2_Approval6_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Approval6_RuleEntry.Field_Api_Name__c = 'has_CheckLists__c';
        stage2_Approval6_RuleEntry.Operator__c = '=';
        stage2_Approval6_RuleEntry.Data_Type__c = 'BOOLEAN';
        stage2_Approval6_RuleEntry.Value__c = 'TRUE';
        stage2_Approval6_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-2170';
        caseRuleEntryList.add(stage2_Approval6_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_Approval7_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Approval7_RuleEntry.Number__c = 7;
        stage2_Approval7_RuleEntry.Case_Rule__c = stage2_StageMovement_Rule.Id;
        stage2_Approval7_RuleEntry.Field_Api_Name__c = 'Has_Open_Tasks__c';
        stage2_Approval7_RuleEntry.Operator__c = '!=';
        stage2_Approval7_RuleEntry.Data_Type__c = 'BOOLEAN';
        stage2_Approval7_RuleEntry.Value__c = 'TRUE';
        stage2_Approval7_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-2111';
        caseRuleEntryList.add(stage2_Approval7_RuleEntry);
              
        ASF_Case_Rule_Entry__c stage2_checklist_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_checklist_RuleEntry.Number__c = 1;
        stage2_checklist_RuleEntry.Case_Rule__c = stage2_checklist_Rule.Id;
        stage2_checklist_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_checklist_RuleEntry.Operator__c = '=';
        stage2_checklist_RuleEntry.Data_Type__c = 'STRING';
        stage2_checklist_RuleEntry.Value__c = 'Pending with Initiator';
        stage2_checklist_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-0021';
        caseRuleEntryList.add(stage2_checklist_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_work1_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_work1_RuleEntry.Number__c = 1;
        stage2_work1_RuleEntry.Case_Rule__c = stage2_Work_Rule.Id;
        stage2_work1_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_work1_RuleEntry.Operator__c = 'in';
        stage2_work1_RuleEntry.Data_Type__c = 'STRING';
        stage2_work1_RuleEntry.Value__c = 'Pending with Initiator';
        stage2_work1_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-0131';
        caseRuleEntryList.add(stage2_work1_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_assignment_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_assignment_RuleEntry.Number__c = 1;
        stage2_assignment_RuleEntry.Case_Rule__c = stage2_Assignment_Rule.Id;
        stage2_assignment_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_assignment_RuleEntry.Operator__c = '=';
        stage2_assignment_RuleEntry.Data_Type__c = 'STRING';
        stage2_assignment_RuleEntry.Value__c = 'Pending with Initiator';
        stage2_assignment_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-7041';
        caseRuleEntryList.add(stage2_assignment_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage1_assignment_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage1_assignment_RuleEntry.Number__c = 1;
        stage1_assignment_RuleEntry.Case_Rule__c = stage1_Assignment_Rule.Id;
        stage1_assignment_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage1_assignment_RuleEntry.Operator__c = '=';
        stage1_assignment_RuleEntry.Data_Type__c = 'STRING';
        stage1_assignment_RuleEntry.Value__c = 'Pending with Initiator';
        stage1_assignment_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-7061';
        caseRuleEntryList.add(stage1_assignment_RuleEntry);
            
        // ASF_Case_Rule_Entry__c stage2_movement_RuleEntry = new ASF_Case_Rule_Entry__c();
        // stage2_movement_RuleEntry.Number__c = 1;
        // stage2_movement_RuleEntry.Case_Rule__c = stage1_StageMovement_Rule.Id;
        // stage2_movement_RuleEntry.Field_Api_Name__c = 'Stage__c';
        // stage2_movement_RuleEntry.Operator__c = '=';
        // stage2_movement_RuleEntry.Data_Type__c = 'STRING';
        // stage2_movement_RuleEntry.Value__c = 'Pending with Initiator';
        // stage2_movement_RuleEntry.External_ID__c = 'CRE-Work-CIBIL-OD-8051';
        // caseRuleEntryList.add(stage2_movement_RuleEntry);
           
    
        insert caseRuleEntryList;
    
    
        ASF_Work_Item__c stage2_Work_WorkItem = new ASF_Work_Item__c();
        //Assigned_Queue__c = '00GHE0000003Qm42AE'
        stage2_Work_WorkItem.Task_Title__c = 'Service Request - Clarification from Credit';
        stage2_Work_WorkItem.Task_Description__c = 'Check the accuracy of the Credit report submitted to bureau for Ownership Dispute';
        stage2_Work_WorkItem.Completion_Time__c = 4;
        stage2_Work_WorkItem.Case_Rule__c= stage2_Work_Rule.Id;
        stage2_Work_WorkItem.Work_Item_External_ID__c='Workitem-CIBIL-OD-0011';
    
        workItemsList.add(stage2_Work_WorkItem);
    
        insert workItemsList;
    
        ASF_Case_Checklist_Master__c checklistRecord = new ASF_Case_Checklist_Master__c();
        checklistRecord.Case_Rule__c = stage2_checklist_Rule.Id;
        checklistRecord.name = 'Test checklist';
        checklistRecord.Mandatory__c = true;
        checklistRecord.Description__c = 'test from test class';
        checklistRecord.Type__c = '	Manual';
        
        insert checklistRecord;
    
    
    }
    
    public static Lead createServiceProspectRecord(){
        Lead ld = new Lead();
        ld.FirstName = 'Prospect 1';
        ld.LastName = 'Prospect 2';
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        ld.Company = 'Salesforce';
        ld.Email = 'invalid.invalid@invalid.com.net';
        //ld.MobilePhone = '98INVALIDNUM';
        ld.MobilePhone = '1234567890';
        return ld;
    }
    public static Lead createSalesProspectRecord(){
        Lead ld = new Lead();
        ld.FirstName = 'Prospect 1';
        ld.LastName = 'Prospect 2';
        ld.Sales_Prospect__c = true;
        ld.Company = 'Salesforce';
        ld.Email = 'invalid.invalid@invalid.com.net';
        //ld.MobilePhone = '98INVALIDNUM';
        ld.MobilePhone = '1234567890';
        return ld;
    }
    
    public static Opportunity createOpportunityRecords(Id accId,Id assetId){
        
       Opportunity oppRec = new Opportunity();
       oppRec.Name = 'Testabc' ;
       oppRec.AccountId = accId;
       oppRec.Policy__c = assetId;
       oppRec.CloseDate = Date.today();
       oppRec.StageName = 'In Progress';
       oppRec.Policy_Number__c = '12456';
       oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();
        
       insert oppRec;
       return oppRec;
    }
    
    public static Opportunity createOpportunityRecords(String strName, Id accId){
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name =  strName;
        oppRec.AccountId = accId; 
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = String.valueOf(Math.random() * 100);
		oppRec.Schedule_Request_Response__c =  '';         
		oppRec.Cancel_Call_Response__c =  '';   
        oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();
        
        insert oppRec;
        return oppRec;
    }


}