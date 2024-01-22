/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 01-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-11-2024   rsinghnagar@salesforce.com   Initial Version
**/
@IsTest
private class ABCL_Logger_Test {
    @IsTest
    public static void logGeneralExceptionTest() {
        Test.startTest();
        ABCL_Logger.push('MyClass.methodA');
        insert new Account(Name = 'Test');
        ABCL_Logger.push('MyClass.methodB');
        ABCL_Logger.message('Doing something');
        insert new Account(Name = 'Test');
        ABCL_Logger.pop();
        List<Account> accounts = [select Id from Account];
        ABCL_Logger.message('Doing something more');        
        ABCL_Logger.pop();
        ABCL_Logger.emit();
        // EventBus.publish(new Log__e(
        //         Title__c = ' Data Upload Statistics',
        //         Insertion_Statistics__c = true,
        //         Data__c = DateTime.now() + 'hello'));
        Test.stopTest();
    }

    @IsTest
    public static void logExceptionTest() {
        Test.startTest();
        ABCL_Logger.enableExceptionLogging();
        ABCL_Logger.push('MyClass.methodA');
        insert new Account(Name = 'Test');
        ABCL_Logger.push('MyClass.methodB');
        ABCL_Logger.message('Doing something');
        insert new Account(Name = 'Test');
        ABCL_Logger.pop();
        List<Account> accounts = [select Id from Account];
        ABCL_Logger.message('Doing something more');        
        ABCL_Logger.pop();
        ABCL_Logger.emit();
        
        ABCL_Logger.enableExceptionLogging();
        ABCL_Logger.message('MyClass.methodA');
        ABCL_Logger.emit();
        Test.stopTest();
    }
}