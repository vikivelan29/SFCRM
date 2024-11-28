public with sharing class ASF_SLAHistoryWraper {
    public String stageName;

    public Long totalTimeSpent;

    public ASF_Case_SLA_History__c violatedTime;

    public ASF_Case_SLA_History__c stageStartTime;


    public ASF_SLAHistoryWraper() {
        this.totalTimeSpent = 0;
    }
}