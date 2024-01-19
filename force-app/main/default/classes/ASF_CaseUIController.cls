/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
**/
public without sharing class  ASF_CaseUIController {
    //get Asset Records for the time of selection while creating Case
    @AuraEnabled(Cacheable=false)
    public static List<account> getMatchingAccount(string userInp) {
        if(userInp!=null){
            Set<id> accIdSet = new Set<id>();
        List<contact> conList = New List<contact>();//database.query(queryField);
        	userInp = '%'+userInp+'%';
            System.debug(userInp);
            List<List<SObject>> searchList = 
                [FIND :userInp IN ALL FIELDS 
                RETURNING 
                Contact (Id, AccountId WHERE email  LIKE :userInp OR mobilePhone LIKE : userInp),
                Account (Id, Name WHERE Client_Code__c  LIKE : userInp OR Name LIKE : userInp),
                Asset (Id, AccountId WHERE Name  LIKE : userInp)
                ]; 
			
            System.debug(searchList);
            if(searchList[0].size()>0){
                conList = (List<contact>)searchList[0];
                for(Contact con: conList)
                    accIdSet.add(con.AccountId);
                
            }else if(searchList[1].size()>0){
                List<Account> accList = (List<Account>)searchList[1];
                for(Account acc: accList)
                    accIdSet.add(acc.Id);
            }else if(searchList[2].size()>0){
                List<Asset> assList = (List<Asset>)searchList[2];
                for(Asset ass: assList)
                    accIdSet.add(ass.AccountId);
            }
            
            List<account> accList = [select id,name,Client_Code__c from account where ID IN:accIdSet];
            return accList;
        }
        else{ return null; }
    }
    
    @AuraEnabled(Cacheable = true)
    public static list<ASF_Case_Category_Config__c> getAccountData(String keyword, String assetProductType,string withoutAsset,String accRecordType, String assetLob) {
        return ASF_CreateCaseWithTypeController.getAccountDataByCustomerType(keyword,assetProductType,withoutAsset,accRecordType,assetLob).lstCCCrecords;
    }
    
    @AuraEnabled(cacheable=true)
    public static conAssetWrapper getMatchingContacts(string accountId) {
        if(accountId!=''){
        List<asset> asstList = [select id,Name from asset where accountId =:accountId];
            
            conAssetWrapper wrapper = new conAssetWrapper(asstList);
            return wrapper;
        }
        else{
            return null;
        }
    }
    
    @AuraEnabled
    public static void updateCRN(string accountId,string assetId,String caseId, String faNumber) {
        
        Case cs = new Case();
        cs.Id = caseId;
        if(accountId != '')
            cs.AccountId = accountId;
        if(assetId != '')
            cs.AssetId  = assetId ;
        if(faNumber != '')
            cs.LAN__c = faNumber;
        update cs;
        
    }
    
    @AuraEnabled(cacheable= true)
    public static String getCaseRelatedObjName(string cccId){
        List<ASF_Case_Field_Config__c> fieldConfigRecords = [SELECT id,Field_Type__c ,FieldAPIName__c , ObjectAPIName__c , ReadOnly__c,IsControllingField__c , Update__c, Mandatory__c, Controlling_field__c, Controlling_Experssion__c, Default_Value__c,Case_Category_Config__c  FROM ASF_Case_Field_Config__c WHERE Case_Category_Config__c =:cccId]; 
        String ObjName;
        for(ASF_Case_Field_Config__c config : fieldConfigRecords){
            if(config.ObjectAPIName__c != 'Case'){
                ObjName = config.ObjectAPIName__c;
            }
        }return ObjName;
    }
    @AuraEnabled
    public static Case updateCase(String fields,string isAsset){
        
        Case cs = new Case();
        Map<String, Object> jsonRes = (Map<String, Object>)JSON.deserializeUntyped(fields);
        for(String fieldName : jsonRes.keySet())
            cs.put(fieldName, jsonRes.get(fieldName));
        
        Case recForOtherFields = [select id,accountId,assetId,ContactId  from case where Id =: cs.Id];
        System.debug('cs.Status -->'+cs.Status);
        if(cs.Status ==ASF_Constants.REJECTIONSTATUS || cs.Reject_Case__c == true ){
            update cs;
            return cs;
        }
        else if( isAsset == 'closeCRN' || (!String.isBlank(cs.Type_Text__c) &&  !String.isBlank(cs.Sub_Type_Text__c) && recForOtherFields.AccountId !=null) )
            update cs;
        else
            throw new AuraHandledException('Please update Customer/Contact');    
        return cs;
    }

    @AuraEnabled
    public static Id createCaseExtension(SObject record, SObject cccRec){
        try{
            Type customType = Type.forName('FrameworkFunctionalityExtender');
            ASF_FrameworkFunctionalityExtender extender = (ASF_FrameworkFunctionalityExtender)customType.newInstance();
            record = extender.populateBUSpecificFields(record, cccRec);
        }
        catch(Exception e){
            system.debug('Error inside createCaseExtension method of ASF_CaseUIController class '+e.getStackTraceString() + ' ' + e.getMessage());
        }
        insert record;
        return record.Id;
    }

    
    public class resWrapper{
        @AuraEnabled
        public string accId;
        @AuraEnabled
        public string accName;
        
        public resWrapper(String accId,String name){
            this.accId = accId;
            this.accName = name;
        }
    } 
    public class conAssetWrapper{
        
        @AuraEnabled
        public List<Asset> asstList;
        
        public conAssetWrapper(List<Asset> assetList){
            this.asstList = assetList;
        }
    }
    
}