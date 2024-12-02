/********************************************************* 
*Class        :  RNWL_IndividualAccRenewalController
*Author       :  Raj Raghuwanshi  
*Created Date :  12/09/2024 
*Last Modified:  12/09/2024
*@description  :  This class is used for calling Renewal Policy Details 
*********************************************************/
//Making the class without sharing because end user context will update the record.
public without sharing class RNWL_IndividualAccRenewalController {
    /****************************************************************************************************************
* @LOB - RNWL
* @Function - getPolicyRenewalDetails
* @param PolicyId - PolicyId
* payload - request body, urlParameters - Map of URL parameters
* @return - 
* @Description - Makes the callout
*****************************************************************************************************************/ 
    @AuraEnabled
    public static List<RNWL_RenewalWrapper> getPolicyRenewalDetails(String opportunityId){
        try{    
            List<Opportunity> oppList = [SELECT Id,Policy_Number__c,Proposal_Number__c,Premium_Amount__c 
                                         FROM Opportunity WHERE Id=:opportunityId LIMIT 1];
            
            List<RNWL_RenewalWrapper> lstRenewalWrapper = new List<RNWL_RenewalWrapper>();
            
            String policyNumber = oppList[0].Policy_Number__c;  
            Map<String, Object> rawResponseMap = new Map<String, Object>();              
            Map<String, String> mapAPIResponse = RNWL_StoredResponseUtility.getResponseFromFiles(opportunityId , new List<String>{'Renewal Check'});
            String responseBody = mapAPIResponse.containsKey('Renewal Check') ? mapAPIResponse.get('Renewal Check') : ''  ;
            set<String> setMemberId = new set<String>(); 
            
            if(String.isBlank(responseBody)){  
                responseBody = RNWL_StoredResponseUtility.getRenewalDetails(policyNumber, 'Renewal Check', 'RNWL_RenewalDetail');
                
                if(String.isBlank(responseBody)) {  
                    getRenewalWrapperErrorInstance('400', 'API Call Failed Please Retry', lstRenewalWrapper);
                    return lstRenewalWrapper;
                }
                
                rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                
                for(Object obj : (List<Object>)rawResponseMap.get('error')){
                    map<String, object> mapErrorToMessage = (map<String, object>)obj;
                    String strErrorCode = String.valueOf(mapErrorToMessage.get('ErrorCode'));  
                    
                    if(strErrorCode != '00'){
                        system.debug('strErrorCode'+strErrorCode); 
                        getRenewalWrapperErrorInstance(strErrorCode, String.valueOf(mapErrorToMessage.get('ErrorMessage')), lstRenewalWrapper);
                        return lstRenewalWrapper;    
                    } 
                } 

                RNWL_StoredResponseUtility.uploadFileToOpportunity(opportunityId);
            }
            else{ 
                rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            }
            
            List<Object> rawPolicyData = (List<Object>)((Map<String, Object>)rawResponseMap.get('response')).get('policyData');
            
            Set<String> combiPolicyNumbers = new Set<String>();

            for(object objPolicy : rawPolicyData){
                
                Map<String, Object> policyData_Map = (Map<String, Object>)objPolicy;
                 
                if(policyNumber == String.valueOf(policyData_Map.get('Policy_number'))){
                      
                    RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
                    
                    objRenewalWrapper.Id = Crypto.getRandomInteger();
                    objRenewalWrapper.Policy_renewal_date = String.valueOf(policyData_Map.get('Policy_renewal_date'));
                    objRenewalWrapper.Upsell_Flag = String.valueOf(policyData_Map.get('Upsell_Flag'));
                    objRenewalWrapper.Renewable_Flag = String.valueOf(policyData_Map.get('Renewable_Flag'));
                    objRenewalWrapper.Renewed_Flag = String.valueOf(policyData_Map.get('Renewed_Flag'));
                    objRenewalWrapper.sumInsuredtype = String.valueOf(policyData_Map.get('sumInsuredtype'));
                    
                    if(policyData_Map.containsKey('Is_cross_sell') && String.valueOf(policyData_Map.get('Is_cross_sell')) == 'Y'){
                        objRenewalWrapper.Is_cross_sell = 'Y';
                    } 
                    
                    objRenewalWrapper.Cross_sell_Reference_Number = policyData_Map.containsKey('Cross_sell_Reference_Number') ? String.valueOf(policyData_Map.get('Cross_sell_Reference_Number')) : '';
                    
                    objRenewalWrapper.Loading_Rate = policyData_Map.containsKey('Loading_Rate') ? String.valueOf(policyData_Map.get('Loading_Rate')) : '';
                    objRenewalWrapper.Loading_Reason = policyData_Map.containsKey('Loading_Reason') ? String.valueOf(policyData_Map.get('Loading_Reason')) : '';
                    
                    Map<String, Object> nominee_Map = (Map<String, Object>)policyData_Map.get('Nominee_Details');
                    
                    objRenewalWrapper.Nominee_Name = String.valueOf(nominee_Map.get('Nominee_Name'));
                    objRenewalWrapper.Nominee_Address = String.valueOf(nominee_Map.get('Nominee_Address'));
                    objRenewalWrapper.Nominee_Contact_No = String.valueOf(nominee_Map.get('Nominee_Contact_No'));
                    
                    Map<String, Object> premium_Map = (Map<String, Object>)policyData_Map.get('premium');
                    
                    objRenewalWrapper.Renewal_Net_Premium = roundOfDecimal(premium_Map.get('Renewal_Net_Premium'));   
                    objRenewalWrapper.Renewal_Gross_Premium = roundOfDecimal(premium_Map.get('Renewal_Gross_Premium'));  
                    objRenewalWrapper.Upsell_Net_Premium = roundOfDecimal(premium_Map.get('Upsell_Net_Premium'));
                    objRenewalWrapper.Upsell_Gross_Premium = roundOfDecimal(premium_Map.get('Upsell_Gross_Premium'));  
                    
                    List<Object> lstMember = (List<Object>) policyData_Map.get('Members');
                    
                    List<RNWL_RenewalWrapper.cls_Members> lstRenewalMembers = new List<RNWL_RenewalWrapper.cls_Members>();
                    
                    for(object member : lstMember){
                        
                        Map<String, Object> member_Map = (Map<String, Object>)member;
                        RNWL_RenewalWrapper.cls_Members objMember = new RNWL_RenewalWrapper.cls_Members();
                        
                        objMember.Name = String.valueOf(member_Map.get('Name'));
                        objMember.SumInsured = String.valueOf(member_Map.get('SumInsured'));
                        objMember.Upsell_SumInsured = String.valueOf(member_Map.get('Upsell_SumInsured'));
                        objMember.healthReturn = String.valueOf(member_Map.get('healthReturn'));
                        objMember.DoB = String.valueOf(member_Map.get('DoB'));
                        objMember.Gender = String.valueOf(member_Map.get('Gender'));
                        objMember.Email = String.valueOf(member_Map.get('Email'));
                        objMember.Mobile_Number = String.valueOf(member_Map.get('Mobile_Number'));
                        objMember.Relation = String.valueOf(member_Map.get('Relation'));
                        objMember.Chronic = String.valueOf(member_Map.get('Chronic'));
                        objMember.CB = String.valueOf(member_Map.get('CB'));
                        objMember.MemberId = String.valueOf(member_Map.get('MemberId'));
                        
                        setMemberId.add(String.valueOf(member_Map.get('MemberId')));   
                        
                        lstRenewalMembers.add(objMember);
                    } 
                    objRenewalWrapper.Members = lstRenewalMembers;

                    // Combi Policy :

                    if(policyData_Map.get('Combi_Flag') == null || String.valueOf(policyData_Map.get('Combi_Flag')) == 'No'){
                        objRenewalWrapper.combi_Policy_Flag = false;
                        objRenewalWrapper.combi_Policy_Disposition_Flag = false;
                    }else{
                        objRenewalWrapper.combi_Policy_Flag = true;
                        objRenewalWrapper.combi_Policy_Disposition_Flag = true;
                        objRenewalWrapper.Combi_Policy_Number = String.valueOf(policyData_Map.get('Combi_Policy_Number'));
                        combiPolicyNumbers.add(objRenewalWrapper.Combi_Policy_Number);
                    }

                    lstRenewalWrapper.add(objRenewalWrapper);
                } 
            } 
            
            if(!lstRenewalWrapper.isEmpty()){  
                updateValueForAccount(setMemberId, lstRenewalWrapper); 
            }
            
            List<object> renewInfoList = (List<object>)rawResponseMap.get('Renew_Info');
            Map<String,object> renewInfoMap = (Map<String,object>)renewInfoList[0];
            String renewedProposalNumber = renewInfoMap.containsKey('Renewed_Policy_Proposal_Number') ?  String.valueOf(renewInfoMap.get('Renewed_Policy_Proposal_Number')) : '';
            
            Boolean isUpdatedNeeded = false;
            
            if(!lstRenewalWrapper.isEmpty() && oppList[0].Premium_Amount__c != Decimal.valueOf(lstRenewalWrapper[0].Renewal_Gross_Premium)) {
                oppList[0].Premium_Amount__c = Decimal.valueOf(lstRenewalWrapper[0].Renewal_Gross_Premium);
                isUpdatedNeeded = true;
            }
            
            if(String.isNotBlank(renewedProposalNumber) && oppList[0].Proposal_Number__c != renewedProposalNumber){
                oppList[0].Proposal_Number__c = renewedProposalNumber;    
                isUpdatedNeeded = true;
            }
            
            if(isUpdatedNeeded) {
                system.debug(oppList);
                update oppList[0];
            }
            
            if(combiPolicyNumbers.size() > 0){
                List<Asset> assets = [SELECT id,Account.Name , Name,
                                                Issue_Date__c, 
                                                Maturity_Date__c, 
                                                Status, 
                                                Cover_Type__c, 
                                                ProductName__c, 
                                                Plan_Name__c,
                                                MasterPolicyNumber__c, 
                                                MasterPolicyNumber__r.name
                                        FROM Asset 
                                        WHERE Name IN:combiPolicyNumbers];
                                          
                Map<String,Asset> combiPolicies = new Map<String,Asset>();
                for(Asset ast : assets){
                    combiPolicies.put(ast.Name,Ast);
                }
                List<Dispositions__c> relatedDispositions = [SELECT Id,Name,Call_Date_Time__c,Renewal_Request__r.Policy_Number__c,
                                                                    Disposition_L1__c,Disposition_L2__c,Disposition_L3__c,
                                                                    Next_Call_Back_Date_Time__c,Remarks__c,Calling_Unit__c,
                                                                    Calling_Mode__c , Agent_Name__r.Name
                                                             FROM Dispositions__c 
                                                             WHERE Renewal_Request__r.Policy_Number__c IN :combiPolicyNumbers];

                Map<String, List<RNWL_RenewalWrapper.cls_RelatedDispositions>> relatedDispostionsMap = new Map<String, List<RNWL_RenewalWrapper.cls_RelatedDispositions>>();

                for(Dispositions__c disp : relatedDispositions){
                    RNWL_RenewalWrapper.cls_RelatedDispositions combiDisp = new RNWL_RenewalWrapper.cls_RelatedDispositions();
                    combiDisp.Disposition_Name = disp.Name; 
                    combiDisp.Disposition_Url = '/'+disp.Id; 
                    combiDisp.Combi_Policy_Number = disp.Renewal_Request__r.Policy_Number__c;
                    combiDisp.Next_CallBack_Datetime =  String.valueOf(disp.Next_Call_Back_Date_Time__c);
                    combiDisp.Disostion_L1 = disp.Disposition_L1__c;
                    combiDisp.Disostion_L2 = disp.Disposition_L2__c;
                    combiDisp.Disostion_L3 = disp.Disposition_L3__c;
                    combiDisp.Call_DateTime = String.valueOf(disp.Call_Date_Time__c);
                    combiDisp.Agent_Name = disp.Agent_Name__r?.Name;
                    combiDisp.Remark = disp.Remarks__c;
                    combiDisp.Calling_Unit = disp.Calling_Unit__c;
                    combiDisp.Calling_Mode = disp.Calling_Mode__c;
                    if(relatedDispostionsMap.containsKey(disp.Renewal_Request__r.Policy_Number__c)){
                        relatedDispostionsMap.get(disp.Renewal_Request__r.Policy_Number__c).add(combiDisp);
                    }else{
                        relatedDispostionsMap.put(disp.Renewal_Request__r.Policy_Number__c, new List<RNWL_RenewalWrapper.cls_RelatedDispositions> {combiDisp});
                    }
                }

                for(RNWL_RenewalWrapper objRenewalWrapper : lstRenewalWrapper){
                    if(objRenewalWrapper.combi_Policy_Flag && combiPolicies.containsKey(objRenewalWrapper.Combi_Policy_Number)){
                        RNWL_RenewalWrapper.cls_CombiPolicy combi = new RNWL_RenewalWrapper.cls_CombiPolicy();
                        combi.Combi_Policy_Number      = objRenewalWrapper.Combi_Policy_Number;
                        combi.combi_Policy_Owner       = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Account?.name;
                        combi.combi_Policy_StartDate   = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Issue_Date__c?.format();
                        combi.combi_Policy_EndDate     = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Maturity_Date__c?.format();
                        combi.combi_Policy_Status      = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Status;
                        combi.combi_Policy_Variant     = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Cover_Type__c;
                        combi.combi_Policy_Product     = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).ProductName__c;
                        combi.combi_Policy_SubPlan     = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).Plan_Name__c;
                        combi.combi_Policy_ProductType = combiPolicies.get(objRenewalWrapper.Combi_Policy_Number).ProductName__c;

                        objRenewalWrapper.CombiPolicies = new List<RNWL_RenewalWrapper.cls_CombiPolicy>{combi};
                    }else{
                        objRenewalWrapper.combi_Policy_Flag = false;
                    }
                    if(objRenewalWrapper.combi_Policy_Disposition_Flag && relatedDispostionsMap.containsKey(objRenewalWrapper.Combi_Policy_Number)){
                        objRenewalWrapper.CombiDispostions = relatedDispostionsMap.get(objRenewalWrapper.Combi_Policy_Number);
                    }
                }
            }
            return lstRenewalWrapper;      
        }catch(exception e){
            system.debug(e.getLineNumber());
            system.debug(e.getMessage());
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    } 
    
    public static string roundOfDecimal(Object objValue){ 
        String strValue = String.valueOf(objValue);
        system.debug('before if strValue'+strValue);
        if(strValue != null && strValue != '' && strValue != '0'){
            system.debug('inside if strValue'+strValue);
            return String.valueOf(Decimal.valueOf(strValue).setScale(2)); 
        }else{
            system.debug('inside else strValue'+strValue);
            return strValue;
        }  
    }
    public static void getRenewalWrapperErrorInstance(String strErrorCode, String strErrorMessage, List<RNWL_RenewalWrapper> lstRenewalWrapper){
        RNWL_RenewalWrapper objRenewalWrapper = new RNWL_RenewalWrapper();
        objRenewalWrapper.ErrorCode = strErrorCode;
        objRenewalWrapper.ErrorMessage = strErrorMessage;  
        lstRenewalWrapper.add(objRenewalWrapper);
        return;
    }
    
    public static void updateValueForAccount(Set<String> setMemberId, List<RNWL_RenewalWrapper> lstRenewalWrapper){
        
        Map<String, Account> mapOfMemberIdToAccount = new Map<String, Account>();
        
        for(Account objAccount : [SELECT Client_Code__c, Chronic_Disease__c, PED__c FROM Account WHERE Client_Code__c IN : setMemberId]){
            mapOfMemberIdToAccount.put(objAccount.Client_Code__c, objAccount);
        }
        
        if(!mapOfMemberIdToAccount.isEmpty()){ 
            List<RNWL_RenewalWrapper.cls_Members> lstCls_Members = new List<RNWL_RenewalWrapper.cls_Members>();
            
            for(RNWL_RenewalWrapper.cls_Members objCls_Members : lstRenewalWrapper[0].Members ){ 
                if(mapOfMemberIdToAccount.containsKey(objCls_Members.MemberId)){
                    Account objAccount = mapOfMemberIdToAccount.get(objCls_Members.MemberId);
                    objCls_Members.Chronic_Disease = objAccount.Chronic_Disease__c;
                    objCls_Members.PED = objAccount.PED__c;   
                }
                lstCls_Members.add(objCls_Members);
            } 
            lstRenewalWrapper[0].Members = lstCls_Members;
        } 
        return;
    }
}
