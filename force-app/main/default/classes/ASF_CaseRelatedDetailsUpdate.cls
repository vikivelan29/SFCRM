public without sharing class ASF_CaseRelatedDetailsUpdate {
    
    public void beforeInsertUpdateCase(List<Case> caseList){
        Map<String, List<Case>> recordsByField = new Map<String, List<Case>>();
        Map<String,Case> cccMap = new Map<String,Case>();
        for(Case record : caseList) {
            if(record.CCC_External_Id__c != null){
                 
                if (recordsByField.containsKey(record.CCC_External_Id__c)){
                    recordsByField.get(record.CCC_External_Id__c).add(record);
                }
                else{
                    recordsByField.put(record.CCC_External_Id__c, new List<Case>{record});
                }
                cccMap.put(record.CCC_External_Id__c,record);
            }
        }
        if(cccMap.keySet().size()>0){
            List<ASF_Case_Category_Config__c> cccList = [Select Id,
                                                         Name,
                                                         Apex_Class_Name__c,
                                                         Apex_Method_Name__c,
                                                         Business_Unit__c,
                                                         Type__c, 
                                                         Sub_Type__c,
                                                         CCC_External_Id__c
                                                         from ASF_Case_Category_Config__c 
                                                         where
                                                         CCC_External_Id__c IN : cccMap.keySet() 
                                                         AND Apex_Class_Name__c != null
                                                         AND Apex_Method_Name__c != null];
            if( cccList != null && !cccList.isEmpty())
            {
                Map<String, ASF_Case_Category_Config__c> buClassMap = new Map<String, ASF_Case_Category_Config__c>();
                for(ASF_Case_Category_Config__c ccc : cccList) {
                    buClassMap.put(ccc.CCC_External_Id__c, ccc);
                }
                
                for(String fieldValue : recordsByField.keySet()) {
                    List<Case> ccList = recordsByField.get(fieldValue);
                    if(buClassMap.containsKey(fieldValue)){
                        ASF_Case_Category_Config__c ccc = buClassMap.get(fieldValue);
                        if(ccc.Apex_Class_Name__c == null && ccc.Apex_Method_Name__c == null ) {
                            System.debug('No class and method name');
                        }
                        else {
                            String className = ccc.Apex_Class_Name__c;
                            String methodName = ccc.Apex_Method_Name__c;
                            Type t = Type.forName(className);
                            ASF_SRHandlerInterface ins = (ASF_SRHandlerInterface)t.newInstance();
                            ins.beforeInsertUpdateCaseData(ccList);
                        }
                    }
                }
            }
            
        }
    }
    
    public void updateRelatedObjectDetailsBulk(List<Case> caseList){
        
        Map<String, List<Case>> recordsByField = new Map<String, List<Case>>();
        Map<String,Case> cccMap = new Map<String,Case>();
        List<SObject> objectList = new List<SObject>();
        for(Case record : caseList) {
            if(record.CCC_External_Id__c != null){
                if (recordsByField.containsKey(record.CCC_External_Id__c)){
                    recordsByField.get(record.CCC_External_Id__c).add(record);
                } 
                else{
                    recordsByField.put(record.CCC_External_Id__c, new List<Case>{record});
                }
                cccMap.put(record.CCC_External_Id__c,record);               
            }
        }
        
        try{
            if(cccMap.keySet().size()>0){
                List<ASF_Case_Category_Config__c> cccList = [Select Id,
                                                             Name,
                                                             Apex_Class_Name__c,
                                                             Apex_Method_Name__c,
                                                             Business_Unit__c,
                                                             Type__c, 
                                                             Sub_Type__c,
                                                             CCC_External_Id__c
                                                             from ASF_Case_Category_Config__c 
                                                             where
                                                             CCC_External_Id__c IN : cccMap.keySet() 
                                                             AND Apex_Class_Name__c != null
                                                             AND Apex_Method_Name__c != null];
                if( cccList != null && !cccList.isEmpty())
                {
                    
                    Map<String, ASF_Case_Category_Config__c> buClassMap = new Map<String, ASF_Case_Category_Config__c>();
                    for(ASF_Case_Category_Config__c ccc : cccList) {
                        buClassMap.put(ccc.CCC_External_Id__c, ccc);
                    }
                    
                    for(String fieldValue : recordsByField.keySet()) {
                        List<Case> ccList = recordsByField.get(fieldValue);
                        if(buClassMap.containsKey(fieldValue)){
                            ASF_Case_Category_Config__c ccc = buClassMap.get(fieldValue);
                            if(ccc.Apex_Class_Name__c == null && ccc.Apex_Method_Name__c == null ) {
                                System.debug('No class and method name');
                            }
                            else {
                                String className = ccc.Apex_Class_Name__c;
                                String methodName = ccc.Apex_Method_Name__c;
                                system.debug('className--'+className);
                                system.debug('methodName--'+methodName);
                                Type t = Type.forName(className);
                                ASF_SRHandlerInterface ins = (ASF_SRHandlerInterface)t.newInstance();
                                objectList.addAll(ins.processSRDataBulk(ccList,ccc));
                            }
                        }
                    }
                    //Database.update(objectList, false);
                    update objectList;
                }
                
            }
            
        }catch(Exception ex){
            throw ex;
        }
    }
}