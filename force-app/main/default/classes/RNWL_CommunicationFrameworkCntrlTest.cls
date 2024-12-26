/*******************************************************
*Class          :  RNWL_CommunicationFrameworkCntrlTest
*Author         :  Gaurav Sharma
*Created Date   :  21/10/2024
*Last Modified  :  21/10/2024
*@description   :  Test class for RNWL_CommunicationFrameworkController
********************************************************/
@isTest
public class RNWL_CommunicationFrameworkCntrlTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        
        insert objUser;
        
        Account acc = RNWL_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        
        Asset asset = RNWL_TestDataFactory.createAsset(acc.Id,''); 
        Contact con = new Contact(FirstName='Test' ,LastName= 'Con' , AccountId=acc.Id);
        Insert con;
        
        RNWL_TestDataFactory.insertBusinessAccount('test before opp', 'strCRN');  
        
        
    }
    
    @isTest
    private static void rNWL_RenewalCustomerPolicyInfo_Test(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity opp = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        List<RNWL_Communications__mdt> mdt= RNWL_CommunicationFrameworkController.fetchCommunicationMDT();
        RNWL_Communications__mdt mdt2;
        for(RNWL_Communications__mdt md : mdt){
            if(md.Metadata_Name__c=='RNWL_Winback_Whatsapp') mdt2 = md;
        }
        system.debug(mdt);
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = opp.AccountId, Opportunity_ID__c = opp.Id,
                                                       RecordID__c = opp.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = mdt2.Metadata_Name__c,
                                                       Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = true,
                                                       Specific_To_Address__c = 'joshnareddy90@gmail.com;joshnareddy902@gmail.com',
                                                       CC_Addresses__c = 'jpalla@salesforce2.com;jpalla@salesforce3.com', Email_Template_Name__c = 'RNWL_Change_in_personal_details');
        insert peLoggerRecord;
        
        
        
        
        RNWL_CommunicationFrameworkController.RequestWrapper wrapper = new RNWL_CommunicationFrameworkController.RequestWrapper();
        wrapper.selectedTemplate = mdt2.Metadata_Name__c;
        wrapper.opportunityId = opp.Id;
        wrapper.notificationMode = 'Email';
        wrapper.toAddresses = 'test@test.com';
        wrapper.ccAddresses = 'test@test.com';
        
        
        
        Test.startTest();
        try{
            RNWL_CommunicationFrameworkController.notifyUsers(JSON.serialize(wrapper));
        }catch(Exception e){
            
        }
        
        wrapper.selectedTemplate = mdt[1].Metadata_Name__c;
        RNWL_CommunicationFrameworkController.notifyUsers(JSON.serialize(wrapper));
        
        Test.stopTest();
        
    }
}