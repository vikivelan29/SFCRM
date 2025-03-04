/*********************************************************
*Class        :  ABFL_InvokeLitmusProcess
*Author       :  Udit Singhal
*Created Date :  07/02/2024
*Last Modified:
*Test Class   :  ABFL_InvokeLitmusProcess_Test
*@description  :  Helper class to invoke Litmus integration
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class ABFL_InvokeLitmusProcess{
    public static Map<Id, List<String>> mapCaseIdEmail = new Map<Id, List<String>>();
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - evaluateCasesForLitmus
     * @param newCaseMap - new case map from trigger
     * @param oldCaseMap - old case map from trigger
     * @description - Method to evaludate and filter case records for which Litmus integration needs to be fired
     *****************************************************************************************************************/
    public void evaluateCasesForLitmus(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap){
        try{
            Set<Id> casesToFurtherProcessSet = new Set<Id>();
            Set<String> cccExternalIdSet = new Set<String>();
            SET<ID> setExpectedLogic = new SET<ID>();
            Map<Id, Case> caseIdToRecordMap = new Map<Id, Case>();
            Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();
            Set<Id> accountIds = new Set<Id>();
            Map<Id, List<String>> mapAccIdEmail = new Map<Id, List<String>>();
            
            List<Case> litmusApiCasesList = new List<Case>();
            for (Case caseRec : newCaseMap.values()){
               if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(caseRec.Business_Unit__c)){
                	setExpectedLogic.add(caseRec.Id); 
                    accountIds.add(caseRec.AccountId);
                } 
            }

            String userEmail = '';
            String userPhone = '';
            for(Contact con : [SELECT Id, Email, AccountId, MobilePhone FROM Contact WHERE AccountId IN :accountIds AND AccountId != null]) {
                mapAccIdEmail.put(con.AccountId, new List<String>{con.Email, con.MobilePhone});
            }
                    
            if(!setExpectedLogic.isEmpty()){
                caseIdToRecordMap = ABFL_SOQL_Case.getCases(setExpectedLogic);
                
                for (Case caseRecord : caseIdToRecordMap.values()){
                    if(caseRecord.AccountId != NULL && !caseRecord.Account.IsPersonAccount && !mapAccIdEmail.isEmpty() &&  mapAccIdEmail.containsKey(caseRecord.AccountId)) {
                        userEmail = mapAccIdEmail.get(caseRecord.AccountId)[0] != null? mapAccIdEmail.get(caseRecord.AccountId)[0] : caseRecord.Account.Office_Email__c; 
                        userPhone = mapAccIdEmail.get(caseRecord.AccountId)[1] != null? mapAccIdEmail.get(caseRecord.AccountId)[1] : caseRecord.Account.Phone; 
                        //userEmail = con.size() > 0 ? con[0]?.Email : caseRecord.Account.Office_Email__c; 
                    }
                    else if(caseRecord.AccountId != NULL && !caseRecord.Account.IsPersonAccount) {
                        userEmail = caseRecord.Account.Office_Email__c;
                        userPhone = caseRecord.Account.Phone;
                    }
                    else if(caseRecord.AccountId != NULL) {
                        userEmail = caseRecord.Account.PersonEmail;
                        userPhone = caseRecord.Account.PersonMobilePhone;
                    }
                    mapCaseIdEmail.put(caseRecord.Id, new List<String>{userEmail, userPhone});
                    
                   // String userPhone = caseRecord.Account.IsPersonAccount ? caseRecord.Account.PersonMobilePhone : caseRecord.Account.Phone;
                    
             
                    
                        
                    if (caseRecord.Source__c != 'SystemIntegration' && (caseRecord.IsClosed == true && (oldCaseMap.get(caseRecord.Id).IsClosed != true)) && (caseRecord.Status == ABFL_Constants.RESOLVED && (oldCaseMap.get(caseRecord.Id).Status != ABFL_Constants.RESOLVED)) && caseRecord.ABFL_Case_Detail__r.Lock_in_Period__c != 'Yes' && String.isNotBlank(caseRecord.Asset.LAN__c) && String.isNotBlank(userPhone) && String.isNotBlank(userEmail)) {
                        casesToFurtherProcessSet.add(caseRecord.Id);
                        cccExternalIdSet.add(caseRecord.CCC_External_Id__c);
                    }
                }
                
                if (cccExternalIdSet.size() > 0){
                    cccIdToRecordsMap = ABFL_SOQL_Util.getCccIdToRecordMap(cccExternalIdSet);
                    
                    for (Id caseId : casesToFurtherProcessSet){
                        Case caseRecord = caseIdToRecordMap.get(caseId);
                        ASF_Case_Category_Config__c cccRecord = cccIdToRecordsMap.get(caseRecord.CCC_External_Id__c);
                        
                        if (cccRecord.Litmus_Trigger__c == true){
                            litmusApiCasesList.add(caseRecord);
                        }
                    }
                }
                
                if (litmusApiCasesList.size() > 0){
                    callLitmusAPI(litmusApiCasesList, cccIdToRecordsMap);
                }
            }
        } catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeLitmusProcess.evaluateCasesForLitmus');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
        }
    }
    
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - callLitmusAPI
     * @param  caseList - List of case records that are eligible for litmus integration
     * @param cccIdToRecordsMap - Map of case category config external Id to case category config record
     * @description - Method to fire litmus integration
     *****************************************************************************************************************/
    public void callLitmusAPI(List<Case> caseList, Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap){
        try{
            //Cancel exixting litmus case Integrations
            List<ASF_Case_Integration__c> pendingLitmusIntList = [SELECT Id
                                                                  FROM ASF_Case_Integration__c
                                                                  WHERE Case__c 
                                                                  IN :caseList
                                                                  AND Type__c = :ABFL_Constants.LITMUS
                                                                  AND Status__c = :ABFL_Constants.PENDING
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
            
            for (Case caseRecord : caseList){
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c = caseRecord.Id;
                caseInt.Status__c = ABFL_Constants.PENDING;
                caseInt.Type__c = ABFL_Constants.LITMUS;
                caseIntList.add(caseInt);
            }
            
            if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseIntList;
            }
            
            caseIdToCaseIntMap = ABFL_SOQL_Integration.getCaseIdsToIntegrationRecordsMap((new Map<Id, SObject>(caseList)).keySet(), ABFL_Constants.LITMUS);
            
            for (Case caseRecord : caseList){
                ABFL_LITMUS_Wrapper wrapper = new ABFL_LITMUS_Wrapper(caseRecord);
                
                caseOutEvntList.add(new Case_Integration_Outbound__e(
                    Business_Unit__c = caseRecord.Business_Unit__c, 
                    Case_Integration_ID__c = caseIdToCaseIntMap.get(caseRecord.Id)?.Name, 
                    Integration_Name__c = ABFL_Constants.LITMUS, 
                    Request_Payload__c = JSON.serialize(wrapper)
                ));
            }
            
            if (caseOutEvntList.size() > 0){
                EventBus.publish(caseOutEvntList);
            }
        } catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeLitmusProcess.callLitmusAPI');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
        }
    }
    
    @SuppressWarnings('PMD.FieldNamingConventions')
    
    /****************************************************************************************************************
    *@description Wrapper to send data
    *****************************************************************************************************************/
    public class ABFL_LITMUS_Wrapper{
        //Mandatory attributes
        public String app_id;
        public String user_phone;
        public String user_email;
        public String customer_id;
        
        //Optional attributes
        public String name;
        public String userWhatsapp;
        public String tag_private_group_hierarchy_0_id;
        public String tag_location;
        public String tag_product_name;
        public String tag_lob;
        public String tag_source;
        public String tag_case_number;
        public String tag_created_on;
        public String tag_resolved_on;
        public String tag_status;
        public String tag_category;
        public String tag_case_type;
        public String tag_sub_type;
        public String tag_ccc;
        public String tag_lan;
        public String tag_business_unit;
        
        /****************************************************************************************************************
         * @description Custom constructor of ABFL_LITMUS_Wrapper class
         * @param caseRecord
        *****************************************************************************************************************/
        public ABFL_LITMUS_Wrapper(Case caseRecord){
            this.app_id = System.Label.ABFL_LITMUS_PROJECT_ID;
            this.tag_business_unit = caseRecord.Business_Unit__c;
           // this.user_phone = caseRecord.Account.IsPersonAccount ? caseRecord.Account.PersonMobilePhone : caseRecord.Account.Phone;
            this.user_phone = !mapCaseIdEmail.isEmpty() && mapCaseIdEmail.containsKey(caseRecord.Id) ? mapCaseIdEmail.get(caseRecord.Id)[1] : '';
            //this.user_email = caseRecord.Account.IsPersonAccount ? caseRecord.Account.PersonEmail : caseRecord.Account.Office_Email__c;
            this.user_email = !mapCaseIdEmail.isEmpty() && mapCaseIdEmail.containsKey(caseRecord.Id) ? mapCaseIdEmail.get(caseRecord.Id)[0] : '';
            this.customer_id = caseRecord.AccountId;
            
            this.name = caseRecord.Account.IsPersonAccount ? caseRecord.Account.Full_Name__pc : caseRecord.Account.Name;
            this.userWhatsapp = '';
            this.tag_private_group_hierarchy_0_id = caseRecord.Owner.Name;
            this.tag_location = String.isNotBlank(caseRecord.Account.City__c) ? caseRecord.Account.City__c : '';
            this.tag_product_name = String.isNotBlank(caseRecord.Asset.Product2.Name) ? caseRecord.Asset.Product2.Name : '';
            this.tag_lob = String.isNotBlank(caseRecord.LOB__c) ? caseRecord.LOB__c : '';
            this.tag_case_number = String.isNotBlank(caseRecord.CaseNumber) ? caseRecord.CaseNumber : '';
            this.tag_created_on = String.valueOf(caseRecord.CreatedDate);
            this.tag_resolved_on = String.valueOf(caseRecord.ClosedDate);
            this.tag_status = caseRecord.Status;
            this.tag_category = String.isNotBlank(caseRecord.Nature__c) ? caseRecord.Nature__c : '';
            this.tag_case_type = String.isNotBlank(caseRecord.Type_Text__c) ? caseRecord.Type_Text__c : '';
            this.tag_sub_type = String.isNotBlank(caseRecord.Sub_Type_Text__c) ? caseRecord.Sub_Type_Text__c : '';
            this.tag_ccc = String.isNotBlank(caseRecord.Account.Client_Code__c) ? caseRecord.Account.Client_Code__c : '';
            this.tag_lan = caseRecord.Asset.LAN__c;
            
            switch on caseRecord.Source__c{
                when 'Branch', 'Internal RM - Collection', 'RM', 'RM-No Email', 'Walkin'{
                    this.tag_source = 'Branch';
                }
                when 'Call- in', 'Inbound Nodal Desk', 'Phone-Inbound', 'Phone-Outbound'{
                    this.tag_source = 'Call Center';
                }
                when 'Chatbot', 'Customer Portal', 'IVR', 'IVR-No Email', 'MOBILEAPP', 'Social Media', 'WhatsApp', 'Webform'{
                    this.tag_source = 'Digital';
                }
                when 'Bureau', 'Email', 'Letter / Snail Mail'{
                    this.tag_source = 'Email';
                }
                when else{
                    this.tag_source = '';
                }
            }
        }
    }
}