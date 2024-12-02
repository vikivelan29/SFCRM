/**
* @File Name : ABHI_LOBSpecificLegacyViewMethods.cls
* @Description : Extension controller class for ABHI legacy case view
* @Author : Salesforce
* @Last Modified By : Aditya Jawadekar
* @Last Modified On : October 29, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 29, 2024 | Aditya Jawadekar  | Initial Version
**/
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions,PMD.TooManyFields')
public without sharing class ABHI_LOBSpecificLegacyViewMethods {
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - getAccountRelatedMembers
    * @param - strRecordId 
    * @return -  List<ABFL_LegacyView.OptionsName>
    * @description - This method will be used to fetch the related members of the Account
    *****************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<ABFL_LegacyView.OptionsName> getAccountRelatedMembers(String strRecordId){
        set<ABFL_LegacyView.OptionsName> optionList = new set<ABFL_LegacyView.OptionsName>();
        String strClientName;
        String strClientCode;
        for(Customer_Member_Mapping__c objCMM : [SELECT Id, Name, Client_Id__c, Client_Id__r.Name, Client_Id__r.Client_Code__c,
                                    Policy_Number__c, Business_Unit__c, MemberExternalId__c, MemberId__c, MemberId__r.Client_Code__c, MemberId__r.Name 
                                    FROM Customer_Member_Mapping__c
                                    WHERE Client_Id__c =: strRecordId AND Client_Id__r.Business_Unit__c =: ABHI_Constants.ABHI
                                    WITH SYSTEM_MODE]) {
            strClientName = objCMM.Client_Id__r.Name;
            strClientCode = objCMM.Client_Id__r.Client_Code__c;
            ABFL_LegacyView.OptionsName option = new ABFL_LegacyView.OptionsName();
            option.label = objCMM.MemberId__r.Name;
            option.value = objCMM.MemberId__r.Client_Code__c;
            optionList.add(option);
        }

        if(optionList.isEmpty()){
            for(Account objAccount : [SELECT Id, Name, Client_Code__c
                                    FROM Account
                                    WHERE Id =: strRecordId AND Business_Unit__c =: ABHI_Constants.ABHI
                                    WITH SYSTEM_MODE]) {
                strClientName = objAccount.Name;
                strClientCode = objAccount.Client_Code__c;
            }
        }

        ABFL_LegacyView.OptionsName originalOption = new ABFL_LegacyView.OptionsName();
        originalOption.label = strClientName;
        originalOption.value = strClientCode;
        optionList.add(originalOption);

        return new List<ABFL_LegacyView.OptionsName>(optionList);
    }

    /****************************************************************************************************************
    *  @LOB - ABHI
    * @Function - getLegacyData
    * @param mapRow
    * @return  ResponseWrapper 
    * @description  This method will get legacy data and display in SF
    *****************************************************************************************************************/
    @AuraEnabled
    public static ResponseWrapper getLegacyData(Map<String, Object> mapRow){
        try{
            ResponseWrapper response = null;
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout('ABFL_Legacy_Case',(String)JSON.serialize(mapRow),null);

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
				response.returnMessage = System.Label.ASF_Error_Case_Merge ;
            }
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getStackTraceString()+' '+e.getLineNumber());
        }
    }
    
     /*********************************************************
    * @Class           ResponseWrapper
    * @Author          Aditya Jawadekar
    * @Created Date    28/10/2024
    * @Last Modified   28/10/2024
    * @description     ResponseWrapper 
    **********************************************************/
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
    * @Author          Aditya Jawadekar
    * @Created Date    28/10/2024
    * @Last Modified   28/10/2024
    * @description     LegacyCaseResponseWrapper 
    ***********************************************************/
    public class LegacyCaseResponseWrapper{
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Customer;
        @AuraEnabled public String Origin;
        @AuraEnabled public String IsWrong;
        @AuraEnabled public String Category;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String CaseSubType;
        @AuraEnabled public String CaseSubSubType;
        @AuraEnabled public String CreatedOn;
        @AuraEnabled public String CreatedBy;
        @AuraEnabled public String ResolvedDate;
        @AuraEnabled public String CustomerTAT;
        @AuraEnabled public String Scheme;
        @AuraEnabled public String IsGrievance;
        @AuraEnabled public String Policy;
        @AuraEnabled public String Description;
        @AuraEnabled public String TypeOfDisposal;
        @AuraEnabled public String ResolutionComments;
        @AuraEnabled public String ClosureComments;
        @AuraEnabled public String SequenceId;
        @AuraEnabled public String ModifiedBy;
        @AuraEnabled public String ModifiedOn;
    }
     /*********************************************************
    * @Class           LegacyCaseResponseBodyWrapper
    * @Author          Aditya Jawadekar
    * @Created Date    28/10/2024
    * @Last Modified   28/10/2024
    * @description     LegacyCaseResponseBodyWrapper 
    **********************************************************/
    public class LegacyCaseResponseBodyWrapper{
		public String ReturnCode;
		public String ReturnMessage;
        public List<LegacyCaseResponseWrapper> lstDetails;
        public LegacyCaseResponseWrapper details;
    }
}