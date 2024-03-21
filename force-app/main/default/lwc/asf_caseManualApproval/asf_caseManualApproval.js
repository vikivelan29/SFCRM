import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/ASF_Case_Approv__c.Approver_01__c';
import { modalStates, errorCodes, staticFields } from "./caseManualApprovalUtility.js";
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import currentUserId from '@salesforce/user/Id';
import APPROVER1 from '@salesforce/schema/ASF_Case_Approv__c.Approver_01__c';
import APPROVER2 from '@salesforce/schema/ASF_Case_Approv__c.Approver_02__c';
import APPROVER3 from '@salesforce/schema/ASF_Case_Approv__c.Approver_03__c';
import APPROVER4 from '@salesforce/schema/ASF_Case_Approv__c.Approver_04__c';
import APPROVER5 from '@salesforce/schema/ASF_Case_Approv__c.Approver_05__c';
import APPROVALTYPE from '@salesforce/schema/ASF_Case_Approv__c.Approval_Type__c';
//import APPROVALPATTERN from '@salesforce/schema/ASF_Case_Approv__c.Approval_Pattern__c';
import CASENUM from '@salesforce/schema/Case.CaseNumber';
import CASESTAGE from '@salesforce/schema/Case.Stage__c'
import CASE_BUSINESSUNIT from '@salesforce/schema/Case.Business_Unit__c'
import LightningAlert from 'lightning/alert';
import getCommunity from "@salesforce/apex/ASF_ApprovalHistoryController.isCommunity";

export default class Asf_caseManualApproval extends NavigationMixin(LightningElement) {
    nameField = NAME_FIELD;

    // Flexipage provides recordId and objectApiName
    @api recordId;
    @api objectApiName = 'ASF_Case_Approv__c';
    objName = 'ASF_Case_Approv__c';
    isLoaded = false;
    arr_fields = [];
    caseNumber = '';
    caseStage = '';
    businessUnit='';
    isClicked = false;
    showSendButton = false;


    _recordId;
    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    get recordEditObjectName() {
        return 'ASF_Case_Approv__c';
    }
    get headerTitle() {
        return 'Approval for Service Request ' + this.caseNumber;
    }
    @wire(getRecord, { recordId: '$recordId', fields: [CASENUM, CASESTAGE, CASE_BUSINESSUNIT] })
    wireUser({ error, data }) {
        if (data) {
            this.caseNumber = data.fields.CaseNumber.value;
            this.caseStage = data.fields.Stage__c.value;
            this.businessUnit =data.fields.Business_Unit__c.value;
        }
    }

    handleLoad(event) {
        let response = JSON.parse(JSON.stringify(event.detail));
        if (response) {
            this.isLoaded = true;
        }
    }
    connectedCallback() {
        this.arr_fields = modalStates.CASE_APPROVAL_FIELDS;
        this.arr_Statisfields = staticFields.APPROVALSTATISFIELDS;
        this.isLoadedInCommunity();

    }
    renderedCallback() {

    }
    getReadyToRender() {
        window.setTimeout(() => {
            return true;
        }, 500);
    }
    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());

    }
    handleAnchorClick(event) {
        console.log(event.currentTarget.dataset.button);
        let actionType = event.currentTarget.dataset.button;
        let currentField = event.currentTarget.dataset.fieldname;
        let fieldLabels = '';

        if (actionType == "ADD") {
            let fieldsToShow = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.addFields;
            let fieldIconsToRemove = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.hideAddDeleteIcon;
            this.showElement(fieldsToShow, 'slds-hide');
            this.showHideAddIncon(fieldIconsToRemove, "hide");

        }
        else if (actionType == "REMOVE") {
            let isValidToRemove = true;
            let fieldToValidate = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields;
            let fieldIconsToRemove = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.showAddDeleteIcon;
            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                for (let arrEle in fieldToValidate) {
                    if (fieldToValidate[arrEle].fieldAPIName == ele.fieldName) {
                        if (!ele.parentElement.parentElement.className.includes('slds-hide')) {
                            if (ele.outerText.includes(errorCodes.GARBAGEVALUEINLOOKUP)) {
                                isValidToRemove = false;
                                let fdLabel = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == ele.fieldName).fieldlabel;
                                fieldLabels += fdLabel + ', '
                            }
                        }
                    }
                }
            })
            if (isValidToRemove) {
                let fieldsToShow = modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields;
                this.hideElement(fieldsToShow, 'slds-hide');
                this.showHideAddIncon(fieldIconsToRemove, "show");
            }
            else {
                fieldLabels = fieldLabels.slice(0, -2);
                let errMsg = errorCodes.WARNINGAPPROVALREMOVAL + fieldLabels;
                this.handleAlertClick(errMsg);
            }



        }
    }
    showHideAddIncon(fieldIconsToRemove, actionType) {
        if (actionType == "hide") {
            fieldIconsToRemove.forEach(field => {
                this.template.querySelectorAll('[data-fieldname="' + field.fieldAPIName + '"]').forEach(ele => {
                    if (!ele.className.includes('slds-hide')) {
                        ele.classList.add('slds-hide');
                    }
                })
            })
        }
        if (actionType == "show") {
            fieldIconsToRemove.forEach(field => {
                this.template.querySelectorAll('[data-fieldname="' + field.fieldAPIName + '"]').forEach(ele => {
                    if (ele.className.includes('slds-hide')) {
                        ele.classList.remove('slds-hide');
                    }
                })
            })
        }

    }
    showElement(fieldsToShow, clsName) {
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            for (let arrEle in fieldsToShow) {
                if (fieldsToShow[arrEle].fieldAPIName == ele.fieldName) {
                    if (ele.parentElement.parentElement.className.includes(clsName)) {
                        ele.parentElement.parentElement.classList.remove(clsName);
                        if (fieldsToShow[arrEle].isRequied) {
                            ele.required = fieldsToShow[arrEle].isRequied;
                        }
                    }
                }
            }

        });
        this.template.querySelectorAll('lightning-radio-group').forEach(ele => {
            for (let arrEle in fieldsToShow) {
                if (fieldsToShow[arrEle].fieldAPIName == ele.dataset.fieldNameCustom) {
                    if (ele.parentElement.parentElement.className.includes(clsName)) {
                        ele.parentElement.parentElement.classList.remove(clsName);
                        if (fieldsToShow[arrEle].isRequied) {
                            ele.required = fieldsToShow[arrEle].isRequied;
                        }
                    }
                }
            }
        });

    }
    hideElement(fieldsToShow, clsName) {
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            for (let arrEle in fieldsToShow) {
                if (fieldsToShow[arrEle].fieldAPIName == ele.fieldName) {
                    if (!ele.parentElement.parentElement.className.includes(clsName)) {
                        ele.parentElement.parentElement.classList.add(clsName);
                        this.template.querySelectorAll('[data-error-help-for-field = "' + ele.fieldName + '"]').forEach(errorDesEle => {
                            errorDesEle.innerText = "";
                        });
                        ele.value = "";
                    }
                    ele.required = false;
                }
            }

        });
        this.template.querySelectorAll('lightning-radio-group').forEach(ele => {
            for (let arrEle in fieldsToShow) {
                if (fieldsToShow[arrEle].fieldAPIName == ele.dataset.fieldNameCustom) {
                    if (!ele.parentElement.parentElement.className.includes(clsName)) {
                        ele.parentElement.parentElement.classList.add(clsName);
                        this.template.querySelectorAll('[data-error-help-for-field = "' + ele.fieldName + '"]').forEach(errorDesEle => {
                            errorDesEle.innerText = "";
                        });
                        ele.value = "";
                    }
                }
            }
        });
    }
    handleSucess(event) {
        const payload = event.detail;
        console.log(JSON.stringify(payload));

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: payload.id,
                objectApiName: this.objName,
                actionName: 'view'
            }
        });


    }
    handleSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        // adding below line to disable the save button once clicked by User 
        this.isClicked = true;
        let isValid = this.validateFields();
        const fields = JSON.parse(JSON.stringify(event.detail.fields).replace(/<p>/g, '').replace(/<\/p>/g, ''));
        fields.SR__c = this.recordId;
        if (this.caseNumber != '') {
            fields.Name = this.caseNumber;
        }
        if (this.caseStage != '') {
            fields.Case_Stage_At_Creation__c = this.caseStage;
        }

        if (fields['Approval_Type__c'] == null || fields['Approval_Type__c'] == undefined || fields['Approval_Type__c'] == "") {
            fields['Approval_Type__c'] = 'Parallel - All to approve';
        }

        if (fields['Approval_Type__c'].startsWith('Parallel')) {
            if (fields[APPROVER1.fieldApiName] != null) {
                let temp_approverFields = [APPROVER2.fieldApiName, APPROVER3.fieldApiName, APPROVER4.fieldApiName, APPROVER5.fieldApiName];

                for (let f in temp_approverFields) {
                    if (fields[temp_approverFields[f]] == null || fields[temp_approverFields[f]] == "" || fields[temp_approverFields[f]] == undefined) {
                        fields[temp_approverFields[f]] = fields[APPROVER1.fieldApiName];
                    }
                }
            }
        }

        fields.TypeOfApproval__c = 'Manual';
        if(this.businessUnit != null && this.businessUnit != undefined){
            fields.Business_Unit__c= this.businessUnit;
        }

        if (isValid) {
            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                if (!fields.hasOwnProperty(ele.fieldName) && !ele.parentElement.parentElement.className.includes('slds-hide')) {
                    if (ele.value != undefined && ele.value != "" && ele.value != null) {
                        fields[ele.fieldName] = ele.value;
                    }
                }
            });
            this.template.querySelectorAll('lightning-radio-group').forEach(ele => {
                if (!fields.hasOwnProperty(ele.dataset.fieldNameCustom) && !ele.className.includes('slds-hide')) {
                    if (ele.value != undefined) {
                        fields[ele.dataset.fieldNameCustom] = ele.value;
                    }
                }
            });

            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
        else {
            this.isClicked = false;
        }

    }
    handleError(event) {
        event.preventDefault();
        event.stopImmediatePropagation();
        console.log(event.detail.detail);

    }
    handleInputFieldChange(event) {
        let val = event.target.value;
        let fdName = event.target.fieldName;
        let allApprovers = [];
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if (ele.fieldName == APPROVER1.fieldApiName || ele.fieldName == APPROVER2.fieldApiName || ele.fieldName == APPROVER3.fieldApiName || ele.fieldName == APPROVER4.fieldApiName || ele.fieldName == APPROVER5.fieldApiName) {
                if (!ele.parentElement.parentElement.className.includes('slds-hide')) {
                    if (ele.fieldName != fdName) {
                        allApprovers.push(ele.value);
                    }

                }
            }
        })
        if (fdName == APPROVER1.fieldApiName || fdName == APPROVER2.fieldApiName || fdName == APPROVER3.fieldApiName || fdName == APPROVER4.fieldApiName || fdName == APPROVER5.fieldApiName) {
            if (val == currentUserId) {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = errorCodes.LOGGEDINUSERAPPROVER;
                });
            }
            else if (allApprovers.indexOf(val) > -1 && val != null && val != undefined && val != "") {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = errorCodes.APPROVERALREADYSELECTED;
                });
            }
            else {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = '';
                });
            }
        }
        if (fdName == APPROVALTYPE.fieldApiName) {

            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            });



        }
    }
    validateFields() {
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {
            // Return whether all fields up to this point are valid and whether current field is valid
            // reportValidity returns validity and also displays/clear message on element based on validity
            let isValid = true;
            if (!field.parentElement.parentElement.className.includes('slds-hide')) {
                this.template.querySelectorAll('[data-error-help-for-field = "' + field.fieldName + '"]').forEach(ele => {
                    if (ele.innerText != null && ele.innerText != "" && ele.innerText != undefined) {
                        isValid = false;
                    }
                })
                if (isValid) {
                    isValid = field.reportValidity();
                }

            }
            else {
                isValid = true;
            }
            return (validSoFar && isValid);
        }, true);
    }
    handleOutsideSubmitButton(event) {
        this.template.querySelector('lightning-record-edit-form').submit();
    }
    handleEditInput(event) {
        let a = event.target.value;
        let b = event.currentTarget.fieldName;
        console.log(a);
        console.log(b);

    }

    async handleAlertClick(msg) {
        await LightningAlert.open({
            message: msg,
            theme: 'shade', // a red theme intended for error states
            label: 'Warning!', // this is the header text
        });
        //Alert has been closed
    }

    isLoadedInCommunity() {

        getCommunity()
            .then(result => {
                console.log('showSendButton' + result);
                this.showSendButton = result;
            })
            .catch(error => {
                console.log('Errorured:- ' + error.body.message);
            });
    }



}