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

    /* when agent wants to recategrize , there is existing CCC id.
    So agent should not see current CCC id. But other ids to change,
    Hence this method 
    */
    @AuraEnabled(Cacheable = true)
    public static CaseDetailsWrapper getTypeSubTypeDataByCustomerType(String keyword ,string asssetProductType,string isasset,String accRecordType, String currentCCCId) {
        CaseDetailsWrapper originalList = getAccountDataByCustomerType(keyword,asssetProductType,isasset,accRecordType);
        List<ASF_Case_Category_Config__c> filteredCCCList = new List<ASF_Case_Category_Config__c>();
        for(ASF_Case_Category_Config__c ccc : originalList.lstCCCrecords){
            if (ccc.CCC_External_Id__c != currentCCCId ){
                filteredCCCList.add(ccc);
            }

        }
        originalList.lstCCCrecords = filteredCCCList;
        return originalList;
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
        
        String dynamicQuery = 'SELECT Id, Is_FTR_Journey__c, Nature__c, Product__c, Source__c, Type__c, Sub_Type__c, Type_Synonyms__c, Business_Unit__c, CCC_External_Id__c, First_Stage__c, Is_Bulk_Creatable__c, ASF_Is_Cloneable__c,Reopen_Days__c,Is_Transaction_Related__c,LOB__c  ' + //Functionality Clone SR - Santanu Oct27,2023 - added ASF_Is_Cloneable__c
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
        return [select id,Line_of_Business__c,RecordType.Name  from account where id=:recId];
    }

    @AuraEnabled(Cacheable = true)
    public static Map<String,Object> getCaseRecordDetails( String recId){
        map<String,object> resultMap = new map<String,object>();

        Case currentRecord =  [SELECT id,
                                        RecordType.Name,
                                        CCC_External_Id__c,
                                        Stage__c,
                                        account.Business_Unit__c,
                                        account.recordtype.name,
                                        accountId,
                                        assetId,
                                        Nature__c,
                                        Source__c,
                                        Channel__c,
                                        isClosed,
                                        (SELECT Stage__c,
                                                Stage_End_Date__c,
                                                is_Running_Record__c    
                                        FROM SR_SLA_Histories__r)  
                                    FROM Case 
                                WHERE id=:recId];
        String extensionObjecAPIname = ASF_GetCaseRelatedDetails.getCaseRelatedObjName(currentRecord.CCC_External_Id__c);
        Set<String> uniqueStages = new Set<String>();
        if(currentRecord.isClosed){
            resultMap.put('recategorizeEnabled',false);
        }
        else {
            for(ASF_Case_SLA_History__c g: currentRecord.SR_SLA_Histories__r){
                uniqueStages.add(g.stage__c);
            }
            resultMap.put('recategorizeEnabled',uniqueStages.size() <= 1);
        }
       
        resultMap.put('currentExtensionName',extensionObjecAPIname);
        resultMap.put('caseDetails',JSON.serialize(currentRecord));
        /*
         if there is more than one stage in SR history , then case is moved beyond first stage.
         hence block from recategorize.
        */
       
        return resultMap;

    }

    /*
        Old external Id is passed along with Case object which will have Nature , Product , Channel and New external Id.
        When external id is changed , there is possibility that extension object might change or new fields might be needed.
        So old external id might have diffrrent fields and now new field wil have different fields.
        If we start showing new fields , then old fields will be there , but no UI. 
        Hence its important to persist losing fields in  oldCCCIdFields__c which will have al fields in JSON
    */
    @AuraEnabled
    public static void updateCaseWithNewCCCId( String recId, String oldCCCId, String newCaseJson){
        /*
        newCaseJson looks like below
        '{"apiName":"Case","fields":{"CCC_External_Id__c":"payments_indi_206","Nature__c":"Query","Source__c":"Branch","Channel__c":"Walk in"}}'
        */

        List<ASF_Checklist__c> openCheckLists = [SELECT ID 
                                                FROM ASF_Checklist__c 
                                                WHERE Case__c = :recId 
                                                AND Systeminitiated__c = true];
        if(openCheckLists != null){                                        
            for(ASF_Checklist__c r : openCheckLists ){
                r.Status__c = 'Rejected';
            }
            update openCheckLists;
        }

        List<Task> openTasks = [SELECT ID
                                 FROM Task 
                                 WHERE WhatId = :recId 
                                 AND Systeminitiated__c = true];
        if(openTasks != null){                                                                 
            for(Task r : openTasks ){
                r.Status = 'Rejected';
            }
            update openTasks;
        }

        Map<String,Object> rawObj = (Map<String,Object>) JSON.deserializeUntyped(newCaseJson);
        Map<String,Object> caseObject =  (Map<String,Object>) rawObj.get('fields');
        Case toUpdateCase = new Case(Id=recId);
        toUpdateCase.CCC_External_Id__c = (String)caseObject.get('CCC_External_Id__c');
        toUpdateCase.Nature__c = (String)caseObject.get('Nature__c');
        toUpdateCase.Source__c = (String)caseObject.get('Source__c');
        toUpdateCase.Channel__c = (String)caseObject.get('Channel__c'); 
        toUpdateCase.Case_Stage_Change_Date__c = system.now();
        toUpdateCase.Recategorisation_Date__c = system.now();
        toUpdateCase.typeSubTypeMismatch__c = false;
        toUpdateCase.Recategorisation_Reason__c = (String)caseObject.get('Recategorisation_Reason__c');
        ASF_Case_Category_Config__c cccRecord = [Select First_Stage__c,type__c,Sub_Type__c From ASF_Case_Category_Config__c where CCC_External_Id__c = :toUpdateCase.CCC_External_Id__c Limit 1];
        String currentstageOfCase = cccRecord.First_Stage__c;

       /*
       null check is at done at app level and not at DB level. this is because 
       when we do null check at db , indexinf will go for TOSS
       SLA history is LDV and this will become long running query.
       */
        List<ASF_Case_SLA_History__c> slaHistoryList = [SELECT id,
                                                                oldExternalId__c 
                                                        FROM ASF_Case_SLA_History__c 
                                                        WHERE Case__c = :recId];
        List<ASF_Case_SLA_History__c> slaHistoryToUpdate = new List<ASF_Case_SLA_History__c>();
        for(ASF_Case_SLA_History__c r : slaHistoryList ){
            if(r.oldExternalId__c == null){
                r.oldExternalId__c	 = oldCCCId;
                r.OldTypeSubType__c = cccRecord.type__c + ' - ' + cccRecord.Sub_Type__c;
                slaHistoryToUpdate.add(r);
            }
        }

        update slaHistoryToUpdate;
        toUpdateCase.stage__c = currentstageOfCase;
        
        /*
        Use case 1: From stage and To Stage are same. but no owner change. SLA cnange
        Use case 2: From stage and To Stage are different. but no owner change. SLA cnange.
        From Stage may not exist in new stage. 

        TBD Integrations and Approvals will remain 
        
        1. change of account and asset
        */
        update toUpdateCase; 

    }
}