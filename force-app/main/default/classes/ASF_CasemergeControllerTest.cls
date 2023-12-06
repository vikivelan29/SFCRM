@isTest
private class ASF_CasemergeControllerTest {
    @testSetup static void setup() {
       Account acc =new Account();
        acc.Name= 'TestAcc';
       // acc.CRN__c ='32122';
        Insert acc;
        list<Case> cList =new List<Case>();
        Case caseRec = new Case();
		caseRec.AccountId =acc.Id;
        caseRec.Subject ='testMergeSubject';
        caseRec.Description ='testdescription';
        caseRec.Stage__c ='New';
        caseRec.Status ='New';
        caseRec.SuppliedEmail ='test@salesforce.com';
        cList.add(caseRec);
        Case mastercaseRec = new Case();
		mastercaseRec.AccountId =acc.Id;
        mastercaseRec.Subject ='testMergeSubject';
        mastercaseRec.Description ='testmasterdescription';
        mastercaseRec.Stage__c ='New';
        mastercaseRec.Status ='New';
        caseRec.SuppliedEmail ='test@salesforce.com';
        cList.add(mastercaseRec);
        Insert cList;  
    }
    
    @isTest static void testfetchCases() {
        test.startTest();
        list<Case> caseRecords =[Select Id,CaseNumber,Stage__c,Status,Subject,Origin,SuppliedEmail from Case];
        Case masterCase =caseRecords[0];
        ASF_CasemergeController.fetchCases(masterCase.Id,masterCase.Subject,masterCase.SuppliedEmail);
        list<Case> selectedCase =new List<Case>();
        selectedCase.add(caseRecords[1]);
       // selectedCase.add(caseRecords[2]);
        ASF_CasemergeController cntrlr=new ASF_CasemergeController();
        ASF_CasemergeController.mergeCases(selectedCase,masterCase.Id);
        try{
            ASF_CasemergeController.mergeCases(selectedCase,masterCase.CaseNumber);
        }
        catch(exception ex){
            system.assertNotEquals(null, ex.getMessage());
        }
        test.stopTest();
    }
    
}