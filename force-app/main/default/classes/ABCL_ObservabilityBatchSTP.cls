/**
 * @description       : 
 * @author            : nikhil.dhoke@in.ey.com
 * @group             : 
 * @last modified on  : 12-06-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class ABCL_ObservabilityBatchSTP implements Database.Batchable<sObject>,Database.Stateful{

    global ABCL_ObservabilityWrapper observWrapper = new ABCL_ObservabilityWrapper();
    global String nonSTPBU = '';
    global String nonBRECCCId = '';
    global String breCCCId = '';
    global List<ABCL_Observability_Mapping__mdt> omList = new List<ABCL_Observability_Mapping__mdt>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        omList = [SELECT Id, DeveloperName, MasterLabel, Business_Unit__c, CCC_External_Id__c FROM ABCL_Observability_Mapping__mdt WHERE DeveloperName IN ('BRE','Non_BRE','BU_Not_For_STP')];
        if(omList.size()>0){
            for(ABCL_Observability_Mapping__mdt om:omList){
                if(om.DeveloperName == 'BU_Not_For_STP'){
                    nonSTPBU = om.Business_Unit__c;
                }
                else if(om.DeveloperName == 'BRE'){
                    breCCCId = om.CCc_External_Id__c;
                }
                else if(om.DeveloperName == 'Non_BRE'){
                    nonBRECCCId = om.CCc_External_Id__c;
                }
            }
        }
        DateTime dt = System.Now().addHours(-1);
        List<String> typeList = new List<String>{'Ebot'};
        List<String> sourceList = new List<String>{'Email'};
        String subType = '';
        String query = 'SELECT Id, Sent_To_Ebot__c, Is_STP__c, CaseNumber, Nature__c, Type_Text__c, Sub_Type_Text__c, LOB__c, CreatedDate, Status, Origin, Source__c, CCC_External_Id__c, SuppliedEmail , Business_Unit__c, RecordType.Name, LAN__c, isClosed, (Select id, Case__c, Status__c, Response__c, Type__c, Retry_Attempt__c, CreatedDate  from ASF_Case_Integrations__r) from Case Where Source__c NOT IN:sourceList AND CreatedDate >=:dt Order By CreatedDate desc';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Process each batch of records
        List<Case> caseList = new List<Case>();
        Integer successCount = 0;
        Integer notSentToIntegrationCount = 0;
        ABCL_ObservabilityWrapper.CaseDetailsWrapper caseDetails = new ABCL_ObservabilityWrapper.CaseDetailsWrapper();
        List<ABCL_ObservabilityWrapper.CaseDetailsWrapper> caseDetailsList = new List<ABCL_ObservabilityWrapper.CaseDetailsWrapper>();
        Map<String,List<ASF_Case_Integration__c>> caseIntegrationMap = new Map<String,List<ASF_Case_Integration__c>>();
        Map<Id,Case> caseMap = new Map<Id,Case>();
        Map<Id,CIWrapper> ciWrapperMap = new Map<Id,CIWrapper>();
        //List<String> stringList = new List<String>();
        System.debug('List execute - '+ scope.size());
        try {
            if(scope.size()>0){
                observWrapper.totalCases += scope.size();
                //caseMap = new Map<Id,Case>(scope);
                for (Case cs : (List<Case>)scope) {
                    if(cs.Status == 'Resolved'){
                        successCount ++; 
                    }
                    else{
                        if(nonSTPBU.toUppercase().contains(cs.Business_Unit__c.toUppercase()) && cs.Is_STP__c == false){
                            notSentToIntegrationCount ++;
                        }
                    
                        if(!caseMap.containsKey(cs.Id)){
                            caseMap.put(cs.Id,cs);
                        }
                        if(caseIntegrationMap.containsKey(cs.Id)){
                            caseIntegrationMap.get(cs.Id).addAll(cs.ASF_Case_Integrations__r);
                        }
                        else{
                            caseIntegrationMap.put(cs.Id,cs.ASF_Case_Integrations__r);
                        }
                    }
                }

                if(caseIntegrationMap.size()>0){
                    for(List<ASF_Case_Integration__c> caseASFList : caseIntegrationMap.values()){
                        for(ASF_Case_Integration__c asfI : caseASFList){
                            CIWrapper ciWrapper = new CIWrapper();
                            if(asfI.Status__c != 'Success'){
                                if(ciWrapperMap.containsKey(asfI.Case__c)){
                                    ciWrapper = ciWrapperMap.get(asfI.Case__c);
                                    if(asfi.Retry_Attempt__c >= ciWrapper.retryAttempt){
                                        ciWrapper.retryAttempt = asfi.Retry_Attempt__c;
                                        ciWrapper.message = asfi.Response__c;
                                        ciWrapper.requestDate = string.valueOf(asfi.CreatedDate);
                                        ciWrapperMap.put(asfI.Case__c,ciWrapper);
                                    }
                                }
                                else{
                                    ciWrapper.retryAttempt = asfi.Retry_Attempt__c;
                                    ciWrapper.message = asfi.Response__c;
                                    ciWrapper.requestDate = string.valueOf(asfi.CreatedDate);
                                    ciWrapperMap.put(asfI.Case__c,ciWrapper);
                                }
                            }
                        }
                    }
                }
                if(!caseMap.isEmpty()){
                    for(Case cs : caseMap.values()){
                        caseDetails.caseNumber = cs.CaseNumber; 
                        caseDetails.lineOfBusiness = cs.LOB__c; 
                        caseDetails.businessUnit = cs.Business_Unit__c;
                        caseDetails.retryAttempt = ciWrapperMap.containsKey(cs.id) ? ciWrapperMap.get(cs.Id).retryAttempt : 0; 
                        caseDetails.caseType = cs.Type_Text__c; 
                        caseDetails.caseSubType = cs.Sub_Type_Text__c; 
                        caseDetails.lan = cs.LAN__c; 
                        caseDetails.status = cs.Status; 
                        caseDetails.source = cs.Source__c; 
                        caseDetails.type = nonBRECCCId.toUpperCase().contains(cs.CCC_External_Id__c.toUpperCase()) ? 'NON-BRE' : breCCCId.toUpperCase().contains(cs.CCC_External_Id__c.toUpperCase()) ? 'BRE' : ''; 
                        caseDetails.message = ''; 
                        caseDetails.description = ciWrapperMap.containsKey(cs.id) ? ciWrapperMap.get(cs.Id).message : 'ASF integration record(s) not found.';
                        caseDetails.caseCreatedDate = string.valueOf(cs.CreatedDate); 
                        caseDetails.requestDate = ciWrapperMap.containsKey(cs.id) ? ciWrapperMap.get(cs.Id).requestDate : '';

                        caseDetailsList.add(caseDetails);
                    }
                }

                observWrapper.integrationType = 'STP';
                observWrapper.casesNotSentToIntegration += notSentToIntegrationCount;
                observWrapper.successfullCases += successCount;
                observWrapper.caseDetailsList.addAll(caseDetailsList);
            }
            
        } catch(Exception e) {
            System.debug('ABCL_ObservabilityBatchSTP execute error - '+ e.getMessage());
        }
        //System.debug('List execute - '+ stringList.size());
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

    public class CIWrapper{
        public Decimal retryAttempt; 
        public String message; 
        public String requestDate;
    }

}