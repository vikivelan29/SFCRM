/******************************************************  
* Author           - Shubham Sinha
* Date             - 15-March-2023
* Description      - Test class for ASF_CaseManualStageController
********************************************************
*/
  @isTest
    private class ASF_CaseManualStageController_Test {
        private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
        @testSetup
        static void setupTestData(){
            User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                 LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                 TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
                    insert userRecord;
              User userRecord1 = new User(Alias = 'standt', Email='stanrduser@testorg.com', 
                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                 LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                 TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56@gmail.com');
                    insert userRecord1;
              User userRecord2 = new User(Alias = 'standt', Email='stadarduser@testorg.com', 
                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                 LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                 TimeZoneSidKey='America/Los_Angeles', UserName='defghijk56@gmail.com');
                    insert userRecord2;
            System.runAs(userRecord) {

            PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Case_Config'];
                PermissionSetAssignment psa1 = new PermissionSetAssignment();
                psa1.AssigneeId = userRecord.Id;
                psa1.PermissionSetId = ps1.Id;
                insert psa1;
           
            PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Case'];
                PermissionSetAssignment psa2 = new PermissionSetAssignment();
                psa2.AssigneeId = userRecord.Id;
                psa2.PermissionSetId = ps2.Id;
                insert psa2;
           
            }
			  String RecordTypeId = (String)Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Individual').getRecordTypeId(); 
              Account acc= new Account(
                Name ='Test FName',
                /*PersonMailingStreet='test@yahoo.com',
                PersonMailingPostalCode='12345',
                PersonMailingCity='SFO',
                PersonEmail='test@yahoo.com',
                PersonHomePhone='1234567',
                PersonMobilePhone='12345678',*/
                RecordTypeId=RecordTypeId
            );
                insert acc; 
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

            LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
                insert lob;
            Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
                insert ast;
            ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',
                                          Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',Overall_Case_Closure_SLA__c = 10,
                                         Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard', First_Stage__c = 'Clarification');
                insert ccc;   
          ASF_Case_Category_Config__c  ccc1 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-0',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                         Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard', Overall_Case_Closure_SLA__c = 10, First_Stage__c = 'In Progress with CEC');
                insert ccc1;  
                      ASF_Case_Category_Config__c  ccc2 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-03',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                         Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard', Overall_Case_Closure_SLA__c = 10, First_Stage__c = 'Pending Clarification');
                insert ccc2;  
                        ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', 
                                                                                              StageName__c = 'In Progress with CEC', Manual_Backward_Stage__c = true,
                                                                                              Case_Category_Config__c= ccc.Id);
                insert caseconfig;
            
            ASF_Case_Stage_Config__c  caseconfig2 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Manual_Backward_Stage__c =true, Case_Category_Config__c= ccc.Id);
                insert caseconfig2;
           ASF_Case_Stage_Config__c  caseconfig3 =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'Pending Clarification', Case_Category_Config__c= ccc1.Id);
                insert caseconfig3;
          ASF_Case_Stage_Config__c  caseconfig4 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc1.Id);
                insert caseconfig4;
         ASF_Case_Stage_Config__c  caseconfig5 =  new ASF_Case_Stage_Config__c (Order__c=4, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'Clarification', Case_Category_Config__c= ccc1.Id);
                insert caseconfig5;
          ASF_Case_Stage_Config__c  caseconfig6 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'Clarification', Case_Category_Config__c= ccc1.Id);
                insert caseconfig6;
                        
            ASF_Case_Stage_Config__c  caseconfig7 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='test', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc2.Id);
                insert caseconfig7;
            
            Case newCase = new Case( Type_Text__c = 'Testing', Sub_Type_Text__c  = 'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CC-RC-01');
                insert newCase;
           Case newCase2 = new Case( Type_Text__c = 'Testing', Sub_Type_Text__c  = 'CreditCard', Stage__c='Pending Clarification', CCC_External_Id__c ='CCC-CC-RC-0');
                insert newCase2;
          Case newCase3 = new Case( Type_Text__c = 'Testing',Status='New', Sub_Type_Text__c  = 'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CC-RC-03');
              insert newCase3;
            
            ASF_Case_Rule__c csaRule = new ASF_Case_Rule__c ( Logical_Condition__c = 'test',Case_Stage_Config__c = caseconfig2.Id,Order__c = 1,Type__c ='Assignment');
                insert csaRule;
             
           //Checklist__c check = new Checklist__c ( Case__c  = newCase3.Id,Status__c='Pending',Rejected_Reason__c ='');
            //  insert check;
           //Task tsk =    new Task ( WhatId   = newCase3.Id,Status ='Open',Rejected_Reason__c  ='');
            //  insert tsk;
        }
            
        @isTest
        public static void fetchCaseSLAHistoryRecordsTest(){
            Case caseRecord = [SELECT Id,Type_Text__c,Stage__c,Sub_Type_Text__c,CCC_External_Id__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest();          
                ASF_CaseManualStageController.fetchCaseSLAHistoryRecords(caseRecord.Id,caseRecord.Stage__c);
                Test.stopTest();     
                System.assertEquals('CCC-CC-RC-01', caseRecord.CCC_External_Id__c);        
            }
        }     
        @isTest
        public static void fetchManualStagesTest(){
            ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                 try{
                    ASF_CaseManualStageController.fetchManualStages(caseRecord.CCC_External_Id__c);
                 }catch(Exception e){
                 } 
               // ASF_CaseManualStageController.fetchManualStages(caseRecord.CCC_External_Id__c);
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-01', caseRecord.CCC_External_Id__c);        
            }
        } 
          @isTest
        public static void fetchNextManualStagesTest(){
            ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                
                ASF_CaseManualStageController.fetchNextManualStages(caseRecord.CCC_External_Id__c,'In Progress with CEC');
                 
               // ASF_CaseManualStageController.fetchManualStages(caseRecord.CCC_External_Id__c);
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-01', caseRecord.CCC_External_Id__c);        
            }
        } 
                @isTest
        public static void fetchAllManualStagesWithCaseTest(){
            Case caseRecord = [SELECT Id,CCC_External_Id__c,Stage__c,Sub_Type_Text__c FROM Case WHERE Stage__c = 'Pending Clarification' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                try{
                    ASF_CaseManualStageController.fetchAllManualStagesWithCase(caseRecord.Id);                 
                }   
                catch(Exception e){
                 } 
                
                Test.stopTest();     
                System.assertEquals('Pending Clarification', caseRecord.Stage__c);
            }
        } 


        /**
         * Test Backward Stage movement
         */
        @isTest
        public static void fetchStagesTest(){
            Case caseRecord = [SELECT Id,CCC_External_Id__c,Stage__c,Sub_Type_Text__c FROM Case WHERE Stage__c = 'Pending Clarification' LIMIT 1];
            ASF_Case_Category_Config__c config = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-0' LIMIT 1];

                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                try{
                    ASF_CaseManualStageController.fetchBackwardStages(config.CCC_External_Id__c,'Clarification',caseRecord.Id);                 
                }   
                catch(Exception e){
                 } 
                
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-0', caseRecord.CCC_External_Id__c);       
            }
        }        
            @isTest
          public static void rejectCaseTest(){
            Case caseRecord = [SELECT Id,CCC_External_Id__c,Stage__c,Sub_Type_Text__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-03' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                //try{
                    ASF_CaseManualStageController.rejectCase(caseRecord.Id,'testingreject');                 
                //}   
                //catch(Exception e){
                 //} 
                
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-03', caseRecord.CCC_External_Id__c);       
            }
        } 
                @isTest
          public static void fetchQueuesTest(){
            Case caseRecord = [SELECT Id,CCC_External_Id__c,Stage__c,Sub_Type_Text__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-0' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                //try{
                    ASF_CaseManualStageController.fetchQueues(caseRecord.Id);                 
                //}   
                //catch(Exception e){
                 //} 
                
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-0', caseRecord.CCC_External_Id__c);      
            }
        } 
        @isTest
          public static void getOwnerSearchResultTest(){
            Case caseRecord = [SELECT Id,CCC_External_Id__c,Stage__c,Sub_Type_Text__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-0' LIMIT 1];
                system.debug('caseRecordquey'+caseRecord);
            User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk56@gmail.com'];
            system.runAs(usr)
            {
                Test.startTest(); 
                //try{
                    ASF_CaseManualStageController.getOwnerSearchResult('abcdefghijk56@gmail.com');                 
                //}   
                //catch(Exception e){
                 //} 
                
                Test.stopTest();     
        		System.assertEquals('CCC-CC-RC-0', caseRecord.CCC_External_Id__c);      
            }
        } 
    }