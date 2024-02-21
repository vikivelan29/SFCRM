/**
 * Simple in memory low cpu logging
 **/
public class ABCL_Logger {
	private static Boolean enableEL = false;
    private static LogScope current;
    private static LogScope root;    
    private static final Integer DML_IDX = 0;
    private static final Integer SOQL_IDX = 1;    
    private static final Map<Integer, String> limitsByIdx = 
        new Map<Integer, String> { DML_IDX => 'DML', SOQL_IDX => 'SQL'};
    
    static {
        reset();
    }
    
    public static void enableExceptionLogging(){
        enableEL = true;
        reset();
    }
    
    private static Set<String> sUserNames;
    private static Set<String> getLogActivations(){
       if(sUserNames==NULL){
           sUserNames = new Set<String>();
           for(ABCL_Log_Activiation__mdt rec: [select Username__c from ABCL_Log_Activiation__mdt where IsActive__c=true]){
               if(String.isNotBlank(rec.Username__c)){
                   sUserNames.add(rec.Username__c);
               }
           }
       }
       return sUserNames;
    }
    
    private static Boolean shouldLog(){
        return (enableEL || getLogActivations().contains(UserInfo.getUserName()));
    }
    
    /**
     * Push this named scope onto the log stack
     **/    
    public static void push(String scope) {
        if(shouldLog()){
            LogScope newScope = new LogScope();
            newScope.scope = scope;
            newScope.limits = new List<Integer> { 
                Limits.getDMLStatements(), 
                Limits.getQueries() };
            newScope.parent = ABCL_Logger.current;
            ABCL_Logger.current.logEntries.add(newScope);
            ABCL_Logger.current = newScope;  
        }      
    }
    
    /**
     * Add the given message to the scope last pushed
     **/
    public static void message(String message) {
        if(shouldLog()){
            ABCL_Logger.current.logEntries.add(message);   
        }     
    }
    
    /**
     * Pop the current scope
     **/
    public static void pop() {
        if(shouldLog()){
            ABCL_Logger.current.limits = new List<Integer> { 
                Limits.getDMLStatements() - ABCL_Logger.current.limits[DML_IDX], 
                Limits.getQueries() - ABCL_Logger.current.limits[SOQL_IDX]};
            ABCL_Logger.current = ABCL_Logger.current.parent;   
        }        
    }

    /**
     * Flush the log entries and serialize 
     **/    
    public static String flush() {
        List<String> logLines = new List<String>();
        logLines.add(ABCL_Logger.root.scope);
        ABCL_Logger.root.flush(logLines, 1);
        reset();
        return String.join(logLines, '\n');
    }
    
    /**
     * Emits the current log state to the Log__e platform event
     **/
    public static void emit() {
        if(shouldLog()){
            // Log title is primarly present to allow filtering
            String title = ABCL_Logger.root.scope;
            Integer dml = -1;
            Integer soql = -1;
            if(ABCL_Logger.root.logEntries.size()>0) {
                Object top = ABCL_Logger.root.logEntries[0];
                if(top instanceof LogScope) {
                    LogScope logScope = (LogScope) top;
                    title = logScope.scope;                
                    dml = logScope.limits[DML_IDX];
                    soql = logScope.limits[SOQL_IDX];
                } else if (top instanceof String) {
                    title = (String) top;                
                }
            }
            
            // Emit the log data via Platform Events
            EventBus.publish(
                new Log__e(
                    Title__c = title,
                    DML__c = dml,
                    SOQL__c = soql,
                    Data__c = flush()));
            // reset exception logging
            enableEL = false;
        }
    }    
    
    /**
     * Resets the log state
     **/
    private static void reset() {
        if(shouldLog()){
            root = current = new LogScope();
            DateTime now = DateTime.now();
            current.scope = String.valueOf(now+'.'+now.millisecond());  
        }      
    }
    
    /**
     * Nested log scopes
     **/
    private class LogScope {
        
        public LogScope parent;
        public String scope;
        public List<Integer> limits;
        public List<Object> logEntries = new List<Object>();
        
        public void flush(List<String> logLines, Integer indent) {
            for(Object logEntry : logEntries) {
                if(logEntry instanceof LogScope) {
                    LogScope logScope = (LogScope) logEntry;
                    List<String> limitDiffs = new List<String>();
                    for(Integer limitIdx : limitsByIdx.keySet()) {
                        Integer limitVariance = logScope.limits[limitIdx];
                        if(limitVariance > 0) {
                            limitDiffs.add(limitsByIdx.get(limitIdx)+' ' + limitVariance);
                        }
                    }
                    String limits = limitDiffs.size() > 0 ? '(' + String.join(limitDiffs, ',') + ')' : '';
                    logLines.add(indent+':'+logScope.scope+' '+limits);
                    logScope.flush(logLines, indent+1);
                } else {
                    logLines.add(indent+':'+logEntry);                    
                }
            }
        }
    }    
}