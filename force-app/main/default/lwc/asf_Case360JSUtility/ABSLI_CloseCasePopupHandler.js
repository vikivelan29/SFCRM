import CASE_ID from '@salesforce/schema/Case.Id';
import CASE_REJECTFLAG from '@salesforce/schema/Case.Reject_Case__c';
import CASE_TECH_SOURCE from '@salesforce/schema/Case.Technical_Source__c';
import { updateRecord } from 'lightning/uiRecordApi';

const absliCloseCasePopup = (that) => {
    if (that.closureTypeSelected == 'unresolved') {
        /* IF POPUP LEVEL VALIDATION SUCCESSFUL - CHECK FORM LEVEL VALIDATION AND EXECUTE CASE CLOSURE */
        let isFormValidated = that.validateFields();
        if (!isFormValidated) {
            that.showError('error', 'Mandatory fields missing', 'Please fill all mandatory fields for this stage....');
            return false;
        }
        let bErrorOccured = false;
        // CHECK IF THE SELECTED VALUE FOR TEAM STATUS IS UNRESOLVED.
        that.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if (ele.fieldName == 'Outcome__c') {
                if (ele.value != 'Unresolved') {
                    that.showError('error', 'Wrong Selection', 'Please select Team Resolution Status as Unresolved.');
                    bErrorOccured = true;
                }
            }
        })
        if (!bErrorOccured) {
            saveRejection(that);
        }


    }
    if(that.closureTypeSelected == 'resolved'){
        /* IF POPUP LEVEL VALIDATION SUCCESSFUL - CHECK FORM LEVEL VALIDATION AND EXECUTE CASE CLOSURE */
        let isFormValidated = that.validateFields();
        if (!isFormValidated) {
            that.showError('error', 'Mandatory fields missing', 'Please fill all mandatory fields for this stage');
            return false;
        }
        let bErrorOccured = false;
        // CHECK IF THE SELECTED VALUE FOR TEAM STATUS IS UNRESOLVED.
        that.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if (ele.fieldName == 'Outcome__c') {
                if (ele.value != 'Resolved') {
                    that.showError('error', 'Wrong Selection', 'Please select Team Resolution Status as Resolved.');
                    bErrorOccured = true;
                }
            }
        })
        if (!bErrorOccured) {
            that.selectedManualStage = 'Resolved';
            that.saveManualCaseStage();
        }
    }
    return false;
};
const saveRejection = (that)=> {
    let isFormValidated = that.validateFields();
    if (isFormValidated) {
        that.loading = true;
        that.skipMoveToNextStage = true;

        //get case record as object from lightning-record-edit-form
        let caseRecord;
        let caseElement = that.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
        if (caseElement) {
            let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseRecord = Object.fromEntries([...fieldsVar, ['Id', that.caseObj.Id], ['sobjectType', 'Case']]);
            caseRecord['Reject_Case__c'] = true;
            if (that.caseObj.Technical_Source__c == 'API') {
                caseRecord['Technical_Source__c'] = 'LWC';
            }
        }

        //get case extn record as object from lightning-record-edit-form
        let caseExtnRecord;
        let caseExtnElement = that.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
        if (caseExtnElement) {
            let inputFields = [...caseExtnElement.querySelectorAll('lightning-input-field')];
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseExtnRecord = Object.fromEntries([...fieldsVar, ['Id', that.caseExtensionRecord.Id]]);
            caseExtnRecord["sobjectType"] = caseExtnElement.objectApiName;
        }
        that.saveCaseWithExtension(caseRecord, caseExtnRecord);
    }
}

export { absliCloseCasePopup };