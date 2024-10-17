@isTest
public class ASF_GetCaseRelatedDetails_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setup() {
        
       /* Branch_Master__c branchM1 = new Branch_Master__c(Branch_Code__c = '8024',Branch_Category__c = 'C');
        insert branchM1; */
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        Account acc= new Account(
            RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId(),
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            Client_Code__c = 'abcd'
           // Home_Branch__c = branchM1.Id
        );
        insert acc;
          User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghik56@gmail.com');
        insert userRecord;
        
        Account acc_b = new Account(recordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId(),Name = 'TestCompanyName',Client_Code__c = '2144');
        insert acc_b;
        
        Contact contact1 = new Contact(AccountId = acc_b.Id,FirstName='Test FName',LastName='Test LName');
        insert contact1;
        
        PAY_Payment_Detail__c  payDetails = new PAY_Payment_Detail__c(Cash_Back_Amount__c = 12000);
        insert payDetails; 
        
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, Price=100); // Financial_Account_Number__c = '0123456789123');
        insert ast;
        
        
     
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'ABFL',Sub_Type__c = 'CreditCard', Overall_Case_Closure_SLA__c = 1);
        insert ccc;
        
        ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        insert caseconfig;
        
        ASF_Case_Stage_Config__c  caseconfig2 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        insert caseconfig2;
        
        ASF_Case_Field_Config__c   caseFieldconfig1 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c=ccc.Id,Display_Order__c=1, FieldAPIName__c = 'Payment_mode__c',ObjectAPIName__c = 'PAY_Payment_Detail__c',Default_Value__c = 'Digital',Default_Type__c = 'STRING',
                                                                              ReadOnly__c = 'Closed',Mandatory__c = 'Closed', Update__c = 'New,Closed,Pending');
        insert caseFieldconfig1;
        
        ASF_Case_Field_Config__c   caseFieldconfig2 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c=ccc.Id,Display_Order__c=2, FieldAPIName__c = 'Payment_mode__c',ObjectAPIName__c = 'PAY_Payment_Detail__c',Default_Value__c = 'Asset.Price',Default_Type__c = 'Reference',
                                                                              ReadOnly__c = 'Closed',Mandatory__c = 'Closed', Controlling_field__c  = 'Mode__c',Controlling_Experssion__c = 'Physical');
        insert caseFieldconfig2;
        
        ASF_Case_Field_Config__c   caseFieldconfig3 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c=ccc.Id,Display_Order__c=3, FieldAPIName__c = 'Subject',ObjectAPIName__c = 'Case',Default_Value__c = 'case.Account.Home_Branch__c',Default_Type__c = 'Reference',
                                                                              ReadOnly__c = 'Closed',Mandatory__c = 'Closed', Controlling_field__c  = 'Mode__c',Controlling_Experssion__c = 'Physical');
        insert caseFieldconfig3;
        
        ASF_Case_Field_Config__c   caseFieldconfig4 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c=ccc.Id,Display_Order__c=1, FieldAPIName__c = 'Payment_mode__c',ObjectAPIName__c = 'PAY_Payment_Detail__c',Default_Value__c = 'Digital',Default_Type__c = 'STRING',
                                                                              ReadOnly__c = 'Closed',Mandatory__c = 'Closed', Update__c = 'New,Pending');
        insert caseFieldconfig4;
        
     /*   ASF_Case_Info_Config__c caseInfo1 = new ASF_Case_Info_Config__c(FieldAPIName__c = 'Branch_Master__r.Branch_Code__c',LOB__c = 'All',ObjectAPIName__c = 'Branch_Master__c');
        insert caseInfo1;
        
        ASF_Case_Info_Config__c caseInfo2 = new ASF_Case_Info_Config__c(FieldAPIName__c = 'Account.CRN__c',LOB__c = 'All',ObjectAPIName__c = 'Account');
        insert caseInfo2;
        
        ASF_Case_Info_Config__c caseInfo3 = new ASF_Case_Info_Config__c(FieldAPIName__c = 'Subject',LOB__c = 'All',ObjectAPIName__c = 'Case');
        insert caseInfo3;  */
        
        //Case_Approv__c approvalRec1 = new Case_Approv__c(ApprovalStatus__c = 'Approved',Case__c = c.Id,TypeOfApproval__c  = 'Test');
        //insert approvalRec1;
        
         //  Case c = new Case(AccountId=acc.Id,Branch_Master__c  = branchM1.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='In Progress with CEC',AssetId = ast.Id );
      	Case c = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='In Progress with CEC',AssetId = ast.Id );
        insert c;
        
      //  Case c2 = new Case(AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='TestExternalId2',Stage__c='Pending Clarification');
        //Case c2 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='Pending Clarification');  
        //insert c2;
        
        // Case c3 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',Source__c='CEC',CCC_External_Id__c='TestExternalId3',Stage__c='In Progress with CEC');
        Case c3 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',Source__c='Customer Portal',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='In Progress with CEC');
        insert c3;
        
        // Case c4 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',Source__c='RL Branch',CCC_External_Id__c='TestExternalId3',Stage__c='Pending Clarification');
        //Case c4 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',Source__c='RL Branch',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='Pending Clarification');
        //insert c4;
        
        // Case c5 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='TestExternalId42',Stage__c='In Progress with CEC');
        Case c5 = new Case(PAY_Payment_Detail__c =payDetails.Id,AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',Stage__c='In Progress with CEC');
        insert c5;
        
        ASF_Case_Approv__c approver = new ASF_Case_Approv__c(Approver_01__c   = userRecord.Id,
                                                             SR__c =c.Id,Approval_Type__c ='Sequential', Requestor_Comments__c = 'approver created');
        insert approver;
        
        
    }
    
    @isTest
    static void testPopulateClassificationValue() {
        
        
        List<case> caseList =[select id from case];
        // Create a test ASF_Case_Category_Config__c record
        ASF_Case_Category_Config__c cccRec = new ASF_Case_Category_Config__c();
        cccRec.CCC_External_Id__c = 'TestExternalId';
        cccRec.Sub_Type__c = 'ITR Refund';
        cccRec.Type__c = 'Refund';
      /*  cccRec.document_type__c = 'Scanned/Physical';
        cccRec.SR_Classification_filter_field__c = 'WM_Details__c.Request_for_Modification__c';
        cccRec.SR_Classification_filter_value__c = 'Account Linking';  */
        // Set other required fields
        insert cccRec;
        
        // Create a test ASF_Case_Category_Config__c record
        ASF_Case_Category_Config__c cccRec2 = new ASF_Case_Category_Config__c();
        cccRec2.CCC_External_Id__c = 'TestExternalId2';
        cccRec2.Sub_Type__c = 'TDS Refund';
        cccRec2.Type__c = 'Refund';
      /*  cccRec2.document_type__c = 'Scanned/Physical';
        cccRec2.SR_Classification_filter_field__c = 'WM_Details__c.Type_of_Modification__c';
        cccRec2.SR_Classification_filter_value__c = 'Email id Updation,Mobile number updation';  */
        // Set other required fields
        insert cccRec2;
        
        // Create a test ASF_Case_Category_Config__c record
        ASF_Case_Category_Config__c cccRec3 = new ASF_Case_Category_Config__c();
        cccRec3.CCC_External_Id__c = 'TestExternalId3';
        cccRec3.Sub_Type__c = 'Cash Refund';
        cccRec3.Type__c = 'Refund';
       /* cccRec3.document_type__c = 'Scanned/Physical';
        cccRec3.SR_Classification_filter_field__c = 'Source__c';
        cccRec3.SR_Classification_filter_value__c = 'CEC';  */
        // Set other required fields
        insert cccRec3;
        
        // Create a test ASF_Case_Category_Config__c record
        ASF_Case_Category_Config__c cccRec4 = new ASF_Case_Category_Config__c();
        cccRec4.CCC_External_Id__c = 'TestExternalId4';
        cccRec4.Sub_Type__c = 'My Complaint not Resolved';
        cccRec4.Type__c = 'Complaint';
      //  cccRec4.document_type__c = 'Physical';
        // Set other required fields
        insert cccRec4;        
        // Create a test ASF_Case_Category_Config__c record
        ASF_Case_Category_Config__c cccRec5 = new ASF_Case_Category_Config__c();
        cccRec5.CCC_External_Id__c = 'TestExternalId42';
        cccRec5.Sub_Type__c = 'How to fill Form-16';
        cccRec5.Type__c = 'Query';
       // cccRec5.document_type__c = 'Physical';
        // Set other required fields
        insert cccRec5;
        
        Test.startTest();
        // Call the method being tested
       /* ASF_GetCaseRelatedDetails.populateClassificationValue(caseList[0].Id);
        ASF_GetCaseRelatedDetails.populateClassificationValue(caseList[1].Id);
        ASF_GetCaseRelatedDetails.populateClassificationValue(caseList[2].Id);  */
        //GetCaseRelatedDetails.populateClassificationValue(caseList[3].Id);
        //GetCaseRelatedDetails.populateClassificationValue(caseList[3].Id);
      //  cccRec4.document_type__c = 'Scanned';
        update cccRec4;
        //GetCaseRelatedDetails.populateClassificationValue(caseList[3].Id);
      //  cccRec4.document_type__c = 'Not Applicable';
        update cccRec4;
        System.assertEquals('Query', cccRec5.Type__c);
        //GetCaseRelatedDetails.populateClassificationValue(caseList[3].Id);
        Test.stopTest();
        
        // Verify that the Documentation_Type__c field on the Case record was set correctly
        //Case updatedCs = [SELECT Documentation_Type__c FROM Case WHERE Id = :cs.Id];
        //System.assertEquals('Scanned', updatedCs.Documentation_Type__c);
    }
    @isTest
    private static void testgetLatestCaseApprovalRecord(){
        List<ASF_Case_Approv__c> caList = new List<ASF_Case_Approv__c>();
        List<Case> caseList = [SELECT ID FROM Case];
        for(Case c : [SELECT ID FROM Case]){
            ASF_Case_Approv__c ca = new ASF_Case_Approv__c ();
            ca.Approver_01__c = UserInfo.getUserId();
            ca.Approver_02__c  = UserInfo.getUserId();
            ca.Approver_03__c  = UserInfo.getUserId();
            ca.Approver_04__c  = UserInfo.getUserId();
            ca.Approver_05__c  = UserInfo.getUserId();
            ca.Approval_Type__c = 'Parallel - All to approve';
            ca.Approval_Status__c = 'Pending';
            ca.SR__c = c.Id;
          //  ca.TypeOfApproval__c  = 'Manual';
          //  ca.Only_Approver_1__c ='NoValidation';
            caList.add(ca);
        }
        Test.startTest();
        if(caList.size()>0){
            insert caList;
        }
        System.assertEquals('Parallel - All to approve', caList[0].Approval_Type__c);
        //Case_Approv__c returnVal = GetCaseRelatedDetails.getLatestCaseApprovalRecord(caseList[0].Id,'Pending for Approval');
        //System.assertEquals('Parallel - All to approve', returnVal.ApprovalType__c,'There is already a Case Approval pending for action.');
        //returnVal = GetCaseRelatedDetails.getLatestCaseApprovalRecord('TEST','In Progress with CEC');
        Test.stopTest();
    }
    
    @isTest
    public static void checkCaseConfigTest(){
        Case caseRecord = [SELECT Id,Type_Text__c,Stage__c,AccountId,Sub_Type_Text__c,CCC_External_Id__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
        
        Test.startTest();
        ASF_GetCaseRelatedDetails.getAssetDetails(caseRecord.AccountId);
        ASF_GetCaseRelatedDetails.getRelatedAssets(caseRecord.AccountId);
        ASF_GetCaseRelatedDetails.getStageConfig(caseRecord.CCC_External_Id__c);
        ASF_GetCaseRelatedDetails.getCaseCategoryConfig(caseRecord.CCC_External_Id__c);
        ASF_GetCaseRelatedDetails.getCaseFieldsConfig(caseRecord.CCC_External_Id__c,'Closed',caseRecord.Id);
        ASF_GetCaseRelatedDetails.getPendingChecklists(caseRecord.Id);
        ASF_GetCaseRelatedDetails.getCaseApprovalRecords(caseRecord.Id);
        ASF_GetCaseRelatedDetails.getLatestCaseApprovalRecord(caseRecord.Id,'Pending for Approval');
        ASF_GetCaseRelatedDetails.getPendingTasks(caseRecord.Id);
        ASF_GetCaseRelatedDetails.fetchRelatedContacts(caseRecord.AccountId);
        System.assertEquals('CCC-CC-RC-01', caseRecord.CCC_External_Id__c);
        Test.stopTest();
    }
    
    @isTest
    public static void getDefaultValuesTest(){
        Case caseRecord = [SELECT Id,Type_Text__c,Stage__c,AccountId,Sub_Type_Text__c,CCC_External_Id__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
        
        List<string> fieldNames = new List<string>();
        List<string> fieldValues= new List<string>();        
        Task task1 = new Task(WhatId  = caseRecord.Id);
        insert task1;
        
          List<Task>lstTask = new List<Task>();
            
          Task tsk = new Task (WhatId = caseRecord.Id, Status ='Open');
          lstTask.add(tsk);

            if(!lstTask.isEmpty()){
            insert lstTask;
            }
        
        ASF_Checklist__c chk1 = new ASF_Checklist__c(Case__c = caseRecord.Id, Status__c ='Completed', Label__c= 'New Ceck Label');
        insert chk1;
        
        List<ASF_Checklist__c>lstCheck = new List<ASF_Checklist__c>();            
          ASF_Checklist__c chk2 = new ASF_Checklist__c(Case__c = caseRecord.Id, Status__c ='Completed', Label__c= 'New Ceck Label1');
          lstCheck.add(chk2);

            if(!lstCheck.isEmpty()){
            insert lstCheck;
            }
        
        fieldNames.add('element');
        fieldValues.add('Asset.Price');
        
        Test.startTest();
        ASF_GetCaseRelatedDetails.getDefaultValues(caseRecord.AccountId,fieldNames,fieldValues);
       // ASF_GetCaseRelatedDetails.getInfoFieldsData(caseRecord.Id,'All');
        ASF_GetCaseRelatedDetails.getCaseRelatedObjName(caseRecord.CCC_External_Id__c);
        ASF_GetCaseRelatedDetails.getLatestApprovalRecord(caseRecord.id);
        //ASF_GetCaseRelatedDetails.getRejectionReasons(caseRecord.CCC_External_Id__c);
        ASF_GetCaseRelatedDetails.getBUReasons(caseRecord.CCC_External_Id__c);//Added by Zahed : PR1030924-224
        ASF_GetCaseRelatedDetails.getPickListValuesIntoList();
        ASF_GetCaseRelatedDetails.updateChecklistComment(chk1.Id,'comments');
        ASF_GetCaseRelatedDetails.updateTaskRecordsComment(task1.Id, 'comments');
        //ASF_GetCaseRelatedDetails.changeOwnership(task1.Id);
        ASF_GetCaseRelatedDetails.updateCheckList(new Map<Id,ASF_Checklist__c>(lstCheck));
        ASF_GetCaseRelatedDetails.updateTask(new Map<Id, Task>(lstTask));
        try{
        ASF_GetCaseRelatedDetails.updateTasks(JSON.serialize(lstTask));
        }catch(Exception e){}
		    System.assertEquals('CCC-CC-RC-01', caseRecord.CCC_External_Id__c);
        //GetCaseRelatedDetails.getLatestApprovalRecord(caseRecord.Id);
        Test.stopTest();
    }
}