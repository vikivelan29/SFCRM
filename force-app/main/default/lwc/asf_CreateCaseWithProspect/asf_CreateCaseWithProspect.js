import { LightningElement, track, api, wire } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountDataByCustomerType';
import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import { reduceErrors } from 'c/asf_ldsUtils';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getForm from '@salesforce/apex/ASF_FieldSetController.getLOBSpecificForm';
import createProspectCase from '@salesforce/apex/ASF_CustomerAndProspectSearch.createProspectWithCaseExtnAndCase';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU';


import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import TECHNICAL_SOURCE_FIELD from '@salesforce/schema/Case.Technical_Source__c';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import TRACK_ID from '@salesforce/schema/Case.Track_Id__c';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';
import NOAUTOCOMM_FIELD from '@salesforce/schema/Case.No_Auto_Communication__c';
import CASE_BUSINESS_UNIT_FIELD from '@salesforce/schema/Case.Business_Unit__c';

import CASE_OBJECT from '@salesforce/schema/Case';

import FROMPROSPECTPAGE from "./asf_CreateCaseFromProspect.html";
import FROMGLOBALSEARCHPAGE from "./asf_CreateCaseWithProspect.html";

import loggedInUserId from '@salesforce/user/Id';

import { getRecord } from 'lightning/uiRecordApi';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import PROSPECT_BUSINESS_UNIT from '@salesforce/schema/Lead.Business_Unit__c';


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
    boolSourceComboboxDisabled = false;
    createCaseWithAll = false;
    boolNoAutoComm = true;
    isNotSelected = true;
    isAllNature = false;
    isAllSource = false;
    caseRelObjName;
    trackId = '';
    caseRecordId;
    ctstSelection = true;
    fields;
    error;
    selectedCTSTRecord;
    disbleNextBtn = true;
    @track disableBackBtn= true;
    disableCreateBtn = true;
    @track dupeLead=[];
    @track showDupeList=false;
    @api recordId;
    @track showFromGlobalSearch = true;
    selectedCTSTFromProspect;
    @api isInternalCase = false;
    @track loggedInUserBusinessUnit = '';
    noAutoCommOptions = [];
    noAutoCommValue = [];
    isPhoneInbound = false;


    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'LOB', fieldName: 'LOB__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ];
    dupeLeadCols = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'MobilePhone', fieldName: 'MobilePhone', type: 'text' }
    ]


    //To get No Auto Communication pickilst values
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NOAUTOCOMM_FIELD })
    wiredPicklistValues({ error, data}) {
        if (data){
            let pickVals = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            this.noAutoCommOptions.push.apply(this.noAutoCommOptions,pickVals) ;
        } else if (error){
            console.log('error in get picklist--'+JSON.stringify(error));
        }
    }


    @wire(getRecord, { recordId: loggedInUserId, fields: [UserBusinessUnit ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
        } else if (error) {
            //this.error = error ;
        }
    }


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

        this.removeSelection();
        
        getAccountData({ keyword: this.searchKey, asssetProductType: "", isasset: "Prospect", accRecordType: null, assetLob : null })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    this.strSource = result.strSource;
                    if (this.strSource) {
                        this.populateSourceFld();
                    }
                    this.boolShowNoData = false;
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        //this.createCaseWithAll = true;
                        this.lstChannelValues = result.lstChannel;
                        this.strDefaultChannel = this.lstChannelValues[0].label;
                        if(this.loggedInUserBusinessUnit != 'ABFL'){
                            this.strChannelValue = this.strDefaultChannel;
                        }
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
        this.sourceFldOptions = getAllSourceFldValues.map(fldVal => ({ label: fldVal, value: fldVal }));
    }

    getSelectedName(event) {
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
            this.selectedCTSTFromProspect = selected;
            if(this.showFromGlobalSearch == false){
                this.disableCreateBtn = false;
            }
        }
        if ((selected) && (this.loggedInUserBusinessUnit == 'ABFL')) {
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
            if (this.loggedInUserBusinessUnit === ABSLIG_BU) {
                this.boolAllChannelVisible = false;
                this.boolNoAutoComm = false;

                if(this.sourceFldOptions.length === 1) {
                    this.boolSourceComboboxDisabled = true;
                }
            }
            this.disbleNextBtn = false;
        }
        // added by sunil 03/09/2024
        this.checkTrackIdCondition();
    }

    // Method Description - Deselect all selection from lightning datatable
    removeSelection() {
        let dataTableRecords = this.template.querySelector('lightning-datatable');
        if(dataTableRecords) {
            dataTableRecords.selectedRows = [];
        }
     }

    async createCaseHandler(event) {
        this.handleLeadSubmit(event);
        //this.template.querySelector('lightning-record-edit-form[data-id="leadCreateForm"]').submit();
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
        let inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(inputField => {
            //if (inputField.value != null && inputField.value != undefined) {

            if (inputField.required == true) {
                if (inputField.value != null && inputField != undefined) {
                    if (inputField.value.trim() == '') {
                        inputField.value = '';
                        inputField.reportValidity();
                        isValid = false;
                    }
                    
                }
                else{
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

    async handleNext(event) {
        event.preventDefault();

        
        
        this.selectedCTSTRecord = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            return;
        }
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
        if(!All_Compobox_Valid){
            return;
        }

        this.ctstSelection = false;
        this.showDupeList = false;
        this.disableBackBtn = false;
        this.dupeLead = [];
        this.disableCreateBtn = false;

        await getForm({ recordId: null, objectName: "Lead", fieldSetName: null,salesProspect:false })
            .then(result => {
                console.log('Data:' + JSON.stringify(result));
                if (result) {
                    this.fields = result.Fields;
                    this.error = undefined;
                }
            }).catch(error => {
                console.log(error);
                this.error = error;
            });
    }
    handleBack(event) {
        this.ctstSelection = true;
        this.selectedCTSTRecord = null;
        this.disbleNextBtn = true;
        this.disableBackBtn = true;
    }
    async handleLeadSubmit(event) {
        event.preventDefault();

        this.disableCreateBtn = true;
        let leadFields = [...this.template.querySelectorAll('lightning-input-field')]
        let fieldsVar = leadFields.map((field)=>[field.fieldName,field.value]);


        if (!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            this.disableCreateBtn = false;
            return;
        }
        var selected = this.selectedCTSTRecord;
        
        //this.loaded = false;
        const fields = {};
        let caseExtnRecord = {};
        let caseRecord = {};
        let leadRecord = Object.fromEntries([...fieldsVar, ['sobjectType', 'Lead']]);
        leadRecord[PROSPECT_BUSINESS_UNIT.fieldApiName] = this.loggedInUserBusinessUnit;

        if(this.showFromGlobalSearch == false){
            selected = this.selectedCTSTFromProspect;
            leadRecord = null;
            caseRecord["Lead__c"]= this.recordId;

        }

        await this.getCaseRelatedObjName(selected.CCC_External_Id__c);

        if (this.caseRelObjName) {
            const extnfields = {};

            if (this.isTransactionRelated) {
                extnfields[TRANSACTION_NUM.fieldApiName] = this.transactionNumber;
            }
            caseExtnRecord["sobjectType"] = this.caseRelObjName;

        }
        else{
            caseExtnRecord = null;
        }

        caseRecord[TECHNICAL_SOURCE_FIELD.fieldApiName] = 'LWC';
        caseRecord[ORIGIN_FIELD.fieldApiName] = 'Phone';
        //fields[ASSETID_FIELD.fieldApiName] = this.recordId;
        caseRecord[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        caseRecord[NATURE_FIELD.fieldApiName] = this.natureVal;
        caseRecord[SOURCE_FIELD.fieldApiName] = this.sourceFldValue;
        caseRecord[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        if(this.trackId != null && this.trackId != undefined && this.trackId != ""){
            caseRecord[TRACK_ID.fieldApiName] = this.trackId;
        }
        caseRecord[NOAUTOCOMM_FIELD.fieldApiName] = this.noAutoCommValue.join(';');
        caseRecord[CASE_BUSINESS_UNIT_FIELD.fieldApiName] = this.loggedInUserBusinessUnit;
        caseRecord["sobjectType"] = "Case";
        
        this.noAutoCommValue = [];
        
        createProspectCase({ caseToInsert: caseRecord, caseExtnRecord: caseExtnRecord, prospectRecord: leadRecord })
            .then(result => {
                if(result.DuplicateLead != null && result.DuplicateLead != undefined){
                    this.dupeLead.push(JSON.parse(JSON.stringify(result.DuplicateLead)));
                    if(this.dupeLead != null && this.dupeLead != undefined && this.dupeLead.length > 0){
                        this.dupeLead[0].redirectLink =  '/' + this.dupeLead[0].Id;
                        this.showDupeList=true;
                        this.disableCreateBtn = true;
                        this.loaded = true;
                        return;
                    }
                }

                this.caseRecordId = result.Case.Id;
                this.resetBox();
                this.loaded = true;
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
                this.disableCreateBtn = true;
                this.selectedCTSTFromProspect = null;
                this.boolShowNoData = true;
                this.searchKey = undefined;
            })
            .catch(error => {
                console.log('tst225572' + JSON.stringify(error));
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
                this.disableCreateBtn = false;
                this.boolShowNoData = true;
                this.searchKey = undefined;
                this.showError('error', 'Oops! Error occured', error);


            })


    }

    connectedCallback(){
        let leadId = this.recordId;
        if((leadId != null && leadId != undefined) || (this.isInternalCase == true)){
            this.showFromGlobalSearch = false;
        }
    }
    render() {
        return this.showFromGlobalSearch ? FROMGLOBALSEARCHPAGE : FROMPROSPECTPAGE;
      }
    
      handleAutoCommChange(event){
        this.noAutoCommValue = event.detail.value;
        console.log('event.detail.value=='+event.detail.value);
    }
    handleSource(event) {
        this.sourceFldValue = event.target.value;
        //code added by sunil - 03/09/2024
        this.checkTrackIdCondition();
    }
    checkTrackIdCondition(){
        if(this.boolAllSourceVisible){
            if(this.loggedInUserBusinessUnit === 'ABHFL'){
                if(this.sourceFldValue === 'Call Center'){
                    this.isPhoneInbound = true;
                }
                else{
                    this.isPhoneInbound = false;
                }
            }
            else if(this.loggedInUserBusinessUnit === 'ABFL'){
                if(this.sourceFldValue === 'Phone-Inbound' || this.sourceFldValue === 'Inbound Nodal Desk' || this.sourceFldValue === 'Phone-Outbound'){
                    this.isPhoneInbound = true;
                }
                else{
                    this.isPhoneInbound = false;
                }
            }
        }
    }

    //method code added by sunil- 03/09/2024
    handleTrackId(event){
        this.trackId = event.target.value;
    }
      
}
