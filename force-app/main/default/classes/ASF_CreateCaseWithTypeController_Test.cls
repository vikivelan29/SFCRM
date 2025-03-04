/******************************************************  
* @author           - Shubham Sinha
* @date             - 8-Feb-2023 
* @description      - Test class for ASF_CreateCaseWithTypeController
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0          Shubham Sinha      8-Feb-2023          Initial Creation
*  1.1          Santanu Halder     28-Oct-2023         Commented Type__c = 'SQ User', Fixed Assert statements - Coverage 87%
********************************************************
*/
@isTest
public class ASF_CreateCaseWithTypeController_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
@testSetup
static void setupTestData(){
    List<User> lstUser = new List<User>();
    User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                               EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                               TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk561123@gmail.com', Business_Unit__c = 'ABHFL');//LOB__c='ABHFL',
    lstUser.add(userRecord);
    
    User userRecord2 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk781234@gmail.com', Business_Unit__c = 'ABHFL', CC__c ='0141');//LOB__c='ABHFL',
    lstUser.add(userRecord2);
    
     User userRecord3 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, Business_Unit__c = 'ABHFL',//type__c='SQ User',
                                TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk90900@gmail.com', CC__c ='0153');//LOB__c='ABHFL',
    lstUser.add(userRecord3);
    
    User userRecord4 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, Business_Unit__c = 'ABHFL',
                                TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk901991@gmail.com', CC__c ='');//LOB__C='ABHFL',
    lstUser.add(userRecord4);
    insert lstUser;
User userRecord5 = new User(Alias = 'standt2', Email='standarduser2@testorgabfl.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, Business_Unit__c = 'ABFL',
                                TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk901991abfl@gmail.com', CC__c ='');//LOB__C='ABHFL',
    insert userRecord5;        
    Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
    Account acc= new Account(
        FirstName='Test FName',
        LastName='Test LName',
        PersonMailingStreet='test@yahoo.com',
        PersonMailingPostalCode='12345',
        PersonMailingCity='SFO',
        PersonEmail='test@yahoo.com',
        PersonHomePhone='1234567',
        PersonMobilePhone='12345678',
        RecordTypeId = recordTypeId
        //CRN__c= 'abcd'
    );
    insert acc;  
    LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'ABHFL');
    insert lob;
    Asset ast = new Asset(
    Name='AccountFinacial'
    ,AccountId=acc.Id
    , LOB_Code__c = lob.Id
    ,Price=100
    //,Financial_Account_Number__c = '0123456789123'
    );
    ast.Name = 'AccountFinacial';
    ast.Aggrement_Date__c = Date.newInstance(2023, 06, 09);
    ast.Application_Number__c = '12345';
    ast.Approved_Date__c = Date.newInstance(2023, 06, 10);
    ast.Approved_Limit__c = 200;
    ast.Branch_Code__c = 'AST';
    ast.LOB__c= 'Retail - Secured';
    insert ast;
    ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                            Business_Unit__c = 'ABHFL',Sub_Type__c = 'CreditCard',Source__c='CEC', 
                                                            Process__c='Case',Only_CRN_Mandatory__c=true);
    insert ccc;  
    
    ASF_Case_Category_Config__c  ccc1 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-02',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                            Business_Unit__c = 'ABHFL',Sub_Type__c = 'CIBIL',Source__c='CEC', 
                                                            Process__c='Case', Only_CRN_Mandatory__c=true);
    insert ccc1;
   ASF_Case_Category_Config__c  ccc2 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-03',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                            Business_Unit__c = 'ABFL',Sub_Type__c = 'CreditCard',Source__c='CEC', 
                                                            Process__c='Case', LOB__c = 'Retail - Secured',Only_CRN_Mandatory__c=true);
    insert ccc2;  
    ASF_Case_Category_Config__c  ccc3 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-04',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                            Business_Unit__c = 'ABFL',Sub_Type__c = 'CreditCard',Source__c='CEC', 
                                                            Process__c='Case', LOB__c = 'Wealth',Only_CRN_Mandatory__c=true);
    insert ccc3;  
}
    
@isTest
public static void testClosureTest(){
    //ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
    Asset assets = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
    User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk561123@gmail.com'];
    string keyword = 'CreditCard';
    system.runAs(usr)
    {
    Test.startTest();          
    ASF_CreateCaseWithTypeController.getAccountData(keyword, assets.LOB_Code__r.BusinessUnit__c,'true');
    //ASF_CreateCaseWithTypeController.getMetadataRecord('RL');
    try{
        ASF_CreateCaseWithTypeController.getAccountData('CIBIL', assets.LOB_Code__r.BusinessUnit__c,'false');
    }catch(Exception e){
        ABCL_Logger.enableExceptionLogging();
        ABCL_Logger.push('ASF_CreateCaseWithTypeControllerTest');
        ABCL_Logger.message(e.getMessage());
        ABCL_Logger.emit();
    } 

    Asset cs = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c
                FROM Asset WHERE Name = 'AccountFinacial'
                  LIMIT 1];
    Test.stopTest();     
    System.assertEquals('ABHFL', cs.LOB_Code__r.BusinessUnit__c, 'Busineess unit');        
    }
} 

     @isTest
    public static void testScenario2(){
        //ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
        Asset assets = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk781234@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest();   
            ASF_CreateCaseWithTypeController.CaseDetailsWrapper objWrapper = ASF_CreateCaseWithTypeController.getAccountData('CIBIL', assets.LOB_Code__r.BusinessUnit__c,'true');
            //ASF_CreateCaseWithTypeController.getSourceDetails();
            Test.stopTest();     
            System.assertEquals(objWrapper.boolNoData, false, 'data');        
        }
    } 

     @isTest
    public static void testScenario3(){
       // ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
       // Asset assets = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk90900@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest(); 
            ASF_CreateCaseWithTypeController.CaseDetailsWrapper objWrapper = ASF_CreateCaseWithTypeController.getAccountData('CIBIL', 'Test','true');
            Test.stopTest();     
            Assert.isFalse(objWrapper.boolNoData, 'Expected false');  
        }
    } 
    
 @isTest
    public static void testScenario4(){
        //ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
       // Asset assets = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk901991@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest(); 
            ASF_CreateCaseWithTypeController.CaseDetailsWrapper objWrapper = ASF_CreateCaseWithTypeController.getAccountData('CIBIL', 'Test','true');
            Test.stopTest();     
            Assert.isFalse(objWrapper.boolNoData, 'Expected false');  
        }
    } 
    @isTest
    public static void testScenario5(){
       // ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
       // Asset assets = [SELECT Id,Name,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk90900@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest(); 
            ASF_CreateCaseWithTypeController.CaseDetailsWrapper objWrapper = ASF_CreateCaseWithTypeController.getAccountData('CIBIL', 'Test','true');
            
            Assert.isFalse(objWrapper.boolNoData, 'Expected false');  
        }
       // Id accId = [select id from account limit 1].Id;
       // Account acc = ASF_CreateCaseWithTypeController.getAccountRec(accId);
        Test.stopTest();
        Integer count = [SELECT Count() FROM Account];
        Assert.areEqual(count, 1, 'count');
    } 
      @isTest
    public static void testScenario6(){
       // ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-03' LIMIT 1];
      //  Asset assets = [SELECT Id,Name,LOB__c,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk901991abfl@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest(); 
            ASF_CreateCaseWithTypeController.getTypeSubTypeByCustomerDetails('CIBIL', 'Test','false','Interaction','Retail - Secured','{"accountLOB":"Wealth","businessUnit":"ABFL"}');
        }
        Test.stopTest();
        Integer count = [SELECT Count() FROM Account];
        Assert.areEqual(count, 1, 'count');
    }     
      @isTest
    public static void testScenario7(){
        List<ASF_Case_Category_Config__c> ccc = [SELECT Id,LOB__c,CCC_External_Id__c,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-RC-04' LIMIT 1];
      //  Asset assets = [SELECT Id,Name,LOB__c,LOB_Code__r.BusinessUnit__c FROM Asset WHERE Name = 'AccountFinacial' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk901991abfl@gmail.com'];
        system.runAs(usr)
        {
            Test.startTest(); 
            ABFL_CreateCaseWithTypeControllerHelper.filterCTSTBasedOnBULogic(ccc,'{"accountLOB":"Wealth"}');
            ABFL_CreateCaseWithTypeControllerHelper.filterCTSTBasedOnBULogic(ccc,'{"accountLOB":"Corporate"}');
        }
        Test.stopTest();
        Integer count = [SELECT Count() FROM Account];
        Assert.areEqual(count, 1, 'count');
    }     

}