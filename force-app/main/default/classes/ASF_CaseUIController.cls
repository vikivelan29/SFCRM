/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
**/
@SuppressWarnings('PMD.ClassNamingConventions,PMD.MethodNamingConventions')
public with sharing class  ASF_CaseUIController {
    
    public static Case caseRecord; 

    @AuraEnabled
    public static Map<String,sObject> CreateProspectAndUpdateOnCase(Case caseToInsert,Lead prospectRecord){
        Map<String,sObject> mObjectVsRecId = new Map<String,sObject>();        
        Id salesProspectRTId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
        Id serviceProspectRTId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        User loggedInUser = [SELECT ID FROM User WHERE Id =: UserInfo.getUserId()];
        if(prospectRecord != null){
            // In case of Prospect Case, create Prospect first.
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(new List<Lead>{prospectRecord});
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            System.debug(matchRecord.getRecord());
                            mObjectVsRecId.put('DuplicateLead',matchRecord.getRecord());
                            return mObjectVsRecId;
                        }
                    }
                }
            }
            prospectRecord.RecordTypeId = serviceProspectRTId;
            if(prospectRecord.Sales_Prospect__c == true){
                prospectRecord.RecordTypeId = salesProspectRTId;
            }            
            insert prospectRecord;
            mObjectVsRecId.put('Lead',prospectRecord);
        }        
        if(caseToInsert != null){
            String sObjectName = '';
            if(caseToInsert.Lead__c == null){
                if(prospectRecord != null){
                    // In case of Internal Case - No need to create prospect.
                    caseToInsert.put('Lead__c',prospectRecord.Id);
                    caseToInsert.AccountId = null;
                    caseToInsert.ContactId = null;
                }                
            }            
            update caseToInsert;
            mObjectVsRecId.put('Case',caseToInsert);
        }
        
        return mObjectVsRecId;
    }
    
    //get Asset Records for the time of selection while creating Case
    @AuraEnabled(Cacheable=true)
    public static List<searchResponse> getMatchingAccount(string userInp, boolean accPreSelected) {
        List<searchResponse> lstResponse = new List<searchResponse>();        
        if(userInp!=null){
            Set<id> accIdSet = new Set<id>();
            if(!accPreSelected){
                List<contact> conList = New List<contact>();//database.query(queryField);
                String searchString = '*'+String.escapeSingleQuotes(userInp)+'*';
                userInp = '%'+userInp+'%';                
                System.debug('userInp-'+userInp);
              /*  List<List<SObject>> searchList =  
                    [FIND :searchString IN ALL FIELDS 
                    RETURNING 
                    Contact (Id, AccountId, email WHERE email LIKE :userInp OR mobilePhone LIKE : userInp OR Name Like : userInp),
                    Account (Id, Name, PersonEmail WHERE Client_Code__c  LIKE : userInp OR Name LIKE : userInp OR PersonEmail LIKE : userInp OR PAN__c LIKE : userInp),
                    Asset (Id, AccountId WHERE Name  LIKE : userInp),
                    Lead (Id,Name,mobilePhone,Email,PANNO__c WHERE FirstName LIKE : userInp OR mobilePhone LIKE : userInp)
                    ];  */
                List<List<SObject>> searchList = 
                    [FIND :searchString IN ALL FIELDS 
                    RETURNING 
                    Contact (Id, AccountId, email WHERE email LIKE :userInp OR mobilePhone LIKE : userInp OR Name Like : userInp),
                    Account (Id, Name, PersonEmail WHERE Client_Code__c  LIKE : userInp OR Name LIKE : userInp OR PersonEmail LIKE : userInp OR PAN__c LIKE : userInp OR PersonMobilePhone LIKE : userInp OR Advisor_Code__c LIKE : userInp),
                    Asset (Id, AccountId WHERE Name LIKE : userInp OR LAN__c LIKE : userInp OR Policy_No__c LIKE : userInp OR Application_Number__c LIKE : userInp),
                    Lead (Id,Name,mobilePhone,Email,PANNO__c WHERE Name LIKE : userInp OR mobilePhone LIKE : userInp OR Email LIKE : userInp)
                    ];
                
                System.debug(searchList[3]);
                if(searchList[0].size()>0){
                    conList = (List<contact>)searchList[0];
                    for(Contact con: conList)
                        accIdSet.add(con.AccountId);
                    
                }
                if(searchList[1].size()>0){
                    List<Account> accList = (List<Account>)searchList[1];
                    for(Account acc: accList)
                        accIdSet.add(acc.Id);
                }
                if(searchList[2].size()>0){
                    List<Asset> assList = (List<Asset>)searchList[2];
                    for(Asset ass: assList)
                        accIdSet.add(ass.AccountId);
                }
                if(searchList[3].size()>0){
                    for(Lead prospect : (List<Lead>)searchList[3]){
                        searchResponse resp = new searchResponse(prospect.Id,'Prospect',prospect.Name,'-NA-',prospect.Email,prospect.mobilePhone,prospect.PANNO__c,'','');
                        
                        lstResponse.add(resp);
                    }     
                }
            } else{
                Id accId = [select Id from account where Client_Code__c =: userInp].Id;
                accIdSet.add(accId);
            }
            
            List<account> accList = [select id,name,Client_Code__c,PersonEmail,PAN__c,PersonMobilePhone,Office_Email__c,IsPersonAccount,RecordType.Name,Advisor_Code__c,PAN_Number__c,Business_Unit__c from account where ID IN:accIdSet];
            Map<Id,contact> accIdConMap = new Map<Id,contact>();
            Set<Id> businessAccIdSet = new Set<Id>();
            for(Account accRec : accList){
                if(!accRec.IsPersonAccount){
                    businessAccIdSet.add(accRec.Id);
                }
            }
            for(contact conRec : [select Id, mobilePhone, email, AccountId from contact where AccountId IN: businessAccIdSet and Primary__c = true]){
                accIdConMap.put(conRec.AccountId,conRec);
            }
            for(Account customer : accList){
                searchResponse custResp;
                String customerType = customer.RecordType.Name == 'ABSLI Advisor' ? 'Advisor' : 'Customer';
                String panValue = customer.Business_Unit__c == ABHI_Constants.ABHI ? customer.PAN_Number__c : customer.PAN__c;
                if(customer.IsPersonAccount){
                    custResp = new searchResponse(customer.Id,customerType,customer.Name,customer.Client_Code__c,customer.PersonEmail,String.valueOf(customer.PersonMobilePhone),panValue,customer.RecordType.Name,customer.Advisor_Code__c);
                }else{
                    String phone = accIdConMap.containsKey(customer.Id)? String.valueOf(accIdConMap.get(customer.Id).mobilePhone) : '';
                    String email = accIdConMap.containsKey(customer.Id)? accIdConMap.get(customer.Id).email : '';

                    custResp = new searchResponse(customer.Id,customerType,customer.Name,customer.Client_Code__c,email,phone,panValue,customer.RecordType.Name,customer.Advisor_Code__c);
                }
                
                lstResponse.add(custResp);
            }
            for(integer i=0;i<lstResponse.size();i++){
                System.debug(lstResponse);
            }
            return lstResponse;
        }
        else{ return null; }
    }
    
    @AuraEnabled(Cacheable = true)
    public static list<ASF_Case_Category_Config__c> getAccountData(String keyword, String assetProductType,string withoutAsset,String accRecordType, String assetLob,String inpArg) {
        return ASF_CreateCaseWithTypeController.getTypeSubTypeByCustomerDetails(keyword,assetProductType,withoutAsset,accRecordType,assetLob,inpArg).lstCCCrecords;
    }
    
    @AuraEnabled(cacheable=true)
    public static conAssetWrapper getMatchingContacts(string accountId) {
        if(accountId!=''){
            Set<Id> assetIds = new Set<Id>();
            List<Asset> asstList = new List<Asset>();
            for(LAN_Mapping__c mapping : [SELECT ID,Customer__c,LAN__c FROM LAN_Mapping__c WHERE Customer__c =: accountId]){
                if(mapping.LAN__c != null){
                    assetIds.add(mapping.LAN__c);
                }
            }
            if(assetIds.size()>0 || accountId != null){
                
                asstList = [select id, Name, Product_Code__c, LAN__c, Disbursed_Amount__c, 
                            Loan_Disbursement_Status__c, Loan_Start_Date__c, Loan_End_Date__c, LOB__c, 
                            Policy_No__c, Status, Type__c, Application_Number__c, Zone__c, SM_Name__c, 
                            Plan_Name__c, ContractStartDate__c, ContractEndDate__c
                            from asset where Id =:assetIds OR AccountId =:accountId];
            }
            conAssetWrapper wrapper = new conAssetWrapper(asstList);
            return wrapper;
        }
        else{
            return null;
        }
    }
    
    @AuraEnabled
    public static void updateCRN(string accountId,string assetId,String caseId, String faNumber, Boolean reqFromRecat) {
        
        Case cs = new Case();
        cs.Id = caseId;

        if(accountId != ''){
            Id entityId = Id.ValueOf(accountId);
            if(entityId.getSObjectType() == Account.sObjectType){
            // fetch contact record to be updated/associated along with Account/Customer Tagging
                List<Contact> cont = [SELECT Id from Contact where AccountId = :accountId AND Primary__c = TRUE LIMIT 1];
                List<Account> account = [SELECT id, Client_Code__c from Account where Id =: accountId];
                if(!account.isEmpty()){
                    cs.AccountId = accountId;
                	cs.Client_Code_Text__c = account[0].Client_Code__c;
                }
                
                if(cont.size() > 0){// If contact found
                cs.ContactId = cont[0].Id;// UAT Bug fix Cases tagging to multiple Accounts
                }
                cs.Lead__c = null;
            }
            else if(entityId.getsObjectType() == Lead.sObjectType){
                cs.Lead__c = accountId;
                cs.AccountId = null;
                cs.AssetId = null;
                cs.ContactId =null;
            }
            
        }
        
        if(assetId != ''){
            cs.AssetId  = assetId;
        }
        if(faNumber != ''){
            cs.LAN__c = faNumber;
        }
            
        if(reqFromRecat){
            cs.Recategorisation_Date__c = system.now();
        }
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
        
        Case recForOtherFields = [select id,accountId,assetId,ContactId,Lead__c  from case where Id =: cs.Id];
        System.debug('cs.Status -->'+cs.Status);
        if(cs.Status ==ASF_Constants.REJECTIONSTATUS || cs.Reject_Case__c == true ){
            update cs;
            return cs;
        }
        else if( isAsset == 'closeCRN' || (!String.isBlank(cs.Type_Text__c) &&  !String.isBlank(cs.Sub_Type_Text__c) && recForOtherFields.AccountId !=null) )
            update cs;
        else if(isAsset == 'Prospect' && recForOtherFields.Lead__c != null){
            update cs;
        }
        else
            throw new AuraHandledException('Please update Customer/Contact');    
        return cs;
    }
    
    @AuraEnabled
    public static Id createCaseExtension(SObject record, SObject cccRec, Id caseId, String extnFieldName){
        try{
            if(extnFieldName != null){
                String query = String.escapeSingleQuotes('Select Id,Origin, '+extnFieldName+' from Case where Id = :caseId');
                Case caseRec = (Case)Database.query(query);
                caseRecord = caseRec;
                record.put('Id', caseRec.get(extnFieldName));
            }
            Type customType = Type.forName('FrameworkFunctionalityExtender');
            ASF_FrameworkFunctionalityExtender extender = (ASF_FrameworkFunctionalityExtender)customType.newInstance();
            record = extender.populateBUSpecificFields(record, cccRec);
        }
        catch(Exception e){
            system.debug('Error inside createCaseExtension method of ASF_CaseUIController class '+e.getStackTraceString() + ' ' + e.getMessage());
        }
        upsert record;
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
    
    public class searchResponse{
        @AuraEnabled
        public Id recordId{get;set;}
        @AuraEnabled
        public String objectType{get;set;}
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String clientCode{get;set;}
        @AuraEnabled
        public String emailId{get;set;}
        @AuraEnabled
        public String mobile{get;set;}
        @AuraEnabled
        public String pan{get;set;}
        @AuraEnabled
        public string objectRecordType{get;set;}
        @AuraEnabled
        public string advisorCode{get;set;}
        
        public searchResponse(String recId, String objType,String name,String clientCode,
                            String emailId,String mobile,String pan,String objRecordType, String advisorCode){
            this.recordId = recId;
            this.objectType = objType;
            this.name = name;
            this.clientCode = clientCode;
            this.emailId = emailId;
            this.mobile = mobile;
            this.pan = pan;
            this.objectRecordType = objRecordType;
            this.advisorCode = advisorCode;
                                
        }        
        
    }
}