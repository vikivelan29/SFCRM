/**
* @description       ABSLI Legacy View 
* @author            : aditya.mehrotra@salesforce.com
* @group             : 
* @last modified on  : 08-07-2024
* @last modified by  : aditya.mehrotra@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   08-07-2024   aditya.mehrotra@salesforce.com   Initial Version
**/
public with sharing class ABSLI_LegacyViewController {
    @AuraEnabled(cacheable = true)
    public static List<PolicyName> getRelatedPolicyNames(Id accountId){
        List<PolicyName> policyList = new List<PolicyName>();
        for(Asset ast : [select id,Business_Unit__c, Policy_No__c, Account.Client_Code__c FROM
                         Asset WHERE AccountId = :accountId AND Business_Unit__c= :ABSLI_Constants.BUSINESS_UNIT
                         WITH SECURITY_ENFORCED])
        {
            PolicyName policy = new PolicyName();
            policy.label = ast.Policy_No__c;
            policy.value = ast.Policy_No__c;
            policyList.add(policy);
        }
        return policyList;
    }
    
    /*********************************************************
* @Class           PolicyName
* @Author          Aditya Mehrotra 
* @Created Date    08/07/2024
* @Last Modified   08/07/2024
* @description     PolicyName */
    public class PolicyName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    /* @LOB - ABFL
* @Function - getLegacyData
* @param customerId
* @param lanNumber
* @param startDate
* @param endDate
* @param lob
* @return  ResponseWrapper 
* @description  This method will get legacy date and display in SF
*****************************************************************************************************************/
    @AuraEnabled
    public static ResponseWrapper getLegacyData(String customerId, 
                                                String lanNumber, 
                                                String startDate, 
                                                String endDate, 
                                                String lob,
                                               String msdCaseNumber){
        try{
            ResponseWrapper response = null;
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABSLI_Legacy_Case';
            startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber, startDate, endDate, lob,msdCaseNumber));
            System.debug('conPayload --> '+conPayload);
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
            
            if(legacyCaseResponse.statusCode == 200 && String.isNotBlank(legacyCaseResponse.responseBody)) {
                legacyCaseResponseWrapper = (LegacyCaseResponseBodyWrapper)JSON.deserialize(legacyCaseResponse.responseBody,LegacyCaseResponseBodyWrapper.class);
                response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponseWrapper.lstDetails);     
                response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
                response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
            //If status code is not 200, Sending reponse in string
            else if(String.isNotBlank(legacyCaseResponse.responseBody)) {
                response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponse.responseBody);
                response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
                response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
            //If no response
            else {
                response = new ResponseWrapper(0, '');
                response.returnMessage = Label.ASF_Error_Case_Merge ;
            }
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    /*********************************************************
* @Class           LegacyViewRequest
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     LegacyViewRequest */
    public class LegacyViewRequest{
        String CustomerNumber;
        String PolicyNumber ;
        String CaseNumber;
        String FromDate;
        String ToDate;
        String LOB;
        LegacyViewRequest(String customerId, String holdingNumber, String fromDate, String toDate, String lob,String caseNumber){
            this.CustomerNumber = customerId;
            this.PolicyNumber  = holdingNumber;
            this.FromDate = fromDate;
            this.ToDate = toDate;
            this.LOB = lob;
            this.CaseNumber =caseNumber;
        }
    }
    /*********************************************************
* @Class           ResponseWrapper
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     ResponseWrapper */
    public Class ResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String returnCode;
        @AuraEnabled public String returnMessage;
        //Will be used only in case of failure
        @AuraEnabled public String response;
        @AuraEnabled public List<LegacyCaseResponseWrapper> legacyCaseResponse;
        public ResponseWrapper(Integer statusCode, List<LegacyCaseResponseWrapper> legacyCaseResponse){
            this.statusCode = statusCode;
            this.legacyCaseResponse = legacyCaseResponse;
        }
        public ResponseWrapper(Integer statusCode, String response){
            this.statusCode = statusCode;
            this.response = response;
        }
    }
    /*********************************************************
* @Class           LegacyCaseResponseWrapper
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     LegacyCaseResponseWrapper */
    public class LegacyCaseResponseWrapper{
        @AuraEnabled public String CaseId;
        @AuraEnabled public String CustomerId;
        @AuraEnabled public String PanNo;
        @AuraEnabled public String CustomerName;
        @AuraEnabled public String PolicyNo;
        @AuraEnabled public String ApplicationNo;
        @AuraEnabled public String SourceRequestSubmittedBy;
        @AuraEnabled public String CaseSource;
        @AuraEnabled public String Category;
        @AuraEnabled public String ProcessGroup;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String SubType;
        @AuraEnabled public String AssignedTeam;
        @AuraEnabled public String CaseOwner;
        @AuraEnabled public String CaseStatus;
        @AuraEnabled public String LastUpdatedOn;
        @AuraEnabled public String LastUpdatedBy;
        @AuraEnabled public String CreatedOn;
        @AuraEnabled public String CreatedBy;
        @AuraEnabled public String TeamResolutionStatus;
        @AuraEnabled public String ResolutionComment1;
        @AuraEnabled public String ResolutionComment2;	
        @AuraEnabled public String RCAComments;
        @AuraEnabled public String ReasonForDelay;	
        @AuraEnabled public String CaseComments;
        @AuraEnabled public String IGMSTokenNo;
    }
    /*********************************************************
* @Class           LegacyCaseResponseBodyWrapper
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     LegacyCaseResponseBodyWrapper */
    public class LegacyCaseResponseBodyWrapper{
        public String ReturnCode;
        public String ReturnMessage;
        public List<LegacyCaseResponseWrapper> lstDetails;
        public LegacyCaseResponseWrapper details;
    }
    /*********************************************************
* @Class           OptionsName
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     OptionsName */
    public class OptionsName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    
}