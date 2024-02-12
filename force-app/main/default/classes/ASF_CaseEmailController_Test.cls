/*********************************************************
*Class        :  ASF_CaseEmailController_Test
*Author       :  Anjali Sharma
*Description  :  Test class for ASF_CaseEmailController
*********************************************************/

@IsTest
public class ASF_CaseEmailController_Test {
    @TestSetup
    static void setUpData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];  
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8); 
        User u = new User(Alias = uid, Email= uid + '@testdomain.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_IN', ProfileId = p.Id, 
                          TimeZoneSidKey='Asia/Kolkata', UserName= uid + '@testdomain.com'); 
        insert u;
        PermissionSetGroup psg = [select Id, Status from PermissionSetGroup where DeveloperName='Super_Admin'];
        
        if(psg.Status != 'Updated'){
            Test.calculatePermissionSetGroup(psg.Id);
            insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = u.Id);
        }
        
        System.runAs(u){
            Case caseRecord = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator', Business_Unit__c = 'ABHFL');
            insert caseRecord;
            Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
            Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
            astRec.LAN__c = 'Test';
            astRec.Last_Disbursement_Date__c = Date.Today();
            update astRec;
            
            
            ABHFL_Asset_Detail__c detailRec = new ABHFL_Asset_Detail__c();
            detailRec.Asset__c = astRec.Id;
            detailRec.LAN__c = '2322-21332';
            detailRec.case__c = caseRecord.Id;
            detailRec.Current_Balance__c = 5555;
            detailRec.Amount_Overdue__c = 5689;  
            insert detailRec;
            
            ABHFL_Case_Detail__c caseExtension = new ABHFL_Case_Detail__c();
            caseExtension.Case__c=caseRecord.id;
            //caseExtension.EMI_Tenure__c=3;
            caseExtension.As_On_Date__c = Date.newInstance(2023, 12, 12);
            caseExtension.Part_Payment_Amount__c=100;
            caseExtension.Payable_Charges__c=1000;
            caseExtension.Realization_status__c='Cleared';
            insert caseExtension;
            
            caseRecord.ABHFL_Case_Detail__c = caseExtension.Id;
            caseRecord.AssetId = astRec.Id;
            update caseRecord;
        }
    }
    @IsTest
    static void testGetOutputBody() {
        EmailTemplate lightningEmailTempalte = new EmailTemplate();
        lightningEmailTempalte.isActive = true;
        lightningEmailTempalte.Name = 'TestLightning';
        lightningEmailTempalte.HtmlValue = '<html style="overflow-y: hidden;"> <body> <table> <tbody> <tr> <td> <div> $$ABHFL_Case_Detail__r.As_On_Date__c$$ -- $$Asset.Last_Disbursement_Date__c$$.  --- ##Asset_Details__r.case__c## --- @@ Test multiple lans ##Asset_Details__r.Lan__c## @@ </div> </td> </tr> </tbody> </table> </body> </html>';
        lightningEmailTempalte.DeveloperName = 'TestVf_un';
        lightningEmailTempalte.TemplateType = 'custom';
        lightningEmailTempalte.FolderId = UserInfo.getUserId();
        insert lightningEmailTempalte;
        
        
        Case rec = [select id from case limit 1];
        ASF_CaseEmailController asf = new ASF_CaseEmailController();
        asf.caseId = rec.Id;
        asf.emailTemplateName = 'TestLightning';
        String outputString = asf.getOutputBody();
        SYstem.debug('outputString   ---   '+ outputString);
        System.assertEquals(true, outputString.contains('2023-12-12'));    
    }
}