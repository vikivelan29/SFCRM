/**
* @Class name:      ASF_SMSCommunicationParser_Test
* @Description:     
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee Churiwala             1.0       22/11/2023              #
*/
@isTest
public class ASF_SMSCommunicationParser_Test {
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      setup
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
	@TestSetup
    public static void setup() {
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        Account a = new Account();
        a.Name = '12345';
        //a.CRN__c = '12344';
        insert a;
        
        Lead leads = new Lead(FirstName = 'test', lastName = 'data', MobilePhone = '0000000000',PANNO__c = 'ABCDE1234E');
        insert leads;
        
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = '12345';
        ccc.Business_Unit__c = 'ABFL';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        ccc.SMS_Templates__c = 'PAYMENT_SR_CLOSED,PAYMENT_SR_CREATED,PAYMENT_SR_CLOSED_TRANSACTIONS';
        ccc.Send_SMS__c = true;
        insert ccc;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = a.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        insert con;
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
	        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        Case cs = new Case();
        cs.AccountId = a.Id;
        cs.Lead__c = leads.Id;
        cs.CCC_External_Id__c = '12345';
        cs.contactId = con.Id;
        cs.Status = 'New';
        cs.Stage__c='New';
        insert cs;
        
        List<Contact> cont = [select id from Contact limit 1];
    }    
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      getListOfContactTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void getListOfContactTest(){
        List<Case> cases = [select id from Case limit 1];
        
        test.startTest();
        	List<ASF_SMSCommunicationParser.ASF_ContactDetailsWrapper> wrapper = ASF_SMSCommunicationParser.getListOfContact(cases[0].Id);
        test.stopTest();
        //system.assertEquals(wrapper.size(), 1);
    }
    /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      getListOfTemplateTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void getListOfTemplateTest(){
        List<Case> cases = [select id from Case limit 1];
        
        test.startTest();
        	List<ASF_SMSCommunicationParser.ASF_SMSTemplateWrapper> wrapper = ASF_SMSCommunicationParser.getListOfTemplate(cases[0].Id);
        test.stopTest();
        system.assertEquals(cases.size(), 1);
    }
        /********************************************************************************************************
    * @author           Salesforce
    * @date             22/11/2023
    * @description      isCommunicationEnabledTest
    * @Paramters        
    * @return           void
    *********************************************************************************************************/
    @isTest
    public static void isCommunicationEnabledTest(){
        List<Case> cases = [select id from Case limit 1];
        
        test.startTest();
			Boolean isCommunicationEnabled = ASF_SMSCommunicationParser.isCommunicationEnabled(cases[0].Id);
        test.stopTest();
        Assert.isTrue(isCommunicationEnabled);
    }
    
}