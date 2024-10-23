/*********************************************************
*Class        :  RNWL_MemberDetailsController
*Author       :  Raj Raghuwanshi 
*Created Date :  01/10/2024
*Last Modified:  04/10/2024
*@description  :  This class is used for calling Renewal Check API,Renewal Group Check API, Health Assessment API*/
public with sharing class RNWL_MemberDetailsController {
    
    /****************************************************************************************************************
* @Function - getAPIResponseDetails
* @param PolicyId - opportunityId,  assetId - assetId policyNum - policyNum proposalNo - Asset.SerialNumber lstFileSrcAPI - list of the API for which response is needed.
* @return -  Map of API Name to the Reponse.
* @Description - Makes the callout or get the stored response.
*****************************************************************************************************************/ 
    @AuraEnabled
    public static Map<String, String> getAPIResponseDetails(String opportunityId, String assetId, String policyNum,
                                                            String proposalNo, List<String> lstFileSrcAPI, String accountId)
    {
        Map<String, String> mapOfAPINameToResponse = new Map<String, String>();
        
        try {
            // Fetch stored responses first
            mapOfAPINameToResponse = RNWL_StoredResponseUtility.getResponseFromFiles(opportunityId, lstFileSrcAPI);
            if (mapOfAPINameToResponse.size() == lstFileSrcAPI.size()) {
                System.debug('All Response returned from Files: ' + mapOfAPINameToResponse.keySet());
                return mapOfAPINameToResponse;
            }
            
            // Process each API request
            for (String strAPIName : lstFileSrcAPI) {
                if (!mapOfAPINameToResponse.containsKey(strAPIName)) {
                    if (RNWL_Constants.API_TO_META_DATA_MAP.containsKey(strAPIName)) {
                        mapOfAPINameToResponse.put(strAPIName, RNWL_StoredResponseUtility.getRenewalDetails(policyNum, strAPIName, RNWL_Constants.API_TO_META_DATA_MAP.get(strAPIName)));
                    } else if (strAPIName == RNWL_Constants.HEALTH_API_NAME) {
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getHealthDetails(policyNum, proposalNo)));
                    } else if (strAPIName == RNWL_Constants.FITNESS_API_NAME) {
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getFitnessAssessmentDetails(assetId)));
                    } else if (strAPIName == RNWL_Constants.APP_REG_API_NAME) {
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getAppRegDeatils(accountId)));
                    }
                }
            } 
            
            // Upload file after processing all APIs
            RNWL_StoredResponseUtility.uploadFileToOpportunity(opportunityId);
            return mapOfAPINameToResponse;
            
        } catch (Exception e) {
            System.debug('Error in getAPIResponseDetails: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            throw new AuraHandledException('Error in getAPIResponseDetails: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static MemberUIResponseWrapper getAPIResponse(String opportunityId, String assetId, String policyNum,
                                                         String proposalNo, List<String> lstFileSrcAPI) 
    {
        MemberUIResponseWrapper objMemberUIResponseWrapper = new MemberUIResponseWrapper();
        List<Object> lstFinalResponse = new List<Object>();
        
        try {
            Map<String, String> mapOfAPINameToResponse = getAPIResponseDetails(opportunityId, assetId, policyNum, proposalNo, lstFileSrcAPI, null);
            
            // Fetch Member and Fitness details
            Map<String, Map<String, String>> mapMember = new Map<String, Map<String, String>>();
            Map<String, Map<String, String>> mapFitness = new Map<String, Map<String, String>>();
            
            if (mapOfAPINameToResponse.containsKey(RNWL_Constants.RENEWAL_API_NAME)) {
                mapMember = getMembers(mapOfAPINameToResponse.get(RNWL_Constants.RENEWAL_API_NAME), policyNum, RNWL_Constants.RENEWAL_POLICY_NUM_KEY, RNWL_Constants.RENEWAL_API_NAME);
            } else if (mapOfAPINameToResponse.containsKey(RNWL_Constants.RENEWAL_GROUP_API_NAME)) {
                mapMember = getMembers(mapOfAPINameToResponse.get(RNWL_Constants.RENEWAL_GROUP_API_NAME), policyNum, RNWL_Constants.RENEWAL_GRP_POLICY_NUM_KEY, RNWL_Constants.RENEWAL_GROUP_API_NAME);
            }
             
            if (mapMember.containsKey('errorMap')) {
                Map<String, String> errorMap = mapMember.get('errorMap');
                objMemberUIResponseWrapper.ErrorCode = errorMap.get('ErrorCode');
                objMemberUIResponseWrapper.ErrorMessage = errorMap.get('ErrorMessage');
                objMemberUIResponseWrapper.ErrorAPI = errorMap.get('ErrorAPI');
                return objMemberUIResponseWrapper;
            }
            
            if (mapOfAPINameToResponse.containsKey(RNWL_Constants.FITNESS_API_NAME)) {
                mapFitness = parseFitnessAssessment(mapOfAPINameToResponse.get(RNWL_Constants.FITNESS_API_NAME));
            }
            
            // Merge Member and Fitness data
            for (String strKey : mapMember.keySet()) {
                Map<String, String> mapTemp = new Map<String, String>();
                mapTemp.putAll(mapMember.get(strKey));
                if (mapFitness.containsKey(strKey)) {
                    mapTemp.putAll(mapFitness.get(strKey));
                }
                lstFinalResponse.add(mapTemp);
            }
            
            objMemberUIResponseWrapper.Response = lstFinalResponse;
            return objMemberUIResponseWrapper;
            
        } catch (Exception e) {
            System.debug('Error in getAPIResponse: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            throw new AuraHandledException('Error in getAPIResponse: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }
    
    private static Map<String, Map<String, String>> parseFitnessAssessment(String strFitness) {
        Map<String, Map<String, String>> mapFitness = new Map<String, Map<String, String>>();
        Map<String, Object> rawResponseMap = (Map<String, Object>) JSON.deserializeUntyped(strFitness);
        
        if (Integer.valueOf(rawResponseMap.get('StatusCode')) == 1000) {
            List<Object> rawFitnessAssessment = (List<Object>) (rawResponseMap.get('Response'));
            for (Object objFitness : rawFitnessAssessment) {
                Map<String, Object> fitness_Map = (Map<String, Object>) objFitness;
                Map<String, String> fitnessMap = new Map<String, String>();
                fitnessMap.put('HA', String.valueOf(fitness_Map.get('HealthAssesmentStatusHA')));
                fitnessMap.put('DHA', String.valueOf(fitness_Map.get('HealthAssesmentStatusDHA')));
                fitnessMap.put('AHC', String.valueOf(fitness_Map.get('HealthAssesmentStatusAHC')));
                fitnessMap.put('vchClientCode', String.valueOf(fitness_Map.get('vchClientCode')));
                mapFitness.put(String.valueOf(fitnessMap.get('vchClientCode')), fitnessMap);
            }
        }
        
        return mapFitness;
    }
    
    
    public static Map<String, Map<String, String>> getMembers(String strResponse, String policyNum, String strKey, String strAPIName)
    {    
        Map<String, Map<String, String>> mapOfMemberIdToMembers = new Map<String, Map<String, String>>();
        Map<String, String> errorMap  =  new Map<String, string>();
        
        Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(strResponse);
        
        if(!rawResponseMap.containsKey('response') ||  rawResponseMap.get('response') == null) {  
            getErrorInstance('400', 'API Call Failed Please Retry', 'Renewal', mapOfMemberIdToMembers);
            return mapOfMemberIdToMembers;
        }
        
        Map<String, Object> responseBody  =  (Map<String, Object>)rawResponseMap.get('response'); 
        Object objError = rawResponseMap.get('error');
        List<Object> lstError = new List<Object>();
        if(objError instanceOf List<Object>){
            lstError = (List<Object>) objError;  
        }
        else{
            lstError.add(objError);
        }
        
        for(Object obj : lstError){
            map<String, object> mapErrorToMessage = (map<String, object>)obj;
            String strErrorCode = String.valueOf(mapErrorToMessage.get('ErrorCode'));
            String strErrorMessage = String.valueOf(mapErrorToMessage.get('ErrorMessage')); 
            if(strErrorCode != '00' && strErrorCode != '0' ){
                getErrorInstance(strErrorCode, strErrorMessage, 'Renewal', mapOfMemberIdToMembers);
                return mapOfMemberIdToMembers; 
            }
        }  
        List<Object> rawPolicyData = (List<Object>)responseBody.get('policyData');
        
        system.debug('rawPolicyData : '+rawPolicyData);
          
        for(Object objPolicy : rawPolicyData){ 
            Map<String, Object> policyData_Map = (Map<String, Object>)objPolicy;  
            if(policyNum.equals(String.valueOf(policyData_Map.get(strKey)))){  
                List<Object> lstMember = (List<Object>) policyData_Map.get('Members'); 
                
                for(object member : lstMember) { 
                    Map<String, Object> member_Map = (Map<String, Object>)member;
					Map<String, String> memberMap = new Map<String, String>(); 
                    
                    memberMap.put('Name', String.valueOf(member_Map.get('Name'))); 
                    memberMap.put('Member DOB', String.valueOf(member_Map.get('DoB')));
                    memberMap.put('Membership Relationship', String.valueOf(member_Map.get('Relation')));
                    memberMap.put('FA', '-');
                    
                    String memberIdKey = 'Member_Code'; 
                    if(strAPIName == RNWL_Constants.RENEWAL_API_NAME){ 
                        memberIdKey = 'MemberId';
                        memberMap.put('FA', String.valueOf(member_Map.get('FitnessAssessment')));
                    } 
                    String memberId = String.valueOf(member_Map.get(memberIdKey)); 
                    memberMap.put('Member ID', memberId);
                    mapOfMemberIdToMembers.put(memberId, memberMap);
                }  
            }
        } 
        if(mapOfMemberIdToMembers.isEmpty()){
            getErrorInstance('01', 'Policy is not Matching', 'Renewal', mapOfMemberIdToMembers);
            system.debug('mapOfMemberIdToMembers'+mapOfMemberIdToMembers);
            return mapOfMemberIdToMembers; 
        }
        system.debug('mapOfMemberIdToMembers'+mapOfMemberIdToMembers);
        return mapOfMemberIdToMembers;
    }
    
    public static void getErrorInstance(String strErrorCode, String strErrorMessage, String strAPI, Map<String, Map<String, String>> mapOfMemberIdToMembers)
    {
        Map<String, String> errorMap = new Map<String, String>();
        errorMap.put('ErrorCode', strErrorCode);
        errorMap.put('ErrorMessage', strErrorMessage);
        errorMap.put('ErrorAPI', strAPI);
        mapOfMemberIdToMembers.put('errorMap',errorMap);
        return;
    }
    
    
    @AuraEnabled
    public static list<UIResponseWrapper> getHealthReturnResponse(String opportunityId, String assetId, String policyNum, 
                                                                  String proposalNo, String masterPolicyNum, Date issueDate, List<String> lstFileSrcAPI)
    {
        Map<String, String> mapOfAPINameToResponse = new Map<String, String>();
        Map<String, List<Response>> mapOfNameIdToHealthReturn = new Map<String, List<Response>>();
        Map<String, Map<String, String>> mapFitness = new Map<String, Map<String, String>>();
        list<UIResponseWrapper> lstUIResponseWrapper = new list<UIResponseWrapper>();
        
        system.debug('issueDate'+issueDate); 
        
        mapOfAPINameToResponse = getAPIResponseDetails(opportunityId, assetId, policyNum, proposalNo, lstFileSrcAPI, null);
        
        if(mapOfAPINameToResponse.containsKey(RNWL_Constants.FITNESS_API_NAME)){ 
            String strFitness = mapOfAPINameToResponse.get(RNWL_Constants.FITNESS_API_NAME); 
            Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(strFitness); 
            List<Object> rawFitnessAssessment = (List<Object>)(rawResponseMap.get('Response')); 
            
            if(rawFitnessAssessment != null && !rawFitnessAssessment.isEmpty()){ 
                for(object objFitness : rawFitnessAssessment) { 
                    Map<String, Object> fitness_Map = new Map<String, Object>();
                    fitness_Map = (Map<String, Object>)objFitness;
                    Map<String, String> fitnessMap = new Map<String, String>(); 
                    
                    fitnessMap.put('HR_Expiry_Date', fitness_Map.containsKey('HR_Expiry_Date') ? String.valueOf(fitness_Map.get('HR_Expiry_Date')) : ''); 
                    fitnessMap.put('HHS_Start_Date', fitness_Map.containsKey('HHS_Start_Date') ? String.valueOf(fitness_Map.get('HHS_Start_Date')) : ''); 
                    fitnessMap.put('HHS_End_Date', fitness_Map.containsKey('HHS_End_Date') ? String.valueOf(fitness_Map.get('HHS_End_Date')) : ''); 
                    
                    fitnessMap.put('vchClientCode', String.valueOf(fitness_Map.get('vchClientCode')));  
                    mapFitness.put(String.valueOf(fitnessMap.get('vchClientCode')), fitnessMap);
                } 
            }
        } 
        
        if(mapOfAPINameToResponse.containsKey(RNWL_Constants.HEALTH_API_NAME)){  
            ResponseWrapper rawHealthReturn = (ResponseWrapper) JSON.deserialize(mapOfAPINameToResponse.get(RNWL_Constants.HEALTH_API_NAME), ResponseWrapper.class);
            
            system.debug('rawHealthReturn'+rawHealthReturn); 
            if(rawHealthReturn.StatusCode == 1000){ 
                
                if(rawHealthReturn.Response == null || rawHealthReturn.Response.isEmpty()){ 
                    lstUIResponseWrapper.add(new UIResponseWrapper('No Record Found' , new List<Response>()));
                    return lstUIResponseWrapper;
                }
                
                for(Response objHealth : rawHealthReturn.Response) {  
                    String strKey = objHealth.Name + ' - ' + objHealth.vchClientCode; 
                    if(mapFitness.containsKey(objHealth.vchClientCode)){
                        map<String,String> fitness = mapFitness.get(objHealth.vchClientCode);
                        objHealth.HR_Expiry_Date = fitness.containsKey('HR_Expiry_Date') ? fitness.get('HR_Expiry_Date') : '' ;
                        objHealth.HHS_Start_Date =  fitness.containsKey('HHS_Start_Date') ? fitness.get('HHS_Start_Date') : '' ;
                        objHealth.HHS_End_Date =  fitness.containsKey('HHS_End_Date') ? fitness.get('HHS_End_Date') : '' ;
                    } 
                    objHealth.MasterPolicyNumber = masterPolicyNum;
                    
                    if(!mapOfNameIdToHealthReturn.containsKey(strKey)) {
                        mapOfNameIdToHealthReturn.put(strKey, new List<Response>());
                    }   
                    mapOfNameIdToHealthReturn.get(strKey).add(objHealth);  
                }  
                
                for(String strKey : mapOfNameIdToHealthReturn.keySet()) {   
                    map<integer, Response> mapMonthsToResponse = new map<integer, Response>(); 
                    for(Response objWrapper : mapOfNameIdToHealthReturn.get(strKey)){  
                        string strYear = objWrapper.Month < 10 ?  String.ValueOf(objWrapper.Year) + '0' + String.ValueOf(objWrapper.Month) : 
                        String.ValueOf(objWrapper.Year) + String.ValueOf(objWrapper.Month);  
                        mapMonthsToResponse.put( Integer.valueOf(strYear), objWrapper);                    
                    } 
                    
                    integer activeDays = 0; 
                    List<Response> lstResponse = new List<Response>();
                    List<integer> months = new List<integer>();  
                    months.addAll(mapMonthsToResponse.keySet());
                    months.sort();   
                    Integer issueKey = issueDate.month() > 9 ? Integer.valueOf( String.valueOf(issueDate.year()) + String.valueOf(issueDate.month()) ) : Integer.valueOf( String.valueOf(issueDate.year()) + '0' + String.valueOf(issueDate.month()) );
                    Date expireDate = (issueDate.toStartOfMonth()).addYears(1);
                    Integer expireKey = expireDate.month() > 9 ? Integer.valueOf( String.valueOf(expireDate.year()) + String.valueOf(expireDate.month()) )  : Integer.valueOf( String.valueOf(expireDate.year()) + '0' + String.valueOf(expireDate.month()) );
                    
                    system.debug('issueKey'+issueKey);
                    system.debug('expireKey'+expireKey);
                    for(integer month : months){ 
                        Response objResponse = mapMonthsToResponse.get(month); 
                        system.debug('month'+month);
                        if(month >= issueKey && month < expireKey){
                            objResponse.TotalActiveDays = Integer.valueOf(objResponse.ActiveDays) + activeDays; 
                        }else{
                            objResponse.TotalActiveDays = Integer.valueOf(objResponse.ActiveDays); 
                            issueKey = objResponse.Month > 9 ? Integer.valueOf(objResponse.Year + objResponse.Month) : Integer.valueOf(objResponse.Year + '0' + objResponse.Month);
                            Date updatedExDate = ( Date.newInstance( Integer.valueOf(objResponse.Year), objResponse.Month, 1) ).addYears(1);
                            expireKey = updatedExDate.month() > 9 ? Integer.valueOf( String.valueOf(updatedExDate.year()) + String.valueOf(updatedExDate.month()) ) : Integer.valueOf( String.valueOf(updatedExDate.year()) + '0' + String.valueOf(updatedExDate.month()) );
                        }
                        
                        activeDays = objResponse.TotalActiveDays;
                        integer balance = Integer.valueOf(objResponse.TotalHealthReturnsTM) - Integer.valueOf(objResponse.TotalHealthReturnsTMBurnt);
                        objResponse.HRBalance = balance;
                        objResponse.HRCFRenewal = balance; 
                        objResponse.MonthName = RNWL_Constants.MONTH_MAP.get(objResponse.Month);
                        lstResponse.add(objResponse);
                    } 
                    lstUIResponseWrapper.add(new UIResponseWrapper(strKey , lstResponse)); 
                }    
            } 
            else{
                lstUIResponseWrapper.add(new UIResponseWrapper('API Failed' , new List<Response>()));
                return lstUIResponseWrapper;
            } 
            system.debug('Final Response map'+lstUIResponseWrapper);
            return lstUIResponseWrapper;
        }
        else{ 
            lstUIResponseWrapper.add(new UIResponseWrapper('API Failed' , new List<Response>()));
            return lstUIResponseWrapper;
        } 
    }
    
    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**
* @description - API Response Wrapper.
*/
    public class ResponseWrapper{
        @AuraEnabled public List<Response> Response{get;set;}
        @AuraEnabled public Integer StatusCode{get;set;}
        @AuraEnabled public String Message{get;set;} 
    }
    
    public class UIResponseWrapper{
        @AuraEnabled public List<Response> Response{get;set;}
        @AuraEnabled public String Header{get;set;}  
        
        public UIResponseWrapper(String Header, List<Response> Response){
            this.Header = Header;
            this.Response = Response; 
        }
    }
    
    public class MemberUIResponseWrapper{
        @AuraEnabled public List<Object> Response{get;set;}
        @AuraEnabled public String ErrorCode{get;set;}
        @AuraEnabled public String ErrorMessage{get;set;} 
        @AuraEnabled public String ErrorAPI{get;set;} 
    }  
    
    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ApexDoc')
    public class Response{
        @AuraEnabled public String HealthReturnsforrespectivemonth{get;set;}
        @AuraEnabled public String ChronicMgmtProgramCompliance{get;set;}
        @AuraEnabled public String ActiveDays{get;set;}
        @AuraEnabled public Integer TotalActiveDays{get;set;}
        @AuraEnabled public String HealthReturnsTMthroughBenefitforHospitalRoomchoice{get;set;}
        @AuraEnabled public String FitnessAssessment{get;set;}
        @AuraEnabled public String HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus{get;set;}
        @AuraEnabled public String HealthyHeartScore{get;set;}
        @AuraEnabled public String TotalHealthReturnsTMEarned{get;set;}
        @AuraEnabled public String HealthAssessment{get;set;}
        @AuraEnabled public String TotalHealthReturnsTMBurnt{get;set;}
        @AuraEnabled public Integer Month{get;set;}
        @AuraEnabled public String MonthName{get;set;}
        @AuraEnabled public String TotalHealthReturnsTM{get;set;}
        @AuraEnabled public String Year{get;set;}
        @AuraEnabled public String HealthQuestionnaire{get;set;}
        @AuraEnabled public String Name{get;set;}
        @AuraEnabled public String HRPercentage{get;set;}
        @AuraEnabled public String vchClientCode{get;set;}
        @AuraEnabled public String vchPolicyNumber{get;set;}
        @AuraEnabled public String MasterPolicyNumber{get;set;}   
        @AuraEnabled public String HR_Expiry_Date{get;set;}   
        @AuraEnabled public String HHS_Start_Date{get;set;}   
        @AuraEnabled public String HHS_End_Date{get;set;} 
        @AuraEnabled public Integer HRBalance{get;set;}
        @AuraEnabled public Integer HRCFRenewal{get;set;}
    }
}