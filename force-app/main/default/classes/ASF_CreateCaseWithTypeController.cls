/******************************************************  
* @description      - Class for handling the data query on the LWC CreateCaseWithType
********************************************************
*/
@SuppressWarnings('PMD.ApexSOQLInjection')
public with sharing class ASF_CreateCaseWithTypeController {
    public static CaseDetailsWrapper objCaseDetailsWrapper = new CaseDetailsWrapper();
    public static final String STRING_ALL = 'All';
    public static final String STRING_LOB = 'LOB';
    public static final String STRING_CC ='CC';
    public static final String STRING_SEMI_COLON =';';
    public static final String STRING_COMMA =',';
    public static final String STRING_NORECORDERROR = System.Label.ASF_Case_NoRecordMessage; 
    
    /****************************************************************************************************************
    * @description  Gets the Source tagged to User and its Relavant Channel list.     
    * @return  CaseDetailsWrapper
    *****************************************************************************************************************/
    
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getUserDetails(){

        String source = '';
        String subSource = ''; 
        Map<String, String> sourceToSubsource = new Map<String, String>();
        User objUser = [SELECT Id, LOB__c,Business_Unit__c, Source_Code__c FROM User WHERE Id =: UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1 ];
        String userSourceCode = objUser.Source_Code__c;
        String strLOB = String.isNotBlank(objUser.Business_Unit__c) ? objUser.Business_Unit__c.trim() :'';
        LOBMappingDetails__mdt choosenOneMTD;  
        
        // Return from Method if no CC or LOB mappping is present
        if(String.isBlank(strLOB)) {
            return objCaseDetailsWrapper;
        }
            
        objCaseDetailsWrapper.userBu = strLOB;
        
        List<LOBMappingDetails__mdt> lstLOBMapping = new List<LOBMappingDetails__mdt>();
        
        // Priority 1: Checking both CC and LOB

        // Added userSourceCode filter in below query for dynamic rendering of source field value on UI. // Added by Anirudh Raturi
        lstLOBMapping  = [SELECT  Id, developerName, qualifiedApiName, MasterLabel,LOB__c,
                          Type__c, Channel__c,Source__c,New_Source__c , Sub_Source__c, CCValue__c,Exclusion_Bu_s__c, Complaint_Type__c
                          FROM LOBMappingDetails__mdt WHERE 
                          LOB__c =:strLOB AND Source_Code__c =:userSourceCode AND
                          IsActive__c = true 
                          WITH SYSTEM_MODE
                          LIMIT 1];
        
        
        if(!lstLOBMapping.isEmpty()){
            choosenOneMTD = lstLOBMapping[0];
        }
        
        
        // Populate relevant LOB Mapping Mtd details on objCaseDetailsWrapper
        if(choosenOneMTD != null){
            //source = choosenOneMTD.Source__c;
            //AM-Updated the name of source__c to New_Source__c and 
            //field type from text to long text to accommodate ABSLI sources
            source = choosenOneMTD.New_Source__c;
            subSource = choosenOneMTD.Sub_Source__c;
            sourceToSubsource.put(source, subSource);
            objCaseDetailsWrapper.strSource = source;
            objCaseDetailsWrapper.complaintType = choosenOneMTD.Complaint_Type__c;
            objCaseDetailsWrapper.mapOfSourceToSubsource = sourceToSubsource;
            List<String> lstChannel = new List<String>();
            if(choosenOneMTD.Channel__c != null){
                lstChannel = choosenOneMTD.Channel__c.split(STRING_SEMI_COLON);
            }
            objCaseDetailsWrapper.lstChannel = populateOptionWrapper(lstChannel);
        }
        
        return objCaseDetailsWrapper;
    }
    
    /****************************************************************************************************************
    * @description  Populates the ASF_OptionsWrapper with the Channel List .   
    * @param lstChannel
    * @return  List<ASF_OptionsWrapper>
    *****************************************************************************************************************/
    
    public static List<ASF_OptionsWrapper> populateOptionWrapper( List<String> lstChannel){
        List<ASF_OptionsWrapper> lstOptionWrapper = new List<ASF_OptionsWrapper>();
        for(String strValue : lstChannel){
            ASF_OptionsWrapper objOptionWrapepr = new ASF_OptionsWrapper();
            objOptionWrapepr.label = strValue;
            objOptionWrapepr.value = strValue;
            lstOptionWrapper.add(objOptionWrapepr);
        }
        return lstOptionWrapper;
    }
    
    /****************************************************************************************************************
    * @description - Fetches relevant CCC records . 
    * @param keyword 
    * @param asssetProductType
    * @param isasset
    * @return  CaseDetailsWrapper
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getAccountData(String keyword ,string asssetProductType,string isasset) {
        return getAccountDataByCustomerType(keyword ,asssetProductType,isasset,'',''); 
    }
    /****************************************************************************************************************
    * @description - get Type SubType By Customer Details
    * @param keyword 
    * @param asssetProductType
    * @param isasset
    * @param accRecordType
    * @param assetLob
    * @param inpArg
    * @return  CaseDetailsWrapper
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getTypeSubTypeByCustomerDetails(String keyword ,string asssetProductType,string isasset,String accRecordType,string assetLob,String inpArg) {
        CaseDetailsWrapper returnVal = new CaseDetailsWrapper();
        returnVal = getAccountDataByCustomerType(keyword ,asssetProductType,isasset,accRecordType,assetLob); 
        //List<ASF_Case_Category_Config__c> finalValues = new List<ASF_Case_Category_Config__c>();
        String loggedInUsersBU = returnVal.userBu;
        if(loggedInUsersBU == 'ABFL'){
            // BU SPECIFIC LOGIC
            returnVal.lstCCCrecords = ABFL_CreateCaseWithTypeControllerHelper.filterCTSTBasedOnBULogic(returnVal.lstCCCrecords,inpArg);
        }
        else if (loggedInUsersBU == 'ABHFL'){
            // BU SPECIFIC LOGIC
        }
        else if(loggedInUsersBU == 'Payments'){
            // BU SPECIFIC LOGIC
        }
        else{
            
        }
        
        return returnVal;
    }
     /****************************************************************************************************************
    * @description getAccountDataByCustomerType
    * @param keyword 
    * @param asssetProductType
    * @param accRecordType
    * @param isasset
    * @param assetLob
    * @return  CaseDetailsWrapper
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getAccountDataByCustomerType(String keyword ,string asssetProductType,string isasset,String accRecordType,string assetLob) {
        objCaseDetailsWrapper = getUserDetails();
        String userBu=objCaseDetailsWrapper.userBu;
        string searchKeyword = '%' + String.escapeSingleQuotes(keyword) + '%';
        if(asssetProductType == '' || asssetProductType ==null ) {
            asssetProductType ='';
        }
        //String loanTypes ;
        if(asssetProductType == ASF_Constants.STRING_IS_API_LOAD){
            asssetProductType = 'Loans';
        }
        string searchBusinessUnit = '%' + asssetProductType + '%';
        string searchProdType = '%' + asssetProductType + '%';
        String searchCommaSeperatedProdType = asssetProductType+','+'%';
        String searchCommaProdType = '%'+','+asssetProductType;
        String searchCommaSpaceprodType = '%'+','+' '+asssetProductType;
        String searchCommaSpaceAssetProdType = asssetProductType+' '+','+'%';
        String strSource = '%' + objCaseDetailsWrapper.strSource + '%';
        Set<String> setSourceValues = new Set<String>();
        setSourceValues.add(STRING_ALL);
        String userType = [select id,type__c from user where ID =: userInfo.getUserId()].type__c;
        map<id,ASF_Case_Category_Config__c> searchResults;
        set<ASF_Case_Category_Config__c> cccset= new set<ASF_Case_Category_Config__c>();
        
        String dynamicQuery = 'SELECT Id, Is_FTR_Journey__c, Nature__c, Product__c, Source__c, Type__c, Sub_Type__c, Type_Synonyms__c, Business_Unit__c, CCC_External_Id__c, First_Stage__c, Is_Bulk_Creatable__c, ASF_Is_Cloneable__c,Reopen_Days__c,Is_Transaction_Related__c,LOB__c,Allowed_Issue_Types__c,Show_FTR_Flag_on_Creation__c, Validation_method_during_creation__c  ' + //Functionality Clone SR - Santanu Oct27,2023 - added ASF_Is_Cloneable__c
            'FROM ASF_Case_Category_Config__c WHERE Process__c=\'Case\' AND';
        
        if(accRecordType != null && accRecordType != '' && userBu == 'Payments'){
            dynamicQuery += ' Custom_Segment__c  = \''+String.escapeSingleQuotes(accRecordType)+'\' AND';
        }

       if(isasset == 'true'){
            dynamicQuery += ' Only_CRN_Mandatory__c = true AND ('+
                'Sub_Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type_Synonyms__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\')';
            
        }else if(isasset == 'closeCRN'){
            dynamicQuery += '  ('+
                'Sub_Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type_Synonyms__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\')';
        }else if(isasset == 'Prospect'){
            // For Prospect Search cases.
            dynamicQuery += ' Is_Prospect_Related__c = true AND '+
                '(Sub_Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR ' +
                'Type_Synonyms__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\')';
        }
          else if(isasset == 'false' && userBu == 'ABFL' && assetLob !=null && assetLob != 'Not classified' ){
            dynamicQuery += ' is_FA_Mandatory__c = true AND '+
                '(Sub_Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR ' +
                'Type_Synonyms__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\')'+' AND LOB__c =\''+ String.escapeSingleQuotes(assetLob)+'\'';
        }
        else{
            dynamicQuery += ' is_FA_Mandatory__c = true AND '+
                '(Sub_Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR Type__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\' OR ' +
                'Type_Synonyms__c LIKE \'' + String.escapeSingleQuotes(searchKeyword) + '\')';
        }
        
        searchResults =
            new Map<Id, ASF_Case_Category_Config__c>(
                (List<ASF_Case_Category_Config__c>)Database.query(dynamicQuery));
        if(searchResults.values().isEmpty()) {
            objCaseDetailsWrapper.boolNoData = true;
            objCaseDetailsWrapper.strErrorMessage = STRING_NORECORDERROR;
        }
        objCaseDetailsWrapper.lstCCCrecords = searchResults.values();
        
        if(objCaseDetailsWrapper.lstCCCrecords.size()>0){
            list<string> exclusionBus= objCaseDetailsWrapper.exclusionBus;
            
            for(id cccId: searchResults.keySet()){
                ASF_Case_Category_Config__c ccc=  searchResults.get(cccId);
                if( String.isNotBlank(userBu) && String.isNotBlank(ccc.Business_Unit__c) 
                   && ccc.Business_Unit__c.equalsIgnoreCase(userBu)){
                       cccset.add(searchResults.get(cccId));  
                   } 
                
            }
            objCaseDetailsWrapper.lstCCCrecords = new list<ASF_Case_Category_Config__c> (cccset);
            
        }
        
        return objCaseDetailsWrapper;
    }
    
    
    
    
    /****************************************************************************************************************
* @description - Wrapper class of  CaseDetailsWrapper.   
*****************************************************************************************************************/
    
    public class CaseDetailsWrapper{
        @AuraEnabled public Map<String, String> mapOfSourceToSubsource;
        @AuraEnabled public List<ASF_Case_Category_Config__c> lstCCCrecords;
        @AuraEnabled public String strSource;
        @AuraEnabled public String complaintType;
        @AuraEnabled public List<ASF_OptionsWrapper> lstChannel;
        @AuraEnabled public Boolean boolNoData;
        @AuraEnabled public String strErrorMessage;
        private list<string> exclusionBus;
        private string userBu;
        
         /****************************************************************************************************************
        * @description - Wrapper class of  CaseDetailsWrapper.   
        *****************************************************************************************************************/
            
        public CaseDetailsWrapper(){
            lstCCCrecords = new List<ASF_Case_Category_Config__c>();
            strSource = ASF_Constants.STRING_BLANK;
            lstChannel = new List<ASF_OptionsWrapper>();
            boolNoData = false;
            strErrorMessage = ASF_Constants.STRING_BLANK;
            exclusionBus= new list<string>();
            userBu = '';
        }
    }
    
    /****************************************************************************************************************
* @Description - Boolean
* @return -  Boolean- -> Returns true if certain Permission set are assigned to user  
*****************************************************************************************************************/
    //Method not currently in use. Hence commenting to increase the code coverage. - Santanu 2 Nov 2023
    
    /*@AuraEnabled
public static Boolean getUserPermissionSet(){
Boolean boolShowDownloadButton = false;
Set<String> setBulkPermissionSet =  new  Set<String> {'Bulk_Upload_Admin','Bulk_Upload_User'};
List<PermissionSetAssignment> lstPSetAssgnment = new  List<PermissionSetAssignment>();
lstPSetAssgnment = [ SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId= :UserInfo.getUserId() AND PermissionSet.Name IN: setBulkPermissionSet];
if( lstPSetAssgnment.size()>0 ){
boolShowDownloadButton= true;
}
return boolShowDownloadButton;
}*/
      /****************************************************************************************************************
    * @description getAccountRec
    * @param recId 
    * @return  Account
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable = true)
    public static Account getAccountRec(String recId){
        return [select id,Line_of_Business__c,Business_Unit__c,RecordType.Name  from account where id=:recId WITH SYSTEM_MODE];
    }
}