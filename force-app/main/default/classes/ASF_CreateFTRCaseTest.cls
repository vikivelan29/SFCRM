@isTest
public class ASF_CreateFTRCaseTest {
    
    @testSetup
    static void setupTestData() {
        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = '1234';
        caseCatConfig.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig.First_Stage__c = 'Pending with Initiator';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Source__c = 'CEC';  
        caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
        caseCatConfig.Process__c='Case';
        caseCatConfig.is_FA_Mandatory__c = true;
        caseCatConfig.Business_Unit__c = 'ABSLAMC';
        insert caseCatConfig;   
        
        List<ASF_Case_Field_Config__c> fieldConfigs = new List<ASF_Case_Field_Config__c>();
        ASF_Case_Field_Config__c field1 = new ASF_Case_Field_Config__c();
        field1.Case_Main_Config__c = caseCatConfig.Id;
        field1.ObjectAPIName__c = 'Case';
        field1.FieldAPIName__c = 'Description';
        field1.Display_Order__c = 1;
        fieldConfigs.add(field1);
        
        ASF_Case_Field_Config__c field2 = new ASF_Case_Field_Config__c();
        field2.Case_Main_Config__c = caseCatConfig.Id;
        field2.ObjectAPIName__c = 'PAY_Payment_Detail__c';
        field2.FieldAPIName__c = 'Payment_mode__c';
        field2.Display_Order__c = 2;
        fieldConfigs.add(field2);
        
        insert fieldConfigs;
    }
    
    @isTest
    static void testgetCaseFieldsConfig() {
        ASF_Case_Category_Config__c caseCatConfig = [SELECT Id,CCC_External_Id__c
                                          FROM ASF_Case_Category_Config__c Where CCC_External_Id__c = '1234'];
        
        Test.starttest();
        ASF_CreateFTRCase.FieldConfigWrapper result = ASF_CreateFTRCase.getCaseFieldsConfig(caseCatConfig.Id);
        Test.stoptest();
        
        System.assert(result != null, 'Expected result to be not null');
    }   
}