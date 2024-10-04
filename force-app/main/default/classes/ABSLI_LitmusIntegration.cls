/*********************************************************
*Class        :  ABSLI_LitmusApi
*Author       :  Virendra Patil
*Created Date :  22/07/2024
*Last Modified:  22/07/2024
*Description  :  Class for Litmus Integration
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity')
public class ABSLI_LitmusIntegration {
    public static Map<Id,Boolean> isExecuted = new Map<Id,Boolean>();
    public Static void evaluateCasesForLitmus(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap){
        Set<Id> setExpectedLogic = new Set<Id>();
        Set<String> cccExternalIdSet = new Set<String>();
        Map<Id, Case> caseIdToRecordMap = new Map<Id, Case>();
        Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();
        List<Case> litmusApiCasesList = new List<Case>();
        List<Case> eligibleCases = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Contact> mAccountPrimaryContact = new Map<Id,Contact>();
        
        // CONDITION 1 - CHECK IF BUSINESS UNIT IS ABSLI
        // CONDITION 2 - CHECK IF CASE IS CLOSED AND CASE STATUS IS RESOLVED.
        for (Case caseRec : newCaseMap.values()){
            if(caseRec.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT && 
               ((caseRec.IsClosed == true && (oldCaseMap.get(caseRec.Id).IsClosed != true) && ASF_Constants.RESOLVEDSTAGES.contains(caseRec.Status)) || 
               ASF_Constants.RESOLVEDSTAGES.contains(caseRec.Stage__c)) ){
                   if(!isExecuted.containskey(caseRec.Id)){
                       setExpectedLogic.add(caseRec.Id);
                   		cccExternalIdSet.add(caseRec.CCC_External_Id__c);
                       isExecuted.put(caseRec.Id,true);
                   }
               } 
        }
        
        if(!setExpectedLogic.isEmpty()){
            cccIdToRecordsMap = ABSLI_IntegrationQueryHelper.getCccIdToRecordMap(cccExternalIdSet);
            caseIdToRecordMap = ABSLI_IntegrationQueryHelper.getCases(setExpectedLogic);
            
            for (Case caseRecord : caseIdToRecordMap.values()){
                // CONDITION 3 - CHECK IF AccountId and AssetId is populated.
                // CONDITION 4 - CHECK IF THE SOURCE_REQUEST_SUBMITTED_BY IS "CUSTOMER".
                // CONDITION 5 - CHECK IF THE CCC RECORD IS HAVING LITMUS TRIGGER = TRUE.
                if(caseRecord.AccountId != null && caseRecord.AssetId != null && 
                   caseRecord.ABSLI_Case_Detail__r.Source_Request_submitted_by__c == ABSLI_Constants.LITMUS_SOURCE_REQ_BY)
                {
                    if(cccIdToRecordsMap.containsKey(caseRecord.CCC_External_Id__c)){
                        ASF_Case_Category_Config__c cccRecord = cccIdToRecordsMap.get(caseRecord.CCC_External_Id__c);
                        if(cccRecord.Litmus_Trigger__c == true){
                            accountIds.add(caseRecord.AccountId);
                            //litmusApiCasesList.add(caseRecord);
                            eligibleCases.add(caseRecord);
                        }
                    }
                }
                
            }
        }
        // CHECK IF THERE IS AN EXISTING COMPLAINT OPEN FOR THE CUSTOMER.
        if(accountIds.size()>0){
            Map<Id,AggregateResult> aggResults = new Map<Id,AggregateResult>([SELECT AccountId Id, COUNT(ID) FROM Case WHERE
                                                                             AccountId =: accountIds AND Nature__c=: ABSLI_Constants.COMPLAINT_NATURE AND IsClosed = False
                                                                             GROUP BY AccountId]);
            
            // CODE TO GET THE DETAILS FROM CONTACT - IN CASE OF PERSONACCOUNT, CONTACT RECORD GETS CREATED, IN CASE OF BUSINESS ACCOUNT CONTACT TO BE LOADED.
            for(Contact c : [SELECT ID,Nationality__c,Birthdate,GenderIdentity,MobilePhone,Email,AccountID FROM Contact WHERE AccountId =: accountIds]){
                if(!mAccountPrimaryContact.containsKey(c.AccountId)){
                    mAccountPrimaryContact.put(c.AccountId,c);
                } 
            }
            for(Case c : eligibleCases){
                if(aggResults.containsKey(c.AccountId)){
                    integer iCount = Integer.ValueOf(aggResults.get(c.AccountId).get('expr0'));
                    if(iCount < 1){
                        litmusApiCasesList.add(c);
                    }
                }
                else{
                    litmusApiCasesList.add(c);
                }
            }
            
        }
        if(litmusApiCasesList.size()>0){
            callLitmusAPI(litmusApiCasesList, cccIdToRecordsMap,mAccountPrimaryContact);
            Set<Id> caseDetailIds = new Set<Id>();
       
            for (Case litmusCase : litmusApiCasesList) {
                if (litmusCase.ABSLI_Case_Detail__c != null) {
                    caseDetailIds.add(litmusCase.ABSLI_Case_Detail__c);
                }
            }
   
            List<ABSLI_Case_Detail__c> caseDetails = [SELECT Id,Litmus_Triggered__c FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds];
            for(ABSLI_Case_Detail__c extension : caseDetails){
                extension.Litmus_Triggered__c = 'Yes';
            }
            update caseDetails;
        }
    }
    
    public static void callLitmusAPI(List<Case> caseList, 
                                     Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap,
                                    Map<Id,Contact> mAccountPrimaryContact){ 
        try{
            //Cancel exixting litmus case Integrations
            List<ASF_Case_Integration__c> pendingLitmusIntList = [SELECT Id
                                                                  FROM ASF_Case_Integration__c
                                                                  WHERE Case__c 
                                                                  IN :caseList
                                                                  AND Type__c = :ABSLI_Constants.LITMUS
                                                                  AND Status__c = :ABSLI_Constants.PENDING
                                                                  WITH SYSTEM_MODE];
            if(pendingLitmusIntList.size() > 0){
                for(ASF_Case_Integration__c intRec :pendingLitmusIntList) {
                    intRec.Status__c = 'Canceled';
                }
                
                if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()) {
                    update pendingLitmusIntList;
                    system.debug('cancel litmus');
                }
            }
            
            List<ASF_Case_Integration__c> caseIntList = new List<ASF_Case_Integration__c>();
            List<Case_Integration_Outbound__e> caseOutEvntList = new List<Case_Integration_Outbound__e>();
            
            Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();
            
            for (Case caseRecord : caseList){
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c = caseRecord.Id;
                caseInt.Status__c = ABFL_Constants.PENDING;
                caseInt.Type__c = ABFL_Constants.LITMUS;
                caseIntList.add(caseInt);
            }
            
            if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseIntList;
                system.debug('create litmus');
            }
            
            caseIdToCaseIntMap = ABSLI_IntegrationQueryHelper.getCaseIdsToIntegrationRecordsMap((new Map<Id, SObject>(caseList)).keySet(), ABFL_Constants.LITMUS);
            
            for (Case caseRecord : caseList){
                ABSLI_LITMUS_Wrapper wrapper = new ABSLI_LITMUS_Wrapper(caseRecord,mAccountPrimaryContact);
                
                caseOutEvntList.add(new Case_Integration_Outbound__e(
                    Business_Unit__c = caseRecord.Business_Unit__c, 
                    Case_Integration_ID__c = caseIdToCaseIntMap.get(caseRecord.Id)?.Name, 
                    Integration_Name__c = ABFL_Constants.LITMUS, 
                    Request_Payload__c = JSON.serialize(wrapper)
                ));
            }
            
            if (caseOutEvntList.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(caseOutEvntList);
            }
        } catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_LitmusIntegration.callLitmusAPI');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    
    public static String getGeneration(Date dob){
        if(dob == null){
            return 'not defined';
        }
        Integer iBirthYear = dob.year();
        // 1. fetch BirthYear from DateOfBirth.
        // if >1946 < 1964 --> Baby Boomers.
        // else if 
        
        if(iBirthYear > 1946 && iBirthYear <= 1964){
            return 'Baby Boomers';
        }
        else if(iBirthYear >=1965 && iBirthYear <=1980){
            return 'Generation X';
        }
        else if(iBirthYear >=1981 && iBirthYear <= 1995){
            return 'Millennials';
        }
        else if(iBirthYear >= 1996 && iBirthYear <= 2010){
            return 'Generation Z';
        }
        else if(iBirthYear >= 2011 && iBirthYear <= 2025){
            return 'Generation Alpha';
        }
        return 'not defined';
    }

    
    @SuppressWarnings('PMD.FieldNamingConventions')
    // Wrapper to send data
    public class ABSLI_LITMUS_Wrapper{
        //Mandatory attributes
        public String app_id;
        public String tag_client_id;
        public String tag_policy;
        public String tag_policy_issue_date;
        public String tag_policy_status;
        public String tag_nationality;
        public String tag_customer_income_segment;
        public String tag_date_of_birth;
        public String tag_generation;
		public String tag_occupation;
        public String tag_gender;
        public String tag_case_number;
        public String tag_case_category;
        public String tag_call_type;
        public String tag_sub_type;
        public String tag_subtype_catgeory;
        public String tag_source;
        public String tag_transaction_touchpoint;
        public String tag_nps_project;
        public String tag_case_created_on;
        public String tag_case_modified_on;
        public String tag_ftr;
        public String tag_product_type;
        public String tag_product_name;
        public String tag_sales_channel;
        public String tag_advisor_code_agent_code;
        public String tag_agent_status;
        public String tag_agent_level;
        public String tag_mobile_bwg_status;
        public String tag_email_bwg_status;
        public String tag_serv_agent_id;
        public String tag_serv_agent_status;
        public String tag_private_group_hierarchy_0_id;
        public String userPhone;
        public String name;
        public String userWhatsapp;
        public String userEmail;
        public String shopId;
        public String tag_Feedback_For;
        
 
        
        
        public ABSLI_LITMUS_Wrapper(Case caseRecord,Map<Id,Contact> mAccountPrimaryContact){
            
            Contact accountPrimaryContact = mAccountPrimaryContact.get(caseRecord.AccountId);
            
            this.app_id = System.Label.ABSLI_LITMUS_PROJECT_ID;
            //this.tag_business_unit = caseRecord.Business_Unit__c;
            this.tag_client_id = String.isNotBlank(caseRecord.Account.Client_Code__c) ? caseRecord.Account.Client_Code__c : '';
            this.tag_policy = String.isNotBlank(caseRecord.AssetId)?caseRecord.Asset.Policy_No__c : caseRecord.LAN__c;
            this.tag_policy_issue_date = String.isNotBlank(caseRecord.AssetId) ? ABCL_IntegrationCommonUtility.dateFormat(caseRecord.Asset.Issue_Date__c, 'dd-MM-YYYY') : '';
            this.tag_policy_status = String.isNotBlank(caseRecord.AssetId) ? caseRecord.Asset.Status : '';
            this.tag_nationality = (String.isNotBlank(caseRecord.AccountId) && accountPrimaryContact != null) ? accountPrimaryContact.Nationality__c : '';
            this.tag_customer_income_segment = String.isNotBlank(caseRecord.AccountId) ? caseRecord.Account.Customer_Segment__c : '';
            this.tag_date_of_birth = (String.isNotBlank(caseRecord.AccountId) && accountPrimaryContact != null) ? ABCL_IntegrationCommonUtility.dateFormat(accountPrimaryContact.Birthdate, 'dd-MM-YYYY') : '';
            this.tag_generation = getGeneration((accountPrimaryContact != null ? accountPrimaryContact.Birthdate : null)); // TO BUILD THIS LOGIC.
            this.tag_occupation = String.isNotBlank(caseRecord.AccountId) ? caseRecord.Account.Occupation__c : '';
            this.tag_gender = (String.isNotBlank(caseRecord.AccountId) && accountPrimaryContact != null) ? accountPrimaryContact.GenderIdentity : '';
            this.tag_case_number = caseRecord.CaseNumber;
            this.tag_case_category = caseRecord.Nature__c;
            this.tag_call_type = caseRecord.Type_Text__c;
            this.tag_sub_type = caseRecord.Sub_Type_Text__c;
            this.tag_subtype_catgeory = '';
            this.tag_source = caseRecord.Source__c;
            this.tag_transaction_touchpoint = caseRecord.Channel__c;
            this.tag_nps_project = 'Service – Offline';
            this.tag_case_created_on = ABCL_IntegrationCommonUtility.dateFormat(Date.ValueOf(caseRecord.CreatedDate), 'dd-MM-YYYY');
            this.tag_case_modified_on = ABCL_IntegrationCommonUtility.dateFormat(Date.ValueOf(caseRecord.LastModifiedDate), 'dd-MM-YYYY');
            this.tag_ftr = caseRecord.FTR__c ? 'Yes' : 'No';
            this.tag_product_type = String.isNotBlank(caseRecord.AssetId) ? caseRecord.Asset.Type__c : '';
            this.tag_product_name ='';
            this.tag_sales_channel = String.isNotBlank(caseRecord.AssetId) ? caseRecord.Asset.Channel__c : '';
			this.tag_advisor_code_agent_code =String.isNotBlank(caseRecord.AssetId)? (String.isNotBlank(caseRecord.Asset.Advisor__c ) ? caseRecord.Asset.Advisor__r.Advisor_Code__c:'' ):'';
			this.tag_agent_status = String.isNotBlank(caseRecord.AssetId)? (String.isNotBlank(caseRecord.Asset.Advisor__c ) ? caseRecord.Asset.Advisor__r.Advisor_Status__c:'' ):'';
			this.tag_agent_level = String.isNotBlank(caseRecord.AssetId)? (String.isNotBlank(caseRecord.Asset.Advisor__c ) ? caseRecord.Asset.Advisor__r.Agent_Sub_Category__c:'' ):'';
            this.tag_mobile_bwg_status = ''; // ALWAYS SEND BLANK.
            this.tag_email_bwg_status = ''; // ALWAYS SEND BLANK.
            this.tag_serv_agent_id = String.isNotBlank(caseRecord.AssetId)? (String.isNotBlank(caseRecord.Asset.Advisor__c ) ? caseRecord.Asset.Advisor__r.Advisor_Code__c:'' ):'';
            this.tag_serv_agent_status = String.isNotBlank(caseRecord.AssetId)? (String.isNotBlank(caseRecord.Asset.Advisor__c ) ? caseRecord.Asset.Advisor__r.Advisor_Status__c:'' ):'';
            this.tag_private_group_hierarchy_0_id = String.isNotBlank(caseRecord.OwnerId)? caseRecord.Owner.Name : '';
            this.name = String.isNotBlank(caseRecord.AccountId) ? (caseRecord.Account.IsPersonAccount ? caseRecord.Account.Full_Name__pc : caseRecord.Account.Name) : '';
            this.userPhone = (String.isNotBlank(caseRecord.AccountId) && accountPrimaryContact != null) ? accountPrimaryContact.MobilePhone : '';
            this.userWhatsapp = '';
            this.userEmail = (String.isNotBlank(caseRecord.AccountId) && accountPrimaryContact != null) ? accountPrimaryContact.Email : '';
            this.shopId = 'Touchpoint';
            this.tag_Feedback_For = String.isNotBlank(caseRecord.OwnerId)? caseRecord.Owner.Name : '';
        }
    }
    
}