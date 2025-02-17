/**
* @description       ABCD Legacy View 
* @author            : dhinesh.t@salesforce.com
* @group             : 
* @last modified on  : 02-13-2025
* @last modified by  : dhinesh.t@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   08-07-2024   aditya.mehrotra@salesforce.com   Initial Version
**/
public with sharing class ABCD_LegacyViewController {
    @AuraEnabled(cacheable = true)
    public static List<PolicyName> getRelatedPolicyNames(Id accountId){
        List<PolicyName> policyList = new List<PolicyName>();
        for(Asset ast : [select id,Business_Unit__c, Policy_No__c, Account.Client_Code__c FROM
                         Asset WHERE AccountId = :accountId
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
* @Author          Dhinesh
* @Created Date    : 02-13-2025
* @Last Modified   : 02-13-2025
* @description     PolicyName */
    public class PolicyName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    /* @LOB - ABCD
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
    public static ResponseWrapper getLegacyData(String mobileNumber, 
                                                String email, String startDate, String endDate){
        try{
            ResponseWrapper response = null;
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABCD_Legacy_Case';
            startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new LegacyViewRequest(mobileNumber, email, startDate, endDate));
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
* @Author          dhinesh.t@salesforce.com
* @Created Date    : 02-13-2025
* @Last Modified   : 02-13-2025
* @description     LegacyViewRequest */
    public class LegacyViewRequest{
        String PhoneNumber;
        String Email_Id ;
        String LOB;
        String FromDate;
        String ToDate;
        LegacyViewRequest(String mobileNumber, String email, String fromDate, String toDate){
            this.PhoneNumber = mobileNumber;
            this.Email_Id  = email;
            this.LOB = 'OneABC';
            this.FromDate = fromDate;
            this.ToDate = toDate;
        }
    }
    /*********************************************************
* @Class           ResponseWrapper
* @Author          dhinesh.t@salesforce.com
* @Created Date    : 02-13-2025
* @Last Modified   : 02-13-2025
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
* @Author          dhinesh.t@salesforce.com
* @Created Date    : 02-13-2025
* @Last Modified   : 02-13-2025
* @description     LegacyCaseResponseWrapper */
    public class LegacyCaseResponseWrapper{
        @AuraEnabled public String LOB;
        @AuraEnabled public String AgeingDays;
        @AuraEnabled public String AssignedTeam;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String CaseSubType;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String Category;
        @AuraEnabled public String GoldenID;
        @AuraEnabled public String ModifiedOn;
        @AuraEnabled public String ResolvedBy;
        @AuraEnabled public String ResolvedOn;
        @AuraEnabled public String CaseStatus;
        @AuraEnabled public String TATDeadline;
    }
    /*********************************************************
* @Class           LegacyCaseResponseBodyWrapper
* @Author          dhinesh.t@salesforce.com
* @Created Date    02-13-2025
* @Last Modified   02-13-2025
* @description     LegacyCaseResponseBodyWrapper */
    public class LegacyCaseResponseBodyWrapper{
        public String ReturnCode;
        public String ReturnMessage;
        public List<LegacyCaseResponseWrapper> lstDetails;
        public LegacyCaseResponseWrapper details;
    }
    /*********************************************************
* @Class           OptionsName
* @Author          dhinesh.t@salesforce.com
* @Created Date    02-13-2025
* @Last Modified   02-13-2025
* @description     OptionsName */
    public class OptionsName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    
}