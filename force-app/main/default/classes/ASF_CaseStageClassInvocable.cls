/*********************************************************
*Class        :  ASF_IntegrationInvocable
*Author       :  Ritika Dhandia
*Description  :  Interface to implement Before and After Stage movement Apex Class
*********************************************************/
public interface ASF_CaseStageClassInvocable {
    

    /**
     * Method to be called before Stage movement
     * CANNOT perform any DML. Can Return the Case object, if any DML
     * is needed. The calling class will make the DML as needed
     */
    Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> cases);


    /**
     * Method to be called After Stage movement
     * CANNOT perform any DML. Can Return the Case object, if any DML
     * is needed. The calling class will make the DML as needed
     */
    Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> cases);


}