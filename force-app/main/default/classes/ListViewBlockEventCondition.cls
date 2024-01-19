global class ListViewBlockEventCondition implements TxnSecurity.EventCondition {
    
    public boolean evaluate(SObject event) {
        switch on event{
            when ListViewEvent reportEvent {
                return evaluate(reportEvent);
            }
            when ReportEvent reportEvent {
                return evaluate(reportEvent);
            }
            when else{
                return false;
            }
        }
    }
    
    /****************************************************
* @Description - evaluates the listEvent on columnheader
* @param listEvent - ListViewEvent
* @return -  Boolean based on access 
*****************************************************/ 
    public boolean evaluate(ListViewEvent listEvent) {
        User userObject  = [Select Profile.Name from User where id = :listEvent.UserId LIMIT 1];
        List<MaskedField_Persona__mdt > lstUD_Masking_Detail = new List<MaskedField_Persona__mdt >();
        lstUD_Masking_Detail  = [ SELECT Id, ProfileName__c,FieldsToBeMasked__c  
                                 FROM MaskedField_Persona__mdt  
                                 WHERE ProfileName__c =: userObject.Profile.Name];
        for(MaskedField_Persona__mdt maskData :lstUD_Masking_Detail){
            for(String fieldName : maskData.FieldsToBeMasked__c.split(ASF_Constants.STRING_SEMI_COLON)){
                if(listEvent.ColumnHeaders.containsIgnoreCase(fieldName)){
                    return true;
                }
            }
        }
        return false; 
    }
    
    /****************************************************
     * @Description - evaluates the reportEvent on columnheader
     * @param reportedEvent - ReportEvent
     * @return -  Boolean based on access 
    *****************************************************/ 
    public boolean evaluate(ReportEvent reportedEvent){
        User userObject  = [Select Profile.Name from User where id = :reportedEvent.UserId LIMIT 1];
        List<MaskedField_Persona__mdt > lstUD_Masking_Detail = new List<MaskedField_Persona__mdt >();
        lstUD_Masking_Detail  = [ SELECT Id, ProfileName__c,FieldsToBeMasked__c  
                                 FROM MaskedField_Persona__mdt  
                                 WHERE ProfileName__c =: userObject.Profile.Name];
        for(MaskedField_Persona__mdt maskData :lstUD_Masking_Detail){
            for(String fieldName : maskData.FieldsToBeMasked__c.split(ASF_Constants.STRING_SEMI_COLON)){
                if(reportedEvent.ColumnHeaders.containsIgnoreCase(fieldName)){
                    return true;
                }
            }
        }
        return false; 
    }
    
}