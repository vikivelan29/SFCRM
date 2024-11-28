/*********************************************************
** Class        :  KSC_OptionsWrapper
** Description  : This is the wrapper for generating JSON for option fields on LWC 
                  such as Picklist, Combobox, pills etc
** Author       :  Shreya Mathur
** Created Date : Nov 23, 2022
** Last Modified Data : Nov 24, 2022
** Parent Story Number : JIRA:1234
*/

public  class ASF_OptionsWrapper {
    
    @AuraEnabled public String label;
    @AuraEnabled public String value;
    @AuraEnabled public Boolean selected;

    /****************************************************
     * @Description - Default Constructor of the class.  
    *****************************************************/
    public ASF_OptionsWrapper() {
        label = ASF_Constants.STRING_BLANK;
        value = ASF_Constants.STRING_BLANK;
        selected = false;
    }
}