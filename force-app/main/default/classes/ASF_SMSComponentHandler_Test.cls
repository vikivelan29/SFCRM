@isTest
public class ASF_SMSComponentHandler_Test {
    
    @TestSetup
    private static void setupData(){
        
        //User usr = ASF_TestDataFactory.createCS60UserWithPermissions();
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
       ccc.Type__c = 'tes';
       ccc.CCC_External_Id__c = '12345';
       ccc.Business_Unit__c = 'ABFL';
       ccc.Sub_Type__c = 'TDC Refund';
       ccc.Overall_Case_Closure_SLA__c = 10;
       insert ccc;
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
       insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
       
       insert stage1;
        
        //System.runAs(usr){
            Account acc = ASF_TestDataFactory.insertPersonAccount('John', 'Smith','10110000');
            acc.PersonMobilePhone = '1111111111';
            update acc;
            List<Case> cases = new List<Case>();
           
            Case cs = new Case();
            cs.AccountId = acc.Id;
            cs.CCC_External_Id__c = '12345';
            cs.Status = 'New';
            cs.Stage__c='New';
            insert cs;
           
            
        //}
    }
    
    @isTest
    private static void getTemplateTest1(){
        List<Case> cases = [SELECT ID FROM Case LIMIT 5];
        List<Contact> contacts = [SELECT ID FROM Contact LIMIT 5];
        String returnString = ASF_SMSComponentHandler.getTemplate(cases[0].Id,'PAYMENT_SR_CREATED',true,contacts[0].Id,false);
        System.assertEquals(true, returnString.contains('Success'));
    }
    @isTest
    private static void getTemplateTest2(){
        List<Case> cases = [SELECT ID FROM Case LIMIT 5];
        List<Contact> contacts = [SELECT ID FROM Contact LIMIT 5];
        String returnString = ASF_SMSComponentHandler.getTemplate(cases[0].Id,'PAYMENT_SR_CREATED',false,contacts[0].Id,true); 
        System.assertEquals(true, returnString.contains('Success'));
    }
    @isTest
    private static void getTemplateTest3(){
        List<Case> cases = [SELECT ID FROM Case LIMIT 5];
        List<Contact> contacts = [SELECT ID FROM Contact LIMIT 5];
        String returnString;
        try{
             returnString = ASF_SMSComponentHandler.getTemplate(cases[0].Id,'PAYMENT_SR_CREATED',false,contacts[0].Id,false);  
             System.assertEquals(true, returnString.contains('Success'));
        }
        catch(exception e){                
            System.debug(e.getMessage());
            System.assertEquals('Script-thrown exception', e.getMessage()); 
        }
        
    }

}