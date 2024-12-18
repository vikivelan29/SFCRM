@IsTest
public class ABFL_CaseIntegrationHelperTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void testDataSetup(){
        ABFL_EBOT_Case_Email__mdt mdtEbotCase = ABFL_EBOT_Case_Email__mdt.getInstance('EBOT_Condition');
        String toAddresses=mdtEbotCase.ToAddress__c;
        String winningEmail = toAddresses.split(',')[0].trim();
        Group slaGroup2 = new Group();        
        slaGroup2 = new Group(Name='SLAManagerGroup2', DeveloperName='SLAManagerGroup2');
        insert slaGroup2;
        Group g1 = new Group(Name='OCC-Test-Group2', type='Queue');
        insert g1;
        
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='cdefsddghijk567@gmail.com',
                                   managerGroupId__c=slaGroup2.Id);
        insert userRecord;
        System.runAs(userRecord) {
            ASF_Case_Category_Config__c ccc1 = new ASF_Case_Category_Config__c();
            ccc1.Type__c = 'test';
            ccc1.First_Stage__c = 'New';
            ccc1.CCC_External_Id__c = 'RSTASTNTMOR';
            ccc1.Business_Unit__c = 'ABFL';
            ccc1.Sub_Type__c = 'Cibil Related';
            ccc1.Overall_Case_Closure_SLA__c = 10;
            ccc1.Nature__c='Request';
            insert ccc1;
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc1.Id;
            stage1.Order__c = 1;
            stage1.StageName__c = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            stage1.Default_Queue__c =g1.Id;
            insert stage1;
            
            Case newCase = new Case();
            newCase.Subject = 'Sample Test Case';
            newCase.CCC_External_Id__c ='RSTASTNTMOR' ;
            newCase.Source__c =  'Email';
            newCase.Stage__c = 'Email';
            newCase.Origin = 'ABFL Email';
            newCase.Business_Unit__c  = 'ABFL'; 
            newCase.SuppliedEmail ='abc.de@hjash.com';
            insert newCase; 
            
            Task task1 = new Task(WhatId  = newCase.Id);
            insert task1;
            ASF_Checklist__c checkList = new ASF_Checklist__c(Mandatory__c = TRUE, Case__c=newCase.Id, Stage_Name__c = newCase.Stage__c);
            insert checkList;
            
            if(newCase.Id != null){
                EmailMessage eMsg = new EmailMessage();
                eMsg.ParentId = newCase.Id;
                eMsg.CCAddress = 'test@test.com';
                eMsg.BCCAddress = 'test@test.com';
                eMsg.ToAddress = winningEmail;
                eMsg.Winning_Email__c = winningEmail;
                insert eMsg;
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =newCase.Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'CATEGORIZATION';
                insert caseInt;
            }
            
            
        }
    }
    @isTest
    static void unfydResponseHandlerPotentialComplaintTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"Yes","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"No","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerSubTypeLeadTest(){
        Test.startTest();
        ABFL_EBOT_Case_Email__mdt mdtEbotCase = ABFL_EBOT_Case_Email__mdt.getInstance('EBOT_Condition');
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        Case c=new Case();
        c.Id=objCase[0].Id;
        c.Sub_Type_Text__c='Lead';
        Update c;
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=TRUE;
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerMultiaLANTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=FALSE;
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerPayTMInteractionNULLTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        Case c=new Case();
        c.Id=objCase[0].Id;
        c.Sub_Type_Text__c='Paytm';
        Update c;
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=TRUE;
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerRegCustNOTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        Case c=new Case();
        c.Id=objCase[0].Id;
        c.Sub_Type_Text__c='test';
        Update c;
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=TRUE;
        cccNew.EBOT_Unregistered_Template__c='Test Template';
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerRegCustYesTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        Case c=new Case();
        c.Id=objCase[0].Id;
        c.Sub_Type_Text__c='Cibil Related';
        Update c;
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=TRUE;
        cccNew.EBOT_Registered_Template__c='Test Registered Template';
        
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"Yes","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerMultiIntentTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"Yes","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"Yes","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"No","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerAttachmentTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"Yes","LOB":"Corporate","ISREGISTEREDCUSTOMER":"No","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"Yes","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"Yes","ISMULTIPLEPLAN":"No","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    @isTest
    static void unfydResponseHandlerConfScoreTest(){
        Test.startTest();
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Sample Test Case' LIMIT 1];
        Case c=new Case();
        c.Id=objCase[0].Id;
        c.Sub_Type_Text__c='test';
        Update c;
        ASF_Case_Category_Config__c ccc1 = [Select Id,Type__c,First_Stage__c,CCC_External_Id__c,EBOT_Auto_Response__c from ASF_Case_Category_Config__c where CCC_External_Id__c=: 'RSTASTNTMOR'];
        ASF_Case_Category_Config__c cccNew= New ASF_Case_Category_Config__c();
        cccNew.Id=ccc1.Id;
        cccNew.EBOT_Auto_Response__c=TRUE;
        cccNew.EBOT_Registered_Template__c='Test Registered Template';
        
        update cccNew;
        String jsonResponse='{"CASENUMBER":"00461888","CUSTOMERNO":"","AUTORESPONSE":"Yes","ISSMT":"No","ISMULTIPLEINTENT":"No","LOB":"Corporate","ISREGISTEREDCUSTOMER":"Yes","DEDUPE":"No","PAYMTINTERACTIONID":"","PRIORITY":"High","ISSUECODE":"RSTASTNTMOR","LAN":"","MOODSTAMP":"Negative","POTENTIALCOMPLAINT":"No","CONFIDENCESCORE":"0.80","ISTRAILMAIL":"No","ISATTACHMENT":"No","ISMULTIPLEPLAN":"Yes","DISPOSITION":"","COMMENT":"","OWNERFULLNAME":"","INTENT":"Request for statement of account against loan","REMARKS":{"Case Type":["Statements & Documents"],"Case sub type":["Statement of Account"],"Potential_Reason":"Regulator Threat"},"CASE_INTEGRATION_ID":"ASF_CInt_441271"}';
        ABFL_UNFYDWrapper unfydResponse=(ABFL_UNFYDWrapper)JSON.deserialize(jsonResponse,ABFL_UNFYDWrapper.class);
        ABFL_CaseIntegrationHelper.unfydResponseHandler(objCase[0].Id,unfydResponse);
        Test.stopTest();
    }
    
}