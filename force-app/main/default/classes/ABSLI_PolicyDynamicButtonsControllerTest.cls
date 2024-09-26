@isTest
public class ABSLI_PolicyDynamicButtonsControllerTest {
    @isTest
    public static void getServAceUrl(){
        Asset policy = new Asset();
        policy.Name = '000000001';
        policy.Policy_No__c = '000000001';
        policy.LAN__c = 'ABSLI_000000001';
        policy.Business_Unit__c = 'ABSLI';
		
        Test.StartTest();
        insert policy;
        
        ABSLI_PolicyDynamicButtonsController.getServAceUrl(policy.Id);
        ABSLI_PolicyDynamicButtonsController.getCommunicationLink(policy.Id);
        Test.StopTest();
    }

}