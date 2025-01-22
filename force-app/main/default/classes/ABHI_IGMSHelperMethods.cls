/*********************************************************
*Class        :  ABHI_IGMSHelperMethods
*Author       :  Shubham Sinha
*Created Date :  17/09/2024
*@description  :  Class for ABHI related Business Logic */

public class ABHI_IGMSHelperMethods {
     /**
     * @description  to populate the account from the mobile no when case is created from IGMS
     * @param cases - Case list
     ***/
    public static void associateCustomerForAPIFromPhoneNumber(List<Case> cases){
        List<Case> abhiCases = new List<Case>();
        List<Case> updateCase = new List<Case>();
        Set<String> phoneNumbers = new Set<String>();
        for(Case recCs: cases){
            if(recCs.Business_Unit__c == 'ABHI'
               && recCs.Technical_Source__c == 'API'
               && recCs.SuppliedPhone != null && recCs.SuppliedPhone != ''
               && recCs.AccountId == null)
            {
                abhiCases.add(recCs);
                phoneNumbers.add(recCs.SuppliedPhone);
            }
        }
        Map<String,List<Id>> mAccWithSamePhNum = new Map<String,List<Id>>();
        if(phoneNumbers.size()>0){
            String searchTerms = '';
            integer iCount = 0;
            for(String phoneNum : phoneNumbers){
                if(iCount == (phoneNumbers.size() -1)){
                    searchTerms +='\''+phoneNum+'\'';
                }
                else{
                    searchTerms +='\''+phoneNum+'\' OR ';
                }
                iCount++;
            }
            List<List<SObject>> searchList  = Search.query('FIND :searchTerms  IN PHONE FIELDS RETURNING Contact (Id, Name,AccountId,MobilePhone WHERE MobilePhone IN :phoneNumbers AND Account.Business_Unit__c =\'ABHI\')');
            List<Contact> contactList = searchList[0];
 
            for(Contact con : contactList)
            {
                if(!mAccWithSamePhNum.containsKey(con.MobilePhone))
                {
                    mAccWithSamePhNum.put(con.MobilePhone, new List<Id>());
                }
                if(!mAccWithSamePhNum.get(con.MobilePhone).contains(con.AccountId)){
                    mAccWithSamePhNum.get(con.MobilePhone).add(con.AccountId);
                }
            }
            for(Case cs : cases){
                if(mAccWithSamePhNum.containsKey(cs.SuppliedPhone)){
                    List<Id> accounts = mAccWithSamePhNum.get(cs.SuppliedPhone);
                    if(accounts.size() == 1){
                       // Case  objCase = new Case (Id = cs.Id );
                        cs.AccountId = accounts.get(0);
                       // updateCase.add(objCase);
                    }
                }
            }
            if(!updateCase.isEmpty()){
                //update updateCase;
            }
        }
    }
    public static void associateAssetIgms(List<Case> cases){
        List<Case> abhiCases = new List<Case>();
        Set<String> proposalClaimNo = new Set<String>();
        Boolean updatedCase = false; // Tracking if an update has occurred
        Set<Id> caseDeatilId = new Set<Id>();
        for(Case cs : cases){
            system.debug('ABHIDetails--> '+cs.ABHI_Case_Detail__c) ;
            caseDeatilId.add(cs.ABHI_Case_Detail__c);
            system.debug('caseDeatilId--> '+caseDeatilId) ;
        }
        if(caseDeatilId.size()>0) {
        	Map<Id, ABHI_Case_Detail__c> mapCaseDetailMap = new Map<Id, ABHI_Case_Detail__c>(
        	[SELECT Id, Policy_Proposal_Cert_Claim_Number__c,Proposal_Or_Cover_Note_Number__c ,Claim_No__c FROM ABHI_Case_Detail__c WHERE Id IN: caseDeatilId]);
        //List<Case> fetchedCases = [SELECT ID,Business_Unit__c,Technical_Source__c,AccountId,AssetId,ABHI_Case_Detail__c,ABHI_Case_Detail__r.Policy_Proposal_Cert_Claim_Number__c,ABHI_Case_Detail__r.Proposal_Or_Cover_Note_Number__c,ABHI_Case_Detail__r.Claim_No__c FROM CASE WHERE ID IN:cases];
      //  system.debug('casess '+ cases );
            for(Case recCs: cases){
                if(recCs.Business_Unit__c == 'ABHI'
                   && recCs.Technical_Source__c == 'API'
                   && recCs.AccountId == null && recCs.AssetId == null && mapCaseDetailMap.containsKey(recCs.ABHI_Case_Detail__c))
                {
                    abhiCases.add(recCs);
                    if(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Policy_Proposal_Cert_Claim_Number__c != null){
                        system.debug('proposalClaimNosss '+ mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Policy_Proposal_Cert_Claim_Number__c );
                        proposalClaimNo.add(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Policy_Proposal_Cert_Claim_Number__c);
                    }
                    else if(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Proposal_Or_Cover_Note_Number__c != null){
                        system.debug('proposalClaimNosss '+ mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Proposal_Or_Cover_Note_Number__c );
                        proposalClaimNo.add(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Proposal_Or_Cover_Note_Number__c);
                    }
                    else if(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Claim_No__c != null){
                        proposalClaimNo.add(mapCaseDetailMap.get(recCs.ABHI_Case_Detail__c).Claim_No__c);
                    }
                     system.debug('proposalClaimNosss '+ proposalClaimNo );
                }
            }
            if(proposalClaimNo.size()>0){
                List<Case> updateCase = new List<Case>();
                List<Asset> foundAsset = [SELECT ID, SerialNumber,AccountId FROM ASSET WHERE SerialNumber =:  proposalClaimNo AND Business_Unit__c = 'ABHI' LIMIT 1];
                if(!foundAsset.isEmpty()){
                    for(Case cs : cases){
                       // Case  objCase = new Case (Id = cs.Id );
                        cs.AccountId = foundAsset[0].AccountId;
                        cs.AssetID  = foundAsset[0].Id;
                        //updateCase.add(objCase);
                    }
                }
                else {
                    List<Claim__c > foundAssetClaim = [SELECT ID, Policy_Number__c,Policy_Number__r.AccountID , Name  FROM Claim__c WHERE Name =:  proposalClaimNo LIMIT 1];
                    if(!foundAssetClaim.isEmpty()){
                        for(Case cs : cases){
                           // Case  objCase = new Case (Id = cs.Id );
                            cs.AccountId = foundAssetClaim[0].Policy_Number__r.AccountID;
                            cs.AssetID  = foundAssetClaim[0].Policy_Number__c;
                           // updateCase.add(objCase);
                        }
                    }
                }
               /* if(!updateCase.isEmpty()){
                    system.debug('updateCaseas '+updateCase);
                    update updateCase;
                    updatedCase = true;
                } */
            }
           
        }
        
	}
}
