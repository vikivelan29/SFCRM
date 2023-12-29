@IsTest
public class ABFL_EBOTCaseLogics_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
         Group SLAGroup = new Group();        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        insert SLAGroup;
          Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g1;
       
          User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
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
            update caseIntUpdate;
           
            
            }
        }
    }   
       @isTest
    static void eBotHandler_TestSmtYes(){
       Group SLAGroup2 = new Group();        
        SLAGroup2 = new Group(Name='SLAManagerGroup2', DeveloperName='SLAManagerGroup2');
        insert SLAGroup2;
          Group g1 = new Group(Name='OCC-Test-Group2', type='Queue');
        insert g1;
       
          User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefsddghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup2.Id);
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
           newCase.Business_Unit__c  = 'ABFL'; 
			insert newCase; 
       
            if(newCase.Id != null){
                EmailMessage eMsg = new EmailMessage();
                eMsg.ParentId = newCase.Id;
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
            caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"00003974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"YES","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';
            update caseIntUpdate;
           
            
            }
        }
    } 
  
    @isTest   
    static void testPaytmInteractionNotNull(){
		List<Case> objCase = [Select Id From Case WHERE Subject = 'Test Case Creation' LIMIT 1];
      
       // List<ASF_Case_Category_Config__c> objCaseCateg = [Select Id,Sub_Type__c,EBOT_Auto_Response__c From ASF_Case_Category_Config__c WHERE CCC_External_Id__c = '12345' LIMIT 1];  
        //objCaseCateg[0].EBOT_Auto_Response__c = TRUE;
        //update objCaseCateg[0];
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =objCase[0].Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                insert caseInt;
             ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
             caseIntUpdate.Id = caseInt.Id;
            caseIntUpdate.Status__c = 'Success';
            caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';
            update caseIntUpdate;  
           
     }
        
}