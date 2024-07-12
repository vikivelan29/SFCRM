const getRequiredFieldExpr = (temp, caseFieldsMetadata, currentStep, profileName, caseRecordDetails, caseExtensionRecordDetails) => {
    const caseRecord = new Map();
    const recordElementMap = new Map();

    /* Virendra Patil - 17h Jan 2023
    /* Description - function takes this.template, Case Field Configuration and current Steps from parent template. and derive field Read Only/ Read Write and Required logic based on expression on record.
    */

    try {
        let bRecordLoaded = false;
        temp.querySelectorAll('lightning-input-field').forEach(field => {
            let fdName = field.fieldName;
            let fdVal = field.value;
            if (fdVal != undefined) {
                bRecordLoaded = true;
            }
            else {
                if (caseRecordDetails != undefined && caseRecordDetails != null && caseRecordDetails.hasOwnProperty(fdName)) {
                    fdVal = caseRecordDetails[fdName].value;
                    bRecordLoaded =true;
                }
                else if (caseExtensionRecordDetails != undefined && caseExtensionRecordDetails != null && caseExtensionRecordDetails.hasOwnProperty(fdName)) {
                    fdVal = caseExtensionRecordDetails[fdName].value;
                    bRecordLoaded =true;
                }
            }
            //console.log(fdName +' ---> '+fdVal);
            caseRecord.set(fdName, fdVal);
        });
        if (bRecordLoaded) {
            for (let i in caseFieldsMetadata) {
                if (caseFieldsMetadata[i].useControllingFormula) {
                    let conditionalReadOnlyExpr = '';
                    conditionalReadOnlyExpr = caseFieldsMetadata[i].controllingFormula;
                    conditionalReadOnlyExpr = conditionalReadOnlyExpr.replaceAll('[$Profile.Name]', '"' + profileName + '"');
                    let bTakenCare = false;
                    for (let [key, value] of caseRecord) {
                        conditionalReadOnlyExpr = conditionalReadOnlyExpr.replaceAll('[' + key + ']', '"' + value + '"');
                        bTakenCare = true;
                    }
                    if (!bTakenCare) {
                        conditionalReadOnlyExpr = conditionalReadOnlyExpr.replaceAll('[', '"[');
                        conditionalReadOnlyExpr = conditionalReadOnlyExpr.replaceAll(']', ']"');
                    }
                    let bReadOnly = eval(conditionalReadOnlyExpr);
                    let bRequired = false;

                    temp.querySelectorAll('lightning-input-field').forEach(item => {
                        if (item.fieldName === caseFieldsMetadata[i].FieldAPINAme) {
                            if (caseFieldsMetadata[i].UpdateAt) {
                                if (caseFieldsMetadata[i].UpdateAt.includes(currentStep)) {
                                    item.disabled = bReadOnly;
                                    if (bReadOnly) {
                                        item.value = '';
                                    }
                                    if (caseFieldsMetadata[i].RequiredAt) {
                                        if (caseFieldsMetadata[i].RequiredAt.toString().includes(currentStep)) {
                                            bRequired = !bReadOnly;
                                        }
                                        else {
                                            bRequired = false;
                                        }
                                    }
                                    item.required = bRequired;
                                }
                                else {
                                    // Fixes for Disable on Approval Stage.
                                    item.disabled = true;
                                }
                            }
                            else {
                                // Fixes for Disable on Approval Stage.
                                item.disabled = true;
                            }
                        }
                    });
                    temp.querySelectorAll('c-asf_searchable-picklist').forEach(ele => {
                        if (ele.fieldname === caseFieldsMetadata[i].FieldAPINAme) {
                            if (caseFieldsMetadata[i].UpdateAt) {
                                if (caseFieldsMetadata[i].UpdateAt.includes(currentStep)) {
                                    ele.callSetAsDisabledField(bReadOnly);
                                    if (bReadOnly) {
                                        ele.callSetFieldValue('');
                                    }
                                    else {
                                        ele.callSetFieldValue(caseRecord.get(ele.fieldname));
                                    }
                                    if (caseFieldsMetadata[i].RequiredAt) {
                                        if (caseFieldsMetadata[i].RequiredAt.toString().includes(currentStep)) {
                                            ele.callSetAsRequiredField(!bReadOnly);
                                        }
                                        else {
                                            bRequired = false;
                                            ele.callSetAsRequiredField(bRequired);
                                        }
                                    }
                                    ele.callSetAsRequiredField(bRequired);
                                }
                                else {
                                    // Fixes for Disable on Approval Stage.
                                    if(caseRecord.get(ele.fieldname) != null && caseRecord.get(ele.fieldname) != undefined){
                                        ele.callSetFieldValue(caseRecord.get(ele.fieldname));
                                    }
                                    ele.callSetAsDisabledField(true);
                                }
                            }
                            else {
                                // Fixes for Disable on Approval Stage.
                                ele.callSetAsDisabledField(true);
                            
                            }


                        }
                    });
                }
                
                temp.querySelectorAll('lightning-input-field').forEach(item => {
                    if (item.fieldName === caseFieldsMetadata[i].FieldAPINAme) {
                        if (caseFieldsMetadata[i].UpdateAt) {
                            if (caseFieldsMetadata[i].UpdateAt.includes(currentStep)) {
                                if(caseFieldsMetadata[i].dependentField){
                                    let dependentFields = caseFieldsMetadata[i].dependentField.split(';');
                                    dependentFields.forEach(fld =>{
                                        temp.querySelectorAll('c-asf_searchable-picklist').forEach(searchItem => {
                                            if(fld == searchItem.fieldname){
                                                let val = item.value;
                                                searchItem.callDependentPicklistChanges(val);
                                            }
                                        });
                                    })
                                }
                            }
                        }
                    }
                });
                
            }

        }





    }
    catch (e) {
        console.log(e);
    }




};
const calculateMonthlyPayment = (principal, years, rate) => {
    // Your calculation logic here
};
export { getRequiredFieldExpr, calculateMonthlyPayment };