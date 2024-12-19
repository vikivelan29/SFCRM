@isTest
public class ASF_SendPreFrameworkCaseToLOBTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    
    @IsTest
    static void getPriorityEmailList(){
        Test.startTest();
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmails= ASF_SendPreFrameworkCaseToLOB.getPriorityEmailList();
        Test.stopTest();
        System.assertEquals(priorityEmails.size()>0,true , 'Found Priority Emails');
    }
    
    @IsTest
    static void updateCase(){
        Test.startTest();
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> lstCase = ASF_TestDataFactory.createCaseRecords(1);
        Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
        for(Case c:lstCase){
            c.RecordTypeId = interactionId;
            c.Origin = 'ABCD Email';
            c.Business_Unit__c = 'ABCD';
            c.suppliedEmail = 'test@sales.com';
        }
        
        update lstCase;
        
        EmailMessage emsg = new EmailMessage();
        emsg.ParentId = lstCase[0].Id;
        emsg.Incoming = true;
        insert emsg;
        
        
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmails= ASF_SendPreFrameworkCaseToLOB.getPriorityEmailList();
        ASF_PriorityEmailAddressesByBU__mdt cmdEbotEnabled = new ASF_PriorityEmailAddressesByBU__mdt();
        for(ASF_PriorityEmailAddressesByBU__mdt cmd : priorityEmails){
            if(cmd.Send_to_EBOT__c == true){
                cmdEbotEnabled = cmd;
                break;
            }
        }
        
        ASF_SendPreFrameworkCaseToLOB.updateCase(lstCase[0].Id,cmdEbotEnabled.Id);
        Test.stopTest();
        System.assertEquals(priorityEmails.size()>0,true , 'Found Priority Emails');
    }
    
    
}