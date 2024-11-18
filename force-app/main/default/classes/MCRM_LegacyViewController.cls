/**
* @description       Wellness Legacy View 
* @author            : aditya.mehrotra@salesforce.com
* @group             : 
* @last modified on  : 11-12-2024
* @last modified by  : rsinghnagar@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   08-07-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.ExcessiveParameterList, PMD.NcssMethodCount, PMD.FieldNamingConventions')
public with sharing class MCRM_LegacyViewController {
    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - getRelatedContracts
    * @param accountId
    * @return - List<ContractName>
    * @description - Invoked from the Mcrm_getPolicyDetails Lwc components to send asset policy details.
    */
    @AuraEnabled(cacheable = true)
    public static List<ContractName> getRelatedContracts(Id accountId){
        try {
            List<ContractName> contractList = new List<ContractName>();
            for(Asset ast : [select id,Business_Unit__c, ContractId__c, Account.Client_Code__c FROM
                            Asset WHERE AccountId = :accountId AND Business_Unit__c= :System.Label.Wellness_BU
                            WITH SECURITY_ENFORCED])
            {
                ContractName contractRec = new ContractName();
                contractRec.label = ast.ContractId__c;
                contractRec.value = ast.ContractId__c;
                contractList.add(contractRec);
            }
            return contractList;
        } catch (Exception ex) {
            ABCL_Logger.logException('MCRM_LegacyViewController.getRelatedContracts',ex.getMessage());
            throw new AuraHandledException('Error : '+ex.getMessage()+' '+ex.getLineNumber());
        }
    }
    
    /*********************************************************
* @Class           ContractName
* @Author          Rajendra Singh Nagar
* @Created Date    08/07/2024
* @Last Modified   08/07/2024
* @description     ContractName */
    public class ContractName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - getLegacyData
    * @param customerId
    * @param lanNumber
    * @param startDate
    * @param endDate
    * @param lob
    * @param msdCaseNumber
    * @return - ResponseWrapper
    * @description - This method will get legacy date and display in SF
    */
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
            String integrationName = 'MCRM_Legacy_Case';
            startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber, startDate, endDate, 'ABHMW',msdCaseNumber));

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
        }catch(exception ex){
            ABCL_Logger.logException('MCRM_LegacyViewController.getLegacyData',ex.getMessage());
            throw new AuraHandledException('Error : '+ex.getMessage()+' '+ex.getLineNumber());
        }
    }
    /*********************************************************
* @Class           LegacyViewRequest
* @Author          Rajendra Singh Nagar 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     LegacyViewRequest */
    public class LegacyViewRequest{
        String CustomerNumber;
        String ContractNumber ;
        String CaseNumber;
        String FromDate;
        String ToDate;
        String LOB;
        LegacyViewRequest(String customerId, String holdingNumber, String fromDate, String toDate, String lob,String caseNumber){
            this.CustomerNumber = customerId;
            this.ContractNumber  = holdingNumber;
            this.FromDate = fromDate;
            this.ToDate = toDate;
            this.LOB = lob;
            this.CaseNumber =caseNumber;
        }
    }
    /*********************************************************
* @Class           ResponseWrapper
* @Author          Rajendra Singh Nagar 
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
        /****************************************************************************************************************
        * @description Custom constructor of ResponseWrapper class
        * @param statusCode
        * @param legacyCaseResponse
        *****************************************************************************************************************/
        public ResponseWrapper(Integer statusCode, List<LegacyCaseResponseWrapper> legacyCaseResponse){
            this.statusCode = statusCode;
            this.legacyCaseResponse = legacyCaseResponse;
        }
        /****************************************************************************************************************
        * @description Custom constructor of ResponseWrapper class
        * @param statusCode
        * @param response
        *****************************************************************************************************************/
        public ResponseWrapper(Integer statusCode, String response){
            this.statusCode = statusCode;
            this.response = response;
        }
    }
    /*********************************************************
* @Class           LegacyCaseResponseWrapper
* @Author          Rajendra Singh Nagar 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     LegacyCaseResponseWrapper */
    public class LegacyCaseResponseWrapper{ // NOPMD
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String CustomerType;
        @AuraEnabled public String CustomerID;
        @AuraEnabled public String CustomerName;
        @AuraEnabled public String ContractStatus;
        @AuraEnabled public String Origin;
        @AuraEnabled public String Partner;
        @AuraEnabled public String CaseStatus;
        @AuraEnabled public String BranchName;
        @AuraEnabled public String Product;
        @AuraEnabled public String CreatedBy;
        @AuraEnabled public String ApplicationNo;
        @AuraEnabled public String CaseResolvedOn;
        @AuraEnabled public String CaseCreatedOn;
        @AuraEnabled public String Category;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String CaseSubType;
        @AuraEnabled public String CaseSubSubType;
        @AuraEnabled public String ContractNumber;
        @AuraEnabled public String AssignedTeam;
        @AuraEnabled public String AssignedUser;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public String PlanName;
        @AuraEnabled public String AssignedBy;
        @AuraEnabled public String ContactNumber;
        @AuraEnabled public String Comments;
        @AuraEnabled public String ResolutionComments;
        @AuraEnabled public String FTR;
        @AuraEnabled public String Priority;
    }
    /*********************************************************
* @Class           LegacyCaseResponseBodyWrapper
* @Author          Rajendra Singh Nagar 
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
* @Author          Rajendra Singh Nagar 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     OptionsName */
    public class OptionsName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    
}