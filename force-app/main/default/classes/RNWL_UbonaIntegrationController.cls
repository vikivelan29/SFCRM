public class RNWL_UbonaIntegrationController {
	
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
        }else{
                oppsToOperate.addAll(newOppsList);
        }
        
        for(Opportunity opp : oppsToOperate){
            policyIdsSet.add(opp.Policy__c); 
            accIdsSet.add(opp.AccountId);
        }
        
        for(Asset asst : getPolicies(policyIdsSet)){
            policyIdToAssetMap.put(asst.Id, asst);
        }
        
        Map<Id, Account> accMap = 
            new Map<Id, Account>([SELECT Id, BillingState,
                       					Name, Phone,
                       					PersonMobilePhone,
                                  		RecordType.Name
                				  FROM Account 
                				  WHERE Id IN :accIdsSet]);
        
        List<ABCL_Integration_Event__e> outboundIntPEList = new List<ABCL_Integration_Event__e>();
        for(Opportunity opp : oppsToOperate){
            ABCL_Integration_Event__e intPE = new ABCL_Integration_Event__e();
            intPE.Business_Unit__c = 'ABHI-RNWL';
            intPE.ObjectApiName__c = 'Opportunity';
            intPE.Record_Id__c = opp.Id;
            intPE.Request__c = formJSONBody(opp, policyIdToAssetMap.get(opp.Policy__c), accMap.get(opp.AccountId));
            intPE.ServiceName__c = 'UbonaScheduleCallServiceRenewal';
            outboundIntPEList.add(intPE);
        }
        
        publishResults = EventBus.publish(outboundIntPEList);
    }
    
    /*****************************************************************************************************************
    *                                     private methods
    *****************************************************************************************************************/
    
    private static String formJSONBody(Opportunity opp, Asset asset, Account acc){
        RNWL_UbonaCalloutWrapper ubonaWrap = new RNWL_UbonaCalloutWrapper();
        RNWL_UbonaCalloutWrapper.Cls_payload payld = new RNWL_UbonaCalloutWrapper.Cls_payload();
        RNWL_UbonaCalloutWrapper.Cls_context contxt = new RNWL_UbonaCalloutWrapper.Cls_context();
        
        ubonaWrap.payloadId = opp.Name;
        ubonaWrap.payloadEncrypted = false;
        payld.requestId = opp.Name;

        payld.scheduledTime = String.valueOf(System.now().getTime());
        payld.agentId = '';
        payld.campaign = System.label.RNWL_UbonaCampaignId;//'85008514';
        if(acc != null){
            payld.msisdn = acc.Phone;
            payld.customerInfo = acc.Name;
            contxt.customerName = acc.Name;
            contxt.state = acc.BillingState; 
        }
        if(asset != null){
            contxt.intermediary = asset.IntermediaryName__c;
            contxt.newChannel = asset.Channel__c;
            contxt.nextPremiumDate = asset.Next_Premium_Date__c;
            contxt.policyDueDate = asset.Maturity_Date__c; 
            contxt.productName = asset.ProductName__c;
        	contxt.renewalGrossPremiumFrom = asset.GrossPremium__c;
            contxt.stp_NSTP = asset.Proposal_Type__c;
        	contxt.sumInsured = asset.Sum_Assured__c != null ? String.valueOf(asset.Sum_Assured__c) : '';
        }
        
        contxt.CRMURL = URL.getOrgDomainURL().toExternalForm() + '/' + opp.Id;
        contxt.policyNumber = opp.Policy_Number__c;
        contxt.rnNumber = opp.Name;

        payld.context = contxt;
        ubonaWrap.payload = payld;
        
        String reqBody = replaceWithActualTags(JSON.serialize(ubonaWrap));
        
        return reqBody;
    }
    
    
    private static String replaceWithActualTags(String reqBody){
        reqBody = reqBody.replace('"customerName":', '"Customer Name":');
        reqBody = reqBody.replace('"intermediary":', '"Intermediary":');
        reqBody = reqBody.replace('"newChannel":', '"New Channel":');
        reqBody = reqBody.replace('"nextPremiumDate":', '"Next Premium Date":');
        reqBody = reqBody.replace('"policyDueDate":', '"Policy Due Date":');
        reqBody = reqBody.replace('"policyNumber":', '"Policy Number":');
        reqBody = reqBody.replace('"productName":', '"Product Name":');
        reqBody = reqBody.replace('"renewalGrossPremiumFrom":', '"Renewal Gross Premium-From":');
        reqBody = reqBody.replace('"rnNumber":', '"RN Number":');
        reqBody = reqBody.replace('"state":', '"State":');
        reqBody = reqBody.replace('"stp_NSTP":', '"STP NSTP":');
        reqBody = reqBody.replace('"sumInsured":', '"SUM INSURED":');
        return reqBody;
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