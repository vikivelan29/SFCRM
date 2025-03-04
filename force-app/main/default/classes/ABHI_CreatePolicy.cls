/*********************************************************
*Class        :  ABHI_CreatePolicy
*Author       :  Aditee Churiwala
*Created Date :  08/10/2024
*Last Modified:  10/03/2024
*@description :  This class creates CRM Policy
*********************************************************/
public without sharing class ABHI_CreatePolicy {
    private static Id memberRecordTypeId = Schema.SObjectType.Customer_Member_Mapping__c.getRecordTypeInfosByDeveloperName().get('Customer_Member').getRecordTypeId();
    public ABHI_CreatePolicyWrapper createPolicyWrapper {get; set;}
    /*Used for Kavach policy*/
    public static ABHI_CreatePolicyWrapper createPolicyWrappers {get; set;}
	   
    /**
    * @param req - ABHI_CreatePolicyWrapper
    * @description - This constructor calls parseObjects
    */
    public ABHI_CreatePolicy(String req) {
        createPolicyWrapper = (ABHI_CreatePolicyWrapper)JSON.deserialize(req, ABHI_CreatePolicyWrapper.class);
        parseObjects(createPolicyWrapper);
    }
    /**
    * @param req - ABHI_CreatePolicyWrapper
    * @description - This constructor calls parseObjects for Kavach Policy creation
    */
    public static ABHI_CreatePolicyWrapper.ResponseWrapper createPolicy(String req) {
        try {
            createPolicyWrappers = (ABHI_CreatePolicyWrapper)JSON.deserialize(req, ABHI_CreatePolicyWrapper.class);
            parseObjects(createPolicyWrappers);
            return new ABHI_CreatePolicyWrapper.ResponseWrapper(createPolicyWrappers.StatusCode, createPolicyWrappers.Message);
        }
        catch(Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('KavachPolicy');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
            throw new AuraHandledException(Label.ASF_ErrorMessage);
        }
        
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
       // Contact con = null;
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
                                                         mapObjectFieldMapping.get(fieldMap.ABHI_Object_Mapping__r.DeveloperName).put(fieldMap.ABHI_JSON_Field_Name__c +':'+ fieldMap.ABHI_Type__c + ':'+ fieldMap.ABHI_Field_Type__c , fieldMap.ABHI_Field_API_Name__c);
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
        //throw exception if master policy doesn't exists
        if(!String.isBlank(masterPolicyNumber) && (masterPolicy == null || masterPolicy.isEmpty())) {
            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
            ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateCRMPolicy_Inbound');
            ASF_Case_Integration__c caseIntg = new ASF_Case_Integration__c(Type__c = 'CreateCRMPolicy');
            integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('100', ABHI_Constants.FAILURE, ABHI_Constants.MASTER_POLICY_ERROR), true);
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, true);
            throw new IllegalArgumentException(integrationResponse.responseBody);
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
                acc.put('Street_Address_1__c', createAddress((String)customer.get('AddressLine1'), (String)customer.get('AddressLine2'), (String)customer.get('AddressLine3')));
            }
            else if(customer.get('AddressType') == ABHI_Constants.OTHER) {
                acc.put('Street_Address_2__c', createAddress((String)customer.get('Address2Line1'), (String)customer.get('Address2Line2'), (String)customer.get('Address3Line3')));
            }    
            //Creating contact for business accounts
            if(isBusinessAccount) {
                String name = (customer.get('FullName') != '' || customer.get('FullName') != null) && ((String)customer.get('FullName')).length()>80?((String)customer.get('FullName')).substring(0,80):(String)customer.get('FullName');
                conList.add(new Contact(Account = refAccount, LastName = name, Email = 
                                 (String)customer.get('Email'), MobilePhone = (String)customer.get('MobilePhone'),
                                 UniqueKey__c = ABHI_Constants.ABHI+clientcode, Maritual_Status__c = (String)customer.get('MaritualStatus'),
                                       Height__c = (String)customer.get('Height'), Weight__c = (String)customer.get('Weight'),
                                       Business_Unit__c = ABHI_Constants.ABHI, Line_of_Business__c = ABHI_Constants.ABHI));
            }
            else {
                String fullName = (String)customer.get('FirstName')+' '+(String)customer.get('LastName');
                String fullNameCon = (fullName != '' || fullName != null) && fullName.length() > 255?fullName.substring(0,255):fullName;
                acc.put('Full_Name__pc', fullNameCon);
            }
            
            //Mapping for fields from Custom metadata
            for(String json : mapObjectFieldMapping.get('Account').keyset()) {
                if(isBusinessAccount && json.split(':')[1] == ABHI_Constants.INDIVIDUAL) {
                    continue;
                }
                else if(!isBusinessAccount && json.split(':')[1]  == ABHI_Constants.NON_INDIVIDUAL) {
                    continue;
                }
                
                switch on json.split(':')[2] {
                    when 'Date', 'DateTime' {
                        acc.put(mapObjectFieldMapping.get('Account').get(json), customer.get(json.split(':')[0]) != null?Date.valueOf(customer.get(json.split(':')[0]).toString()):null);
                    }
                    when 'ID' {
                        if(customer.get(json.split(':')[0]) != null) {
                            acc.putSObject(mapObjectFieldMapping.get('Account').get(json), new Account(Client_Code__c = customer.get(json.split(':')[0]).toString()));
                        }
                    }
                    when 'Boolean' {
                        acc.put(mapObjectFieldMapping.get('Account').get(json), customer.get(json.split(':')[0]) != null && customer.get(json.split(':')[0]) != 'No'?true:false);
                    }
                    when else {
                        if(mapObjectFieldMapping.get('Account').get(json) == 'FirstName') {
                            String firstName = (customer.get('FirstName') != '' || customer.get('FirstName') != null) && ((String)customer.get('FirstName')).length()>40?((String)customer.get('FirstName')).substring(0,40):(String)customer.get('FirstName');
                            acc.put(mapObjectFieldMapping.get('Account').get(json), firstName);
                        }
                        else if(mapObjectFieldMapping.get('Account').get(json) == 'LastName') {
                            String lastName = (customer.get('LastName') != '' || customer.get('LastName') != null) && ((String)customer.get('LastName')).length()>80?((String)customer.get('LastName')).substring(0,80):(String)customer.get('LastName');
                            acc.put(mapObjectFieldMapping.get('Account').get(json), lastName);
                        }
                        else {
                            acc.put(mapObjectFieldMapping.get('Account').get(json), customer.get(json.split(':')[0]));
                        }
                    }
                }
            }
            acc.put('LOB_Client_Code__c', ABHI_Constants.ABHI+'_'+clientcode);
            acc.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
            acc.put('Line_of_Business__c', ABHI_Constants.ABHI);
            acc.put('BillingCity',createAddress((String)customer.get('City'), (String)customer.get('district_town'), ''));
            acc.put('ShippingCity',createAddress((String)customer.get('City2'), (String)customer.get('District2'), ''));
            accounts.put(acc.Client_Code__c, acc);
            
            //Creating LAN mapping for policy & customer
            lanMap = new LAN_Mapping__c(Customer__r = refAccount, LAN__r = refPolicy, Business_Unit__c = ABHI_Constants.ABHI, 
                                        UniqueKey__c = ABHI_Constants.ABHI+clientcode+policyMap.get('ProposalNumber').toString(),
                                       Source_System__c = ABHI_Constants.JARVIS);
            listLanMap.add(lanMap);
        }
        //<---------- Customer data ends ------>
        
        //Creating LAN mapping for policy & master customer
	//Commenting to be sync with data load
        /*if(masterPolicy != null && !masterPolicy.isEmpty()) {	
            lanMap = new LAN_Mapping__c(Customer__c = masterPolicy[0].AccountId, LAN__r = refPolicy, Business_Unit__c = ABHI_Constants.ABHI, 
                                        UniqueKey__c = ABHI_Constants.ABHI+masterPolicy[0].Account.LOB_Client_Code__c+policyMap.get('ProposalNumber').toString(),
                                        Source_System__c = ABHI_Constants.JARVIS);
            listLanMap.add(lanMap);
        }  */  
        
        //<---------- Customer mem mapping starts ------>
        if(!mapCustMemMappingList.isEmpty()) {
        	for(Map<String, Object> cusMap : mapCustMemMappingList) {
                cusMemMapping = new Customer_Member_Mapping__c();
                for(String json : mapObjectFieldMapping.get('Customer_Member_Mapping').keyset()) {
                    switch on json.split(':')[2] {
                        when 'Double' {
                            cusMemMapping.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json),cusMap.get(json.split(':')[0])!= '' && cusMap.get(json.split(':')[0])!= null?Double.valueOf(cusMap.get(json.split(':')[0])):0);
                        }
                        when 'ID' {
                            refObject = new Account();
                            refObject.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json).split(':')[1], ABHI_Constants.ABHI+'_'+cusMap.get(json.split(':')[0]));
                            cusMemMapping.putSObject(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json).split(':')[0], refObject);
                        }
                        when 'Date' {
                            cusMemMapping.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json), cusMap.get(json.split(':')[0]) != null && cusMap.get(json.split(':')[0]) != ''?Date.valueOf(cusMap.get(json.split(':')[0])).toString():null);
                        }
                        when else {
                            cusMemMapping.put(mapObjectFieldMapping.get('Customer_Member_Mapping').get(json), cusMap.get(json.split(':')[0]));
                        }
                    }
                    
                } 
                cusMemMapping.Policy_Number__r = refPolicy;
                cusMemMapping.Policy_Number_Text__c = policyMap.get('PolicyNumber').toString();
                cusMemMapping.Business_Unit__c = ABHI_Constants.ABHI;
                cusMemMapping.RecordTypeId = memberRecordTypeId;
                //External ID = MemberId+ProposalNo, Also remove REcord from Field Mapping
                cusMemMapping.MemberExternalId__c  = clientcode = (String)cusMap.get('MemberId') + policyMap.get('ProposalNumber').toString();
                listCustMemMapping.add(cusMemMapping);
            }
        }
        //<---------- Customer mem mapping ends ------>

        Asset policy = createAsset(policyMap, mapObjectFieldMapping.get('Asset'));
        System.debug('@@@accounts1'+policy);
        upsert accounts.values() LOB_Client_Code__c ;
        upsert conList UniqueKey__c;
        //upsert policy ABHI_Policy_Id__c;

        Database.UpsertResult results = Database.upsert(policy, Asset.ABHI_Policy_Id__c);
        
        //System.debug('@@@results'+results);
        //upsert policy LAN__c;
        upsert listCustMemMapping MemberExternalId__c;        
        upsert listLanMap UniqueKey__c;
        
        Boolean isCreated = results.isSuccess() && results.isCreated();
        
        if(!mapNomineeDetailList.isEmpty()) {
            List<Policy_Nominee__c> policyNominee = createNominees(mapNomineeDetailList, mapObjectFieldMapping.get('Nominee'), policy, isCreated);
        	upsert policyNominee;
        }
        System.debug('@@@previousPolicy '+mapPreviousPolicyList);
        if(!mapPreviousPolicyList.isEmpty()) {
            List<Previous_Policy_Details__c> previousPolicy = createPreviousPolicy(mapPreviousPolicyList, mapObjectFieldMapping.get('Previous_Policy_Details'), policy);
        	upsert previousPolicy ;
        }
        ABHI_CreateCRMPolicy.proposalNumber = policyMap.get('ProposalNumber').toString();        
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
        for(String policyMapping : policyObjectFieldMapping.keyset()) {
            switch on policyMapping.split(':')[2] {
                when 'Double' {
                    policy.put(policyObjectFieldMapping.get(policyMapping),policyMap.get(policyMapping.split(':')[0]) != ''?Double.valueOf(policyMap.get(policyMapping.split(':')[0])):null);
                }
                when 'Date' {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split(':')[0]) != null && policyMap.get(policyMapping.split(':')[0]) != ''?Date.valueOf(policyMap.get(policyMapping.split(':')[0]).toString()):null);
                }
                when 'Boolean' {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split(':')[0]) != null && policyMap.get(policyMapping.split(':')[0]) != 'No'?true:false);
                    
                }
                when 'ID' {
                    if(policyMap.get(policyMapping.split(':')[0]) == null || policyMap.get(policyMapping.split(':')[0]) == '') {
                        continue;
                    }
                    else if(policyMapping.split(':')[1] == 'Account') {
                        policyRefs = new Account();
                                                System.debug('@@@pp'+policyMap.get(policyMapping.split(':')[0]));
                        policyRefs.put(policyObjectFieldMapping.get(policyMapping).split(':')[1], ABHI_Constants.ABHI+'_'+policyMap.get(policyMapping.split(':')[0]));
                    }
                    else if(policyMapping.split(':')[1] == 'Asset') {
                        policyRefs = new Asset();
                        policyRefs.put(policyObjectFieldMapping.get(policyMapping).split(':')[1], policyMap.get(policyMapping.split(':')[0]));
                    }
                    policy.putSObject(policyObjectFieldMapping.get(policyMapping).split(':')[0], policyRefs);
                }
                when else {
                    policy.put(policyObjectFieldMapping.get(policyMapping), policyMap.get(policyMapping.split(':')[0]));
                }    
            }  
        }   
        policy.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
        /*Setting LAN__c ext Id to the Policy no
         First time PolicyNumber will be blank*/
        if(policyMap.get('PolicyNumber') != null) {
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
                switch on nomineeMapping.split(':')[2] {
                    when 'Double' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split(':')[0]) != ''?Double.valueOf(nominee.get(nomineeMapping.split(':')[0])):null);
                    }
                    when 'Date' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split(':')[0]) != null && nominee.get(nomineeMapping.split(':')[0]) != ''?Date.valueOf(nominee.get(nomineeMapping.split(':')[0]).toString()):null);
                        //policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split(':')[0]) != null && nominee.get(nomineeMapping.split(':')[0]) != ''?(Date)(nominee.get(nomineeMapping.split(':')[0])):null);
                    }
                    when 'Boolean' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split(':')[0]) != null && nominee.get(nomineeMapping.split(':')[0]) != 'No'?true:false); 
                    }
                    when 'ID' {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), policy.Id);
                    }
                    when else {
                        policyNominee.put(nomineeFieldMapping.get(nomineeMapping), nominee.get(nomineeMapping.split(':')[0]));
                    }    
                }  
            } 
            policyNominee.put(ABHI_Constants.BUSINESS_UNIT_API, ABHI_Constants.ABHI);
            //NomineeExternalId__c = <NomineeId><ProposalNumber>
            policyNominee.put('Policy_Number_Text__c', policy.LAN__c);
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
                switch on prevPolMapping.split(':')[2] {
                    when 'Date' {
                       // prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split(':')[0]) != null?Date.valueOf(previousPolicy.get(prevPolMapping.split(':')[0]).toString()):null);
                        prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split(':')[0]) != null && previousPolicy.get(prevPolMapping.split(':')[0]) != ''?Date.valueOf(previousPolicy.get(prevPolMapping.split(':')[0]).toString()):null);
                        System.debug('@@@date1'+previousPolicy.get(prevPolMapping.split(':')[0]));
                        System.debug('@@@date2'+prevPolicyFieldMapping.get(prevPolMapping));
                    }
                    when 'Double' {
						prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split(':')[0]) != ''? Double.valueOf(previousPolicy.get(prevPolMapping.split(':')[0])):null);
                    }
                    when else {
                        prevPolicy.put(prevPolicyFieldMapping.get(prevPolMapping), previousPolicy.get(prevPolMapping.split(':')[0]));
                    }    
                }  
            } 
            prevPolicy.put('Policy__c', policy.Id);
            prevPolicy.putSObject('Customer__r', new Account(LOB_Client_Code__c = policy.Account.LOB_Client_Code__c ));
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
        String result = (street1 != null && street1 != 'null'? street1 : '')+
            (street2 != null && street2 != 'null' ? street2 : '')+
            (street3 != null && street3 != 'null'? street3 : '');
        
        return result.length()>255?result.substring(0, 255):result;
    }
}