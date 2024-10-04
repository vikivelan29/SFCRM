/*********************************************************
*Class        :  RNWL_IndividualAccRenewalController
*Author       :  Raj Raghuwanshi 
*Created Date :  12/09/2024
*Last Modified:  12/09/2024
*@description  :  This class is used for calling Renewal Policy Details 
*********************************************************/
public with sharing class RNWL_IndividualAccRenewalController {
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
            List<Opportunity> oppList = [SELECT Id,Policy_Number__c,Proposal_Number__c
                                         FROM Opportunity WHERE Id=:opportunityId LIMIT 1];
            
            String policyNumber = oppList[0].Policy_Number__c;
            system.debug('policyId '+policyNumber); 
            
            String responseBody = RNWL_NonIndAccountRenewalController.getResponseFromFiles(opportunityId , 'Renewal Check');
            system.debug('responseBody-'+responseBody);

            if(String.isBlank(responseBody)){
                String payload = '{"Policy_Number":"' + policyNumber + '","Source":"CRON-JOB"}';
                
                system.debug('payload'+payload);
                
                ABCL_IntegrationCallout.IntegrationResponseWrapper renewalDetailResponse = ABCL_IntegrationCallout.executeCallout('RNWL_RenewalDetail', payload, null);
                String fileName = 'Renewal Check-'+Date.today();
                responseBody = renewalDetailResponse.responseBody;
                if(String.isNotBlank(responseBody)){
                    RNWL_NonIndAccountRenewalController.uploadFileToOpportunity(oppList[0].Id , responseBody , fileName , 'Renewal Check');
                }
            }
            
            Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
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
                        
                        lstRenewalMembers.add(objMember);
                    }
                    
                    objRenewalWrapper.Members = lstRenewalMembers;
                    lstRenewalWrapper.add(objRenewalWrapper);
                }
            }
            system.debug('lstRenewalWrapper '+lstRenewalWrapper);  

            List<object> renewInfoList = (List<object>)rawResponseMap.get('Renew_Info');
            Map<String,object> renewInfoMap = (Map<String,object>)renewInfoList[0];
            String renewedProposalNumber = renewInfoMap.containsKey('Renewed_Policy_Proposal_Number') ?  String.valueOf(renewInfoMap.get('Renewed_Policy_Proposal_Number')) : '';
            
            if(String.isNotBlank(renewedProposalNumber) && oppList[0].Proposal_Number__c != renewedProposalNumber){
                oppList[0].Proposal_Number__c = renewedProposalNumber;
                system.debug(oppList);
                update oppList[0];
            }

            return lstRenewalWrapper;      
            
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

    
}