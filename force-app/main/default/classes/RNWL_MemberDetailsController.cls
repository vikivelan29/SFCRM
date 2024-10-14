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
                    if(strAPIName == 'Renewal Check'){
                        mapOfAPINameToResponse.put(strAPIName, RNWL_StoredResponseUtility.getRenewalDetails(policyNum, strAPIName, 'RNWL_RenewalDetail'));
                    }else if(strAPIName == 'Renewal Group Check'){
                        mapOfAPINameToResponse.put(strAPIName, RNWL_StoredResponseUtility.getRenewalDetails(policyNum, strAPIName, 'RNWL_Non_Ind_Account')); 
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
            
            /* if(mapOfAPINameToResponse.containsKey('Health Return')){

List<Object> rawHealthReturn = (List<Object>)mapOfAPINameToResponse.get('Health Return');

for(object objHealth : rawHealthReturn) { 
Map<String, Object> health_Map = (Map<String, Object>)objHealth;
Map<String, String> healthMap = new Map<String, String>(); 

healthMap.put('HA', String.valueOf(health_Map.get('HealthAssesmentStatusHA')));
healthMap.put('DHA', String.valueOf(health_Map.get('HealthAssesmentStatusDHA')));
healthMap.put('AHC', String.valueOf(health_Map.get('HealthAssesmentStatusAHC')));
healthMap.put('vchClientCode', String.valueOf(health_Map.get('vchClientCode')));

mapHealth.put(String.valueOf(health_Map.get('vchClientCode')), healthMap);

}
} */
            
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
}