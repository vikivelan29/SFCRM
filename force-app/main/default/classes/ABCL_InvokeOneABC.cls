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
                    System.debug('stage-->: '+caseRecord.OwnerText__c );
                	System.debug('Source-->: '+caseRecord.Resolution_Comments__c);
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
            List<ASF_Case_Integration__c> lstAsfCaseInteg = new List<ASF_Case_Integration__c>();
            List<Case_Integration_Outbound__e> caseOutEvntList = new List<Case_Integration_Outbound__e>();
            for (Case caseRecordRef : caseRecord){
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c = caseRecordRef.Id;
                caseInt.Status__c = ABFL_Constants.PENDING;
                //caseInt.Type__c = 'OneABC';
                lstAsfCaseInteg.add(caseInt);
             }
                
            if (!lstAsfCaseInteg.isEmpty()){
                Database.SaveResult[] insertResult = Database.insert(lstAsfCaseInteg,false); 
            }
            Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();
            for(ASF_Case_Integration__c caseIntRecord :[SELECT ID, Name,Status__c,Type__c ,Case__c FROM ASF_Case_Integration__c WHERE Case__c IN :caseRecord 
                                                        AND Status__c = :ABFL_Constants.PENDING AND Type__c = NULL WITH SECURITY_ENFORCED LIMIT 1]){
                caseIdToCaseIntMap.put(caseIntRecord.Case__c, caseIntRecord);
            }    
            if(!caseIdToCaseIntMap.isEmpty()){
               for (Case caseRecordFinal : caseRecord){
                   if(caseIdToCaseIntMap.containsKey(caseRecordFinal.Id)){
                       system.debug('enterePE');
                        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                            'AssignedTeam' => caseRecordFinal.OwnerText__c, 
                            'AssignedUser' =>  caseRecordFinal.OwnerText__c,
                            'LOBCaseID' => caseRecordFinal.CaseNumber,
                            'Remarks' => caseRecordFinal.Resolution_Comments__c ,
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
               	system.debug('enterePE '+caseOutEvntList);
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