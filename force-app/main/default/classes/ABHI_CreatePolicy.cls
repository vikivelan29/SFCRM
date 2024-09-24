/*********************************************************
*Class        :  ABHI_CreatePolicy
*Author       :  Aditee Churiwala
*Created Date :  06/31/2024
*Last Modified:  07/13/2024
*@description :  This class creates CRM Policy
*********************************************************/
public with sharing class ABHI_CreatePolicy {
    public ABHI_CreatePolicyWrapper createPolicyWrapper {get; set;}
    private static Id memberRecordTypeId = Schema.SObjectType.Customer_Member_Mapping__c.getRecordTypeInfosByDeveloperName().get('Customer_Member').getRecordTypeId();
	    
    public ABHI_CreatePolicy(String req) {
        createPolicyWrapper = (ABHI_CreatePolicyWrapper)JSON.deserialize(req, ABHI_CreatePolicyWrapper.class);
        parseObjects(createPolicyWrapper);
    }
   /**
    * @param customerLAN - ABHI_CreatePolicyWrapper
    * @return - ResponseWrapper 
    * @description - This method creates record in Account, Contact, Asset, LAN Mapping, Mem Mapping, Policy nomineee
    */
    public static void parseObjects(ABHI_CreatePolicyWrapper createPolicyWrapper) { 
        Account refAccount = null;
        Account acc = null;
        Asset refMasterPolicy = null;
        Contact con = null;
        Customer_Member_Mapping__c cusMemMapping = null;
        LAN_Mapping__c lanMap = null;
        Sobject refObject = null;
        String clientcode = '';
        Boolean isBusinessAccount = false;
        
        List<Map<String,Object>> mapCustList = new List<Map<String,Object>>();
        List<Map<String,Object>> mapPreviousPolicyList = new List<Map<String,Object>>();
        List<Map<String,Object>> mapCustMemMappingList = new List<Map<String,Object>>();
        List<Map<String,Object>> mapNomineeDetailList = new List<Map<String,Object>>();
		List<Contact> conList = new List<Contact>();
        List<Customer_Member_Mapping__c> listCustMemMapping = new List<Customer_Member_Mapping__c>();
        List<LAN_Mapping__c> listLanMap = new List<LAN_Mapping__c>();
        
        Map<String, Account> accounts = new Map<String, Account>();
       // Map<String, List<ABHI_CreatePolicyWrapper.CustomerSegments>> mapCustSeg = new Map<String, List<ABHI_CreatePolicyWrapper.CustomerSegments>>();
       // Map<String, List<ABHI_CreatePolicyWrapper.CustomerRoles>> mapCustRole = new Map<String, List<ABHI_CreatePolicyWrapper.CustomerRoles>>();
        Map<String, Map<String, String>> mapObjectFieldMapping = new Map<String, Map<String, String>>();
        
        
        for(ABHI_CreatePolicyWrapper.Customer customers : createPolicyWrapper.Customer) {
            mapCustList.add((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(customers)));
        }
        if(createPolicyWrapper.CustomerMemberMapping != null) {
            for(ABHI_CreatePolicyWrapper.CustomerMemberMapping customerMem : createPolicyWrapper.CustomerMemberMapping) {
            	mapCustMemMappingList.add((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(customerMem)));
        	}
        }
        if(createPolicyWrapper.PreviousPolicyDetails != null) {
            for(ABHI_CreatePolicyWrapper.PreviousPolicyDetails previousPolicy : createPolicyWrapper.PreviousPolicyDetails) {
            	mapPreviousPolicyList.add((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(previousPolicy)));
        	}
        }
        if(createPolicyWrapper.NomineeDetails != null) {
            for(ABHI_CreatePolicyWrapper.NomineeDetails nominee : createPolicyWrapper.NomineeDetails) {
                mapNomineeDetailList.add((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(nominee)));
            }
        }    
        
        Map<String,Object> policyMap =  (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(createPolicyWrapper.Policy));
        
        for(ABHI_Field_Mapping__mdt fieldMap : [SELECT ID, ABHI_Field_API_Name__c, ABHI_JSON_Field_Name__c,
                                                 ABHI_Object_Mapping__r.DeveloperName, ABHI_Type__c, ABHI_Field_Type__c
                                                 FROM ABHI_Field_Mapping__mdt 
                                                 WHERE ABHI_Object_Mapping__r.DeveloperName IN :ABHI_Constants.POLICY_ALL_OBJECT]) {
                                                     if(!mapObjectFieldMapping.containsKey(fieldMap.ABHI_Object_Mapping__r.DeveloperName)) {
                                                         mapObjectFieldMapping.put(fieldMap.ABHI_Object_Mapping__r.DeveloperName, new Map<String, String>());
                                                         }
                                                         mapObjectFieldMapping.get(fieldMap.ABHI_Object_Mapping__r.DeveloperName).put(fieldMap.ABHI_JSON_Field_Name__c +'_'+ fieldMap.ABHI_Type__c + '_'+ fieldMap.ABHI_Field_Type__c , fieldMap.ABHI_Field_API_Name__c);
                                                 }
        //LAN is based of ProposalNumber-1st time ProposalNumber will be there
        Asset refPolicy = new Asset(ABHI_Policy_Id__c = (String)policyMap.get('ProposalNumber'));
        String masterPolicyNumber = (String)policyMap.get('MasterPolicyNumber');
        List<Asset> masterPolicy = null;
        if(!String.isBlank(masterPolicyNumber)) {
            //ABHI_Policy_Id__c is based on Policy no
            refMasterPolicy = new Asset(LAN__c = masterPolicyNumber);
            //Get master account Id
            masterPolicy = [SELECT Id,AccountId, Account.LOB_Client_Code__c FROM Asset WHERE LAN__c = :masterPolicyNumber];
           
        }    
        //<-------- Customer data starts ------>
        for(Map<String,Object> customer : mapCustList) {
            acc = new Account();
            
            clientcode = (String)customer.get('CoreSystemId');
            refAccount = new Account(LOB_Client_Code__c = ABHI_Constants.ABHI+'_'+clientcode);
            
            
            isBusinessAccount = (String.isBlank(masterPolicyNumber) && policyMap.get('ProposalNumber') != null && policyMap.get('PolicyType') != 'Retail')?true:false;
             System.debug('@@@isBusinessAccount'+isBusinessAccount);
            //isBusinessAccount = customer.get('CustomerType') == 'Group' ? true : false;
            
            if(customer.get('AddressType') == ABHI_Constants.PERMANENT) {
                acc.put('BillingStreet', createAddress((String)customer.get('AddressLine1'), (String)customer.get('AddressLine2'), (String)customer.get('AddressLine3')));
            }
            else if(customer.get('AddressType') == ABHI_Constants.OTHER) {
                acc.put('ShippingAddress', createAddress((String)customer.get('address2Line1'), (String)customer.get('Address2Line2'), (String)customer.get('Address3Line3')));
            }    
            //Creating contact for business accounts
            if(isBusinessAccount) {
                conList.add(new Contact(Account = refAccount, LastName = (String)customer.get('FullName'), Email = 
                                 (String)customer.get('Email'), MobilePhone = (String)customer.get('MobilePhone'),
                                 UniqueKey__c = ABHI_Constants.ABHI+clientcode, Maritual_Status__c = (String)customer.get('MaritualStatus'),
                                       Height__c = (String)customer.get('Height'), Weight__c = (String)customer.get('Weight'),
                                       Business_Unit__c = ABHI_Constants.ABHI, Line_of_Business__c = ABHI_Constants.ABHI));
            }
            
            //Mapping for fields from Custom metadata
            for(String json : mapObjectFieldMapping.get('Account').keyset()) {
                if(isBusinessAccount && json.split('_')[1] == ABHI_Constants.INDIVIDUAL) {
                    continue;
                }
                else if(!isBusinessAccount && json.split('_')[1]  == ABHI_Constants.NON_INDIVIDUAL) {
                    continue;
                }
                
                switch on json.split('_')[2] {
                    when 'Date', 'DateTime' {
                        acc.put(mapObjectFieldMapping.get('Account').get(json), customer.get(json.split('_')[0]) != null?Date.valueOf(customer.get(json.split('_')[0]).toString()):null);
                    }
                    when 'ID' {
                        if(customer.get(json.split('_')[0]) != null) {
                            acc.putSObject(mapObjectFieldMapping.get('Account').get(json), new Account(Client_Code__c = customer.get(json.split('_')[0]).toString()));
                        }
                    }
                    when else {
                        acc.put(mapObjectFieldMapping.get('Account').get(json), customer.get(json.split('_')[0]));
                    }
                }
            }
            acc.put('LOB_Client_Code__c', ABHI_Constants.ABHI+'_'+clientcode);
            acc.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
            acc.put('Line_of_Business__c', ABHI_Constants.ABHI);
            acc.put('BillingCity',createAddress((String)customer.get('City'), (String)customer.get('district_town'), ''));
            acc.put('ShippingCity',createAddress((String)customer.get('City2'), (String)customer.get('District2'), ''));
            accounts.put(acc.Client_Code__c, acc);
            
            System.debug('@@accounts'+accounts);
            //Creating LAN mapping for policy & customer
            lanMap = new LAN_Mapping__c(Customer__r = refAccount, LAN__r = refPolicy, Business_Unit__c = ABHI_Constants.ABHI, 
                                        UniqueKey__c = ABHI_Constants.ABHI+clientcode+policyMap.get('ProposalNumber').toString(),
                                       Source_System__c = ABHI_Constants.JARVIS);
            listLanMap.add(lanMap);
        }
        
        //<---------- Customer data ends ------>
        
        //Creating LAN mapping for policy & master customer
        if(masterPolicy != null && !masterPolicy.isEmpty()) {	
            lanMap = new LAN_Mapping__c(Customer__c = masterPolicy[0].AccountId, LAN__r = refPolicy, Business_Unit__c = ABHI_Constants.ABHI, 
                                        UniqueKey__c = ABHI_Constants.ABHI+masterPolicy[0].Account.LOB_Client_Code__c+policyMap.get('ProposalNumber').toString(),
                                        Source_System__c = ABHI_Constants.JARVIS);
            listLanMap.add(lanMap);
        }    
        
        //<---------- Customer mem mapping starts ------>
        if(!mapCustMemMappingList.isEmpty()) {
        	for(Map<String, Object> cusMap : mapCustMemMappingList) {
                cusMemMapping = new Customer_Member_Mapping__c();
                for(String json : mapObjectFieldMapping.get('Customer_Member_Mapping').keyset()) {
                    switch on json.split('_')[2] {
                        when 'Double' {
                            cusMemMapping.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json), Double.valueOf(cusMap.get(json.split('_')[0])));
                        }
                        when 'ID' {
                            refObject = new Account();
                            refObject.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json).split(':')[1], cusMap.get(json.split('_')[0]));
                            cusMemMapping.putSObject(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json).split(':')[0], refObject);
                        }
                        when else {
                            cusMemMapping.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json), cusMap.get(json.split('_')[0]));
                        }
                    }
                    
                } 
                cusMemMapping.Policy_Number__r = refPolicy;
                cusMemMapping.Business_Unit__c = ABHI_Constants.ABHI;
                cusMemMapping.RecordTypeId = memberRecordTypeId;
                //External ID = MemberId+ProposalNo, Also remove REcord from Field Mapping
                cusMemMapping.MemberExternalId__c  = clientcode = (String)cusMap.get('MemberId') + policyMap.get('ProposalNumber').toString();
                listCustMemMapping.add(cusMemMapping);
            }
        }
        //<---------- Customer mem mapping ends ------>
        
      	
        Asset policy = createAsset(policyMap, mapObjectFieldMapping.get('Asset'));
        
        
        upsert accounts.values() LOB_Client_Code__c ;
        upsert conList UniqueKey__c;
		Database.UpsertResult results = Database.upsert(policy, Asset.ABHI_Policy_Id__c);
        //upsert policy LAN__c;
        upsert listCustMemMapping MemberExternalId__c;        
        upsert listLanMap UniqueKey__c;
        
        Boolean isCreated = results.isSuccess() && results.isCreated();
        if(!mapNomineeDetailList.isEmpty()) {
            List<Policy_Nominee__c> policyNominee = createNominees(mapNomineeDetailList, mapObjectFieldMapping.get('Nominee'), policy, isCreated);
        	upsert policyNominee;
        }
       
        if(!mapPreviousPolicyList.isEmpty()) {
            List<Previous_Policy_Details__c> previousPolicy = createPreviousPolicy(mapPreviousPolicyList, mapObjectFieldMapping.get('Previous_Policy_Details'), policy);
        	upsert previousPolicy PreviousPolicyNumber__c ;
        }
       
        ABHI_CreateCRMPolicy.proposalNumber = policyMap.get('ProposalNumber').toString();
        //return  policyMap.get('ProposalNumber').toString();
    }
    
    /**
    * @param policyMap
    * @param policyObjectFieldMapping 
    * @return Asset 
    * @description - this method creates record in Asset
    */
    private static Asset createAsset(Map<String,Object> policyMap, Map<String, String> policyObjectFieldMapping) {
        Sobject policyRefs = null;
        Asset policy = new Asset();
        Account accountRef = new Account();
        Boolean nullFlag = false;
        Date nullDate = null;
        for(String policyMapping : policyObjectFieldMapping.keyset()) {
            switch on policyMapping.split('_')[2] {
                when 'Double' {
                    policy.put(policyObjectFieldMapping.get(policyMapping), Double.valueOf(policyMap.get(policyMapping.split('_')[0])));
                }
                when 'Date' {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split('_')[0]) != null && policyMap.get(policyMapping.split('_')[0]) != ''?Date.valueOf(policyMap.get(policyMapping.split('_')[0]).toString()):null);
                }
                when 'Boolean' {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split('_')[0]) != null?Boolean.valueOf(policyMap.get(policyMapping.split('_')[0]).toString()):false);
                    
                }
                when 'ID' {
                    if(policyMap.get(policyMapping.split('_')[0]) == null || policyMap.get(policyMapping.split('_')[0]) == '') {
                        continue;
                    }
                    else if(policyMapping.split('_')[1] == 'Account') {
                        policyRefs = new Account();
                        policyRefs.put(policyObjectFieldMapping.get(policyMapping).split(':')[1], policyMap.get(policyMapping.split('_')[0]));
                    }
                    else if(policyMapping.split('_')[1] == 'Asset') {
                        policyRefs = new Asset();
                        policyRefs.put(policyObjectFieldMapping.get(policyMapping).split(':')[1], policyMap.get(policyMapping.split('_')[0]));
                    }
                    policy.putSObject(policyObjectFieldMapping.get(policyMapping).split(':')[0], policyRefs);
                }
                when else {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split('_')[0]));
                }    
            }  
        }   
        policy.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
        /*Setting LAN__c ext Id to the Policy no
         First time PolicyNumber will be blank*/
        if(policyMap.get('PolicyNumber') != null) {
            System.debug('@@@LAN__c'+policyMap.get('PolicyNumber'));
            policy.put('LAN__c', policyMap.get('PolicyNumber'));
            policy.put('Name', policyMap.get('PolicyNumber'));
        }
        else {
            policy.put('Name', policyMap.get('ProposalNumber'));
        }
        
        return policy;
    }
    
    /**
    * @param nomineeList
    * @param nomineeFieldMapping
    * @param policyId
    * @return - List<Policy_Nominee__c> 
    * @description - this method creates nominees
    */
    private static List<Policy_Nominee__c> createNominees(List<Map<String,Object>> nomineeList, Map<String, String> nomineeFieldMapping, Asset policy, Boolean policyCreated) {
        List<Policy_Nominee__c> listPolicyNominee = new List<Policy_Nominee__c>();
        Policy_Nominee__c  policyNominee = null;
        Account acc = new Account();
        //Policy exists(not created) - need to delete existing nominees
        if(!policyCreated) {
            List<Policy_Nominee__c> existingNomineeList = [SELECT ID FROM Policy_Nominee__c WHERE Policy_Number__c = :policy.Id];
            if(!existingNomineeList.isEmpty()) {
                delete existingNomineeList;
            }
        }
        //Creating new mapping for nominees again
        for(Map<String,Object> nominee : nomineeList) {
            policyNominee = new Policy_Nominee__c ();
            for(String nomineeMapping : nomineeFieldMapping.keyset()) {
                switch on nomineeMapping.split('_')[2] {
                    when 'Double' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), Double.valueOf(nominee.get(nomineeMapping.split('_')[0])));
                    }
                    when 'Date' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split('_')[0]) != null && nominee.get(nomineeMapping.split('_')[0]) != ''?(Date)(nominee.get(nomineeMapping.split('_')[0])):null);
                    }
                    when 'Boolean' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split('_')[0]) != null?Boolean.valueOf(nominee.get(nomineeMapping.split('_')[0]).toString()):false); 
                    }
                    when 'ID' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), policy.Id);
                    }
                    when else {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split('_')[0]));
                    }    
                }  
            } 
            policyNominee.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
            //NomineeExternalId__c = <NomineeId><ProposalNumber>
            //policyNominee.put('NomineeExternalId__c', nominee.get('NomineeId').toString()+ policy.LAN__c);
            listPolicyNominee.add(policyNominee);
        }
        
        return listPolicyNominee;
    }
    
    /**
    * @param nomineeList
    * @param nomineeFieldMapping
    * @param policyId
    * @return - List<Policy_Nominee__c> 
    * @description - this method creates nominees
    */
     private static List<Previous_Policy_Details__c> createPreviousPolicy(List<Map<String,Object>> prevPolicyList, Map<String, String> prevPolicyFieldMapping, Asset policy) {
        List<Previous_Policy_Details__c> listPrevPolicy = new List<Previous_Policy_Details__c>();
        Previous_Policy_Details__c  prevPolicy = null;
        //Creating new mapping for previousPolicys again
        for(Map<String,Object> previousPolicy : prevPolicyList) {
            prevPolicy = new Previous_Policy_Details__c ();
            for(String prevPolMapping : prevPolicyFieldMapping.keyset()) {
                switch on prevPolMapping.split('_')[2] {
                    when 'Date' {
                        prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split('_')[0]) != null && previousPolicy.get(prevPolMapping.split('_')[0]) != ''?(Date)(previousPolicy.get(prevPolMapping.split('_')[0])):null);
                    }
                    when 'Double' {
                        prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), Double.valueOf(previousPolicy.get(prevPolMapping.split('_')[0])));
                    }
                    when else {
                        prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split('_')[0]));
                    }    
                }  
            } 
            prevPolicy.put('Policy__c', policy.Id);
            prevPolicy.put('Customer__c', policy.AccountId);
            listPrevPolicy.add(prevPolicy);
        }
        
        return listPrevPolicy;
    }
    /**
    * @param street1
    * @param street2
    * @param street3
    * @return - String 
    * @description - this method creates address based on input
    */
    private static String createAddress(String street1, String street2, String street3) {
        String result = (street1 != NULL ? street1 : '')+
            (street2 != NULL ? street2 : '')+
            (street3 != NULL ? street3 : '');
        
        return result.length()>255?result.substring(0, 255):result;
    }
}
