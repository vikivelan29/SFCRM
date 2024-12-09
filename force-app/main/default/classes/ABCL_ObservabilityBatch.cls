/**
 * @description       : 
 * @author            : nikhil.dhoke@in.ey.com
 * @group             : 
 * @last modified on  : 12-06-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class ABCL_ObservabilityBatch implements Database.Batchable<sObject>,Database.Stateful{

    global ABCL_ObservabilityWrapper observWrapper = new ABCL_ObservabilityWrapper();

	global Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime dt = System.Now().addHours(-1);
        List<String> typeList = new List<String>{'Ebot'};
        List<String> sourceList = new List<String>{'Email'};
        String subType = '';
        String query = 'SELECT Id, Sent_To_Ebot__c, CaseNumber, Nature__c, Type_Text__c, Sub_Type_Text__c, LOB__c, CreatedDate, Status, Origin, Source__c, CCC_External_Id__c, SuppliedEmail , Business_Unit__c, RecordType.Name, LAN__c, isClosed, (Select id, Status__c, Response__c, Type__c, Retry_Attempt__c, CreatedDate  from ASF_Case_Integrations__r Where Type__c IN:typeList) from Case Where Source__c IN:sourceList AND CreatedDate >=:dt Order By CreatedDate desc';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Process each batch of records
        List<Case> caseList = new List<Case>();
        Integer successCount = 0;
        Integer notSentToEbotCount = 0;
        ABCL_ObservabilityWrapper.CaseDetailsWrapper caseDetails = new ABCL_ObservabilityWrapper.CaseDetailsWrapper();
        List<ABCL_ObservabilityWrapper.CaseDetailsWrapper> caseDetailsList = new List<ABCL_ObservabilityWrapper.CaseDetailsWrapper>();
        Map<String,List<ASF_Case_Integration__c>> caseIntegrationMap = new Map<String,List<ASF_Case_Integration__c>>();
        //List<String> stringList = new List<String>();
        try {
            if(scope.size()>0){
                observWrapper.totalCases += scope.size();
                for (Case cs : (List<Case>)scope) {
                    if(cs.Status == 'Resolved'){
                        successCount ++; 
                    }
                    else if(cs.Sent_To_Ebot__c == false){
                        notSentToEbotCount ++; 
                    }
                    else if(cs.isClosed == false && cs.Sub_Type_Text__c == '' && cs.ASF_Case_Integrations__r.size()>0){
                        /* if(caseIntegrationMap.containsKey(cs.Id)){
                            caseIntegrationMap.get(cs.Id).addAll(cs.ASF_Case_Integrations__r);
                        }
                        else{
                            caseIntegrationMap.put(cs.Id,cs.ASF_Case_Integrations__r);
                        } */
                        /* Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(cs.ASF_Case_Integrations__r[0].Response__c);
                        String comment = (String)result.get('COMMENT'); */
                        caseDetails.caseNumber = cs.CaseNumber; 
                        caseDetails.lineOfBusiness = cs.LOB__c; 
                        caseDetails.businessUnit = cs.Business_Unit__c;
                        caseDetails.retryAttempt = cs.ASF_Case_Integrations__r[0].Retry_Attempt__c; 
                        caseDetails.caseType = cs.Type_Text__c; 
                        caseDetails.caseSubType = cs.Sub_Type_Text__c; 
                        caseDetails.lan = cs.LAN__c; 
                        caseDetails.status = cs.Status; 
                        caseDetails.source = cs.Source__c; 
                        caseDetails.type = 'Ebot'; 
                        caseDetails.message = ''; 
                        caseDetails.description = cs.ASF_Case_Integrations__r[0].Response__c; //comment; 
                        caseDetails.caseCreatedDate = string.valueOf(cs.CreatedDate); 
                        caseDetails.requestDate = string.valueOf(cs.ASF_Case_Integrations__r[0].CreatedDate);

                        caseDetailsList.add(caseDetails);
                    }
                }
                observWrapper.integrationType = 'Ebot';
                observWrapper.casesNotSentToIntegration += notSentToEbotCount;
                observWrapper.successfullCases += successCount;
                observWrapper.caseDetailsList.addAll(caseDetailsList);
                /* if(caseIntegrationMap.size()>0){

                } */
            }
            
        } catch(Exception e) {
            System.debug('ABCL_ObservabilityBatch execute error - '+ e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        //System.debug('List count nik - '+ stringList.size());
        // Publish a platform event after processing all batches
        ABCL_Observability__e event = new ABCL_Observability__e(
            Event_Details__c = JSON.serialize(observWrapper)
        );
        //EventBus.publish(event);
        Database.SaveResult sr = EventBus.publish(event);
        // Inspect publishing result
        if (sr.isSuccess()) {
            System.debug('Successfully published event.');
        } else {
            for(Database.Error err : sr.getErrors()) {
                System.debug('Error returned: ' +err.getStatusCode() +' - ' +err.getMessage());
            }
        }
    }
}