/**
* @description       : This Class perform Real Time API to Fetch Nominee Records from Core System.
* @author            : Virendra Patil
* @group             : 
* @last modified on  : 26-05-2024
* @last modified by  : Virendra
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   01-17-2024   Virendra Patil   Initial Version
**/
public with sharing class ABSLI_NomineeDetailController {
    @AuraEnabled(Cacheable = true)
    public static nomineeResponse getNomineeFromCore(String policyId){
        nomineeResponse retVal = new nomineeResponse();
        System.debug('policyId --> '+policyId);
        Asset policy = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT LIMIT 1];
        
        ObjRequest custSearchReqWrapper = new ObjRequest(policy.Policy_No__c);
        
        string custSearchReqBody = JSON.serialize(custSearchReqWrapper);
        ABCL_IntegrationCallout.IntegrationResponseWrapper policyNomineeResp = 
            ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FETCH_POLICY_NOMINEE_METADATA,
                                                   custSearchReqBody,null);
        List<detail> details = new List<detail>();
        if(policyNomineeResp.statusCode == 200 && String.isNotBlank(policyNomineeResp.responseBody)){
            ObjResponse responseWrapper = (ObjResponse)System.JSON.deserialize(policyNomineeResp.responseBody,ObjResponse.class);
            if(responseWrapper.ReturnCode == '0'){
                if(responseWrapper.lstDetails.size()>0){
                    for(nomineeDetail nd : responseWrapper.lstDetails){
                        detail cls = new detail();
                        cls.name = nd.NOMINEE_NAME;
                        System.debug(nd.NOMINEE_NAME);
                        cls.appointee = nd.APPOINTEE;
                        cls.nomineeDob = nd.DOB_OF_NOMINEE;
                        cls.relationship = nd.RELATIONSHIP; 
                        cls.allocation = nd.ALLOCATION;
                        details.add(cls);
                    }
                    retVal.bSuccess = true;
                    retVal.nominees = details;
                }
                else{
                    retVal.bSuccess = false;
                    retVal.nominees = details;
                    retVal.errorMessage = responseWrapper.ReturnMessage;
                }
                
            } else{
                System.debug('policyNomineeResp.responseBody --> '+policyNomineeResp);
                retVal.bSuccess = false;
                retVal.nominees = details;
                retVal.errorMessage = 'Something wrong happened ! Please contact your system administrator.';
                System.debug('here');
            }
        }
        else{
            System.debug('policyNomineeResp.responseBody --> '+policyNomineeResp.responseBody);
            retVal.bSuccess = false;
            retVal.nominees = details;
            retVal.errorMessage = 'Something wrong happened ! Please contact your system administrator.';
            System.debug('here');
        }
        System.debug(retVal.nominees);
        return retVal;
    }
    public class ObjRequest{
        public string POLICY_NO{get;set;}
        public string ClientIPAddress{get;set;}
        public string DeviceID{get;set;}
        public string OS{get;set;}
        public string IMEI{get;set;}
        public ObjRequest(String polNumber){
            this.POLICY_NO = polNumber;
        }
    }
    public class ObjResponse{
        public string ReturnMessage{get;set;}
        public string ReturnCode{get;set;}
        public List<nomineeDetail> lstDetails{get;set;}
    }
    public class nomineeDetail{
        public string POLICY_NO{get;set;}
        public string NOMINEE_NAME{get;set;}
        public string APPOINTEE{get;set;}
        public string DOB_OF_NOMINEE{get;set;}
        public string RELATIONSHIP{get;set;}
        public string ALLOCATION{get;set;}
        public string SEQUENCENO{get;set;}
    }
    public class nomineeResponse{
        @AuraEnabled 
        public boolean bSuccess{get;set;}
        @AuraEnabled 
        public List<detail> nominees{get;set;}
        @AuraEnabled 
        public string errorMessage{get;set;}
    }
    public class detail{
        @AuraEnabled
        public string POLICY_NO{get;set;}
        @AuraEnabled
        public string name{get;set;}
        @AuraEnabled
        public string appointee{get;set;}
        @AuraEnabled
        public string nomineeDob{get;set;}
        @AuraEnabled
        public string relationship{get;set;}
        @AuraEnabled
        public string allocation{get;set;}
    }
    
    
}