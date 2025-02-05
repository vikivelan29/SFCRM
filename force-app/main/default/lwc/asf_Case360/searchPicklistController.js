const setPicklistFieldValue = (event, templ) => {
    let temp = event.detail;
    templ.querySelectorAll('lightning-input-field').forEach(ele => {
        if (ele.fieldName == temp.fldName) {
            ele.value = temp.fldValue;
        }
    });
};
const conditionalRenderingPicklist = (event, templ, caseFieldsMetadata, currentStep) => {

    for (var fieldmdt in caseFieldsMetadata) {
        //console.log(caseFieldsMetadata[fieldmdt]);

        if (caseFieldsMetadata[fieldmdt].UpdateAt) {
            if (caseFieldsMetadata[fieldmdt].UpdateAt.toString().includes(currentStep) && caseFieldsMetadata[fieldmdt].ControllingExpression != null && caseFieldsMetadata[fieldmdt].ControllingField != null) {
                if (event.currentTarget.fieldName == caseFieldsMetadata[fieldmdt].ControllingField) {

                    if (event.detail.value == caseFieldsMetadata[fieldmdt].ControllingExpression) {

                        templ.querySelectorAll('c-asf_searchable-picklist').forEach((field) => {
                            if (field.fieldName == caseFieldsMetadata[fieldmdt].FieldAPINAme && !caseFieldsMetadata[fieldmdt].useControllingFormula) {
                                field.callSetAsDisabledField(false);
                                //field.required = true;
                                //var controllingField = caseFieldsMetadata.find(item1 => item1.FieldAPINAme == caseFieldsMetadata[item].ControllingField);
                                if (caseFieldsMetadata[fieldmdt].RequiredAt) {
                                    if (caseFieldsMetadata[fieldmdt].RequiredAt.toString().includes(currentStep)) {
                                        field.callSetAsRequiredField(true);
                                    }
                                    else {
                                        field.callSetAsRequiredField(false);
                                    }
                                }
                                else {
                                    field.callSetAsRequiredField(false);
                                }

                            }

                        });

                    }
                    else {
                        templ.querySelectorAll('c-asf_searchable-picklist').forEach((field) => {
                            if (field.fieldName == caseFieldsMetadata[fieldmdt].FieldAPINAme && !caseFieldsMetadata[fieldmdt].useControllingFormula) {
                                field.callSetAsDisabledField(true);
                                field.callSetAsRequiredField(false);
                                field.callSetFieldValue('');
                            }

                        });
                    }


                }
            }
        }

    }

}
const renderingPicklistOnStageAdjustment = (templ, caseFieldsMetadata, currentStep, caseExtensionObj, caseRecordDetails) => {
    const caseRecord = new Map();
    let bRecordLoaded = false;
    templ.querySelectorAll('lightning-input-field').forEach(field => {
        let fdName = field.fieldName;
        let fdVal = field.value;
        if (fdVal != undefined) {
            bRecordLoaded = true;
        }else {
            if (caseRecordDetails != undefined && caseRecordDetails != null && caseRecordDetails.hasOwnProperty(fdName)) {
                fdVal = caseRecordDetails[fdName].value;
                bRecordLoaded =true;
            }
            else if (caseExtensionObj != undefined && caseExtensionObj != null && caseExtensionObj.hasOwnProperty(fdName)) {
                fdVal = caseExtensionObj[fdName].value;
                bRecordLoaded =true;
            }
        }
        console.log(fdName + ' ---> ' + fdVal);
        caseRecord.set(fdName, fdVal);

    });
    if (bRecordLoaded) {

        for (var item=0;item<caseFieldsMetadata.length; item++){//in caseFieldsMetadata) {
            console.log('item ---> '+item+' --> '+caseFieldsMetadata[item])
            if (caseFieldsMetadata[item].bSearchablePicklist || caseFieldsMetadata[item].bMultiSelectSearchablePicklist) {
                templ.querySelectorAll('c-asf_searchable-picklist').forEach(field => {
                    if (field.fieldname == caseFieldsMetadata[item].FieldAPINAme) {
                        if (caseFieldsMetadata[item].UpdateAt) {
                            if (caseFieldsMetadata[item].UpdateAt.includes(currentStep)) {
                                if (caseFieldsMetadata[item].ControllingField == null && !caseFieldsMetadata[item].useControllingFormula) {
                                    field.callSetAsDisabledField(false);
                                    templ.querySelectorAll('.slds-hide').forEach(hiddenEle => {
                                        if (hiddenEle.fieldName == field.fieldname) {
                                            if (hiddenEle.value != undefined) {
                                                field.callSetFieldValue(hiddenEle.value);
                                            }
                                            else if (caseRecordDetails) {
                                                if (caseRecordDetails.hasOwnProperty(hiddenEle.fieldName)) {
                                                    let tempVal = caseRecordDetails[hiddenEle.fieldName].value;
                                                    field.callSetFieldValue(tempVal);
                                                }
                                            }

                                        }
                                    });
                                }
                                else {
                                    var controllingField = caseFieldsMetadata.find(item1 => item1.FieldAPINAme == caseFieldsMetadata[item].ControllingField);
                                    if (caseExtensionObj && controllingField) {
                                        if (caseExtensionObj[controllingField.FieldAPINAme] == caseFieldsMetadata[item].ControllingExpression && !caseFieldsMetadata[item].useControllingFormula) {
                                            field.callSetAsDisabledField(false);
                                            //check for mandatory
                                            if (caseFieldsMetadata[item].RequiredAt) {
                                                if (caseFieldsMetadata[item].RequiredAt.toString().includes(currentStep)) {
                                                    field.callSetAsRequiredField(true);
                                                }
                                                else {
                                                    field.callSetAsRequiredField(false);
                                                }
                                            }
                                        }
                                        else {
                                            if (!caseFieldsMetadata[item].useControllingFormula) {
                                                field.callSetAsDisabledField(true);
                                                templ.querySelectorAll('.slds-hide').forEach(hiddenEle => {
                                                    if (hiddenEle.fieldName == field.fieldname) {
                                                        field.callSetFieldValue("");
                                                    }
                                                });
                                            }

                                        }
                                    }
                                    else {
                                        templ.querySelectorAll('.slds-hide').forEach((field1) => {
                                            if (controllingField) {
                                                if (field1.fieldName == controllingField.FieldAPINAme) {
                                                    if (field1.value != undefined) {
                                                        if (field1.value == caseFieldsMetadata[item].ControllingExpression && !caseFieldsMetadata[item].useControllingFormula) {
                                                            field1.callSetAsDisabledField(false);
                                                            hideReadOnlyFields(field1);//Virendra : hide/show element when disabled is true;

                                                            if (caseFieldsMetadata[item].RequiredAt) {
                                                                if (caseFieldsMetadata[item].RequiredAt.toString().includes(currentStep)) {
                                                                    field1.callSetAsRequiredField(true);
                                                                }
                                                                else {
                                                                    field1.callSetAsRequiredField(false);
                                                                }
                                                            }
                                                        }
                                                        else {
                                                            if (!caseFieldsMetadata[item].useControllingFormula) {
                                                                field1.callSetAsDisabledField(true);
                                                                hideReadOnlyFields(field1);//Virendra : hide/show element when disabled is true;
                                                            }
                                                        }
                                                    }


                                                }
                                            }

                                        });

                                        //field.disabled = true;
                                    }
                                }
                            }
                            else {
                                if (!caseFieldsMetadata[item].useControllingFormula) {
                                    templ.querySelectorAll('.slds-hide').forEach(hiddenEle => {
                                        if (hiddenEle.fieldName == field.fieldname) {
                                            if (hiddenEle.value != undefined) {
                                                field.callSetFieldValue(hiddenEle.value);
                                            }
                                            else if (caseRecordDetails) {
                                                if (caseRecordDetails.hasOwnProperty(hiddenEle.fieldName)) {
                                                    let tempVal = caseRecordDetails[hiddenEle.fieldName].value;
                                                    field.callSetFieldValue(tempVal);
                                                }
                                            }

                                        }
                                    });
                                    field.callSetAsDisabledField(true);
                                    //hideReadOnlyFields(field);//Virendra : hide/show element when disabled is true;
                                }

                            }
                        }
                        else {
                            if (!caseFieldsMetadata[item].useControllingFormula) {
                                field.callSetAsDisabledField(true);
                                //hideReadOnlyFields(field);//Virendra : hide/show element when disabled is true;
                            }

                        }

                        if (caseFieldsMetadata[item].RequiredAt) {
                            if (caseFieldsMetadata[item].RequiredAt.includes(currentStep)) {
                                if (caseFieldsMetadata[item].ControllingField == null) {
                                    field.callSetAsRequiredField(true);
                                }
                                else {
                                    //field.required = false;
                                }

                            }
                            else {
                                field.callSetAsRequiredField(false);
                            }
                        }
                        else {
                            field.callSetAsRequiredField(false);
                        }
                    }
                });
            }
        }
    }
}

const hideReadOnlyFields = (ele) => {
    if (ele.disabled == true) {
        if (!ele.className.includes('slds-hide')) {
            //ele.classList.add('slds-hide');
        }
    }
    else {
        if (ele.dataset.hiddenpicklist != true && ele.dataset.hiddenpicklist != "true") {
            if (ele.className.includes('slds-hide')) {
                //ele.classList.remove('slds-hide');
            }
        }

    }
}

export { setPicklistFieldValue, conditionalRenderingPicklist, renderingPicklistOnStageAdjustment, hideReadOnlyFields };