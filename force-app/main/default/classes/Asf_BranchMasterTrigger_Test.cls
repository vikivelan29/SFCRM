@IsTest
public class Asf_BranchMasterTrigger_Test {
    @TestSetup
    static void setup() {
            Group g1 = new Group(Name='TestGroup1', type='Queue');     
            insert g1;
            Group g2 = new Group(Name='Test-Group', type='Queue');
            insert g2;
            Branch_Master__c bm = new Branch_Master__c(Name = 'testBranchMaster1', UniqueKey__c = '234234',Branch_Queue_Name__c = 'Test-Group');      
			insert bm;
            Branch_Master__c bm1 = new Branch_Master__c(Name = 'testBranchMaster1', UniqueKey__c = '2342345',Branch_Queue_Id__c = '12345678');      
			insert bm1;
    }

    @IsTest
    static void testBeforeInsert() {
        Branch_Master__c bm = new Branch_Master__c(Name = 'testBranchMaster', UniqueKey__c = '23456',Branch_Queue_Name__c = 'TestGroup1', Business_Unit__c = ABHFL_Constants.BUSINESS_UNIT_ABHFL);      
        Test.startTest();
        insert bm;
        bm = [select id, Branch_Queue_Id__c from Branch_Master__c where Branch_Queue_Name__c = 'TestGroup1' limit 1];
        System.assertEquals(true, bm.Branch_Queue_Id__c != null);
        Test.stopTest();
    }


    @IsTest
    static void testBeforeUpdate() {  
        Branch_Master__c bm = [select id, Business_Unit__c, Branch_Queue_Id__c from Branch_Master__c where Branch_Queue_Name__c = 'Test-Group' limit 1];
        bm.Business_Unit__c = ABHFL_Constants.BUSINESS_UNIT_ABHFL;
        Test.startTest();
        update bm;
        bm = [select id, Branch_Queue_Id__c from Branch_Master__c where Branch_Queue_Name__c = 'Test-Group' limit 1];
        System.assertEquals(true, bm.Branch_Queue_Id__c!= null);
        Test.stopTest();
    }
}