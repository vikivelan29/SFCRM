@isTest
public class RNWL_Communications_ValidationsTest {
    
    @TestSetup
    public static void setup(){
        
        Account acc = RNWL_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        Asset asset = RNWL_TestDataFactory.createAsset(acc.Id,''); 
        Opportunity opp = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        
        
    }
    
    @isTest
    private static void call_ExpiredTest(){
        Asset asset = [SELECT Id, Maturity_Date__c FROM Asset LIMIT 1];
        asset.Maturity_Date__c = System.today();
        update asset;
        
        Opportunity opp = [SELECT Id, Policy_Expiry_Date__c FROM Opportunity LIMIT 1];

        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = opp.Id;
                requestInst.methodName = 'policyExpirySMSValidation';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
             }
        Test.stopTest();
        System.assertNotEquals('', result, 'Uh Oh! the error is not thrown');
    }
    
    @isTest
    private static void call_WinBackTest(){
        Asset asset = [SELECT Id, Maturity_Date__c FROM Asset LIMIT 1];
        asset.Maturity_Date__c = System.today()+365;
        update asset;
        
        Opportunity opp = [SELECT Id, Policy_Expiry_Date__c FROM Opportunity LIMIT 1];

        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = opp.Id;
                requestInst.methodName = 'winBackSMSValidation';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
             }
        Test.stopTest();
        System.assertNotEquals('', result, 'Uh Oh! the error is not thrown');
    }

    @isTest
    private static void call_WinBackWhatsAppTest(){
        Asset asset = [SELECT Id, Maturity_Date__c FROM Asset LIMIT 1];
        asset.Maturity_Date__c = System.today()+365;
        update asset;
        
        Opportunity opp = [SELECT Id, Policy_Expiry_Date__c FROM Opportunity LIMIT 1];

        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = opp.Id;
                requestInst.methodName = 'winBackWhatsAppValidation';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
             }
        Test.stopTest();
        System.assertNotEquals('', result, 'Uh Oh! the error is not thrown');
    }

    @isTest
    private static void call_WinBackWhatsAppCallingSourceTest(){
        Asset asset = [SELECT Id, Maturity_Date__c FROM Asset LIMIT 1];
        asset.Maturity_Date__c = System.today() - 10;
        update asset;
        Opportunity opp = [SELECT Id, Calling_Source__c, Policy_Expiry_Date__c FROM Opportunity LIMIT 1];
        opp.Calling_Source__c = 'ATS';
        update opp;

        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = opp.Id;
                requestInst.methodName = 'winBackWhatsAppValidation';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
             }
        Test.stopTest();
        System.assertNotEquals('', result, 'Uh Oh! the error is not thrown');
    }

    @isTest
    private static void call_NullOppTest(){
        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = '006Bl00000CyMqbIAF';
                requestInst.methodName = 'test';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});

             }
        Test.stopTest();
        System.assertNotEquals('', result, 'Uh Oh! the error is not thrown');
    }

    @isTest
    private static void call_WithoutMethodName(){
        Opportunity opp = [SELECT Id, Calling_Source__c, Policy_Expiry_Date__c FROM Opportunity LIMIT 1];

        RNWL_CommunicationFrameworkController.RequestWrapper requestInst = 
            new RNWL_CommunicationFrameworkController.RequestWrapper();
                requestInst.className = 'RNWL_Communications_Validations'; 
                requestInst.opportunityId = opp.Id;
                requestInst.methodName = 'testcommMethod';
        String result = '';
        Test.startTest();
             if (requestInst.className != null && requestInst.methodName != null) {
                    Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                    try {
                        result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
                    } catch (Exception ex) {}
             }
        Test.stopTest();
    }
}