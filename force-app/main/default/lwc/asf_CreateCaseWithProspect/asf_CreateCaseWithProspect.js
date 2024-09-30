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
import { getObjectInfo, getObjectInfos, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
import ABHI_BU from '@salesforce/label/c.ABHI_BU';

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
import ABSLI_CASE_DETAIL_OBJECT from '@salesforce/schema/ABSLI_Case_Detail__c';

import FROMPROSPECTPAGE from "./asf_CreateCaseFromProspect.html";
import FROMGLOBALSEARCHPAGE from "./asf_CreateCaseWithProspect.html";

import loggedInUserId from '@salesforce/user/Id';

import { getRecord } from 'lightning/uiRecordApi';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import PROSPECT_BUSINESS_UNIT from '@salesforce/schema/Lead.Business_Unit__c';
import { lanLabels } from 'c/asf_ConstantUtility';
import ABSLI_Track_Sources from '@salesforce/label/c.ABSLI_Track_Sources';
import ABHI_Track_Sources from '@salesforce/label/c.ABHI_Track_Sources';
import ANI_NUMBER from '@salesforce/schema/Case.ANI_Number__c';
import BSLI_ISSUE_TYPE from '@salesforce/schema/Case.Issue_Type__c';
import BSLI_CATEGORY_TYPE from '@salesforce/schema/ABSLI_Case_Detail__c.Complaint_Category__c';
import FTR_FIELD from '@salesforce/schema/Case.FTR__c';
import * as validator from 'c/asf_CreateCaseValidations';

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
    @track noAutoCommOptions = [];
    noAutoCommValue = [];
    //BSLI
    showAniNumber = false;
    aniNumber;
    showFtr = false;
    ftrValue = false;
    showIssueType = false;
    issueTypeVal;
    issueTypeOptions = [];
    showCategoryType = false;
    @track categoryTypeOptions = [];
    @api defaultRecTypeId; // this field is used to fetch the picklist values
    @api picklistApiName = NOAUTOCOMM_FIELD;
    @api bsliRecTypeId;
    isPhoneInbound = false;
    currentObj = CASE_OBJECT.objectApiName;

    //ABHI
    abhiTrackSources = ABHI_Track_Sources.includes(',') ? ABHI_Track_Sources.split(',') : ABHI_Track_Sources;
    natureVal = '';

    cols;
    dupeLeadCols = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'MobilePhone', fieldName: 'MobilePhone', type: 'text' }
    ]

    //To get No Auto Communication and category picklist values
    @wire(getObjectInfos, { objectApiNames: [CASE_OBJECT, ABSLI_CASE_DETAIL_OBJECT] })
    objectInfos({ error, data}) {
        if(data){
            for (const [key, value] of Object.entries(data.results)) {
                if(value.result.apiName === CASE_OBJECT.objectApiName){
                    this.currentObj = CASE_OBJECT.objectApiName;
                    this.defaultRecTypeId = value.result.defaultRecordTypeId;
                    this.picklistApiName = NOAUTOCOMM_FIELD;
                }
                if(value.result.apiName === ABSLI_CASE_DETAIL_OBJECT.objectApiName){
                    this.bsliRecTypeId = value.result.defaultRecordTypeId;
                } 
            }
        }else if(error){
            console.log('error in get objectInfos--'+JSON.stringify(error));
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$defaultRecTypeId', fieldApiName: '$picklistApiName' })
    wiredPicklistValues({ error, data}) {
        if (data){
            if(this.currentObj === CASE_OBJECT.objectApiName && this.picklistApiName === NOAUTOCOMM_FIELD){
                this.noAutoCommOptions = data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));

                this.currentObj = ABSLI_CASE_DETAIL_OBJECT.objectApiName;
                this.defaultRecTypeId = this.bsliRecTypeId;
                this.picklistApiName = BSLI_CATEGORY_TYPE;
                
            }else if(this.currentObj === ABSLI_CASE_DETAIL_OBJECT.objectApiName && this.picklistApiName === BSLI_CATEGORY_TYPE){
                this.categoryTypeOptions = data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
            
            console.log('picklist options--'+JSON.stringify(this.noAutoCommOptions)+'--'+JSON.stringify(this.categoryTypeOptions));
        } else if (error){
            console.log('error in get picklist--'+JSON.stringify(error));
        }
    }


    @wire(getRecord, { recordId: loggedInUserId, fields: [UserBusinessUnit ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
            this.cols = lanLabels[this.loggedInUserBusinessUnit].CTST_COLS != null? lanLabels[this.loggedInUserBusinessUnit].CTST_COLS : lanLabels["DEFAULT"].CTST_COLS;
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
        this.isPhoneInbound = false;
        this.showAniNumber = false;
        this.showCategoryType = false;
        this.showFtr = false;
        this.showIssueType = false;
        this.ftrValue = false;
        
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
        this.ftrValue = false;
        this.showFtr = false;
        this.showIssueType = false;
        this.showCategoryType = false;
        this.issueTypeVal = '';
        this.aniNumber = '';
        this.trackId = '';
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.natureVal = selected.Nature__c;
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
            this.selectedCTSTFromProspect = selected;
            if(this.showFromGlobalSearch == false){
                this.disableCreateBtn = false;
            }
            if(this.loggedInUserBusinessUnit === ABHI_BU && this.abhiTrackSources.includes(this.sourceFldValue.trim())){
                this.isPhoneInbound = true;
            }
        }
        if ((selected) && (this.loggedInUserBusinessUnit == 'ABFL')) {
            this.boolAllChannelVisible = false;
            this.boolAllSourceVisible = true;
        }
        if ((selected) && (this.loggedInUserBusinessUnit == ABSLI_BU || this.loggedInUserBusinessUnit == ABHI_BU)) {
            this.boolNoAutoComm = false;
        }
        if((selected) && this.loggedInUserBusinessUnit === ABSLI_BU && selected.Show_FTR_Flag_on_Creation__c){
            this.showFtr = true;
        }
        if((selected) && this.loggedInUserBusinessUnit === ABSLI_BU && selected.Nature__c === 'Complaint'){
            this.showCategoryType = true;
        }
        if((selected) && this.loggedInUserBusinessUnit === ABHI_BU && this.abhiTrackSources.includes(this.sourceFldValue.trim())){
            this.isPhoneInbound = true;
        }
        if((selected) && selected.Allowed_Issue_Types__c && this.loggedInUserBusinessUnit === ABSLI_BU){
            
            if(!selected.Allowed_Issue_Types__c.includes(';')){
                this.issueTypeOptions = [{label: selected.Allowed_Issue_Types__c, value: selected.Allowed_Issue_Types__c }];
            }else{
                this.issueTypeOptions = selected.Allowed_Issue_Types__c.split(';').map(item => ({
                    label: item,
                    value: item
                }));
            }
            this.showIssueType = true;
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
        if(isValid === true){
            let inputText = this.template.querySelectorAll('.validate');
            inputText.forEach(inputField => {
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
        } 
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
            let categoryType = (this.template.querySelector("[data-id='Category_Type']") != undefined && this.template.querySelector("[data-id='Category_Type']") != null) ? this.template.querySelector("[data-id='Category_Type']").value : null;
            if(categoryType && categoryType != null) {
                fields[BSLI_CATEGORY_TYPE.fieldApiName] = categoryType;
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
        caseRecord[NOAUTOCOMM_FIELD.fieldApiName] = this.noAutoCommValue.join(';');
        caseRecord[FTR_FIELD.fieldApiName] = this.ftrValue;
        //Field Checks
        if(this.trackId != null && this.trackId != undefined && this.trackId != ""){
            caseRecord[TRACK_ID.fieldApiName] = this.trackId;
        }
        if(this.aniNumber && this.aniNumber != null){
            caseRecord[ANI_NUMBER.fieldApiName] = this.aniNumber;
        }
        if(this.issueTypeVal && this.issueTypeVal != null){
            caseRecord[BSLI_ISSUE_TYPE.fieldApiName] = this.issueTypeVal;
        }
        caseRecord[CASE_BUSINESS_UNIT_FIELD.fieldApiName] = this.loggedInUserBusinessUnit;

        const caseRecordforVal = { apiName: CASE_OBJECT.objectApiName, fields: caseRecord };

        caseRecord["sobjectType"] = "Case"; 
        this.noAutoCommValue = [];

        this.loaded = false;
        console.log('validation--'+selected.Validation_method_during_creation__c);
        if(selected.Validation_method_during_creation__c){
            console.log('invoking validator');
            let methodName = selected.Validation_method_during_creation__c;
            let validationResult = await validator[methodName](caseRecordforVal,'prospect');
            console.log('returned with dynamic method '+JSON.stringify(validationResult));
            if(validationResult.isSuccess == false){
                this.showError('error', 'Oops! Validation error occured', validationResult.errorMessageForUser);
                this.loaded = true;
                this.disableCreateBtn = true;
                this.selectedCTSTFromProspect = null;
                this.resetFields();
                return;
            }
            console.log('ending validator');
        }
        this.loaded = false;
        
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

                this.disableCreateBtn = true;
                this.selectedCTSTFromProspect = null;
                this.resetFields();
            })
            .catch(error => {
                console.log('tst225572' + JSON.stringify(error));
                this.loaded = true;
                this.disableCreateBtn = false;
                this.resetFields();
                this.showError('error', 'Oops! Error occured', error);


            })


    }
    resetFields(){
        this.boolShowNoData = true;
        this.createCaseWithAll = false;
        this.searchKey = undefined;
        this.isPhoneInbound = false;
        this.showIssueType = false;
        this.showFtr = false;
        this.showAniNumber = false;
        this.showCategoryType = false;
        this.isNotSelected = true;
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
        if (this.sourceFldValue && this.sourceFldValue != '') {
            this.isPhoneInbound = false;
            this.showAniNumber = false;
            this.trackId = '';
            this.aniNumber = '';
            let bsliSourceList = ABSLI_Track_Sources.includes(',') ? ABSLI_Track_Sources.split(',') : ABSLI_Track_Sources;
            if(this.loggedInUserBusinessUnit === ABSLI_BU && bsliSourceList.includes(this.sourceFldValue.trim())){
                this.isPhoneInbound = true;
                this.showAniNumber = true;
            }
            if(this.loggedInUserBusinessUnit === ABHI_BU && this.abhiTrackSources.includes(this.sourceFldValue.trim())){
                this.isPhoneInbound = true;
            }
        }
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
    
    handleChangeChannel(event) {
        this.strChannelValue = event.target.value;
    }
    handleFtr(event){
        this.ftrValue = event.target.checked;
    }
    handleTrackId(event){
        this.trackId = event.target.value;
    }
    handleAniNumber(event){
        this.aniNumber = event.target.value;
    }
    handleIssueTypeChange(event){
        this.issueTypeVal = event.detail.value;
    }
      
}