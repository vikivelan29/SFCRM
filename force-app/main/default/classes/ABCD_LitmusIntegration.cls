/**
* @description Outbound Callout to Withdrawal Policy of a Customer
*
* @author Siddarth Jaitly
* @date 2024-12-09
*/
public with sharing class ABCD_LitmusIntegration {
    public static Map<Id,Boolean> isExecuted = new Map<Id,Boolean>();
    public Static void evaluateCasesForLitmus(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap){
        Set<Id> setExpectedLogic = new Set<Id>();
        Set<String> cccExternalIdSet = new Set<String>();
        Map<Id, Case> caseIdToRecordMap = new Map<Id, Case>();
        Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();
        List<Case> litmusApiCasesList = new List<Case>();
        List<Case> eligibleCases = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> prospectIds = new Set<Id>();
        Map<Id,Contact> mAccountPrimaryContact = new Map<Id,Contact>();
        
        // CONDITION 1 - CHECK IF CASE IS CLOSED AND CASE STATUS IS RESOLVED.
        for (Case caseRec : newCaseMap.values()){
            if(((caseRec.IsClosed == true && (oldCaseMap.get(caseRec.Id).IsClosed != true) && ASF_Constants.RESOLVEDSTAGES.contains(caseRec.Status)) || 
               ASF_Constants.RESOLVEDSTAGES.contains(caseRec.Stage__c)) ){
                   if(!isExecuted.containskey(caseRec.Id)){
                        setExpectedLogic.add(caseRec.Id);
                        cccExternalIdSet.add(caseRec.CCC_External_Id__c);
                        isExecuted.put(caseRec.Id,true);
                   }
               } 
        }
        
        if(!setExpectedLogic.isEmpty()){
            for (ASF_Case_Category_Config__c cccRecord :[SELECT Id, CCC_External_Id__c, Litmus_Trigger__c, Litmus_Project__c,LOB__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExternalIdSet WITH SYSTEM_MODE]) {
                cccIdToRecordsMap.put(cccRecord.CCC_External_Id__c, cccRecord);
            }
            
            caseIdToRecordMap = new Map<Id, Case> ([SELECT Id, Status, IsClosed, FTR__c,CaseNumber, AccountId, AssetId, LAN__c,CreatedDate,LastModifiedDate,Lead__c,ClosedDate, Business_Unit__c,CreatedBy.Name, 
                                                    Stage__c,Nature__c, Type_Text__c, Sub_Type_Text__c,CCC_External_Id__c, LOB__c, Source__c,Channel__c,Owner.Name,Account.RecordType.Name, Account.PAN__c,
                                                    Account.IsPersonAccount,Account.Name, Account.Full_Name__pc,Account.PersonMobilePhone, Account.Phone,Account.PersonEmail, Account.Office_Email__c,
                                                    Account.City__c, Account.Client_Code__c,Asset.Product2.Name, Asset.LAN__c,Asset.Policy_No__c,Asset.Issue_Date__c,Asset.Status,Asset.Type__c,
                                                    Asset.Channel__c,Asset.Advisor__c,Asset.Advisor__r.Advisor_Code__c,Asset.Advisor__r.Advisor_Status__c,Asset.Advisor__r.Agent_Sub_Category__c,
                                                    Account.Nationality__pc,Account.Customer_Segment__c,Account.PersonBirthdate,Account.Occupation__c,Account.PersonGenderIdentity,ABCD_Case_Detail__c,
                                                    ABCD_Case_Detail__r.Function__c,SuppliedEmail,SuppliedName,SuppliedPhone 
                                                    FROM Case WHERE Id IN :setExpectedLogic WITH SYSTEM_MODE]);
            
            for (Case caseRecord : caseIdToRecordMap.values()){
                // CONDITION 2 - CHECK IF THE CCC RECORD IS HAVING LITMUS TRIGGER = TRUE.
                if(cccIdToRecordsMap.containsKey(caseRecord.CCC_External_Id__c)){
                    ASF_Case_Category_Config__c cccRecord = cccIdToRecordsMap.get(caseRecord.CCC_External_Id__c);
                    if(cccRecord.Litmus_Trigger__c == true){
                        if(caseRecord.AccountId != null){
                            accountIds.add(caseRecord.AccountId);
                        }
                        if(caseRecord.Lead__c != null){
                            prospectIds.add(caseRecord.Lead__c);
                        }
                        
                        eligibleCases.add(caseRecord);
                    }
                }
            }
        }
        Map<Id,Lead> prospectMap = new Map<Id,Lead>();
        if(accountIds.size()>0){
            // CODE TO GET THE DETAILS FROM CONTACT - IN CASE OF PERSONACCOUNT, CONTACT RECORD GETS CREATED, IN CASE OF BUSINESS ACCOUNT CONTACT TO BE LOADED.
            for(Contact c : [SELECT ID,Nationality__c,Birthdate,MobilePhone,Email,AccountID,Name FROM Contact WHERE AccountId =: accountIds]){
                if(!mAccountPrimaryContact.containsKey(c.AccountId)){
                    mAccountPrimaryContact.put(c.AccountId,c);
                } 
            }

            prospectMap = new Map<Id,Lead>([SELECT Id,Email,Name,MobilePhone FROM Lead WHERE Id IN : prospectIds]);

            for(Case c : eligibleCases){
                // CONDITION 3 - CHECK FOR MOBILE NUMBER
                string phone = '';
                if(c.AccountID != null){
                    if(mAccountPrimaryContact.containsKey(c.AccountId)){
                        Contact accountPrimaryContact = mAccountPrimaryContact.get(c.AccountId);
                        phone = accountPrimaryContact.MobilePhone;
                    }
                } else if(c.Lead__c != null){
                    Lead prospect = prospectMap.get(c.Lead__c);
                    phone = prospect.MobilePhone;
                } else {
                    phone = c.SuppliedPhone;
                }
                if(String.isNotBlank(phone)){
                    litmusApiCasesList.add(c);
                }
            }  
        }
        if(litmusApiCasesList.size()>0){
            callLitmusAPI(litmusApiCasesList,mAccountPrimaryContact,prospectMap,cccIdToRecordsMap);
            Set<Id> caseDetailIds = new Set<Id>();
       
            for (Case litmusCase : litmusApiCasesList) {
                if (litmusCase.ABCD_Case_Detail__c != null) {
                    caseDetailIds.add(litmusCase.ABCD_Case_Detail__c); 
                }
            }
   
            List<ABCD_Case_Detail__c> caseDetails = [SELECT Id,Litmus_Triggered__c FROM ABCD_Case_Detail__c WHERE Id IN :caseDetailIds];
            for(ABCD_Case_Detail__c extension : caseDetails){
                extension.Litmus_Triggered__c = true;
            }
            update caseDetails;
        }
    }
    
    public static void callLitmusAPI(List<Case> caseList,
                                    Map<Id,Contact> mAccountPrimaryContact,
                                    Map<Id,Lead> prospectMap,
                                    Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap){ 
        try{
            //Cancel exixting litmus case Integrations
            List<ASF_Case_Integration__c> pendingLitmusIntList = [SELECT Id
                                                                  FROM ASF_Case_Integration__c
                                                                  WHERE Case__c 
                                                                  IN :caseList
                                                                  AND Type__c = 'Litmus'
                                                                  AND Status__c = 'Pending'
                                                                  WITH SYSTEM_MODE];
            if(pendingLitmusIntList.size() > 0){
                for(ASF_Case_Integration__c intRec :pendingLitmusIntList) {
                    intRec.Status__c = 'Canceled';
                }
                
                if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()) {
                    update pendingLitmusIntList;
                }
            }
            
            List<ASF_Case_Integration__c> caseIntList = new List<ASF_Case_Integration__c>();
            List<Case_Integration_Outbound__e> caseOutEvntList = new List<Case_Integration_Outbound__e>();
            
            Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();
            Map<Id,ABCD_ObjectRequest> caseIdLitmusWrapper = new Map<Id,ABCD_ObjectRequest>();

            for (Case caseRecord : caseList){
                string phone = '';
                string email = '';
                string name = 'Customer';
                ASF_Case_Category_Config__c cccRecord = cccIdToRecordsMap.get(caseRecord.CCC_External_Id__c);
                if(caseRecord.AccountID != null){
                    if(mAccountPrimaryContact.containsKey(caseRecord.AccountId)){
                        Contact accountPrimaryContact = mAccountPrimaryContact.get(caseRecord.AccountId);
                        if(accountPrimaryContact != null){
                            name = accountPrimaryContact.Name;
                            phone = accountPrimaryContact.MobilePhone;
                            email = accountPrimaryContact.Email;
                        }
                    }
                } else if(caseRecord.Lead__c != null){
                    Lead prospect = prospectMap.get(caseRecord.Lead__c);
                    name = prospect.Name;
                    phone = prospect.MobilePhone;
                    email = prospect.Email;
                } else {
                    name = caseRecord.SuppliedName != null ? caseRecord.SuppliedName : name;
                    phone = caseRecord.SuppliedPhone;
                    email = caseRecord.SuppliedEmail;
                }
                ABCD_LitmusWrapper wrapper = new ABCD_LitmusWrapper();
                ABCD_ObjectRequest objRequest = new ABCD_ObjectRequest();
                objRequest.userPhone = phone;
                objRequest.userEmail = email;
                objRequest.name = name;
                objRequest.tag_case_type = caseRecord.Type_Text__c;
                objRequest.tag_sub_type = caseRecord.Sub_Type_Text__c;
                objRequest.tag_SR_id = caseRecord.CaseNumber;
                objRequest.tag_module_type = 'Case Module';
                objRequest.tag_city = caseRecord.Account.City__c != null ? caseRecord.Account.City__c :'';
                objRequest.tag_SR_date = String.valueOf(ABCL_IntegrationCommonUtility.dateFormat(Date.valueOf(caseRecord.CreatedDate), 'dd-MM-YYYY'));
                objRequest.tag_source = caseRecord.Source__c;
                objRequest.tag_lob = caseRecord.Business_Unit__c;
                objRequest.tag_closure_date = String.valueOf(ABCL_IntegrationCommonUtility.dateFormat(Date.valueOf(caseRecord.ClosedDate), 'dd-MM-YYYY'));
                objRequest.tag_sub_lob = caseRecord.Business_Unit__c == 'ABCD'?caseRecord.ABCD_Case_Detail__r.Function__c:cccRecord.LOB__c;
                objRequest.tag_case_category = caseRecord.Nature__c;
                objRequest.tag_lobuid = caseRecord.Account.PAN__c != null ? caseRecord.Account.PAN__c :'';
                objRequest.tag_agent_name = caseRecord.CreatedBy.Name;
                objRequest.app_id = System.Label.ABCD_LitmusAppId;
                objRequest.tag_business_unit = caseRecord.Business_Unit__c;
                wrapper.objRequest = objRequest;
                
                caseIdLitmusWrapper.put(caseRecord.Id,objRequest);
            }

            for (Case caseRecord : caseList){
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c = caseRecord.Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'Litmus';
                caseInt.Request__c = JSON.serialize(caseIdLitmusWrapper.get(caseRecord.Id));
                caseIntList.add(caseInt);
            }
            
            if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseIntList;
            }
            
            List<ASF_Case_Integration__c> caseIntRecordsList = [SELECT Name, Case__c FROM ASF_Case_Integration__c 
                                                                WHERE Case__c IN :caseList AND Status__c = :ABFL_Constants.PENDING AND Type__c = :ABFL_Constants.LITMUS];

            for(ASF_Case_Integration__c caseIntRecord :caseIntRecordsList) {
            caseIdToCaseIntMap.put(caseIntRecord.Case__c, caseIntRecord);
            }

            for (Case caseRecord : caseList){
                caseOutEvntList.add(new Case_Integration_Outbound__e(
                    Business_Unit__c = caseRecord.Business_Unit__c, 
                    Case_Integration_ID__c = caseIdToCaseIntMap.get(caseRecord.Id)?.Name, 
                    Integration_Name__c = ABFL_Constants.LITMUS, 
                    Request_Payload__c = JSON.serialize(caseIdLitmusWrapper.get(caseRecord.Id))
                ));
            }
            
            if (caseOutEvntList.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(caseOutEvntList);
            }
        } catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABCD_LitmusIntegration.callLitmusAPI');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class ABCD_LitmusWrapper{
        public ABCD_ObjectRequest ObjRequest;
    }
	public class ABCD_ObjectRequest {
		public String app_id;
		public String userPhone;
		public String userEmail;
		public String name;
		public String tag_case_type;
		public String tag_sub_type;
		public String tag_SR_id;
		public String tag_module_type;
		public String tag_city;
		public String tag_SR_date;
		public String tag_source;
		public String tag_lob;
		public String tag_closure_date;
		public String tag_sub_lob;
		public String tag_case_category;
		public String tag_lobuid;
		public String tag_agent_name;
		public String ClientIPAddress;
		public String DeviceID;
		public String OS;
		public String IMEI;
		public String UDP;
		public String UDP1;
		public String UDP2;
		public String UDP3;
		public String UDP4;
		public String UDP5;
		public String LogRefId;
        public String tag_business_unit;
    }
}