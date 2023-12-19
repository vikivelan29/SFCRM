import { LightningElement, track } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountDataByCustomerType';
import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import { reduceErrors } from 'c/asf_ldsUtils';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getForm from '@salesforce/apex/ASF_FieldSetController.getForm';


import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import TECHNICAL_SOURCE_FIELD from '@salesforce/schema/Case.Technical_Source__c';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import TRACK_ID from '@salesforce/schema/Case.Track_Id__c';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';

import CASE_OBJECT from '@salesforce/schema/Case';

export default class Asf_CreateCaseWithProspect extends NavigationMixin(LightningElement) {
    @track loaded = true;
    typingTimer;
    doneTypingInterval = 300;
    @track accounts;
    strSource = '';
    sourceFldValue;
    sourceFldOptions;
    boolShowNoData = false;
    strDefaultChannel = '';
    strChannelValue = '';
    strNoDataMessage = '';
    boolAllChannelVisible = false;
    boolAllSourceVisible = false;
    createCaseWithAll = false;
    isNotSelected = true;
    isAllNature = false;
    isAllSource = false;
    caseRelObjName;
    trackId = '';
    caseRecordId;
    ctstSelection = true;
    fields;
    error;



    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'LOB', fieldName: 'LOB__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ]


    handelSearchKey(event) {
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;

        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.SearchAccountHandler();
            }
        }, this.doneTypingInterval);
    }
    SearchAccountHandler() {
        getAccountData({ keyword: this.searchKey, asssetProductType: "", isasset: "false", accRecordType : null })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    this.strSource = result.strSource;
                    if(this.strSource) {
                        this.populateSourceFld();
                    }
                    this.boolShowNoData = false;
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        //this.createCaseWithAll = true;
                        this.lstChannelValues = result.lstChannel;
                        this.strDefaultChannel = this.lstChannelValues[0].label;
                        this.strChannelValue = this.strDefaultChannel;
                        this.boolChannelVisible = true;

                    }
                }
                else if (result.boolNoData == true) {
                    this.boolShowNoData = true;
                    this.strNoDataMessage = result.strErrorMessage;
                }
                this.isNotSelected = true;
                this.loaded = true;
            })
            .catch(error => {
                this.accounts = null;
                console.log('tst22423', error);
                this.isNotSelected = true;
                this.loaded = true;
            });

    }
    populateSourceFld() {
        let getAllSourceFldValues = this.strSource.split(',');
        this.sourceFldValue = getAllSourceFldValues[0];
        this.sourceFldOptions = getAllSourceFldValues.map(fldVal => ({label : fldVal, value : fldVal}));
    }

    getSelectedName(event) {
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
        }
        if ((selected) && (this.businessUnit == 'ABFL')) {
            this.boolAllChannelVisible = false;
            this.boolAllSourceVisible = true;
        }

        if (selected) {
            this.createCaseWithAll = true;
            this.isNotSelected = false;

            if (selected[NATURE_FIELD.fieldApiName] == "All") {
                this.isAllNature = true;
            }
            if (selected[SOURCE_FIELD.fieldApiName] == "All") {
                this.isAllSource = true;
            }
        }
    }
    async createCaseHandler(event){
        if(!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            return;
        }
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];

        //this.loaded = false;
        const fields = {};

        await this.getCaseRelatedObjName(selected.CCC_External_Id__c);

        if (this.caseRelObjName) {
            await this.createRelObj();
            fields[this.caseRelObjName] = this.caseExtensionRecordId;
        }

        fields[TECHNICAL_SOURCE_FIELD.fieldApiName] = 'LWC';
        fields[ORIGIN_FIELD.fieldApiName] = 'Phone';
        //fields[ASSETID_FIELD.fieldApiName] = this.recordId;
        fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[SOURCE_FIELD.fieldApiName] = this.sourceFldValue;
        fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        fields[TRACK_ID.fieldApiName] = this.trackId;

        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
        this.loaded = false;
        createRecord(caseRecord)
            .then(result => {
                this.caseRecordId = result.id;
                this.resetBox();
                this.loaded = true;

                //tst strt
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.caseRecordId,
                        actionName: 'view'
                    },
                    state: {
                        mode: 'edit'
                    }
                });
                //tst end
                this.dispatchEvent(new CloseActionScreenEvent());


                this.isNotSelected = true;
                this.createCaseWithAll = false;
            })
            .catch(error => {
                console.log('tst225572' + JSON.stringify(error));
                this.showError('error', 'Oops! Error occured', error);
                
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
            })
    }

    async getCaseRelatedObjName(cccExtId) {
        //tst Get the Case Extension Object Name
        await getCaseRelatedObjName({ cccId: cccExtId })
            .then(result => {
                console.log('tst23' + result);
                this.caseRelObjName = result;
                // this.caseExtensionRecordId = this.caseObj.fields[this.caseRelObjName].value;
            })
            .catch(error => {
                console.log(error);
                //this.error = error;
            });
        //tst end
    }
    async createRelObj() {
        const fields = {};

        if(this.isTransactionRelated){
            fields[TRANSACTION_NUM.fieldApiName] = this.transactionNumber;
        }

        const caseRecord = { apiName: this.caseRelObjName, fields: fields };

        await createRecord(caseRecord)
            .then(result => {
                this.caseExtensionRecordId = result.id;
                console.log('tst22557' + this.caseExtensionRecordId);
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
                
                this.loaded = true;
            })
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
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            else if(inputField.value != null && inputField.value != undefined){
                if(inputField.value.trim() == ''){
                    inputField.value = '';
                    inputField.reportValidity();
                    isValid = false;
                }
            }
        });
        return isValid;
    }
    resetBox() {
        console.log('in reset box');
        this.dispatchEvent(new CustomEvent('resetbox', {
            detail: {
                message: 'true'
            }
        }));
    }

    async handleNext(event){
        this.ctstSelection = false;
        await getForm({ recordId: null,objectName:"Lead", fieldSetName:"ABHFL_Prospect_FieldSet"})
        .then(result => {
            console.log('Data:'+ JSON.stringify(result));
            if (result) {
                this.fields = result.Fields;
                this.error = undefined;
            }
        }) .catch(error => {
            console.log(error);
            this.error = error;
        }); 
    }
    handleBack(event){
        this.ctstSelection = true;
    }
}