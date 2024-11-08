/*********************************************************
*Class          :   ABSLAMC_BusinessLogic_HelperClassTest
*Author         :   Udit Singhal
*Created Date   :   04-09-2024
*Last Modified  :   04-09-2024
*@description   :   Test class for ABSLAMC_BusinessLogic_HelperClass
*********************************************************/
@isTest
public class ABSLAMC_BusinessLogic_HelperClassTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id
                                                        FROM Profile
                                                        WHERE name = 'System Administrator'
                                                        LIMIT 1];
    @TestSetup
    static void makeData(){
        Group slaGroup = new Group();
        
        slaGroup = new Group(
            Name = 'SLAManagerGroup', 
            DeveloperName = 'SLAManagerGroup'
        );
        insert slaGroup;
        
        User userRecord1 = new User(
            Alias = 'standt', 
            Email = 'stanrduserEmails@testorg.com', 
            EmailEncodingKey = 'UTF-8',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
			LOB__c = 'MF',
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567@gmail.com', 
            managerGroupId__c = slaGroup.Id
        );
        insert userRecord1;
        
        Test.startTest();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id);
        Test.stopTest();
        
        System.runAs(userRecord1){
            Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
        }
    }
    
    @IsTest(seeAllData = false)
    static void prePopulateFieldsBeforeInsert_Test() {
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            // Create common test Leads
            Lead newLead = new lead();
            newLead.RecordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ABSLAMC_Leads').getRecordTypeId();
            newLead.FirstName = 'FULLNAM2E';
            newLead.Lastname = 'name';
            newLead.MobilePhone = '1236547899';
            newLead.Email = 'Email2@gmail.com';
            newLead.PANNO__c = 'PANNO2';
            newLead.Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU;
			newLead.LOB__c = 'MF';
            insert newLead;

            Test.startTest();
            List<Lead> leadList = [SELECT Id, Line_Of_Business__c FROM Lead WHERE Id =:newLead.Id];
            Assert.areEqual(newLead.LOB__c, leadList[0].Line_Of_Business__c, 'Line_Of_Business__c field on lead record should have been populated');
            Test.stopTest();
        }
    }

    @IsTest(seeAllData = false)
    static void prePopulateFieldsBeforeUpdate_Test() {
        User userRecord = [SELECT Id, LOB__c
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            // Create common test Leads
            Lead newLead = new lead();
            newLead.RecordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ABSLAMC_Leads').getRecordTypeId();
            newLead.FirstName = 'FULLNAM2E';
            newLead.Lastname = 'name';
            newLead.MobilePhone = '1236547899';
            newLead.Email = 'Email2@gmail.com';
            newLead.PANNO__c = 'PANNO2';
            newLead.Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU;
			newLead.LOB__c = 'MF';
            newLead.Lead_Type__c = 'MF Transaction Related Outcall';
            newLead.Lead_Subtype__c = 'Activity - TRO SIP Expiry';
            insert newLead;

            newLead.LOB__c = 'PMS';
            newLead.Lead_Type__c = 'PMS Client Leads';
            newLead.Lead_Subtype__c = 'Activity - Client Interested To Invest';
            newLead.Status = 'Lost';
            update newLead;

            Test.startTest();
            List<Lead> leadList = [SELECT Id, Line_Of_Business__c FROM Lead WHERE Id =:newLead.Id];
            Assert.areEqual(userRecord.LOB__c.split(';')[0], leadList[0].Line_Of_Business__c, 'Line_Of_Business__c field on lead record should have been populated');
            Test.stopTest();
        }
    }

    @IsTest(seeAllData = false)
    static void closeEligibleLeads_Test() {
        User userRecord = [SELECT Id, LOB__c
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord) {
            // Create common test Leads
            Lead newLead = new lead();
            newLead.RecordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ABSLAMC_Leads').getRecordTypeId();
            newLead.FirstName = 'FULLNAM2E';
            newLead.Lastname = 'name';
            newLead.MobilePhone = '1236547899';
            newLead.Email = 'Email2@gmail.com';
            newLead.PANNO__c = 'PANNO2';
            newLead.Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU;
			newLead.LOB__c = 'MF';
            newLead.Lead_Type__c = 'MF Transaction Related Outcall';
            newLead.Lead_Subtype__c = 'Activity - TRO SIP Expiry';
            insert newLead;

            Conversion_Details__c conDetail = new Conversion_Details__c();
            conDetail.Lead__c = newLead.Id;
            conDetail.Business_Unit__c = 'ABSLAMC';
            conDetail.Converted_Flag__c = true;
            conDetail.Folio_Number__c = '100100';
            conDetail.Scheme_Code__c = '123434';
            conDetail.Scheme_Name__c = 'Test Schme';
            conDetail.Asset_Class__c = 'Test Asset Class';
            conDetail.Investment_date__c = Date.newInstance(2024,08,29);
            conDetail.Conversion_Amount__c = 1000000;
            conDetail.Transaction_Type__c = 'Test Type';
            conDetail.SIP_or_Lumpsum_flag__c = 'Test psum flag';
            conDetail.SIP_From_Date__c = Date.newInstance(2024,08,29);
            conDetail.SIP_To_Date__c = Date.newInstance(2024,09,30);
            conDetail.ARN_Code__c = 'ABDKS';
            conDetail.Broker_Name__c = 'Test Name';
            conDetail.Transaction_Source__c = 'Test Source';
            insert conDetail;

            Test.startTest();
            List<Lead> leadList = [SELECT Id, Status, Line_Of_Business__c FROM Lead WHERE Id =:newLead.Id];
            Assert.areEqual('Won', leadList[0].Status, 'Status of the lead should have been changed to Won');
            Test.stopTest();
        }
    }
}