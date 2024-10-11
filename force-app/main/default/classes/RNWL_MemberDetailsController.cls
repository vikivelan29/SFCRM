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
        try{  
            Map<String, String> mapOfAPINameToResponse = new Map<String, String>(); 
            
            mapOfAPINameToResponse = RNWL_StoredResponseUtility.getResponseFromFiles(opportunityId , lstFileSrcAPI);
            
            if(mapOfAPINameToResponse.size() == lstFileSrcAPI.size()){
                system.debug('All Response returned from Files'+mapOfAPINameToResponse.keySet());
                return mapOfAPINameToResponse;
            }
            
            system.debug('Responses from Files'+mapOfAPINameToResponse.keySet());
            
            for(String strAPIName : lstFileSrcAPI){
                if(!mapOfAPINameToResponse.containsKey(strAPIName)) {
                    if(strAPIName == 'Renewal Check' || strAPIName == 'Renewal Group Check'){
                        mapOfAPINameToResponse.put(strAPIName, RNWL_StoredResponseUtility.getRenewalDetails(policyNum, strAPIName));
                    }else if(strAPIName == 'Health Return'){
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getHealthDetails(policyNum, proposalNo))); 
                    }else if(strAPIName == 'Fitness Assessment'){
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getFitnessAssessmentDetails(assetId)));
                    }else if(strAPIName == 'AppRegDetails'){
                        mapOfAPINameToResponse.put(strAPIName, JSON.serialize(RNWL_StoredResponseUtility.getAppRegDeatils(accountId)));
                    }
                }
            } 
            
            RNWL_StoredResponseUtility.uploadFileToOpportunity(opportunityId);
            
            return mapOfAPINameToResponse;
            
        }catch(exception e){
            system.debug('Error : '+e.getMessage()+' '+e.getLineNumber());
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static List<object> getAPIResponse(String opportunityId, String assetId, String policyNum, 
                                              String proposalNo, List<String> lstFileSrcAPI)
    {
        List<object> lstFinalResponse = new List<object>();
        
        try{  
            Map<String, String> mapOfAPINameToResponse = new Map<String, String>();
            
            mapOfAPINameToResponse = getAPIResponseDetails(opportunityId, assetId, policyNum, proposalNo, lstFileSrcAPI, null);
            
            Map<String, Map<String, String>> mapMember = new Map<String, Map<String, String>>();
            Map<String, Map<String, String>> mapHealth = new Map<String, Map<String, String>>();
            Map<String, Map<String, String>> mapFitness = new Map<String, Map<String, String>>();
            
            if(mapOfAPINameToResponse.containsKey('Renewal Check')){ 
                
                mapMember = getMembers(mapOfAPINameToResponse.get('Renewal Check'), policyNum, 'Policy_number', 'Renewal Check' );
            }
            
            else if(mapOfAPINameToResponse.containsKey('Renewal Group Check')){
                
                mapMember = getMembers(mapOfAPINameToResponse.get('Renewal Group Check'), policyNum, 'Certificate_number', 'Renewal Group Check' );
                
            }
            
            if(mapOfAPINameToResponse.containsKey('Fitness Assessment')){
                
                String strFitness = mapOfAPINameToResponse.get('Fitness Assessment');
                
                system.debug('strFitness'+strFitness);
                
                Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(strFitness);
                
                List<Object> rawFitnessAssessment = (List<Object>)(rawResponseMap.get('Response')); 
                
                for(object objFitness : rawFitnessAssessment) { 
                    Map<String, Object> fitness_Map = (Map<String, Object>)objFitness;
                    Map<String, String> fitnessMap = new Map<String, String>();   
                    
                    fitnessMap.put('HA', String.valueOf(fitness_Map.get('HealthAssesmentStatusHA')));
                    fitnessMap.put('DHA', String.valueOf(fitness_Map.get('HealthAssesmentStatusDHA')));
                    fitnessMap.put('AHC', String.valueOf(fitness_Map.get('HealthAssesmentStatusAHC'))); 
                    fitnessMap.put('vchClientCode', String.valueOf(fitness_Map.get('vchClientCode'))); 
                    
                    mapFitness.put(String.valueOf(fitnessMap.get('vchClientCode')), fitnessMap);
                    
                } 
            } 
            
            
            system.debug('mapFitness'+mapFitness);
            
            system.debug('mapMember'+mapMember);
            
            for(String strKey : mapMember.keySet()){
                map<String, String> mapTemp = new map<String, String>();
                mapTemp.putAll(mapMember.get(strKey));
                if(mapFitness.containsKey(strKey) ){
                    mapTemp.putAll(mapFitness.get(strKey)); 
                }
                
                lstFinalResponse.add(mapTemp);
            }
            
            system.debug('lstFinalResponse'+lstFinalResponse);
            
            return lstFinalResponse;
            
        }catch(exception e){
            system.debug('Error : '+e.getMessage()+' '+e.getLineNumber());
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    public static Map<String, Map<String, String>> getMembers(String strResponse, String policyNum, String strKey, String strAPIName)
    {    
        
        Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(strResponse);
        List<Object> rawPolicyData = (List<Object>)((Map<String, Object>)rawResponseMap.get('response')).get('policyData');
        Map<String, Map<String, String>> mapOfMemberIdToMembers = new Map<String, Map<String, String>>();
        
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
                    
                    String memberIdKey = 'Member_Code';
                    memberMap.put('FA', '-');
                    
                    if(strAPIName == 'Renewal Check'){
                        memberIdKey = 'MemberId';
                        memberMap.put('FA', String.valueOf(member_Map.get('FitnessAssessment')));
                    } 
                    String memberId = String.valueOf(member_Map.get(memberIdKey));
                    
                    memberMap.put('Member ID', memberId);
                    mapOfMemberIdToMembers.put(memberId, memberMap);
                }  
            }
        } 
        system.debug('mapOfMemberIdToMembers'+mapOfMemberIdToMembers);
        return mapOfMemberIdToMembers;
    }
    
    @AuraEnabled
    public static list<UIResponseWrapper> getHealthReturnResponse(String opportunityId, String assetId, String policyNum, 
                                                                  String proposalNo, String masterPolicyNum, List<String> lstFileSrcAPI)
    {
        Map<String, String> mapOfAPINameToResponse = new Map<String, String>();
        Map<String, List<Response>> mapOfNameIdToHealthReturn = new Map<String, List<Response>>();
        Map<String, Map<String, String>> mapFitness = new Map<String, Map<String, String>>();
        list<UIResponseWrapper> lstUIResponseWrapper = new list<UIResponseWrapper>();
        
        mapOfAPINameToResponse = getAPIResponseDetails(opportunityId, assetId, policyNum, proposalNo, lstFileSrcAPI, null);
        
        if(mapOfAPINameToResponse.containsKey('Fitness Assessment')){
            
            String strFitness = mapOfAPINameToResponse.get('Fitness Assessment');
            
            system.debug('strFitness'+strFitness);
            
            Map<String, Object> rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(strFitness);
            
            List<Object> rawFitnessAssessment = (List<Object>)(rawResponseMap.get('Response')); 
            
            system.debug('rawFitnessAssessment'+rawFitnessAssessment);
            
            for(object objFitness : rawFitnessAssessment) { 
                Map<String, Object> fitness_Map = new Map<String, Object>();
                fitness_Map = (Map<String, Object>)objFitness;
                Map<String, String> fitnessMap = new Map<String, String>();   
                
                
                fitnessMap.put('HR_Expiry_Date', String.valueOf(fitness_Map.get('HR_Expiry_Date')));
                
                fitnessMap.put('HHS_Start_Date', String.valueOf(fitness_Map.get('HHS_Start_Date')));
                
                fitnessMap.put('HHS_End_Date', String.valueOf(fitness_Map.get('HHS_End_Date')));
                
                fitnessMap.put('vchClientCode', String.valueOf(fitness_Map.get('vchClientCode'))); 
                
                system.debug('fitnessMap'+fitnessMap);
                
                mapFitness.put(String.valueOf(fitnessMap.get('vchClientCode')), fitnessMap);
                
            } 
        } 
        
        if(mapOfAPINameToResponse.containsKey('Health Return')){
            
            system.debug('Health'+mapOfAPINameToResponse.containsKey('Health Return'));
            ResponseWrapper rawHealthReturn = (ResponseWrapper) JSON.deserialize(mapOfAPINameToResponse.get('Health Return'), ResponseWrapper.class);
            
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
            
            system.debug('mapOfNameIdToHealthReturn'+mapOfNameIdToHealthReturn); 
            
            for(String strKey : mapOfNameIdToHealthReturn.keySet()) {   
                
                map<integer, Response> mapMonthsToResponse = new map<integer, Response>();
                
                
                for(Response objWrapper : mapOfNameIdToHealthReturn.get(strKey)){ 
                    mapMonthsToResponse.put(objWrapper.Month, objWrapper);                    
                } 
                
                list<integer> months = new list<integer>();
                
                months.addAll(mapMonthsToResponse.keySet());
                months.sort();
                
                system.debug('sorted months list '+months); 
                
                integer activeDays = 0;
                
                List<Response> lstResponse = new List<Response>();
                
                for(integer month : months){ 
                    Response objResponse = mapMonthsToResponse.get(month);
                    objResponse.TotalActiveDays = Integer.valueOf(objResponse.ActiveDays) + activeDays;  
                    activeDays = objResponse.TotalActiveDays;
                    integer balance = Integer.valueOf(objResponse.TotalHealthReturnsTM) - Integer.valueOf(objResponse.TotalHealthReturnsTMBurnt);
                    objResponse.HRBalance = balance;
                    objResponse.HRCFRenewal = balance; 
                    
                    lstResponse.add(objResponse);
                }
                
                UIResponseWrapper objUIResponseWrapper = new UIResponseWrapper();
                objUIResponseWrapper.Response = lstResponse;
                objUIResponseWrapper.Header = strKey;
                
                lstUIResponseWrapper.add(objUIResponseWrapper);
            }  
            system.debug('Final Response map'+lstUIResponseWrapper);
            return lstUIResponseWrapper;
        }
        
        return null;
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