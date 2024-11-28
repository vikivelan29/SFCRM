/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-30-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class ABSLI_PolicyDynamicButtonsControllerTest {
    @isTest
    public static void getServAceUrl(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLLtest','Test_1');
        Asset policy = new Asset();
        policy.Name = '000000001';
        policy.Policy_No__c = '000000001';
        policy.LAN__c = 'ABSLI_000000001';
        policy.Business_Unit__c = 'ABSLI';
        policy.AccountId = accRec.Id;
		
        Test.StartTest();
        insert policy;
        
        ABSLI_PolicyDynamicButtonsController.getServAceUrl(policy.Id);
        ABSLI_PolicyDynamicButtonsController.getCommunicationLink(policy.Id);
        Test.StopTest();
    }

}