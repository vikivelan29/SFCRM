public class ASF_CasePathController {
    @AuraEnabled
    public static list<StageWrapper> getCasePath(string recordId){
        list<StageWrapper> result = new list<StageWrapper>();
        try { 
            case currentCase = [Select Id,CCC_External_Id__c, Stage__c FROM Case where Id=:recordId].get(0);
            //Query all the Case Stage configs based on external ID
            list<ASF_Case_Stage_Config__c > caseStages = [Select Id, Order__c, Optional_Stage__c,StageName__c FROM ASF_Case_Stage_Config__c where Parent_C3_Record__c =:currentCase.CCC_External_Id__c order by Order__c];
            Integer activeOrder;
            for(ASF_Case_Stage_Config__c csc: caseStages){
                StageWrapper tempWrapper = new StageWrapper();
                if((!ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c)) && (csc.StageName__c == 'Closed' || (!ASF_Constants.REJECTIONSTATUSES.contains(csc.StageName__c)))){
                    tempWrapper.stageName = csc.StageName__c;
                    tempWrapper.Order = Integer.valueOf(csc.Order__c);
                    tempWrapper.className = '';
                    if(currentCase.Stage__c == csc.StageName__c){
                        
                        activeOrder = Integer.valueOf(csc.Order__c);
                        
                    }
                    
                    if(csc.Optional_Stage__c == true){
                        tempWrapper.isOptional = true;
                    }
                    
                    
                    result.add(tempWrapper);
                }
                if((ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c)) && csc.StageName__c!='Closed' && csc.StageName__c!='Resolved'){
                    tempWrapper.stageName = csc.StageName__c;
                    tempWrapper.Order = Integer.valueOf(csc.Order__c);
                    tempWrapper.className = '';
                    if(currentCase.Stage__c == csc.StageName__c){
                        
                        activeOrder = Integer.valueOf(csc.Order__c);
                        
                    }
                    
                    if(csc.Optional_Stage__c == true){
                        tempWrapper.isOptional = true;
                    }
                    
                    
                    result.add(tempWrapper);
                }
                
                
            }
            
            if(result.size() >0){
                for(integer i=0;i<result.size();i++){
                    // if(result[i].StageName != 'Rejected'){
                    if(result[i].Order == activeOrder){
                        if(result[i].Order == activeOrder && result[i].isOptional == true){
                            result[i].className = 'slds-path__item slds-is-optional  slds-is-active slds-is-current';
                        }else{
                            result[i].className = 'slds-path__item slds-is-current slds-is-active';
                        }
                        
                    }else if(result[i].Order < activeOrder ){
                        if(  result[i].isOptional == true){
                            result[i].className = 'slds-path__item slds-is-optional slds-is-complete';
                        }else{
                            result[i].className = 'slds-path__item slds-is-complete';
                        }
                        
                    }else{
                        result[i].className = 'slds-path__item slds-is-incomplete';
                    }
                    
                    if(result[i].Order == activeOrder && (ASF_Constants.REJECTIONSTATUSES.contains(result[i].StageName))){
                        result[i].className = 'slds-path__item slds-is-lost slds-is-active slds-is-current';
                    }
                    
                    
                    
                }
            }
            
            
        } catch (Exception e) {
            system.debug('aura error--->'+e.getLineNumber()+'------->'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static list<StageWrapper> getCasePath1(string recordId){
        list<StageWrapper> result = new list<StageWrapper>();
        
        Integer lastActiveStageNumber = 100;
        Integer activeOrder = 100;
        
        try {
            case currentCase = [Select Id,CCC_External_Id__c, Stage__c,Nature__c FROM Case where Id=:recordId].get(0);
            
            //else{//Non Rejection stage logic
             

            list<ASF_Case_Stage_Config__c> caseStages = [Select Id, Order__c,Manual_Stage__c,Stage_Help_Text__c, Optional_Stage__c,StageName__c FROM ASF_Case_Stage_Config__c where Parent_C3_Record__c =:currentCase.CCC_External_Id__c order by Order__c];
            for(ASF_Case_Stage_Config__c csc: caseStages){
                StageWrapper tempWrapper = new StageWrapper();
                if((!ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c)) && (csc.StageName__c == 'Closed' || csc.StageName__c == 'Resolved' || (!ASF_Constants.REJECTIONSTATUSES.contains(csc.StageName__c)))){
                    tempWrapper.stageName = csc.StageName__c;
                    tempWrapper.Order = Integer.valueOf(csc.Order__c);
                    tempWrapper.className = '';
                    if(currentCase.Stage__c == csc.StageName__c){
                        
                        activeOrder = Integer.valueOf(csc.Order__c);
                        
                    }
                    
                    if(csc.Optional_Stage__c == true){
                        tempWrapper.isOptional = true;
                    }
                    if(csc.Stage_Help_Text__c!= null){
                        tempWrapper.HelpText = csc.StageName__c + ': ' + csc.Stage_Help_Text__c;
                    }
                    
                    //Logic to remove Manual Stages from path
                    /*
if(csc.Manual_Stage__c != true){
result.add(tempWrapper);
//tempWrapper.isManual = true;
} 
*/
                    
                    result.add(tempWrapper);
                    
                }
                if((ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c)) && csc.StageName__c!='Closed' && csc.StageName__c!='Resolved'){
                    tempWrapper.stageName = csc.StageName__c;
                    tempWrapper.Order = Integer.valueOf(csc.Order__c);
                    tempWrapper.className = '';
                    if(currentCase.Stage__c == csc.StageName__c){
                        
                        activeOrder = Integer.valueOf(csc.Order__c);
                        
                    }
                    
                    if(csc.Optional_Stage__c == true){
                        tempWrapper.isOptional = true;
                    }
                    
                    if(csc.Stage_Help_Text__c!= null){
                        tempWrapper.HelpText = csc.StageName__c + ': ' + csc.Stage_Help_Text__c;
                    }
                    
                    //Logic to remove Manual Stages from path
                    /*
if(csc.Manual_Stage__c != true){
result.add(tempWrapper);
//tempWrapper.isManual = true;
} 
*/
                    
                    
                    result.add(tempWrapper);
                }
                
                //Adding logic for Reject stage for Request/Query Nature
                if((ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c)) && (csc.StageName__c=='Closed' || csc.StageName__c=='Resolved')){
                    tempWrapper.stageName = ASF_Constants.REJECTIONSTATUS; 
                    tempWrapper.Order = Integer.valueOf(csc.Order__c);
                    tempWrapper.className = '';
                    activeOrder = Integer.valueOf(csc.Order__c);
                    result.add(tempWrapper);
                }
            }
            
            if(result.isEmpty())
                return result;
            
            List<string> pastStages = new List<string>();
            for(ASF_Case_SLA_History__c  caseHist : [SELECT id,Case__c, Stage__c, Status__c from ASF_Case_SLA_History__c  WHERE Case__c =: recordId]){
                pastStages.add(caseHist.Stage__c);
            }
            
            for(integer i=0;i<result.size();i++){
                
                string styles = 'slds-path__item';
                
                if(result[i].Order == activeOrder){
                    styles += ' slds-is-current slds-is-active';
                    
                    if(ASF_Constants.REJECTIONSTATUSES.contains(result[i].StageName))
                        styles += ' slds-is-lost';
                    else if(result[i].isOptional)
                        styles += ' slds-is-optional';
                    
                }else if(result[i].Order < activeOrder ){
                    if(pastStages.contains(result[i].stageName)){
                        styles += ' ksc-complete';
                        
                        if(result[i].isOptional)
                            styles += ' slds-is-optional';
                        
                    }else{
                        if(lastActiveStageNumber == 100)
                            lastActiveStageNumber = i;
                        styles += ' slds-is-incomplete';
                    }
                }else{
                    styles += ' slds-is-incomplete';
                }
                
                
                result[i].className = styles;
            }
            
            
        } catch (Exception e) {
            system.debug('aura error--->'+e.getLineNumber()+'------->'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    
    public class StageWrapper{
        
        public StageWrapper(){
            isOptional = false;
        }
        
        @AuraEnabled
        public string stageName {get;set;}
        
        @AuraEnabled
        public Integer Order {get;set;}
        
        @AuraEnabled
        public string className {get;set;}
        
        @AuraEnabled
        public boolean isOptional {get;set;}
        
        @AuraEnabled
        public boolean isManual {get;set;}
        
        @AuraEnabled
        public string HelpText {get;set;}
    }
}