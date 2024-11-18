@isTest
public class ABSLAMC_BU_CTSTHelper_Test {
    
    @testSetup
    static void setupTestData(){ 
        
        ASF_Case_Category_Config__c cccRec = new ASF_Case_Category_Config__c(Nature__c = 'Request', Type__c='Channel Transaction', Sub_Type__c='Channel FT not processed');
        cccRec.Business_Unit__c = 'ABSLAMC';
        cccRec.CCC_External_Id__c = 'MF029';
        cccRec.First_Stage__c = 'Open';
        cccRec.process__c= 'Case';
        cccRec.Overall_Case_Closure_SLA__c = 39;
        cccRec.Litmus_Trigger__c = true;
        cccRec.Litmus_Project__c = '';
        insert cccRec;
        
        list<ASF_Case_Field_Config__c> casefieldconfiglist = new List<ASF_Case_Field_Config__c>();
        
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Description',	ObjectAPIName__c='Case',	Field_Type__c='TextArea',	ReadOnly__c='Pending with CAMS, Resolved',	Update__c='Open, Reply Received from CAMS',	Mandatory__c='Open',	Display_Order__c=1,	Field_External_Id_c__c='CFC-1-MF029', Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Caller_Type__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='LOV',	ReadOnly__c='Pending with CAMS, Resolved',	Update__c='Open, Reply Received from CAMS',	Mandatory__c='Open',	Display_Order__c=2,	Field_External_Id_c__c='CFC-2-MF029',Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='PHD_Complaint_Source__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='LOV',	ReadOnly__c='Pending with CAMS, Resolved',	Update__c='Open, Reply Received from CAMS',		Display_Order__c=3,	Field_External_Id_c__c='CFC-3-MF029',Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Dialer_Call_Track_ID__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='TextArea',	ReadOnly__c='Pending with CAMS, Resolved',	Update__c='Open, Reply Received from CAMS', 		Display_Order__c=4,	Field_External_Id_c__c='CFC-4-MF029',Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Critical_Request__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='LOV',	ReadOnly__c='Pending with CAMS, Resolved',	Update__c='Open, Reply Received from CAMS',	Mandatory__c='Open',	Display_Order__c=5,	Field_External_Id_c__c='CFC-5-MF029',Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Transaction_Channel_Source__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='LOV',	ReadOnly__c='Pending with CAMS, Reply Received from CAMS, Resolved',	Update__c='Open',	Mandatory__c='Open',	Display_Order__c=6,	Field_External_Id_c__c='CFC-6-MF029',Case_Main_Config__c=cccRec.Id));
        casefieldconfiglist.add(new ASF_Case_Field_Config__c(FieldAPIName__c='Note_For_CAMS__c',	ObjectAPIName__c='ABSLAMC_Case_Detail__c',	Field_Type__c='TextArea',	ReadOnly__c='Pending with CAMS, Reply Received from CAMS, Resolved',	Update__c='Open',	Mandatory__c='Open',	Display_Order__c=7,	Field_External_Id_c__c='CFC-7-MF029',Case_Main_Config__c=cccRec.Id));
        insert casefieldconfiglist;
        
        list<ASF_Case_Stage_Config__c> casestageconfiglist = new List<ASF_Case_Stage_Config__c>();
        
        casestageconfiglist.add(new ASF_Case_Stage_Config__c(STAGENAME__C='Open',	MANAGER_ESCALATION_LEVELS__C=2,	Stage_SLA_1__c=1,	Stage_SLA_2__c=2,	SLA_TARGET_1_TYPE__C='Manager',	SLA_TARGET_2_TYPE__C='Manager',	Order__c=1,	STATUS_MAPPING__C='New',	Query_Fields__c='Stage__c',			Stage_External_Id__c='CSC-1-AIF010', Case_Category_Config__c=cccRec.Id	));
        casestageconfiglist.add(new ASF_Case_Stage_Config__c(STAGENAME__C='Approval',	MANAGER_ESCALATION_LEVELS__C=	2,	Stage_SLA_1__c=36,	Stage_SLA_2__c=40,	SLA_TARGET_1_TYPE__C='Manager',	SLA_TARGET_2_TYPE__C='Manager',	Order__c=2, STATUS_MAPPING__C='In Progress',	Query_Fields__c='Stage__c',		Stage_External_Id__c='CSC-2-AIF011'	, Case_Category_Config__c=cccRec.Id, Mandatory_Approval__c=true,Is_Approval_Stage__c=true,	Manual_Approval__c=true	));
        casestageconfiglist.add(new ASF_Case_Stage_Config__c(STAGENAME__C='Pending with CAMS',	MANAGER_ESCALATION_LEVELS__C=	2,	Stage_SLA_1__c=36,	Stage_SLA_2__c=40,	SLA_TARGET_1_TYPE__C='Manager',	SLA_TARGET_2_TYPE__C='Manager',	Order__c=3, STATUS_MAPPING__C='In Progress',	Query_Fields__c='Stage__c',		Stage_External_Id__c='CSC-3-AIF011'	, Case_Category_Config__c=cccRec.Id	));
        casestageconfiglist.add(new ASF_Case_Stage_Config__c(STAGENAME__C='Reply Received from CAMS',	MANAGER_ESCALATION_LEVELS__C=	2,	Stage_SLA_1__c=	5,	Stage_SLA_2__c=6,	SLA_TARGET_1_TYPE__C='Manager',	SLA_TARGET_2_TYPE__C='Manager',	Order__c=4,	STATUS_MAPPING__C='In Progress',	Query_Fields__c='Stage__c',		Stage_External_Id__c='CSC-4-AIF012'	, Case_Category_Config__c=cccRec.Id	));	
        casestageconfiglist.add(new ASF_Case_Stage_Config__c(STAGENAME__C='Resolved',	Order__c=5,	STATUS_MAPPING__C='Resolved	Stage__c',			Stage_External_Id__c='CSC-5-AIF013',	 Case_Category_Config__c=cccRec.Id	));	
        insert casestageconfiglist;
        
        
        
        Case newCase1 = new Case(Status = 'In Progress', Origin = 'Phone', Subject = 'Test Case Creation1', 
                                 SLA_Target_1__c = 'testwesffwefe@salesforce.com', CSAT__c = 22, DB_Hours__c = 3, has_CheckLists__c=false, Reopen_Days__c=29 );
        newCase1.Stage_SLA_1__c = System.now();
        newCase1.Stage_SLA_2__c = System.now()+1;
        newCase1.Stage_SLA_3__c = System.now()+2;
        newCase1.CCC_External_Id__c = 'MF029';
        newCase1.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        newCase1.Business_Unit__c = 'ABSLAMC';
        newCase1.Line_Of_Business__c = 'MF';
        newCase1.Stage__c = 'Reply Received from CAMS';
        newCase1.Status = 'In Progress';
        insert newCase1;
        
        Case newCase = new Case(Status = 'In Progress', Origin = 'Phone', Subject = 'Test Case Creation', 
                                SLA_Target_1__c = 'testwesffwefe@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        newCase.Stage_SLA_1__c = System.now();
        newCase.Stage_SLA_2__c = System.now()+1;
        newCase.Stage_SLA_3__c = System.now()+2;
        newCase.CCC_External_Id__c = 'MF029';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        newCase.Business_Unit__c = 'ABSLAMC';
        newCase.Line_Of_Business__c = 'MF';
        newCase.Stage__c = 'Open';
        newCase.Status = 'New';
        insert newCase;  
        
        
        ABSLAMC_Case_Detail__c casedetails = new ABSLAMC_Case_Detail__c(Approval_Required__c = 'Yes');
        insert casedetails;
        
        Case newCase2 = new Case(Status = 'In Progress', Origin = 'Phone', Subject = 'Test Case Creation1', 
                                SLA_Target_1__c = 'testwesffwefe@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        newCase2.Stage_SLA_1__c = System.now();
        newCase2.Stage_SLA_2__c = System.now()+1;
        newCase2.Stage_SLA_3__c = System.now()+2;
        newCase2.CCC_External_Id__c = 'MF029';
        newCase2.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        newCase2.Business_Unit__c = 'ABSLAMC';
        newCase2.Line_Of_Business__c = 'MF';
        newCase2.Stage__c = 'Approval';
        newCase2.Status = 'New';
        newcase2.ABSLAMC_Case_Detail__c = casedetails.Id;
        insert newCase2; 
        
        ASF_Case_Approv__c caseapproval = new ASF_Case_Approv__c(Approval_Status__c = 'Approved', Approval_Type__c='Sequential', Approver_01__c=UserInfo.getUserId(), SR__c=newCase2.Id);
        //insert caseapproval;
    }
    
    @isTest
    static void testCheckQueueAssignementSpecificToLOB(){
        case currentcase = [SELECT id, Casenumber, Business_Unit__c,OwnerId, Line_Of_Business__c from Case where ccc_External_Id__c = 'MF029' AND Stage__c='Open' limit 1];
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        String errormsg;
        
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }
        Test.StartTest();
        ASF_Case360Controller.moveToNextStage(currentcase.Id);
        currentcase.OwnerId = testGroup.Id;
        try{
            update currentcase;
        }catch(exception e){
            errormsg = e.getMessage();
        }
        Test.StopTest();
    }
    
    @isTest
    static void testrestrictForwardStageMovementToThirdStageCAMS(){
        case currentcase = [SELECT id, Stage__c, Casenumber, Business_Unit__c,OwnerId, Line_Of_Business__c from Case where ccc_External_Id__c = 'MF029' AND Stage__c='Open' limit 1];
        //ASF_Case360Controller.moveToNextStage(currentcase.Id);
        //
        test.startTest();
        System.runAs(new User(Id=UserInfo.getUserId())){
            ASF_Case360Controller.moveToRequestedStage(currentcase.Id,'Reply Received from CAMS', true );
        }
        test.stopTest();
       
    }
    
    @isTest
    static void testrestrictBackStageMovementFromStage3ToSatage1(){
        case currentcase = [SELECT id, Stage__c, Casenumber, Business_Unit__c,OwnerId, Line_Of_Business__c from Case where Stage__c = 'Reply Received from CAMS' limit 1];
        try{
        	ASF_Case360Controller.moveToNextStage(currentcase.Id);
        }
        catch(exception e){
            
        }
    }
    
    @isTest
    static void testvalidateManualApproval(){
        case currentcase = [SELECT id, Stage__c, Casenumber, Business_Unit__c,OwnerId, Line_Of_Business__c from Case where Stage__c = 'Approval' limit 1];
        try{
            ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Approv__c');
        	ASF_Case360Controller.moveToNextStage(currentcase.Id);
        }
        catch(exception e){
            
        }
    }
    
    
    @isTest
    static void testcheckAMCResolutionComments (){
        case currentcase = [SELECT id, Stage__c, Casenumber, Business_Unit__c,OwnerId, Line_Of_Business__c from Case where Stage__c = 'Reply Received from CAMS' limit 1];
        try{
        	ASF_Case360Controller.moveToRequestedStage(currentcase.Id,'Open', false );
        }
        catch(exception e){
            
        }
    }
    
    
}