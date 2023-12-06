@IsTest
public class ASF_CasePreFrameworkTriggerHelper_Test {
	private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @IsTest
    static void populatePreFrameworkFieldsTest(){
        Test.startTest();
        try{
            ASF_TestDataFactory.createCaseCategoryConfig();
            List<Case> lstCase = ASF_TestDataFactory.createCaseRecords(1);
            Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
            for(Case c:lstCase){
                c.RecordTypeId = interactionId;
                c.Origin = 'Payments Email';
                c.suppliedEmail = 'test@sales.com';
            }

            Configuration__c cf = new Configuration__c();
            cf.Active__c = true;
            cf.Exclusion_Email__c = 'test@sales.com';
            cf.domain_name__c = 'sales.com';
            cf.RecordTypeId = Schema.SObjectType.Configuration__c.getRecordTypeInfosByDeveloperName().get('Exclusion_Emails').getRecordTypeId();
            insert cf;
            
            ASF_CasePreFrameworkTriggerHelper helperObj = new ASF_CasePreFrameworkTriggerHelper();
			map<Id, case> caseMap = new Map<Id,case>();
            for(Case c: lstCase){
                caseMap.put(c.Id,c);
            }            
            if(lstCase.size() > 0){
            	helperObj.populatePreFrameworkFields(lstCase); 
                helperObj.populateStageFields(lstCase);
                helperObj.caseSLAHistoryAfterInsert(caseMap);
            }
            
        }
        catch(Exception ex){
            system.assertEquals(ex.getMessage(), ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void populatePreFrameworkFieldsSecondTest(){
        Test.startTest();
        try{
            ASF_TestDataFactory.createCaseCategoryConfig();
            List<Case> lstCase = ASF_TestDataFactory.createCaseRecords(1);
            Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
            for(Case c:lstCase){
                c.RecordTypeId = interactionId;
                c.Origin = 'Payments Email';
                c.suppliedEmail = 'test@sales.com';
            }
            
            Configuration__c cf1 = new Configuration__c();
            cf1.Active__c = true;
            cf1.Exclusion_Email__c = 'nontest@sales.com';
            cf1.domain_name__c = 'sales.com';
            cf1.RecordTypeId = Schema.SObjectType.Configuration__c.getRecordTypeInfosByDeveloperName().get('Priority_domain').getRecordTypeId();
            //cf.ExclusionSubjectKeyword__c = 'Complaint';
            insert cf1;
            
            ASF_CasePreFrameworkTriggerHelper helperObj = new ASF_CasePreFrameworkTriggerHelper();
            
            if(lstCase.size() > 0){
            	helperObj.populatePreFrameworkFields(lstCase);
            }
            
        }
        catch(Exception ex){
            system.assertEquals(ex.getMessage(), ex.getMessage());
        }
        Test.stopTest();
    }
}