/*********************************************************
** Class        :  ABFL_TestDataFactory
** Author       :  Aditee Churiwala
** @description  :  Data Factory for Test Class
** Created Date :  Dec 18, 2023
** Modified By  :  
** Modified Date :  
*********************************************************/
@SuppressWarnings(
    'PMD.ExcessiveParameterList'
)
@isTest
public class ABFL_TestDataFactory {
    /****************************************************
    * @description - Create Case Configs
    * @param isCreate
    * @return - List<ASF_Case_Category_Config__c>      
    *****************************************************/
    public static List<ASF_Case_Category_Config__c> createCaseCategoryConfig(Boolean isCreate) {
        List<ASF_Case_Category_Config__c> listCaseCatConfig = new List<ASF_Case_Category_Config__c>();
        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

        caseCatConfig.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseCatConfig.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig.First_Stage__c = 'Open';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Source__c = 'CEC';
        caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
        caseCatConfig.Litmus_Trigger__c = true;
        
        listCaseCatConfig.add(caseCatConfig);
        
        if(isCreate) {
            insert listCaseCatConfig;
        }
        return listCaseCatConfig;
    }    
     
    /****************************************************
    * @description - Create Case stage Configs
    * @param caseCatConfigId
    * @param isCreate
    * @return - List<ASF_Case_Category_Config__c>      
    *****************************************************/
     public static List<ASF_Case_Stage_Config__c> createCaseStageConfig(Id caseCatConfigId, Boolean isCreate) {
        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
    
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = caseCatConfigId;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'Open';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.Gateway_Stage__c = true;
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;

        stageConfigList.add(stage1);
        
        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
        stage2.Case_Category_Config__c = caseCatConfigId;
        stage2.Order__c = 2;
        stage2.Stage_SLA_1__c = 1;
        stage2.Stage_SLA_2__c = 2;
        stage2.Stage_SLA_3__c = 3;
        stage2.Gateway_Stage__c = true;
        stage2.SLA_Target_1_Type__c = 'Manager';
        stage2.SLA_Target_2_Type__c = 'Manager';
        stage2.SLA_Target_3_Type__c = 'Manager';
        stage2.StageName__c  = 'Manual Fulfilment';
        stage2.Status_Mapping__c = 'Manual Fulfilment';
        stage2.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage2);


        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
        stage3.Case_Category_Config__c = caseCatConfigId;
        stage3.Order__c = 3;
        stage3.Stage_SLA_1__c = 1;
        stage3.Stage_SLA_2__c = 2;
        stage3.Stage_SLA_3__c = 3;
        stage3.SLA_Target_1_Type__c = 'Manager';
        stage3.SLA_Target_2_Type__c = 'Manager';
        stage3.SLA_Target_3_Type__c = 'Manager';
        stage3.StageName__c  = 'Resolved';
        stage3.Gateway_Stage__c = true;
        stage3.Status_Mapping__c = 'Resolved';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);

         if(isCreate) {
            insert stageConfigList; 
         }
         return stageConfigList;
     }
    
     /****************************************************
     * @description - Create Case rule entries
     * @param stageConfigList 
     *****************************************************/
     public static void createCaseRuleEntry(List<ASF_Case_Stage_Config__c> stageConfigList) {
         List<ASF_Case_Rule__c> listCaseRule = new List<ASF_Case_Rule__c>();
         List<ASF_Case_Rule_Entry__c> cres = new List<ASF_Case_Rule_Entry__c>();
         ASF_Case_Rule_Entry__c stage1MovementRuleEntry = null;
         ASF_Case_Rule__c stage1StageMovementRule = null;
         for(ASF_Case_Stage_Config__c config : stageConfigList) {
            stage1StageMovementRule = new ASF_Case_Rule__c();
             
             stage1StageMovementRule.Case_Stage_Config__c = config.Id;
             //stage1StageMovementRule.Logical_Condition__c = '1';
             stage1StageMovementRule.Order__c = 1;
             stage1StageMovementRule.Type__c = 'Stage Movement';
             
             listCaseRule.add(stage1StageMovementRule);
         }    
            // caseRuleList.add(stage1StageMovementRule);
         insert listCaseRule;
         Integer i = 0;
         for(ASF_Case_Rule__c caseRule : listCaseRule) {
             stage1MovementRuleEntry = new ASF_Case_Rule_Entry__c();
             //create case rule entry
             stage1MovementRuleEntry.Number__c = 1;
             stage1MovementRuleEntry.Case_Rule__c = caseRule.Id;
             stage1MovementRuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
             stage1MovementRuleEntry.Operator__c = '=';
             stage1MovementRuleEntry.Data_Type__c = 'STRING';
             stage1MovementRuleEntry.Value__c = '12345';
             stage1MovementRuleEntry.External_ID__c = 'CRE-STAGEMV-OD-01'+i;
             i++;
             cres.add(stage1MovementRuleEntry);
         } 
         insert cres;  
     }
     
     /****************************************************
     * @description - Create Case stage Configs
     * @param caseCatConfigId
     * @param isCreate
     * @return - List<ASF_Case_Stage_Config__c>      
     *****************************************************/
     public static List<ASF_Case_Stage_Config__c> createCaseStageConfigWithTwoStages(Id caseCatConfigId, Boolean isCreate) {
        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
    
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = caseCatConfigId;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'Open';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.Gateway_Stage__c = true;
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;

        stageConfigList.add(stage1);

        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
        stage3.Case_Category_Config__c = caseCatConfigId;
        stage3.Order__c = 2;
        stage3.Stage_SLA_1__c = 1;
        stage3.Stage_SLA_2__c = 2;
        stage3.Stage_SLA_3__c = 3;
        stage3.SLA_Target_1_Type__c = 'Manager';
        stage3.SLA_Target_2_Type__c = 'Manager';
        stage3.SLA_Target_3_Type__c = 'Manager';
        stage3.StageName__c  = 'Resolved';
        stage3.Gateway_Stage__c = true;
        stage3.Status_Mapping__c = 'Resolved';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);

         if(isCreate) {
            insert stageConfigList; 
         }
         return stageConfigList;
     }  
    /****************************************************
    * @description - Create ASF Integration
    * @param stageConfigId
    * @param isCreate
    * @param processingClass
    * @param stpAPIIdentifier
    * @return - List<ASF_Integration__c>
    *****************************************************/
    public static List<ASF_Integration__c> createIntegration(Id stageConfigId, Boolean isCreate, String processingClass, String stpAPIIdentifier) {
        List<ASF_Integration__c> intConfigList = new List<ASF_Integration__c>();

        ASF_Integration__c prePopInt1 = new ASF_Integration__c();
        prePopInt1.External_Id__c = 'ASF_INT_01';
        prePopInt1.Case_Stage_Config__c = stageConfigId;//stageConfigList[0].Id;
        prePopInt1.Type__c = 'Pre Populate';
        prePopInt1.When_to_Appear__c = 'Stage Entry';
        prePopInt1.Visibility_Class__c = processingClass;//'ABFL_UpdateSTPFlow';
        prePopInt1.Processing_Class__c = processingClass;
        prePopInt1.STP_API_Identifier__c = stpAPIIdentifier;
        prePopInt1.Display_Name__c = 'Fetch Field';
        prePopInt1.Query_Fields__c = 'Id,ABFL_Case_Detail__c,ABFL_Case_Detail__r.Autoclosure_IN_RR__c,ABFL_Case_Detail__r.IsRegisteredCustomer__c,ABFL_Case_Detail__r.Autoclosed__c,ABFL_Case_Detail__r.Closure_Time__c,CCC_External_Id__c,ContactId,No_Auto_Communication__c,ABFL_Case_Detail__r.Document_URL__c,LAN__c,Account.IsPersonAccount,Asset.Loan_Start_Date__c,Account.PersonEmail,Account.Office_Email__c,Account.PersonMobilePhone,Account.Phone,Technical_Source__c,AccountId,AssetId,Source__c,Account.Name,MoveToNext__c,CaseNumber,Business_Unit__c,ContactEmail,ContactMobile,ABFL_Case_Detail__r.From_Date__c,ABFL_Case_Detail__r.To_Date__c,BRE_Source__c,SuppliedEmail,Origin,ABFL_Case_Detail__r.IsSMT__c';                                                         
        prePopInt1.STP_Template__c = 'ABFL_FIRST_TAT_COMMUNICATION_DIGITAL';

        intConfigList.add(prePopInt1);
        if(isCreate) {
            insert intConfigList;
        }
        return intConfigList;
    }    
    
    /****************************************************
    * @description - Create Case Detail
    * @param lob
    * @param isCreate
    * @return - List<ABFL_Case_Detail__c>
    *****************************************************/
    public static List<ABFL_Case_Detail__c> createCaseDetail(String lob, Boolean isCreate) {
        List<ABFL_Case_Detail__c> caseDetailList = new List<ABFL_Case_Detail__c>();
        ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c(ISREKYC__c= true,
                                                                 Resolution_Comments__c= 'COMMENTS',
                                                                 URL__c= 'URL',
                                                                 MHNUMBER__c= 'MHNUMBER',
                                                                 PRIORITY__c= 'PRIORITY',
                                                                 SEGMENT__c= 'SEGMENT',
                                                                 REKYCURL__c= 'REKYCURL',
                                                                 KYCCOMPLIED__c='Some Text',
                                                                 IsRegisteredCustomer__c='Yes',
                                                                 SUBSOURCE__c= 'SUBSOURCE',
                                                                 Frequency__c = 'M',
                                                                 To_Date__c = System.Today()+6,
                                                                 From_Date__c = System.Today()+2,
                                                                 EMI_Amount__c = 5000,
                                                                 New_Bank_Account_No__c = '123356666',
                                                                 Bank_IFSC_Code__c = '12345',
                                                                 Lock_in_Period__c = 'No'
                                                                );
        caseDetailList.add(caseDetail);
        if(isCreate) {
            insert caseDetailList;
        }
        return caseDetailList;
    }
    /****************************************************
     * @description - Create Account 
     * @return - Account    
    *****************************************************/
    public Static Account createAccount() {
        Account a = new Account();
        a.Name = '12345';
        a.Office_Email__c = 'testAcc@123.com';
        a.Phone = '444-010-4444';
        a.PAN__c = 'ADNPN4241N';
        a.Client_Code__c = '1234';
        //a.CRN__c = '12344';
        insert a;
        
        return a;
    }    
    
    /****************************************************
     * @description - Create Account 
     * @param accountId
     * @return - List of Account       
    *****************************************************/
    public Static Contact createContact(Id accountId){
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = accountId;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        con.MobilePhone = '8329673314';
        insert con;
        
        return con;
    }    
    /****************************************************
     * @description - Create Case 
     * @param noOfCase
     * @param caseDetailId
     * @param isCreate
     * @return List<Case>     
    *****************************************************/
    public static List<Case> createCaseRecords(Integer noOfCase, Id caseDetailId, Boolean isCreate) {

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<noOfCase;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
            SLA_Target_1__c = 'test'+i+'@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30, Business_Unit__c = ABFL_Constants.ABFL);
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.Subject = 'CC-TEST-0'+i;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            newCase.LAN__c = 'LAN';
            //newCase.Technical_Source__c = 'API';
            newCase.ABFL_Case_Detail__c = caseDetailId;
            newCase.Source__c =  ABFL_Constants.RM_NO_EMAIL;
            newCase.Stage__c = 'Open';
            newCase.pending_clarification__c = false;
            newCase.OwnerId = UserInfo.getUserId();
            caseList.add(newCase);
        
        }
        if(isCreate) {
            insert caseList;
        }

        return caseList;
    }
}