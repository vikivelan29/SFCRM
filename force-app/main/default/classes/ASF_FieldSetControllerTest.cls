@isTest
public class ASF_FieldSetControllerTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @isTest
    public static void getFormTest(){
        ASF_FieldSetController.getForm(null,'Lead','ABFL_Prospect_FieldSet');
        ASF_FieldSetController.getForm(null,'Lead','ABHFL_Prospect_FieldSet');
    }
    @isTest
    public static void getLOBSpecificFormTest(){
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com',Business_Unit__c = 'ABHFL');
        
        System.runAs(userRecord) {
        	ASF_FieldSetController.getLOBSpecificForm(null,'Lead','ABHFL_Prospect_FieldSet');
            
        }
        
    }

}