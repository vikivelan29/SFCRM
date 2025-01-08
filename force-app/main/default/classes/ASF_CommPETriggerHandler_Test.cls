/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 04-24-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
private class ASF_CommPETriggerHandler_Test {
    @testSetup
    private static void testDataSetup(){
        Account a = new Account();
        a.Name = 'Test account';
        a.Client_Code__c = '3r4fwefcw';
        a.Line_Of_Business__c = 'Payments';
        a.Business_Unit__c = 'Payments';
        a.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId();
        insert a;

	Account a1 = new Account();
        a1.Name = 'Test account';
        a1.Client_Code__c = '3r4fwefcw';
        a1.Line_Of_Business__c = 'Payments';
        a1.Business_Unit__c = 'Payments';
        a1.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId();
        insert a1;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = a.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        con.MobilePhone = '9100091000';
        insert con;
        
        ASF_Case_Category_Config__c config = new ASF_Case_Category_Config__c();
        config.Send_Closed_stage_communications__c  = true;
        config.Send_open_stage_communications__c  = true;
        config.Send_Rejected_stage_communications__c  = true;
        config.CCC_External_Id__c = '12345';
        config.Type__c = 'TDS Related';
        config.Sub_Type__c = 'TDS Related';
        config.Process__c='Case';
        insert config;
        
        Lead leaRec= new Lead();
        leaRec.FirstName = 'John';
        leaRec.LastName = 'Doe';
        leaRec.Company = 'Acme Inc.';
        leaRec.Email = 'john.doe@example.com';
        leaRec.Phone = '1234567890';
        leaRec.LeadSource='Branch Ops';
        leaRec.Sub_Source__c='Walk-in';
        leaRec.Requested_Loan_Amount__c=1234;
        leaRec.Preferred_Communication__c='Email';
        leaRec.ABHFL_Prospect_Type__c='Individual';
        insert leaRec;
        
        List<Case> cases = new List<Case>();
        
        for(integer i=0;i<1;i++){
            Case cs = new Case();
            cs.AccountId = a.Id;
            cs.CCC_External_Id__c = '12345';
            cs.contactId = con.Id;
            cs.Status = 'New';
            cs.Stage__c='New'; 
            cs.Type_Text__c ='Cancellation of card'; 
            cs.Sub_Type_Text__c ='Aqua Card Cancel - liquidate TD'; 
            cs.Business_Unit__c = 'Payments';
            cases.add(cs);
        }
        for(integer i=0;i<1;i++){
            Case cs2 = new Case();
            cs2.CCC_External_Id__c = '12345';
            cs2.AccountId = a.Id;
            cs2.Status = 'New';
            cs2.Stage__c='New'; 
            cs2.Type_Text__c ='Cancellation of card'; 
            cs2.Sub_Type_Text__c ='Aqua Card Cancel - liquidate TD'; 
            cs2.Business_Unit__c = 'Payments';
            cases.add(cs2);
        }
	//For Payments
         for(integer i=0;i<1;i++){
            Case cs3 = new Case();
            cs3.CCC_External_Id__c = 'payments_indi_21';
            cs3.AccountId = a.Id;
            cs3.Status = 'Resolved';
            cs3.Stage__c='Resolved'; 
            cs3.Type_Text__c ='Report Fraud'; 
            cs3.Sub_Type_Text__c ='Reporting of fraudulent transaction'; 
            cs3.Business_Unit__c = 'Payments';
            cases.add(cs3);
        }
         for(integer i=0;i<1;i++){
            Case cs4 = new Case();
            cs4.CCC_External_Id__c = 'payments_indi_193';
            cs4.AccountId = a1.Id;
            cs4.Status = 'Resolved';
            cs4.Stage__c='Resolved'; 
            cs4.Type_Text__c ='Report Fraud'; 
            cs4.Sub_Type_Text__c ='Reporting of fraudulent transaction'; 
            cs4.Business_Unit__c = 'Payments';
            cs4.Lead__c = leaRec.Id;
            cases.add(cs4);
        }
         for(integer i=0;i<1;i++){
            Case cs5 = new Case();
            cs5.CCC_External_Id__c = 'payments_indi_213';
            cs5.Status = 'Resolved';
            cs5.Stage__c='Resolved'; 
            cs5.Type_Text__c ='Report Fraud'; 
            cs5.Sub_Type_Text__c ='Reporting of fraudulent transaction'; 
            cs5.Business_Unit__c = 'Payments';
            cases.add(cs5);
        }
          
          
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        insert cases;
        System.assertNotEquals(0, cases.size() , 'case list should not be zero');
    }
    
    
    @isTest
    private static void executeAfterInsert_error(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c,AccountId,ContactId FROM Case];
        List<ASF_CommnunicationLog__e > commEvts = new List<ASF_CommnunicationLog__e >();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        boolean errorCase = false;
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.AccountId__c = cList[i].AccountId;
            peLogger.ContactId__c = cList[i].ContactId;
            peLogger.Email_Template_Name__c = 'PAYMENT_SR_CREATED';
            peLogger.Is_Attachment__c = true;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e  evt = new ASF_CommnunicationLog__e ();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            if(!errorCase){
                evt.CustomMetadataName__c = 'XXXXXXXX';
            }
            else{
                evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            }
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        System.assertNotEquals(0, commEvts.size(), 'commevt should not be 0');
        if(commEvts.size()>0){
            
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }
    @isTest
    private static void executeAfterInsert_completed(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Is_Attachment__c = true;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.Specific_To_MobilePhone__c = '9999999999';
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        if(commEvts.size()>0){
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }
    @isTest
    private static void executeAfterInsert_completed2(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Completed';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Is_Attachment__c = true;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        if(commEvts.size()>0){
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }
    @isTest
    private static void CommLogPERetryBatch(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        if(commEvts.size()>0){
            Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('ASF_commLogProcessingBatch'); 
            //System.schedule('TestCommRetryPublisherJob', '0 30 * * * ?', new CommLogPERetryBatch());
            System.assertNotEquals(null, mdtPEFramework, 'save result should not be null');
            Test.getEventBus().deliver();
        }
        Test.stopTest();
    }
    @isTest
    private static void commLogProcessingBatch_defaultContructor(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Processing';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.Case__c = cList[i].Id;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLogger.No_Auto_Communication__c = null;
            peLoggers.add(peLogger);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        System.schedule('TEST_WorkOnPELoggerProcessingRecords', '0 0 15,18,22 ? * *', new ASF_commLogProcessingBatch());
        Test.stopTest();
    }
    @isTest
    private static void commLogProcessingBatch_StringConstructor(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Processing';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
                        peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLogger.No_Auto_Communication__c = 'Email;SMS';
            peLoggers.add(peLogger);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        System.schedule('TEST_WorkOnPELoggerProcessingRecords', '0 0 15,18,22 ? * *', new ASF_commLogProcessingBatch('SELECT ID,RecordID__c,CustomMetadataName__c,Lead__c FROM PE_Logger__c WHERE Status__c=\'Processing\' AND CreatedDate = Today ORDER BY CreatedDate DESC'));
        Test.stopTest();
    }
 @isTest
    private static void executeAfterInsert_completed3(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case LIMIT 1];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Case__c = cList[i].Id;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.Specific_To_Address__c  = 'abc.def@gm.com';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
           	peLogger.Email_Template_Name__c = 'SMT_Escalation_Template';
            peLogger.RecordID__c = cList[i].Id;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        if(commEvts.size()>0){
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }  
@isTest
    private static void executeAfterInsert_errorForProspect(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c,AccountId FROM Case where CCC_External_Id__c='payments_indi_193'];
        Lead leaRecd = [Select id,firstName from Lead where FirstName='John'];
        List<ASF_CommnunicationLog__e > commEvts = new List<ASF_CommnunicationLog__e >();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        boolean errorCase = false;
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.AccountId__c = cList[i].AccountId;
            //peLogger.ContactId__c = cList[i].ContactId;
            peLogger.Email_Template_Name__c = 'PAYMENT_SR_CREATED';
            peLogger.Is_Attachment__c = true;
            peLogger.Lead__c = leaRecd.id;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e  evt = new ASF_CommnunicationLog__e ();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            if(!errorCase){
                evt.CustomMetadataName__c = 'XXXXXXXX';
            }
            else{
                evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            }
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        System.assertNotEquals(0, commEvts.size(), 'commevt should not be 0');
        if(commEvts.size()>0){    
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }  
@isTest
    private static void executeAfterInsert_errorForContact(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c,AccountId,ContactId FROM Case where CCC_External_Id__c='payments_indi_21'];
        List<ASF_CommnunicationLog__e > commEvts = new List<ASF_CommnunicationLog__e >();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        boolean errorCase = false;
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.Email_Template_Name__c = 'PAYMENT_SR_CREATED';
            peLogger.Is_Attachment__c = true;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e  evt = new ASF_CommnunicationLog__e ();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            if(!errorCase){
                evt.CustomMetadataName__c = 'XXXXXXXX';
            }
            else{
                evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            }
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        System.assertNotEquals(0, commEvts.size(), 'commevt should not be 0');
        if(commEvts.size()>0){
            
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    } 
    
    
    @isTest
    private static void executeAfterInsert_completed4(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case LIMIT 1];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        
        /*ContentVersion cvlist = new Contentversion(); 
        cvlist.Title = 'CZDSTOU'; 
        cvlist.PathOnClient = 'test'; 
        cvlist.VersionData = ; 
        List<ContentVersion> cvl = new List<ContentVersion>(); 
        cvl.add(cvlist); 
		insert cvl;
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvl[0].Id].ContentDocumentId;*/
        Test.startTest();
        
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Case__c = cList[i].Id;
            peLogger.Send_To_Specific_Emails__c  = True;
            peLogger.Specific_To_Address__c  = 'abc.def@gm.com';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
           	peLogger.Email_Template_Name__c = 'SMT_Escalation_Template';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.TakeBodyFromContentDoc__c = true;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertNotEquals(0, peLoggers.size() , 'pelogger list should not be zero');
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        if(commEvts.size()>0){
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }

    
    @isTest
    private static void executeAfterInsert_withoutContact(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c,AccountId,ContactId FROM Case];
        List<ASF_CommnunicationLog__e > commEvts = new List<ASF_CommnunicationLog__e >();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        boolean errorCase = false;
        for(Integer i=0;i<1;i++){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.Email_Template_Name__c = 'PAYMENT_SR_CREATED';
            peLogger.Is_Attachment__c = true;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e  evt = new ASF_CommnunicationLog__e ();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            if(!errorCase){
                evt.CustomMetadataName__c = 'XXXXXXXX';
            }
            else{
                evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            }
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        for(Integer i=0;i<1;i++){
            ASF_CommnunicationLog__e evt = commEvts[i];
            evt.PELoggerId__c = peLoggers[i].id;
        }
        System.assertNotEquals(0, commEvts.size(), 'commevt should not be 0');
        if(commEvts.size()>0){
            
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
            System.assertNotEquals(null, results, 'save result should not be null');
        }
        Test.stopTest();
        
    }
    

    
}
