/******************************************************  
* Description      - Class for handling the data query on the LWC CreateCaseWithType
********************************************************
*/
public with sharing class ASF_CreateCaseWithTypeController {
    public static CaseDetailsWrapper objCaseDetailsWrapper = new CaseDetailsWrapper();
    public static final String STRING_ALL = 'All';
    public static final String STRING_LOB = 'LOB';
    public static final String STRING_CC ='CC';
    public static final String STRING_SEMI_COLON =';';
    public static final String STRING_COMMA =',';
    public static final String STRING_NORECORDERROR = System.Label.ASF_Case_NoRecordMessage;
    
    /****************************************************************************************************************
* @Description - Gets the Source tagged to User and its Relavant Channel list.     
* @return -  CaseDetailsWrapper - Wrapper containing Source and List of Channel.     
*****************************************************************************************************************/
    
    public static CaseDetailsWrapper getUserDetails(){
        User objUser = [SELECT Id, LOB__c,Business_Unit__c, Source_Code__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        String userSourceCode = objUser.Source_Code__c;
        String strLOB = String.isNotBlank(objUser.Business_Unit__c) ? objUser.Business_Unit__c.trim() :'';
        LOBMappingDetails__mdt choosenOneMTD;  
        
        // Return from Method if no CC or LOB mappping is present
        if(String.isBlank(strLOB))
            return objCaseDetailsWrapper;
        
        objCaseDetailsWrapper.userBu = strLOB;
        
        List<LOBMappingDetails__mdt> lstLOBMapping = new List<LOBMappingDetails__mdt>();
        
        // Priority 1: Checking both CC and LOB

        // Added userSourceCode filter in below query for dynamic rendering of source field value on UI. // Added by Anirudh Raturi
        lstLOBMapping  = [SELECT  Id, developerName, qualifiedApiName, MasterLabel,LOB__c,
                          Type__c, Channel__c,Source__c, CCValue__c,Exclusion_Bu_s__c
                          FROM LOBMappingDetails__mdt WHERE 
                          LOB__c =:strLOB AND Source_Code__c =:userSourceCode AND
                          IsActive__c = true 
                          LIMIT 1];
        
        
        if(!lstLOBMapping.isEmpty()){
            choosenOneMTD = lstLOBMapping[0];
        }
        
        
        // Populate relevant LOB Mapping Mtd details on objCaseDetailsWrapper
        if(choosenOneMTD != null){
            objCaseDetailsWrapper.strSource = choosenOneMTD.Source__c;
            List<String> lstChannel = choosenOneMTD.Channel__c.split(STRING_SEMI_COLON);
            objCaseDetailsWrapper.lstChannel = populateOptionWrapper(lstChannel);
        }
        
        return objCaseDetailsWrapper;
    }
    
    /****************************************************************************************************************
* @Description - Populates the KSC_OptionsWrapper with the Channel List .   
* @param lstChannel -  List of String containting the Channel List.
* @return -  List<KSC_OptionsWrapper> - Wrapper containing Channel List which can be iterated by lighnting-combobox.     
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
* @Description - Fetches relevant CCC records . 
* @param keyword -  Seached Keyword.
* @param asssetProductType - Relavant Business Unit of Selected Asset.
* @return -  CaseDetailsWrapper  - Returns CaseDetailsWrapper to LWC.     
*****************************************************************************************************************/
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getAccountData(String keyword ,string asssetProductType,string isasset) {
        return getAccountDataByCustomerType(keyword ,asssetProductType,isasset,''); 
    }
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getAccountDataByCustomerType(String keyword ,string asssetProductType,string isasset,String accRecordType) {
        objCaseDetailsWrapper = getUserDetails(); 
        String userBu=objCaseDetailsWrapper.userBu;
        string searchKeyword = '%' + keyword + '%';
        if(asssetProductType == '' || asssetProductType ==null )
            asssetProductType ='';
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
        
        String dynamicQuery = 'SELECT Id, Is_FTR_Journey__c, Nature__c, Product__c, Source__c, Type__c, Sub_Type__c, Type_Synonyms__c, Business_Unit__c, CCC_External_Id__c, First_Stage__c, Is_Bulk_Creatable__c, ASF_Is_Cloneable__c,Reopen_Days__c,Is_Transaction_Related__c  ' + //Functionality Clone SR - Santanu Oct27,2023 - added ASF_Is_Cloneable__c
            'FROM ASF_Case_Category_Config__c WHERE Process__c=\'Case\' AND';
        
        if(accRecordType != null && accRecordType != '' && userBu == 'Payments'){
            dynamicQuery += ' Custom_Segment__c  = \''+accRecordType+'\' AND';
        }
        
        if(isasset == 'true'){
            dynamicQuery += ' Only_CRN_Mandatory__c = true AND ('+
                'Sub_Type__c LIKE \'' + searchKeyword + '\' OR Type__c LIKE \'' + searchKeyword + '\' OR Type_Synonyms__c LIKE \'' + searchKeyword + '\')';
            
        }else if(isasset == 'closeCRN'){
            dynamicQuery += '  ('+
                'Sub_Type__c LIKE \'' + searchKeyword + '\' OR Type__c LIKE \'' + searchKeyword + '\' OR Type_Synonyms__c LIKE \'' + searchKeyword + '\')';
        }else{
            dynamicQuery += ' is_FA_Mandatory__c = true AND '+
                //'(ccc_product_Type__c = \''  +asssetProductType+'\' OR  ccc_product_Type__c LIKE \'' + searchProdType+'\' OR ccc_product_Type__c LIKE \''+ searchCommaSeperatedProdType+ ' \' OR ccc_product_Type__c LIKE \''+ searchCommaProdType+'\' OR ccc_product_Type__c LIKE \''+searchCommaSpaceProdType+ '\' OR ccc_product_Type__c LIKE \''+searchCommaSpaceAssetProdType+'\')'
                //+  'AND'+
                //ccc_product_Type__c field is not available in ABCL Dev
                '(Sub_Type__c LIKE \'' + searchKeyword + '\' OR Type__c LIKE \'' + searchKeyword + '\' OR ' +
                'Type_Synonyms__c LIKE \'' + searchKeyword + '\')';
            
            
        } 
        system.debug('dynamicQuery'+dynamicQuery);
        
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
            system.debug('exclusionBus'+exclusionBus);
            
            for(id cccId: searchResults.keySet()){
                ASF_Case_Category_Config__c ccc=  searchResults.get(cccId);
                if( String.isNotBlank(userBu) && String.isNotBlank(ccc.Business_Unit__c) 
                   && ccc.Business_Unit__c.contains(userBu)){
                       cccset.add(searchResults.get(cccId));  
                   } 
                
            }
            objCaseDetailsWrapper.lstCCCrecords = new list<ASF_Case_Category_Config__c> (cccset);
            
        }
        
        return objCaseDetailsWrapper;
    }
    
    
    
    
    /****************************************************************************************************************
* @Description - Wrapper class of  CaseDetailsWrapper.   
*****************************************************************************************************************/
    
    public class CaseDetailsWrapper{
        @AuraEnabled public List<ASF_Case_Category_Config__c> lstCCCrecords;
        @AuraEnabled public String strSource;
        @AuraEnabled public List<ASF_OptionsWrapper> lstChannel;
        @AuraEnabled public Boolean boolNoData;
        @AuraEnabled public String strErrorMessage;
        private list<string> exclusionBus;
        private string userBu;
        
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
    
    @AuraEnabled(Cacheable = true)
    public static Account getAccountRec( String recId){
        return [select id,Line_of_Business__c,Business_Unit__c,RecordType.Name  from account where id=:recId];
    }
}