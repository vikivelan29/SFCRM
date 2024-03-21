/*********************************************************
*Class        :  ABCL_InvokeOneABC
*Author       :  Shubham Sinha 
*Created Date :  14/02/2024
*Last Modified:  14/02/2024
*Description  :  ABCL_InvokeOneABC sends the details to OneABC for ABFL and ABHFL when case source is OneABC and case is resolved.
*********************************************************/
public without sharing class ABCL_InvokeOneABC {
	public static void evaluateCasesForOneABC(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap){
        try{
            List<Case> lstOneABCCases = new List<Case>();
            for (Case caseRecord : newCaseMap.values()){ 
                if(oldCaseMap.get(caseRecord.Id).Stage__c != caseRecord.Stage__c && caseRecord.Stage__c == 'Resolved' && caseRecord.Source__c == 'OneABC'){
                    // System.debug('stage-->: '+caseRecord.OwnerText__c );
                	// System.debug('Source-->: '+caseRecord.Resolution_Comments__c);
                    lstOneABCCases.add(caseRecord);
                }
            }
             if (!lstOneABCCases.isEmpty()){
                oneAbcCallout(lstOneABCCases);
            }
          
        } catch (Exception e){ 
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABCL_InvokeOneABC.evaluateCasesForOneABC');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
     /****************************************************************************************************************
    * @Function - oneAbcCallout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - callout method
    *****************************************************************************************************************/
    public static void oneAbcCallout(List<Case> caseRecord){
    	try{
            // logic to insert case integration record
            List<ASF_Case_Integration__c> lstAsfCaseInteg = new List<ASF_Case_Integration__c>();
            for (Case caseRecordRef : caseRecord){
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c = caseRecordRef.Id;
                caseInt.Status__c = ABFL_Constants.PENDING;
                //caseInt.Type__c = 'OneABC';
                lstAsfCaseInteg.add(caseInt);
            }
            
            List<Id> ciIds = new List<Id>();
            if (!lstAsfCaseInteg.isEmpty()){
                Database.SaveResult[] srList = Database.insert(lstAsfCaseInteg,false); 
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        // System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                        ciIds.add(sr.getId());
                    }
                }
            }
            
            List<Case_Integration_Outbound__e> caseOutEvntList = new List<Case_Integration_Outbound__e>();
            Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();
            for(ASF_Case_Integration__c caseIntRecord :ABFL_SOQL_Integration.getCaseIntegrationInfos(ciIds, ABFL_Constants.PENDING)){
                caseIdToCaseIntMap.put(caseIntRecord.Case__c, caseIntRecord);
            }    
            if(!caseIdToCaseIntMap.isEmpty()){
               for (Case caseRecordFinal : [SELECT ID,OwnerText__c,CaseNumber,Business_Unit__c ,Stage__c,ABFL_Case_Detail__c,ABFL_Case_Detail__r.Resolution_comments__c FROM CASE WHERE ID IN:caseRecord]){
                   if(caseIdToCaseIntMap.containsKey(caseRecordFinal.Id)){
                       system.debug('enterePE');
                        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                            'AssignedTeam' => caseRecordFinal.OwnerText__c, 
                            'AssignedUser' =>  caseRecordFinal.OwnerText__c,
                            'LOBCaseID' => caseRecordFinal.CaseNumber,
                            'Remarks' => caseRecordFinal.ABFL_Case_Detail__r.Resolution_comments__c  ,
                            'Status' => caseRecordFinal.Stage__c
                         };
                        caseOutEvntList.add(new Case_Integration_Outbound__e(
                            Business_Unit__c = caseRecordFinal.Business_Unit__c, 
                            Case_Integration_ID__c = caseIdToCaseIntMap.get(caseRecordFinal.Id)?.Name, 
                            Integration_Name__c = 'OneABC', 
                            Request_Payload__c = JSON.serialize(payloadWrap)
                        ));
               		}
                }  
            }
            if (!caseOutEvntList.isEmpty()){
               	// system.debug('enterePE '+caseOutEvntList);
                List<Database.SaveResult> results = EventBus.publish(caseOutEvntList);
            }
    	}
        catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABCL_InvokeOneABC.oneAbcCallout');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
}