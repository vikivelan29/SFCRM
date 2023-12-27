/*********************************************************
*Class        :  ASF_CaseEmailController_Test
*Author       :  Anjali Sharma
*Description  :  Test class for ASF_CaseEmailController
*********************************************************/

@IsTest
public class ASF_CaseEmailController_Test {
    @TestSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, PAY_Payment_Detail__c, PAY_Payment_Detail__r.Payment_mode__c,
                           SLA_Target_1__c, CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c, Reopen_Days__c,Reopened__c,ABHFL_Case_Detail__r.EMI_Tenure__c  from case LIMIT 1];
        
        ABHFL_Case_Detail__c caseExtension = new ABHFL_Case_Detail__c();
        caseExtension.Case__c=caseRecord.id;
        caseExtension.EMI_Tenure__c=3;
        caseExtension.As_On_Date__c = Date.newInstance(2023, 12, 12);
        caseExtension.Part_Payment_Amount__c=100;
        caseExtension.Payable_Charges__c=1000;
        caseExtension.Realization_status__c='Cleared';
        insert caseExtension;

        caseRecord.ABHFL_Case_Detail__c = caseExtension.Id;
        update caseRecord;


        
    }
    @IsTest
    static void testGetOutputBody() {
        EmailTemplate lightningEmailTempalte = new EmailTemplate();
        lightningEmailTempalte.isActive = true;
        lightningEmailTempalte.Name = 'TestLightning';
        lightningEmailTempalte.HtmlValue = '<html style="overflow-y: hidden;"> <body> <table> <tbody> <tr> <td> <div> $$ABHFL_Case_Detail__r.As_On_Date__c$$ </div> </td> </tr> </tbody> </table> </body> </html>';
        lightningEmailTempalte.DeveloperName = 'TestVf_un';
        lightningEmailTempalte.TemplateType = 'custom';
        lightningEmailTempalte.FolderId = UserInfo.getUserId();
        insert lightningEmailTempalte;


        Case rec = [select id from case limit 1];
        ASF_CaseEmailController asf = new ASF_CaseEmailController();
        asf.caseId = rec.Id;
        asf.emailTemplateName = 'TestLightning';
        String outputString = asf.getOutputBody();
        System.assertEquals(true, outputString.contains('2023-12-12'));    
    }
}