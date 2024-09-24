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
        Set<String> phoneNumbers = new Set<String>();
        try{
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
                for(Case cs : abhiCases){
                    if(mAccWithSamePhNum.containsKey(cs.SuppliedPhone)){
                        List<Id> accounts = mAccWithSamePhNum.get(cs.SuppliedPhone);
                        if(accounts.size() == 1){
                            Case  objCase = new Case (Id = cs.Id );
                            objCase.AccountId = accounts.get(0);
                            updateCase.add(objCase);
                        }
                    }
                }
            }
        }
          catch(Exception e){
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('associateCustomerForAPIFromPhoneNumber failed for ABHI');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static void associateAssetIgms(List<Case> cases){
        List<Case> abhiCases = new List<Case>();
        Set<String> proposalClaimNo = new Set<String>();
        List<Case> fetchedCases = [SELECT ID,Business_Unit__c,Technical_Source__c,AccountId,AssetId,ABHI_Case_Detail__c,ABHI_Case_Detail__r.Policy_Proposal_Cert_Claim_Number__c FROM CASE WHERE ID IN:cases];
        system.debug('casess '+ cases );
        try{
            for(Case recCs: fetchedCases){
                if(recCs.Business_Unit__c == 'ABHI'
                   && recCs.Technical_Source__c == 'API'
                   && recCs.AccountId == null && recCs.AssetId == null)
                {
                    abhiCases.add(recCs);
                    proposalClaimNo.add(recCs.ABHI_Case_Detail__r.Policy_Proposal_Cert_Claim_Number__c);
                            system.debug('proposalClaimNosss '+ proposalClaimNo );

                }
            }
            if(proposalClaimNo.size()>0){
				List<Asset> foundAsset = [SELECT ID, SerialNumber FROM ASSET WHERE SerialNumber =:  proposalClaimNo AND Business_Unit__c = 'ABHI' LIMIT 1];
                if(!foundAsset.isEmpty()){
                    for(Case cs : abhiCases){
                    	cs.LAN__c  = foundAsset[0].SerialNumber;
                    }
                }
                else {
                	List<Claim__c > foundAssetClaim = [SELECT ID, Policy_Number__c , Name  FROM Claim__c WHERE Name =:  proposalClaimNo LIMIT 1];
                    if(!foundAsset.isEmpty()){
                        for(Case cs : abhiCases){
                            cs.LAN__c  = foundAssetClaim[0].Policy_Number__c;
                        }
                    }
                }
            }
            else {
               // associateCustomerForAPIFromPhoneNumber(cases);
            }
        }
          catch(Exception e){
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('associateCustomerForAPIFromPhoneNumber failed for ABHI');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
}