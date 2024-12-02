// import { updateRecord } from 'lightning/uiRecordApi';
const wellnessCloseCasePopup = (that) => {
    // console.log('that.closureTypeSelected-->',that.closureTypeSelected);
    if (that.closureTypeSelected == 'unresolved') {
        console.log('wellnessCloseCasePopup  unresolved');
        return true;// usual behaviour
    }
    if(that.closureTypeSelected == 'resolved'){
        console.log('wellnessCloseCasePopup  resolved');
        /* IF POPUP LEVEL VALIDATION SUCCESSFUL - CHECK FORM LEVEL VALIDATION AND EXECUTE CASE CLOSURE */
        let isFormValidated = that.validateFields();
        if (!isFormValidated) {
            that.showError('error', 'Mandatory fields missing', 'Please fill all mandatory fields for this stage');
            return false;
        }
        let bErrorOccured = false;
        console.log('36  resolved');
        // Accessing the value of the comment box
        const inputVal = that.template.querySelector('.resolve-input');
        // Accessing the value of the combobox
        const selectedCombo = that.template.querySelector('.resolve-combobox');
        if (!inputVal.value || !selectedCombo.value) {
            inputVal.reportValidity();
            selectedCombo.reportValidity();
            // that.showError('error', 'Wrong Selection', 'Please enter Resolution comments.');
            bErrorOccured = true;
        }
        // else if (!selectedCombo.value) {
            
        //     // that.showError('error', 'Wrong Selection', 'Please select Resolution reason.');
        //     bErrorOccured = true;
        // }
        else{
            // CHECK IF THE SELECTED VALUE FOR TEAM STATUS IS UNRESOLVED.
            that.template.querySelectorAll('lightning-input-field').forEach(ele => {
                if (ele.fieldName == 'Resolution_Reason__c') {
                    ele.value = selectedCombo.value;
                }
            })
        }

        if (!bErrorOccured) {
            that.selectedManualStage = 'Resolved';
            that.saveManualCaseStage();
        }
    }
    return false;
};
const saveRejection = (that)=> {
    let isFormValidated = that.validateFields();
    console.log('in saveRejection');
    if (isFormValidated) {
        that.loading = true;
        that.skipMoveToNextStage = true;

        //get case record as object from lightning-record-edit-form
        let caseRecord;
        let caseElement = that.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
        if (caseElement) {
            let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
            console.log('inputFields-->',inputFields);
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseRecord = Object.fromEntries([...fieldsVar, ['Id', that.caseObj.Id], ['sobjectType', 'Case']]);
            caseRecord['Reject_Case__c'] = true;
            caseRecord['Rejection_Reason__c'] = that.template.querySelector('.Unresolve-combobox').value;
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
        console.log('caseRecord-->'+JSON.stringify(caseRecord));
        console.log('caseExtnRecord-->',caseExtnRecord);
        that.saveCaseWithExtension(caseRecord, caseExtnRecord);
    }
}

export { wellnessCloseCasePopup };
