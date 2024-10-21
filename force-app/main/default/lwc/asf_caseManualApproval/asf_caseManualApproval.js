import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/ASF_Case_Approv__c.Approver_01__c';
import { modalStates, errorCodes, getBUSpecificStaticFields } from "./caseManualApprovalUtility.js";
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import currentUserId from '@salesforce/user/Id';
import APPROVER1 from '@salesforce/schema/ASF_Case_Approv__c.Approver_01__c';
import APPROVER2 from '@salesforce/schema/ASF_Case_Approv__c.Approver_02__c';
import APPROVER3 from '@salesforce/schema/ASF_Case_Approv__c.Approver_03__c';
import APPROVER4 from '@salesforce/schema/ASF_Case_Approv__c.Approver_04__c';
import APPROVER5 from '@salesforce/schema/ASF_Case_Approv__c.Approver_05__c';
import RECAT_APPROVER1 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_01__c';
import RECAT_APPROVER2 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_02__c';
import RECAT_APPROVER3 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_03__c';
import RECAT_APPROVER4 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_04__c';
import RECAT_APPROVER5 from '@salesforce/schema/ASF_Case_Approv__c.Recat_Approver_05__c';
import APPROVALTYPE from '@salesforce/schema/ASF_Case_Approv__c.Approval_Type__c';
//import APPROVALPATTERN from '@salesforce/schema/ASF_Case_Approv__c.Approval_Pattern__c';
import CASENUM from '@salesforce/schema/Case.CaseNumber';
import CASESTAGE from '@salesforce/schema/Case.Stage__c';
import CASE_BUSINESSUNIT from '@salesforce/schema/Case.Business_Unit__c';
import LightningAlert from 'lightning/alert';
import getCommunity from "@salesforce/apex/ASF_ApprovalHistoryController.isCommunity";
import { RefreshEvent } from 'lightning/refresh';
import { fireEventNoPageRef } from 'c/asf_pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';

export default class Asf_caseManualApproval extends NavigationMixin(LightningElement) {
    nameField = NAME_FIELD;

    // Flexipage provides recordId and objectApiName
    @api recordId;
    @api objectApiName = 'ASF_Case_Approv__c';
    @api isRecatRequest = false;
    @api typeSubTypeText = '';
    objName = 'ASF_Case_Approv__c';
    isLoaded = false;
    arr_fields = [];
    caseNumber = '';
    caseStage = '';
    businessUnit='';
    isClicked = false;
    showSendButton = false;
    fields;
    approver1 = '';
    approver2 = '';
    approver3 = '';
    approver4 = '';
    approver5 = '';
    loaded = true;

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
        if(this.isRecatRequest){
            return 'Recategorize Approval Request - ' + this.caseNumber;
        }else{
            return 'Approval for Case ' + this.caseNumber;
        }
    }
    @wire(getRecord, { recordId: '$recordId', fields: [CASENUM, CASESTAGE, CASE_BUSINESSUNIT] })
    wireUser({ error, data }) {
        if (data) {
            this.caseNumber = data.fields.CaseNumber.value;
            this.caseStage = data.fields.Stage__c.value;
            this.businessUnit =data.fields.Business_Unit__c.value;
            let staticFields = getBUSpecificStaticFields(this.businessUnit);
            this.arr_Statisfields = staticFields.APPROVALSTATISFIELDS;
        }
    }

    handleLoad(event) {
        let response = JSON.parse(JSON.stringify(event.detail));
        if (response) {
            this.isLoaded = true;
        }
    }
    connectedCallback() {
        this.approver1 = !this.isRecatRequest ? APPROVER1.fieldApiName : RECAT_APPROVER1.fieldApiName;
        this.approver2 = !this.isRecatRequest ? APPROVER2.fieldApiName : RECAT_APPROVER2.fieldApiName;
        this.approver3 = !this.isRecatRequest ? APPROVER3.fieldApiName : RECAT_APPROVER3.fieldApiName;
        this.approver4 = !this.isRecatRequest ? APPROVER4.fieldApiName : RECAT_APPROVER4.fieldApiName;
        this.approver5 = !this.isRecatRequest ? APPROVER5.fieldApiName : RECAT_APPROVER5.fieldApiName;
        this.arr_fields = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS : modalStates.RECAT_APPROVAL_FIELDS;
        
        this.isLoadedInCommunity();
    }
    renderedCallback() {

    }
    getReadyToRender() {
        window.setTimeout(() => {
            return true;
        }, 500);
    }
    submitForm(event){
        this.template.querySelector('.hiddenSubmit').click();
    }
    handleCancel(event) {
        if(this.isRecatRequest){
            const cancelEvent = new CustomEvent('closescreen');
            this.dispatchEvent(cancelEvent);
        }else{
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
    handleAnchorClick(event) {
        console.log(event.currentTarget.dataset.button);
        let actionType = event.currentTarget.dataset.button;
        let currentField = event.currentTarget.dataset.fieldname;
        let fieldLabels = '';

        if (actionType == "ADD") {
            let fieldsToShow = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.addFields
                                                    :  modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.addFields;
            let fieldIconsToRemove = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.hideAddDeleteIcon
                                                          : modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorAddAction.hideAddDeleteIcon;
            this.showElement(fieldsToShow, 'slds-hide');
            this.showHideAddIncon(fieldIconsToRemove, "hide");

        }
        else if (actionType == "REMOVE") {
            let isValidToRemove = true;
            let fieldToValidate = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields
                                                        : modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields;
            let fieldIconsToRemove = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.showAddDeleteIcon
                                                        : modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.showAddDeleteIcon;
            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                for (let arrEle in fieldToValidate) {
                    if (fieldToValidate[arrEle].fieldAPIName == ele.fieldName) {
                        if (!ele.parentElement.parentElement.className.includes('slds-hide')) {
                            if (ele.outerText.includes(errorCodes.GARBAGEVALUEINLOOKUP)) {
                                isValidToRemove = false;
                                let fdLabel = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == ele.fieldName).fieldlabel
                                                                    : modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == ele.fieldName).fieldlabel;
                                fieldLabels += fdLabel + ', '
                            }
                        }
                    }
                }
            })
            if (isValidToRemove) {
                let fieldsToShow = !this.isRecatRequest ? modalStates.CASE_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields
                                                        : modalStates.RECAT_APPROVAL_FIELDS.find(fd => fd.fieldAPIName == currentField).anchorRemoveAction.removeFields;
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
                        let staticField = this.arr_Statisfields.find((field)=>{return fieldsToShow[arrEle].fieldAPIName == field.fieldAPIName});
                        if(staticField && staticField.defaulSelectedOption){
                            ele.value = staticField.defaulSelectedOption;
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
    async handleSubmit(event) {
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
            let staticField = this.arr_Statisfields.find((field)=>{return 'Approval_Type__c' == field.fieldAPIName});
            if(staticField && staticField.defaulSelectedOption && staticField.defaulSelectedOption != 'Parallel'){
                fields['Approval_Type__c'] = staticField.defaulSelectedOption;
            }
        }
        if (fields['Approval_Type__c'].startsWith('Parallel')) {
            if (fields[this.approver1] != null) {
                let temp_approverFields = [this.approver2, this.approver3, this.approver4, this.approver5];

                for (let f in temp_approverFields) {
                    if (fields[temp_approverFields[f]] == null || fields[temp_approverFields[f]] == "" || fields[temp_approverFields[f]] == undefined) {
                        fields[temp_approverFields[f]] = fields[this.approver1];
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
            fields.Is_Recategorization_Request__c = this.isRecatRequest;

            if (this.isRecatRequest) {
                fields.Approver_01__c = fields[this.approver1];
                fields.Approver_02__c = fields[this.approver2];
                fields.Approver_03__c = fields[this.approver3];
                fields.Approver_04__c = fields[this.approver4];
                fields.Approver_05__c = fields[this.approver5];
                fields.Name = 'Recategorize - '+this.caseNumber;
            }
            this.fields = fields;
            if(this.isRecatRequest){
                this.loaded = false;
                const submitEvent = new CustomEvent('submitcase');
                this.dispatchEvent(submitEvent);
                this.loaded = true;
            }else{
                this.template.querySelector('lightning-record-edit-form').submit(fields); 
            }
        }
        else {
            this.isClicked = false;
            this.showError('error','Error Occured !','Required field missing.');
        }

    }
    
    @api submitApproval(requestedCCC, caseId){
        console.log('req ccc parm and reload---'+requestedCCC+'--case id--'+caseId);
        this.fields.Requested_CCC_Details__c = requestedCCC;
        this.template.querySelector('lightning-record-edit-form').submit(this.fields);
        this.dispatchEvent(new RefreshEvent());
        let payload = {'source':'recat', 'recordId':caseId};
        fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);
        let changeArray = [{recordId: caseId}];
        getRecordNotifyChange(changeArray);
        window.location.reload();
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
            if (ele.fieldName == this.approver1 || ele.fieldName == this.approver2 || ele.fieldName == this.approver3 || ele.fieldName == this.approver4 || ele.fieldName == this.approver5) {
                if (!ele.parentElement.parentElement.className.includes('slds-hide')) {
                    if (ele.fieldName != fdName) {
                        allApprovers.push(ele.value);
                    }

                }
            }
            if(fdName == "Requestor_Comments__c" ){
                if(val || val==undefined || val==''){ // check is used to enable the Send button when we received the "text too long" error
                    this.isClicked = false;
                }
            }
        })
        /*if (fdName == this.approver1 || fdName == this.approver2 || fdName == this.approver3 || fdName == this.approver4 || fdName == this.approver5) {
            console.log('Inside approvers comp',fdName);
            console.log(JSON.stringify(allApprovers));
            if (val == currentUserId) {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = errorCodes.LOGGEDINUSERAPPROVER;
                    console.log(ele);
                });
            }
            
            else if (allApprovers.indexOf(val) > -1 && val != null && val != undefined && val != "") {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = errorCodes.APPROVERALREADYSELECTED;
                    console.log(ele);
                });
            }
            else {
                this.template.querySelectorAll('[data-error-help-for-field="' + fdName + '"]').forEach(ele => {
                    ele.innerText = '';
                    console.log('3',ele);
                });
            }
        }*/
        
        let errorMessage = '';
        if (val == currentUserId) {
            errorMessage = errorCodes.LOGGEDINUSERAPPROVER;
        } else if (allApprovers.indexOf(val) > -1 && val) {
            errorMessage = errorCodes.APPROVERALREADYSELECTED;
            console.log('1',errorMessage);
        }else{
            errorMessage = '';
        }

        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if ([this.approver1, this.approver2, this.approver3, this.approver4, this.approver5].includes(ele.fieldName)) {
                this.template.querySelectorAll(`[data-error-help-for-field="${ele.fieldName}"]`).forEach(errorEle => {
                    //commented below 2 line to keep the error message(s) to the respective fields
                    //errorEle.innerText = '';
                    //console.log('Cleared:', errorEle);
                });
            }
        });
    
        // Set the error message for the specific field
        this.template.querySelectorAll(`[data-error-help-for-field="${fdName}"]`).forEach(errorEle => {
            errorEle.innerText = errorMessage;
            console.log('Set Error:', errorEle);
            this.isClicked = errorEle.innerText? true :false;
        });
    
        if (fdName == APPROVALTYPE.fieldApiName) {

            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            });



        }
    }
    hasImgTag(htmlString) {
        // Regular expression to match <img> tags
        var imgRegex = /<img[^>]+>/g;
        
        // Check if the htmlString contains any <img> tags
        return imgRegex.test(htmlString);
    }
    removeHTMLTags(htmlString) {
        if(this.hasImgTag(htmlString)){
            return htmlString;
        }
        // Create a new DOMParser instance
        const parser = new DOMParser();
        // Parse the HTML string into a DOM document
        const doc = parser.parseFromString(htmlString, 'text/html');
        // Extract the text content from the parsed document
        const textContent = doc.body.textContent || "";
        return textContent.trim(); // Trim any leading or trailing whitespace
    }
    validateFields() {
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {
            // Return whether all fields up to this point are valid and whether current field is valid
            // reportValidity returns validity and also displays/clear message on element based on validity
            let isValid = true;
            if (!field.parentElement.parentElement.className.includes('slds-hide')) {
                //let plainTextContent  = field.value.replace(/(<([^>]+)>)/ig, '');                
                let plainTextContent = this.removeHTMLTags(field.value);
                if(plainTextContent == undefined || plainTextContent == null || plainTextContent == ""){
                        field.value = plainTextContent;
                        if(field.fieldName == "Requestor_Comments__c"){
                            isValid = false;
                            return (validSoFar && isValid);
                        }
                }


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

    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }



}