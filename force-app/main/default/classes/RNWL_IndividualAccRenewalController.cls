/*********************************************************
*Class        :  RNWL_IndividualAccRenewalController
*Author       :  Raj Raghuwanshi 
*Created Date :  12/09/2024
*Last Modified:  12/09/2024
*@description  :  This class is used for calling Renewal Policy Details 
*********************************************************/
//Making the class without sharing because end user context will update the record.
public without sharing class RNWL_IndividualAccRenewalController {
    /****************************************************************************************************************
* @LOB - RNWL
* @Function - getPolicyRenewalDetails
* @param PolicyId - PolicyId
* payload - request body, urlParameters - Map of URL parameters
* @return - 
* @Description - Makes the callout
*****************************************************************************************************************/ 
    @AuraEnabled
    public static List<RNWL_RenewalWrapper> getPolicyRenewalDetails(String opportunityId){
        try{    
            List<Opportunity> oppList = [SELECT Id,Policy_Number__c,Proposal_Number__c,Premium_Amount__c 
                                         FROM Opportunity WHERE Id=:opportunityId LIMIT 1];
            
            String policyNumber = oppList[0].Policy_Number__c;
            
            Map<String, Object> rawResponseMap = new Map<String, Object>(); 
            
            Map<String, String> mapAPIResponse = RNWL_StoredResponseUtility.getResponseFromFiles(opportunityId , new List<String>{'Renewal Check'});
            
            String responseBody = mapAPIResponse.containsKey('Renewal Check') ? mapAPIResponse.get('Renewal Check') : ''  ;
            
            set<String> setMemberId = new set<String>(); 
            
            if(String.isBlank(responseBody)){ 
                String payload = '{"Policy_Number":"' + policyNumber + '","Source":"CRON-JOB"}';
                system.debug('payload'+payload);
                
                ABCL_IntegrationCallout.IntegrationResponseWrapper renewalDetailResponse = ABCL_IntegrationCallout.executeCallout('RNWL_RenewalDetail', payload, null);
                String fileName = 'Renewal Check-'+Date.today(); 
                
                responseBody = renewalDetailResponse.responseBody;
                
                if(String.isBlank(responseBody)) {
                    RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
                    objRenewalWrapper.ErrorCode = '400';
                    objRenewalWrapper.ErrorMessage = 'API Call Failed Please Retry'; 
                    List<RNWL_RenewalWrapper> lstRenewalWrapper = new List<RNWL_RenewalWrapper>();
                    lstRenewalWrapper.add(objRenewalWrapper);
                    return lstRenewalWrapper;
                }
                
                rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                
                Object objError = rawResponseMap.get('error');
                
                List<Object> lstError = new List<Object>();
                
                system.debug('objError'+objError); 
                
                if(objError instanceOf List<Object>){
                    lstError = (List<Object>) objError;  
                }
                else{
                    lstError.add(objError);
                }
                
                for(Object obj : lstError){
                    map<String, object> mapErrorToMessage = (map<String, object>)obj;
                    String strErrorCode = String.valueOf(mapErrorToMessage.get('ErrorCode'));
                    String strErrorMessage = String.valueOf(mapErrorToMessage.get('ErrorMessage'));
                    
                    if(String.isNotBlank(responseBody) && (strErrorCode == '00' || strErrorCode == '0')){
                        RNWL_NonIndAccountRenewalController.uploadFileToOpportunity(oppList[0].Id , responseBody , fileName , 'Renewal Check');
                    }
                    else{
                        RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
                        objRenewalWrapper.ErrorCode = strErrorCode;
                        objRenewalWrapper.ErrorMessage = strErrorMessage; 
                        List<RNWL_RenewalWrapper> lstRenewalWrapper = new List<RNWL_RenewalWrapper>();
                        lstRenewalWrapper.add(objRenewalWrapper);
                        return lstRenewalWrapper;
                        
                    }
                } 
            }else{
                rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            }
            
            
            List<Object> rawPolicyData = (List<Object>)((Map<String, Object>)rawResponseMap.get('response')).get('policyData');
            
            List<RNWL_RenewalWrapper> lstRenewalWrapper = new List<RNWL_RenewalWrapper>();
             
            for(object objPolicy : rawPolicyData){
                
                Map<String, Object> policyData_Map = (Map<String, Object>)objPolicy;
                if(policyNumber == String.valueOf(policyData_Map.get('Policy_number'))){
                    RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
                    
                    objRenewalWrapper.Id = Crypto.getRandomInteger();
                    objRenewalWrapper.Policy_renewal_date = String.valueOf(policyData_Map.get('Policy_renewal_date'));
                    objRenewalWrapper.Upsell_Flag = String.valueOf(policyData_Map.get('Upsell_Flag'));
                    objRenewalWrapper.Renewable_Flag = String.valueOf(policyData_Map.get('Renewable_Flag'));
                    objRenewalWrapper.Renewed_Flag = String.valueOf(policyData_Map.get('Renewed_Flag'));
                    objRenewalWrapper.sumInsuredtype = String.valueOf(policyData_Map.get('sumInsuredtype'));
                    objRenewalWrapper.Renewal_Net_Premium = String.valueOf(policyData_Map.get('Renewal_Net_Premium'));
                    objRenewalWrapper.Renewal_Gross_Premium = String.valueOf(policyData_Map.get('Renewal_Gross_Premium'));
                    objRenewalWrapper.Upsell_Net_Premium = String.valueOf(policyData_Map.get('Upsell_Net_Premium'));
                    objRenewalWrapper.Upsell_Gross_Premium = String.valueOf(policyData_Map.get('Upsell_Gross_Premium'));
                    
                    system.debug('policyData_Map Cross_sell_Reference_Number'+policyData_Map.get('Cross_sell_Reference_Number'));
                    system.debug('policyData_Map Is_cross_sell'+policyData_Map.get('Is_cross_sell'));
                    if(policyData_Map.containsKey('Is_cross_sell') && String.valueOf(policyData_Map.get('Is_cross_sell')) == 'Y'){
                        objRenewalWrapper.Is_cross_sell = 'Y';
                    } 
                    
                    objRenewalWrapper.Cross_sell_Reference_Number = policyData_Map.containsKey('Cross_sell_Reference_Number') ? String.valueOf(policyData_Map.get('Cross_sell_Reference_Number')) : '';
                    
                    objRenewalWrapper.Loading_Rate = policyData_Map.containsKey('Loading_Rate') ? String.valueOf(policyData_Map.get('Loading_Rate')) : '';
                    objRenewalWrapper.Loading_Reason = policyData_Map.containsKey('Loading_Reason') ? String.valueOf(policyData_Map.get('Loading_Reason')) : '';
                    
                    Map<String, Object> nominee_Map = (Map<String, Object>)policyData_Map.get('Nominee_Details');
                    
                    objRenewalWrapper.Nominee_Name = String.valueOf(nominee_Map.get('Nominee_Name'));
                    objRenewalWrapper.Nominee_Address = String.valueOf(nominee_Map.get('Nominee_Address'));
                    objRenewalWrapper.Nominee_Contact_No = String.valueOf(nominee_Map.get('Nominee_Contact_No'));

                    Map<String, Object> premium_Map = (Map<String, Object>)policyData_Map.get('premium');
                    
                    objRenewalWrapper.Renewal_Net_Premium = String.valueOf(premium_Map.get('Renewal_Net_Premium'));
                    objRenewalWrapper.Renewal_Gross_Premium = String.valueOf(premium_Map.get('Renewal_Gross_Premium'));
                    objRenewalWrapper.Upsell_Gross_Premium = String.valueOf(premium_Map.get('Upsell_Gross_Premium'));
                    objRenewalWrapper.Upsell_Net_Premium = String.valueOf(premium_Map.get('Upsell_Net_Premium'));  
    
                    List<Object> lstMember = (List<Object>) policyData_Map.get('Members');
                        
                    List<RNWL_RenewalWrapper.cls_Members> lstRenewalMembers = new List<RNWL_RenewalWrapper.cls_Members>();
                        
                    for(object member : lstMember){
                        
                        Map<String, Object> member_Map = (Map<String, Object>)member;
                        RNWL_RenewalWrapper.cls_Members objMember = new RNWL_RenewalWrapper.cls_Members();
                        
                        objMember.Name = String.valueOf(member_Map.get('Name'));
                        objMember.SumInsured = String.valueOf(member_Map.get('SumInsured'));
                        objMember.Upsell_SumInsured = String.valueOf(member_Map.get('Upsell_SumInsured'));
                        objMember.healthReturn = String.valueOf(member_Map.get('healthReturn'));
                        objMember.DoB = String.valueOf(member_Map.get('DoB'));
                        objMember.Gender = String.valueOf(member_Map.get('Gender'));
                        objMember.Email = String.valueOf(member_Map.get('Email'));
                        objMember.Mobile_Number = String.valueOf(member_Map.get('Mobile_Number'));
                        objMember.Relation = String.valueOf(member_Map.get('Relation'));
                        objMember.Chronic = String.valueOf(member_Map.get('Chronic'));
                        objMember.CB = String.valueOf(member_Map.get('CB'));
                        objMember.MemberId = String.valueOf(member_Map.get('MemberId'));
                        
                        setMemberId.add(String.valueOf(member_Map.get('MemberId')));  
                        
                        system.debug('MemberId'+objMember.MemberId);
                        
                        lstRenewalMembers.add(objMember);
                    } 
                    objRenewalWrapper.Members = lstRenewalMembers;
                    lstRenewalWrapper.add(objRenewalWrapper);
                } 
            }
            
            system.debug('lstRenewalWrapper '+lstRenewalWrapper);  
            
            if(!lstRenewalWrapper.isEmpty()){  
                updateValueForAccount(setMemberId, lstRenewalWrapper); 
            }
            
            List<object> renewInfoList = (List<object>)rawResponseMap.get('Renew_Info');
            Map<String,object> renewInfoMap = (Map<String,object>)renewInfoList[0];
            String renewedProposalNumber = renewInfoMap.containsKey('Renewed_Policy_Proposal_Number') ?  String.valueOf(renewInfoMap.get('Renewed_Policy_Proposal_Number')) : '';
            
            Boolean isUpdatedNeeded = false;
            
            if(!lstRenewalWrapper.isEmpty() && oppList[0].Premium_Amount__c != Decimal.valueOf(lstRenewalWrapper[0].Renewal_Gross_Premium)) {
                oppList[0].Premium_Amount__c = Decimal.valueOf(lstRenewalWrapper[0].Renewal_Gross_Premium);
                isUpdatedNeeded = true;
            }
            
            if(String.isNotBlank(renewedProposalNumber) && oppList[0].Proposal_Number__c != renewedProposalNumber){
                oppList[0].Proposal_Number__c = renewedProposalNumber;    
                isUpdatedNeeded = true;
            }
            
            if(isUpdatedNeeded) {
                system.debug(oppList);
                update oppList[0];
            }
            
            
            
            
            return lstRenewalWrapper;      
            
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    } 
    
    public static void getRenewalWrapperErrorInstance(String strErrorCode, String strErrorMessage, List<RNWL_RenewalWrapper> lstRenewalWrapper){
        RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
        objRenewalWrapper.ErrorCode = strErrorCode;
        objRenewalWrapper.ErrorMessage = strErrorMessage;  
        lstRenewalWrapper.add(objRenewalWrapper);
        return;
    }
    
    public static void updateValueForAccount(Set<String> setMemberId, List<RNWL_RenewalWrapper> lstRenewalWrapper){
        
        Map<String, Account> mapOfMemberIdToAccount = new Map<String, Account>();
        
        for(Account objAccount : [SELECT Client_Code__c, Chronic_Disease__c, PED__c FROM Account WHERE Client_Code__c IN : setMemberId]){
            mapOfMemberIdToAccount.put(objAccount.Client_Code__c, objAccount);
        }
        
        if(!mapOfMemberIdToAccount.isEmpty()){
            
            List<RNWL_RenewalWrapper.cls_Members> lstCls_Members = new List<RNWL_RenewalWrapper.cls_Members>();
            
            for(RNWL_RenewalWrapper.cls_Members objCls_Members : lstRenewalWrapper[0].Members ){
                
                if(mapOfMemberIdToAccount.containsKey(objCls_Members.MemberId)){
                    Account objAccount = mapOfMemberIdToAccount.get(objCls_Members.MemberId);
                    objCls_Members.Chronic_Disease = objAccount.Chronic_Disease__c;
                    objCls_Members.PED = objAccount.PED__c;   
                }
                lstCls_Members.add(objCls_Members);
            }
            
            lstRenewalWrapper[0].Members = lstCls_Members;
        }
        
        return;
    }
}
