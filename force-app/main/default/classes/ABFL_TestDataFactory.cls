/*********************************************************
** Class        :  ABFL_TestDataFactory
** Author       :  Aditee Churiwala
** Description  :  Data Factory for Test Class
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
    * @Description - Create Case Configs 
    * return - Map of Case Configs       
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
        
        listCaseCatConfig.add(caseCatConfig);
        
        if(isCreate) {
            insert listCaseCatConfig;
        }
        return listCaseCatConfig;
    }    
     
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
        stage3.Status_Mapping__c = 'Closed';
        stage3.Query_Fields__c = 'Id,Stage__c';
        stageConfigList.add(stage3);

         if(isCreate) {
            insert stageConfigList; 
         }
         return stageConfigList;
     }  
    /****************************************************
    * @Description - Create ASF Integration 
    * return - List<ASF_Integration__c>
    *****************************************************/
    public static List<ASF_Integration__c> createIntegration(Id stageConfigId, Boolean isCreate,
                                                             String processingClass, String stpAPIIdentifier) {
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

        intConfigList.add(prePopInt1);
        if(isCreate) {
            insert intConfigList;
        }
        return intConfigList;
    }    
    
    /****************************************************
    * @Description - Create Case Detail
    * return - List<ABFL_Case_Detail__c>
    *****************************************************/
    public static List<ABFL_Case_Detail__c> createCaseDetail(String Lob, Boolean isCreate) {
        List<ABFL_Case_Detail__c> caseDetailList = new List<ABFL_Case_Detail__c>();
        ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c(ISREKYC__c= true,
                                                                 //CallbackDate__c= 'CallbackDate',
                                                                 //CallBackTimeSlot__c= 'CallBackTimeSlot',
                                                                 //LOB__c= Lob,//'Corporate',
                                                                 Resolution_Comments__c= 'COMMENTS',
                                                                 URL__c= 'URL',
                                                                 MHNUMBER__c= 'MHNUMBER',
                                                                 PRIORITY__c= 'PRIORITY',
                                                                 SEGMENT__c= 'SEGMENT',
                                                                 REKYCURL__c= 'REKYCURL',
                                                                 KYCCOMPLIED__c= false,
                                                                 IsRegisteredCustomer__c=true,
                                                                 SUBSOURCE__c= 'SUBSOURCE',
                                                                 From_Date__c = Date.Today(),
                                                                 To_Date__c = Date.Today()+1
                                                                );
        caseDetailList.add(caseDetail);
        if(isCreate) {
            insert caseDetailList;
        }
        return caseDetailList;
    }
    /****************************************************
     * @Description - Create Account 
     * @return - List of Account       
    *****************************************************/
    public Static Account createAccount() {
        Account a = new Account();
        a.Name = '12345';
        //a.CRN__c = '12344';
        insert a;
        
        return a;
    }    
    
    /****************************************************
     * @Description - Create Account 
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
     * @Description - Create Case 
     * @return - List of Case       
    *****************************************************/
    public static List<Case> createCaseRecords(Integer noOfCase, Id caseDetailId, Boolean isCreate) {

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<noOfCase;i++){
            
            Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test'+i+'@salesforce.com' );
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
            newCase.pending_clarification__c = true;
            newCase.OwnerId = UserInfo.getUserId();
            caseList.add(newCase);
        
        }
        if(isCreate) {
            insert caseList;
        }

        return caseList;
    }
}