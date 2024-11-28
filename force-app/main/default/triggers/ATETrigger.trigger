/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 03-16-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-14-2024   rsinghnagar@salesforce.com   Initial Version
**/
trigger ATETrigger on Async_Transaction_Event__e (after insert) {
	
	// Prepare set of ATF settings to query
	Set<String> sATFSettings = new Set<String>();
	for(Async_Transaction_Event__e ateRec: trigger.new){
		if(!String.isBlank(ateRec.payload__c)){
			sATFSettings.add(ateRec.ATF_Settings__c);
		}
	}
	
	if(!sATFSettings.isEmpty()){
		// query sATFSettings
		Map<String,Async_Transaction_Settings__mdt> mATS = new Map<String,Async_Transaction_Settings__mdt>();
		for(Async_Transaction_Settings__mdt atsRec: [select DeveloperName,Class_Name__c, Method_Name__c 
													from Async_Transaction_Settings__mdt where DeveloperName IN :sATFSettings])
		{
			mATS.put(atsRec.DeveloperName, atsRec);
			
		}
		for(Async_Transaction_Event__e ateRec: trigger.new){
			if(!String.isBlank(ateRec.payload__c)){
				// get settings from map
				Async_Transaction_Settings__mdt settings = mATS.get(ateRec.ATF_Settings__c);
				// run respective methods dynamically
				Callable atfService =  (Callable) Type.forName(settings.Class_Name__c).newInstance();
				String result = (String) atfService.call(
															settings.Method_Name__c, new Map<String, Object> { 
																	'jsonEMIds' => ateRec.payload__c
																}
														);
				System.debug('***result:'+result);
			}
		}
	}
}