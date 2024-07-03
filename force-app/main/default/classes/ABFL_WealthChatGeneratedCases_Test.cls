/*********************************************************
*Class        :  ABFL_WealthChatGeneratedCases_Test
*Author       :  Salesforce 
*Created Date :  14/04/2024
*Last Modified:  14/04/2024
*Description  :  Test class for  ABFL_WealthChatGeneratedCases class
*********************************************************/

@isTest
public class ABFL_WealthChatGeneratedCases_Test {
    @isTest 
    public static void testWealthChatGeneratedCases(){
        
        Case newCase = new Case();
        newCase.Subject = 'Test Wealth Chat Cases';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        newCase.Origin = ABFL_Constants.WMCHATCASEORIGIN;
        insert newCase;
        
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.Subject = 'Test Wealth Chat Cases';
        email.HtmlBody = 'This is test email with new name.. Email ID: test@gmail.com 8309u90 Mobile No . 9722392312  thanks ';
        email.ParentId = newCase.Id; 
        email.Headers = '';
        insert email;

        Case currentCase = [select Id, SuppliedEmail, SuppliedPhone from Case where Id =:newCase.Id ];
        System.assertEquals('test@gmail.com', currentCase.SuppliedEmail, 'Email should Match');
    }
    @isTest
    public static void testWealthChatGeneratedCasesNegative(){
        
        Case newCase = new Case();
        newCase.Subject = 'Test case';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        
        insert newCase;
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.Subject = 'Test case';
        email.HtmlBody = 'This is test email with new name..';
        email.ParentId = newCase.Id; 
        email.Headers = 'teestheader';
        insert email;

        Case currentCase = [select Id, SuppliedEmail, SuppliedPhone from Case where Id =:newCase.Id ];
        System.assertNotEquals('test@gmail.com', currentCase.SuppliedEmail, 'Email should Match');
        System.assertEquals(null, currentCase.SuppliedPhone, 'Phone should be null');
    }
    
}