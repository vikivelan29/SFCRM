/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-28-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@IsTest
public class ABFL_EBOTCaseLogics_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
         Group slaGroup = new Group();        
         slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        insert slaGroup;
          Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g1;
       
          User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657123456@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
        System.runAs(userRecord) {
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
            ccc.Type__c = 'tes';
            ccc.First_Stage__c = 'New';
            ccc.CCC_External_Id__c = '12345';
            ccc.Business_Unit__c = 'ABFL';
            ccc.Sub_Type__c = 'Paytm';
            ccc.EBOT_Auto_Response__c = True;
            ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;
        // ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c=g1.Id, StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        //insert caseconfig;
        //       
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc.Id;
            stage1.Order__c = 1;
            stage1.StageName__c = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            // stage1.Stage_SLA_3__c = 3;
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            stage1.Default_Queue__c =g1.Id;
            insert stage1;
            
             Case newCase = new Case();
            newCase.Subject = 'Test Case Creation';
            newCase.CCC_External_Id__c ='' ;
          newCase.Source__c =  'Email';
          newCase.Stage__c = 'Email';
          newCase.Origin = 'ABFL Email';
          newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
           newCase.Business_Unit__c  = 'ABFL'; 
            insert newCase; 
          //  List<Case> caseRecords = ASF_TestDataFactory.createCaseRecords(1);
            /*caseRecords[0].Source__c = 'Email';
            caseRecords[0].CCC_External_Id__c = '';
            caseRecords[0].RecordTypeId = ASF_Constants.RT_INTERACTION;
            caseRecords[0].Business_Unit__c  = 'ABFL';
            caseRecords[0].Stage__c = 'New'; */
           // update caseRecords;
            if(newCase.Id != null){
                EmailMessage eMsg = new EmailMessage();
                eMsg.ParentId = newCase.Id;
                eMsg.ToAddress = 'abcl.abfl@gmail.com';
                eMsg.CCAddress = 'test@test.com';
                eMsg.BCCAddress = 'test@test.com';
                insert eMsg;
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =newCase.Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                insert caseInt;
             ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
             caseIntUpdate.Id = caseInt.Id;
            caseIntUpdate.Status__c = 'Success';
            caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"00003974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';
           // insert caseIntUpdate;
           
            
            }
        }
    }   
       @isTest
    static void eBotHandlerTestSmtYes(){
         Test.startTest(); 
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
            ccc1.Type__c = 'tess';
            ccc1.First_Stage__c = 'New';
            ccc1.CCC_External_Id__c = '123456';
            ccc1.Business_Unit__c = 'ABFL';
            ccc1.Sub_Type__c = 'TDC Refund';
            ccc1.Overall_Case_Closure_SLA__c = 10;
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
            newCase.Subject = 'Test Case Creations';
            newCase.CCC_External_Id__c ='' ;
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
                eMsg.Winning_Email__c = 'abfssl.uatcaredigitalfinance@adityabirlacapital.com';
                insert eMsg;
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =newCase.Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                insert caseInt;
             ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
             caseIntUpdate.Id = caseInt.Id;
            caseIntUpdate.Status__c = 'Success';
            caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"00003974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"YES","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';
            update caseIntUpdate;
              ABFL_Case_Detail__c objABFL = new ABFL_Case_Detail__c();
                objABFL.Case__c = newCase.Id;
                insert objABFL; 
                ABFL_EbotWrapper.EbotResponseWrapper mockResponse = new ABFL_EbotWrapper.EbotResponseWrapper();
                  mockResponse.AUTOCLOSURE_IN_RR = 'NO';
                  mockResponse.CASEID = '00003974';
                  mockResponse.CASESUBTYPE = '12345';
                  mockResponse.COMMENT = 'updatedd';
                  mockResponse.CONFIDENCESCORE = '40.12';
                  mockResponse.CUSTOMERNO = '1234566';
                  mockResponse.ISATTACHMENTFLAG = 'NO';
                  mockResponse.ISMULTIPLELAN = 'YES';
                  mockResponse.ISREGISTEREDCUSTOMER = 'YES';
                  mockResponse.ISSMT = 'YES';
                  mockResponse.LAN = '122321321';
                  mockResponse.LOB = '001';
                  mockResponse.MOODSTAMP = 'not sure';
                  mockResponse.OWNERFULLNAME = 'Shubham Sinha';
                  mockResponse.PAYTMINTERACTIONID = '';
                  mockResponse.PRIORITY = 'low';
                  mockResponse.AUTORESPONSEFLAG = 'YES';
                ABFL_EBOT_Case_Email__mdt mdtEbotCase = ABFL_EBOT_Case_Email__mdt.getInstance('EBOT_Condition'); 
                  ABFL_EBOTCaseLogics.checkIsSmtAndMultipleLAN(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.checkPaytmInteractionNotNull(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.checkLeadSubtype(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.checkIsRegisteredCustomerNo(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.checkIsRegisteredCustomerYes(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.confidenceScoreAndSubtypeCheck(eMsg,newCase,ccc1,mockResponse,mdtEbotCase);
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,true,objABFL.Id,true,true,true,true);
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,true,objABFL.Id,false,true,true,true);                     
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,true,objABFL.Id,false,false,false,true);
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,true,objABFL.Id,false,true,false,false);
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,true,objABFL.Id,false,false,false,false);
                  ABFL_EBOTCaseLogics.genericSendEmailAndCaseClose(ccc1,newCase,false,objABFL.Id,false,false,false,false);
            System.assertEquals('Success', caseIntUpdate.Status__c,'record found');          
             Test.stopTest();            
            }
        }
    } 
    @isTest   
    static void testPaytmInteractionNotNull(){
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Test Case Creation' LIMIT 1];

        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        {
        Test.startTest(); 
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =objCase[0].Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                insert caseInt;
             ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
             caseIntUpdate.Id = caseInt.Id;
            caseIntUpdate.Status__c = 'Success';
            caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';
           // update caseIntUpdate;  
            System.assertEquals('Success', caseIntUpdate.Status__c,'record found');          
        Test.stopTest(); 
        }
    }
        
}