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
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        insert cases;
    }
    
    
    @isTest
    private static void executeAfterInsert_error(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c,AccountId,ContactId FROM Case];
        List<ASF_CommnunicationLog__e > commEvts = new List<ASF_CommnunicationLog__e >();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        boolean errorCase = false;
        for(Integer i=0;i<1;i++){
            DateTime dt = DateTime.now();
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
        if(commEvts.size()>0){
            
            Database.SaveResult[] results = EventBus.publish(commEvts);
            Test.getEventBus().deliver();
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
            DateTime dt = DateTime.now();
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        // Assert to check the count of the account
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name = 'Test account']);
         // Assert to check the size of the peLoggers
        System.assertEquals(1, peLoggers.size());
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
            DateTime dt = DateTime.now();
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = false;
            peLogger.Status__c = 'Completed';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name = 'Test account']);
        System.assertEquals(1, peLoggers.size());
        
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
            DateTime dt = DateTime.now();
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Pending';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLoggers.add(peLogger);
            
            ASF_CommnunicationLog__e evt = new ASF_CommnunicationLog__e();
            evt.CCCExternalId__c = cList[i].CCC_External_Id__c;
            evt.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            evt.Unique_Id__c = 'CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            evt.RecordID__c = cList[i].Id;
            commEvts.add(evt);
        }
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name = 'Test account']);
        System.assertEquals(1, peLoggers.size());
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        if(commEvts.size()>0){
            Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('ASF_commLogProcessingBatch'); 
            integer iRetryInterval = (Integer.ValueOf(mdtPEFramework.RetryInterval__c)*-1);
            Datetime lastFifteen = Datetime.now().addMinutes(iRetryInterval);  
            String sLastFifteen = lastFifteen.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); 
            Datetime currentTime = Datetime.now();
            String sCurrTime = currentTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            String peQuery = 'Select id,Retry_Time__c, unique_id__c,PE_JSON__c,PE_Name__c,Retry_PE__c,CCCExternalId__c,CustomMetadataName__c,RecordID__c from PE_Logger__c where Retry_PE__c = true and status__c = \'Pending\'';// and (Retry_Time__c > ' + sLastFifteen + ' and Retry_Time__c < ' + sCurrTime + ')';
            List<PE_Logger__c> peLs = Database.query(peQuery);
            System.debug('STartTime --> '+lastFifteen);
            System.debug('EndTime --> '+currentTime);
            System.debug(peLs);
            //System.schedule('TestCommRetryPublisherJob', '0 30 * * * ?', new CommLogPERetryBatch());
            Test.getEventBus().deliver();
        }
        Test.stopTest();
    }
    @isTest
    private static void commLogProcessingBatch_defaultContructor(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            DateTime dt = DateTime.now();
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Processing';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLoggers.add(peLogger);
        }
        
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name = 'Test account']);
        System.assertEquals(1, peLoggers.size());
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        System.schedule('TEST_WorkOnPELoggerProcessingRecords', '0 0 15,18,22 ? * *', new ASF_commLogProcessingBatch());
        Test.stopTest();
    }
    @isTest
    private static void commLogProcessingBatch_StringConstructor(){
        List<Case> cList = [SELECT ID,CCC_External_Id__c FROM Case];
        List<ASF_CommnunicationLog__e> commEvts = new List<ASF_CommnunicationLog__e>();
        List<PE_Logger__c> peLoggers = new List<PE_Logger__c>();
        Test.startTest();
        for(Integer i=0;i<1;i++){
            DateTime dt = DateTime.now();
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.PE_Name__c = 'CommnunicationLog';
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Processing';
            peLogger.Unique_Id__c ='CommnunicationLog-'+UserInfo.getUserId() + System.currentTimeMillis();
            peLogger.CCCExternalId__c = cList[i].CCC_External_Id__c;
            peLogger.CustomMetadataName__c = 'PAYMENT_SR_CREATED';
            peLogger.RecordID__c = cList[i].Id;
            peLogger.Case__c = cList[i].Id;
            peLogger.Retry_Time__c = DateTime.now().addMinutes(-2);
            peLoggers.add(peLogger);
        }
        
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name = 'Test account']);
        System.assertEquals(1, peLoggers.size());
        
        if(peLoggers.size()>0){
            insert peLoggers;
        }
        System.schedule('TEST_WorkOnPELoggerProcessingRecords', '0 0 15,18,22 ? * *', new ASF_commLogProcessingBatch('SELECT ID,RecordID__c,CustomMetadataName__c FROM PE_Logger__c WHERE Status__c=\'Processing\' AND CreatedDate = Today ORDER BY CreatedDate DESC'));
        Test.stopTest();
    }
    
}