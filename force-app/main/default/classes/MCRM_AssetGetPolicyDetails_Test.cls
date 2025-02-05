@isTest
public class MCRM_AssetGetPolicyDetails_Test {
    @TestSetup
    static void testData(){
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            HealthIDCardNumber__pc ='QU-24-4000-0053869-00,QU-24-5211-4061797-00,QU-24-5211-3970653-00',
            PersonMobilePhone='12345678'
        );
        insert acc;  
        List<Asset> assetListToInsert = new List<Asset>();
        Asset assetObj = new Asset();
        assetObj.Name = '981726345';
        assetObj.AccountId = acc.Id;
        assetObj.RM_Assignment__c = 'Processed';
        assetObj.Business_Unit__c ='Wellness';
        assetObj.ABHI_Policy_Id__c = 'QU-24-4000-0053869-00';
        assetListToInsert.add(assetObj);
        
        Asset assetObj2 = new Asset();
        assetObj2.Name = '981726345';
        assetObj2.AccountId = acc.Id;
        assetObj2.RM_Assignment__c = 'Processed';
        assetObj2.Business_Unit__c ='Wellness';
        assetObj2.ABHI_Policy_Id__c = 'QU-24-5211-4061797-00';
        assetListToInsert.add(assetObj2);
        
        insert assetListToInsert;
    }
    @isTest
    static void beforeUpdateContainsABFLTest(){
        List<Asset> assetRec = [SELECT Id,Name,ABHI_Policy_Id__c,Business_Unit__c FROM Asset];
        Test.startTest();
        List<Map<String, String>> resultData = MCRM_AssetGetPolicyDetails.getAssetData(assetRec[0].Id);
         Test.stopTest();
       
        system.assertEquals(2,resultData.size());
    }
}