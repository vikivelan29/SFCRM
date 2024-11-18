public without sharing class RNWL_UbonaIntegrationController {
    @TestVisible
    private static Database.SaveResult[] publishResults;
    
    /****************************************************************************************************************
    * @Function - firePlatformEventForUbona
    * @param newOppsList -  list of Opportunities from trigger.new.
    * @return - void .
    * @Description - Invoked from BeforeInsert this method pre-populates fields on Opps from Asset record.
    *****************************************************************************************************************/
    public static void firePlatformEventForUbona(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOpps){
        Set<Id> policyIdsSet = new Set<Id>();
        Set<Id> accIdsSet = new Set<Id>();
        Map<Id, Asset> policyIdToAssetMap = new Map<Id, Asset>();
        List<Opportunity> oppsToOperate = new List<Opportunity>();
        
        if(oldOpps != null){
            for(Opportunity opp : newOppsList){
                if(opp.Dialer_Status__c == 'Schedule Call Request Submitted' 
                   && oldOpps.get(opp.Id).Dialer_Status__c ==  'Schedule Call Request Failed'){
                   oppsToOperate.add(opp);
                } 
            }
        } else {
            oppsToOperate.addAll(newOppsList);
        }
        
        if(oppsToOperate.size() == 0){ return; }
        
        for(Opportunity opp : oppsToOperate){
            policyIdsSet.add(opp.Policy__c); 
            accIdsSet.add(opp.AccountId);
        }
        
        for(Asset asst : getPolicies(policyIdsSet)){
            policyIdToAssetMap.put(asst.Id, asst);
        }
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, BillingState, Name, Phone, PersonMobilePhone, RecordType.Name
            FROM Account 
            WHERE Id IN :accIdsSet]);
		
        List<ABCL_Integration_Event__e> outboundIntPEList = new List<ABCL_Integration_Event__e>();
        for(Opportunity opp : oppsToOperate){
            ABCL_Integration_Event__e intPE = new ABCL_Integration_Event__e();
            intPE.Business_Unit__c = 'ABHI-RNWL';
            intPE.ObjectApiName__c = 'Opportunity';
            intPE.Record_Id__c = opp.Id;
            
            if(policyIdToAssetMap.size() > 0 && policyIdToAssetMap.containsKey(opp.Policy__c) && 
               accMap.size() > 0 && accMap.containsKey(opp.AccountId)){
               	   intPE.Request__c = formJSONBody(opp, policyIdToAssetMap.get(opp.Policy__c), accMap.get(opp.AccountId)); 
                   system.debug('*******' + intPE.Request__c);
            }
            
            intPE.ServiceName__c = 'UbonaScheduleCallServiceRenewal';
            outboundIntPEList.add(intPE);
        }
        
        if(outboundIntPEList.size() > 0){
            publishResults = EventBus.publish(outboundIntPEList);
        }
        
    }
    
    /*****************************************************************************************************************
    *                                     private methods
    *****************************************************************************************************************/
    
    private static String formJSONBody(Opportunity opp, Asset asset, Account acc){
        RNWL_UbonaCalloutWrapper ubonaWrap = new RNWL_UbonaCalloutWrapper();
        RNWL_UbonaCalloutWrapper.Cls_payload payld = new RNWL_UbonaCalloutWrapper.Cls_payload();
        //RNWL_UbonaCalloutWrapper.Cls_context contxt = new RNWL_UbonaCalloutWrapper.Cls_context();
        
        ubonaWrap.payloadId = opp.Name;
        ubonaWrap.payloadEncrypted = false;
        payld.requestId = opp.Name;

        payld.scheduledTime = String.valueOf(System.now().getTime());
        payld.agentId = '';
        payld.campaign = System.label.RNWL_UbonaCampaignId;//'85008514';

        if(acc != null){
            payld.msisdn = acc.Phone;
            payld.customerInfo = acc.Name; 
        }

        // construncting the JSON string manually as the keys have spaces and cannot be class parameters
        String context = '{"CRMURL": "' + URL.getOrgDomainURL().toExternalForm() + '/' + opp.Id + '",'
            + '"Customer Name": "' + getValue(acc?.Name) + '",'
            + '"Intermediary": "' + getValue(asset?.IntermediaryName__c) + '",'
            + '"New Channel": "' + getValue(asset?.Channel__c) + '",'
            + '"Next Premium Date": "' + getValue(asset?.Next_Premium_Date__c) + '",'
            + '"Policy Due Date": "' + getValue(asset?.Maturity_Date__c) + '",'
            + '"Policy Number": "' + getValue(opp.Policy_Number__c) + '",'
            + '"Product Name": "' + getValue(asset?.ProductName__c) + '",'
            + '"Renewal Gross Premium-From": "' + getValue(asset?.GrossPremium__c) + '",'
            + '"RN Number": "' + getValue(opp.Name) + '",'
            + '"State": "' + getValue(acc?.BillingState) + '",'
            + '"STP NSTP": "' + getValue(asset?.Proposal_Type__c) + '",'
            + '"SUM INSURED": "' + getValue(asset.Sum_Assured__c) + '",';

        payld.context = context;
        ubonaWrap.payload = JSON.serialize(payld);
        return JSON.serialize(ubonaWrap);
    }

    private static String getValue(Object fieldValue) {
        system.debug('*** field value - ' + fieldValue);
        if (fieldValue == null) {
            return '';
        } else {
            return String.valueOf(fieldValue);
        }
    }
    
    /*****************************************************************************************************************
    *                                      Data Getters
    *****************************************************************************************************************/
    
    private static List<Asset> getPolicies(Set<Id> policyIdSet){
        return [SELECT 
            Id, 
            IntermediaryName__c,
            Channel__c,
            Next_Premium_Date__c,
            Maturity_Date__c,
            ProductName__c,
            GrossPremium__c,
            Proposal_Type__c,
            Sum_Assured__c
        FROM Asset 
        WHERE Id IN : policyIdSet];
    }
}
