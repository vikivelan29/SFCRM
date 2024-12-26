@isTest
public class ABHI_CaseCreationValidationTest {
    
    /*@testSetup
    static void setupData() {
        // Insert some Assets (policies) with various statuses and plan names
        List<Asset> assets = new List<Asset>{
            new Asset(Name = 'Policy 1', Status = 'Active', Plan_Name__c = 'Premier Plan'),
            new Asset(Name = 'Policy 2', Status = 'RJ', Plan_Name__c = 'Classic Plan'),
            new Asset(Name = 'Policy 3', Status = 'Active', Plan_Name__c = 'Standard Plan')
        };
        insert assets;
    }*/
    
    @IsTest
    public static void testCheckCreateCaseValidations(){
        String errorMessage = '';
        Account accRec = ASF_TestDataFactory.insertPersonAccount('SJ', 'SJ', '100');
        
        Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
        assetRec.Status = 'RJ';
		update assetRec;

		ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
		insert detailRec;
        Case cs = new Case(AssetId=assetRec.Id,ABHI_Case_Detail__c=detailRec.Id,Business_Unit__c='ABHI',Technical_Source__c='LWC',
                           RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId(),
                          Status = 'Open', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Open',
                          CCC_External_Id__c = 'ABHI_Endorsement_Request18');
        try{
        	insert cs;    
        }catch(Exception ex){
            errorMessage = ex.getMessage();
        }
        System.debug('Error------>>>>>'+errorMessage);
        System.assertEquals(errorMessage,'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Raise a request under active policy: []');
    }

}