import { LightningElement, track, api, wire } from 'lwc';
import {loadStyle} from 'lightning/platformResourceLoader';
//import overrideCSSFile from '@salesforce/resourceUrl/asf_QuickActionHeightWidthIncreaser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import { createRecord, notifyRecordUpdateAvailable, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import RECATEGORISATION_REASON_FIELD from '@salesforce/schema/Case.Recategorisation_Reason__c';
import BOT_FEEDBACK_FIELD from '@salesforce/schema/Case.Bot_Feedback__c';
import CASE_BU_FIELD from '@salesforce/schema/Case.Business_Unit__c';
import SENTTOBOT_FIELD from '@salesforce/schema/Case.Sent_to_EBOT__c';
import OLDCCCIDFIELDS from '@salesforce/schema/Case.oldCCCIdFields__c';
import CASE_ACCOUNT_ID from '@salesforce/schema/Case.AccountId';
import CASE_ASSET_ID from '@salesforce/schema/Case.AssetId';
import CASE_ASSET_LAN_NUMBER from '@salesforce/schema/Case.Asset.LAN__c';
import CASE_ASSET_POLICY_NUMBER from '@salesforce/schema/Case.Asset.Policy_No__c';
import CASE_LEAD_ID from '@salesforce/schema/Case.Lead__c';
import BSLI_ISSUE_TYPE from '@salesforce/schema/Case.Issue_Type__c';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU'; 
import BU_TO_HIDE_EBOT_FEEDBACK from '@salesforce/label/c.BUsToHideEbotFeedbackInRecat';


import Email_Bot_BU_label from '@salesforce/label/c.ASF_Email_Bot_Feedback_BU';
import Recat_Approval_Required_BU_label from '@salesforce/label/c.ASF_Recat_Approval_Required_BU';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { reduceErrors } from 'c/asf_ldsUtils';
import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';
import { RefreshEvent } from 'lightning/refresh';

import getTypeSubTypeData from '@salesforce/apex/ASF_RecategoriseCaseController.getTypeSubTypeDataByCustomerType';
import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import getCaseRecordDetails from '@salesforce/apex/ASF_RecategoriseCaseController.getCaseRecordDetails';
import updateCaseRecord from '@salesforce/apex/ASF_RecategoriseCaseController.updateCaseWithNewCCCId';
import updateRequestedCCC from '@salesforce/apex/ASF_RecategoriseCaseController.updateRequestedCCC';
import fetchCCCDetails from '@salesforce/apex/ASF_RecategoriseCaseController.fetchCCCDetails';
import callEbotFeedbackApi from '@salesforce/apex/ABCL_EBotFeedback.callEbotFeedbackApi';



import CUSTOMERPROSPECTSEARCH from "./reparentingCase.html";
//import RECATEGORISATIONUI from './asf_RecategoriseCase.html';

import { getCurrentCustomer,setSelectedAccount,setSelectedAsset,updateAccountAndAssetOnCase } from './reparentinghelper.js';
import { getConstants } from './constants.js';
import { lanLabels } from 'c/asf_ConstantUtility';
//import getMatchingAccount from '@salesforce/apex/ASF_CaseUIController.getMatchingAccount';
//import getMatchingContacts from '@salesforce/apex/ASF_CaseUIController.getMatchingContacts';




export default class asf_RecategoriseCase extends NavigationMixin(LightningElement) {
    searchKey;
    accounts;
    isNotSelected = true;
    @api recordId;
    @wire(CurrentPageReference) pageRef;
    @api fieldToBeStampedOnCase;
    loaded = false;
    caseRelObjName;
    caseExtensionRecordId;
    //TBD . load this 
    caseRecordId;

    //tst strt
    doneTypingInterval = 300;
    typingTimer;
    createCaseWithAll = false;
    
    isAllNature = false;
    isAllProduct = false;
    isAllSource = false;

    isRequestAndQuery = false;
    isRequestAndQuerySource = false;
    isOnlySource = false;
    natureVal;
    productVal;
    sourceVal;
    rejectionReasonVal;
    botFeedbackVal;

    assetLOB;
    assetId;
    isasset;
    accountId;
    leadId; // Virendra - Added for Prospect Related ReCategorisation.
    
    //asset;

    singleChoice;
    
    sourceValues = [];
    natureValues = [];
    lstChannelValues = [];
    complaintValues = [];

    primaryLOBValue;

    strSource = '';
    strChannelValue = '';
    strDefaultChannel = '';

    //boolChannelVisible = false;

    boolShowNoData = false;
    //boolAllChannelVisible = false;
    //boolAllSourceVisible = false;
    strNoDataMessage = '';
    complaintLevelVisible = false;
    
    complaintSelected;
    subsourceSelected;
    cccProductType;
    selectedSRCategory;
    caseComplaintLevel;
    
    cccproduct_type = '';
    businessUnit = '';

    accountRecordType = '';
    leadRecordType = ''; // Virendra - Added as part of Prospect Requirement.
    caseFields = [NATURE_FIELD, SOURCE_FIELD, CHANNEL_FIELD];
    oldCaseDetails ;
    currentCCCId;
    oldCCCIdFields = '';
    currentNature = '';
    currentUserFullName = '';
    selectedType;
    selectedSubType;
    overallSLA = '';
    recategorizeEnabled;
    approvalPending;
    sendBotFeedback = true;
    showBotFeedback = false;

    /* Virendra - FOR REPARENTING USE CASE */
    accData;
    selectedCustomer;
    selectedCustomerName ='';
    selectedCustomerClientCode = '';
    selectedLoanAccNumber = '';
    selectedLANLOB = '';
    selectedAssetId = '';
    asstData;
    initialRecords;
    selectedAsset;
    originalCCCValue;
    preselectedCustomerName = '';
    preselectedLoanAccountNumber = '';
    @track allCustomerRelatedAssets;
    @track showLANForCustomer = false;
    accCols = getConstants.ACCOUNT_COLUMNS;
    asstCols;
    cols;
    caseAccountClientCode = '';
    showWhenCCCEligible = false;
    showWhenCCCNotEligible = false;
    bProceedToRecategorisation =false;
    showCustomerSelection = true;
    isAssetChange = false;
    recategorisationOptions = getConstants.RECATEGORISATION_OPTIONS;
    recategorisationBtn1Lable = getConstants.RECATEGORISATION_UPD_ACC;
    recategorisationBtn2Lable = getConstants.RECATEGORISATION_PROCEED;
    eligibleWithNewCustomerCSTSMsg;
    noneligibleWithNewCustomerCSTMsg;
    //Added for approval
    showApproval = false;
    isTrue = true;
    newTypeSubType = '';
    selectedCCC;
    recatReason = '';
    botFeedbackReason = '';
    requestedCCC = '';
    //Added for ABSLIG
    showBotFeedbackDropdown = true;
    //Added for bsli
    showIssueType = false;
    issueTypeVal;
    issueTypeOptions = [];
    originalIssueType = '';
    selectLan;
    assetSearchPlaceholder;
    currentIssueType = '';
    
    /* METHOD TO GET THE CASE RELATED INFORMATION ON LOAD.
    */
    @wire(getRecord, { recordId: '$recordId', fields: [SENTTOBOT_FIELD, CASE_BU_FIELD,CCC_FIELD,CASE_ASSET_LAN_NUMBER,BSLI_ISSUE_TYPE,CASE_ASSET_POLICY_NUMBER] })
    wiredRecord({ error, data }) {
        if (data) {
            const case_Bu = getFieldValue(data, CASE_BU_FIELD);
            //Show Bot Feedback checkbox if Case source is Email and for specific BU
            const email_Bot_BU = Email_Bot_BU_label.includes(';') ? Email_Bot_BU_label.split(';') : [Email_Bot_BU_label];
            if(getFieldValue(data, SENTTOBOT_FIELD) === true && email_Bot_BU.includes(getFieldValue(data, CASE_BU_FIELD))){
                this.showBotFeedback = true;
            }
            this.businessUnit = getFieldValue(data, CASE_BU_FIELD);
            this.originalCCCValue = getFieldValue(data,CCC_FIELD);
            this.selectedLoanAccNumber = getFieldValue(data,CASE_ASSET_LAN_NUMBER);
            //if(getFieldValue(data, CASE_BU_FIELD) === ABSLIG_BU || getFieldValue(data, CASE_BU_FIELD) == ABSLAMC_BU){
            if(BU_TO_HIDE_EBOT_FEEDBACK.split(';').includes(case_Bu)){
                this.showBotFeedbackDropdown = false;
            }
            this.originalIssueType = getFieldValue(data,BSLI_ISSUE_TYPE);
            if(this.businessUnit === ABSLI_BU || this.businessUnit === ABSLIG_BU){
                this.selectedLoanAccNumber = getFieldValue(data,CASE_ASSET_POLICY_NUMBER);
            }
            this.selectLan = lanLabels[this.businessUnit].SELECT_PRODUCT != null? lanLabels[this.businessUnit].SELECT_PRODUCT : lanLabels["DEFAULT"].SELECT_PRODUCT;
            this.asstCols = lanLabels[this.businessUnit].ASSET_COLUMNS != null? lanLabels[this.businessUnit].ASSET_COLUMNS : lanLabels["DEFAULT"].ASSET_COLUMNS;
            this.assetSearchPlaceholder = lanLabels[this.businessUnit].PRODUCT_SEARCH_PLACEHOLDER != null? lanLabels[this.businessUnit].PRODUCT_SEARCH_PLACEHOLDER : lanLabels["DEFAULT"].PRODUCT_SEARCH_PLACEHOLDER;
            this.eligibleWithNewCustomerCSTSMsg = lanLabels[this.businessUnit].CASE_ELIGIBLE_WITH_NEW_CTST_MSG != null? lanLabels[this.businessUnit].CASE_ELIGIBLE_WITH_NEW_CTST_MSG : lanLabels["DEFAULT"].CASE_ELIGIBLE_WITH_NEW_CTST_MSG;
            this.noneligibleWithNewCustomerCSTMsg = lanLabels[this.businessUnit].CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG != null? lanLabels[this.businessUnit].CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : lanLabels["DEFAULT"].CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG;
            this.cols = lanLabels[this.businessUnit].CTST_COLS != null? lanLabels[this.businessUnit].CTST_COLS : lanLabels["DEFAULT"].CTST_COLS;
            
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    /* LOAD THE STYLE SHEET. NO NEED FOR THIS ANY MORE. ASK RAJENDER KUMAR TO REMOVE THIS.
    */
    /*renderedCallback(){
        Promise.all([
            //loadStyle(this, overrideCSSFile)
        ]);
    } */

    /* UTILITY METHOD TO SHOW ERROR MESSAGE.
    */
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }

    connectedCallback() {
        //api record id was not working
        //console.log('this.recordId',this.recordId);
        this.recordId = this.pageRef.state.recordId;
        this.getCurrentCaseRecordDetails();
    }

    resetToBlank(event){
        let formEl = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
        let fields = formEl.querySelectorAll('lightning-input-field');
            for (let field of fields) {
                if (field.getAttribute('data-id') != 'bizUnit') {
                field.value = '';
                }
            }
    }
    //This Funcation will get the value from Text Input.
    handelSearchKey(event) {
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;

        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.searchTypeSubtypeHandler();
            }
        }, this.doneTypingInterval);
    }

    //This function gets the value from the Send Bot Feedback Checkbox
    handleBotFeedback(event){
        this.sendBotFeedback = event.target.checked;
    }
    //This function gets the value from the Send Bot Feedback Dropdown
    handleBotDropdown(event){
        this.botFeedbackVal = event.target.value;
    }
    //This function will fetch the CCC Name on basis of searchkey
    searchTypeSubtypeHandler() {
        this.accounts = null;
        this.createCaseWithAll = false;
        //this.boolAllChannelVisible = false;
        //this.boolAllSourceVisible = false;
        this.boolChannelVisible = false;
        this.isNotSelected = true;
        this.showIssueType = false;
        let isthisNotAssetRelated = this.getIsAssetValue();
 
        getTypeSubTypeData({ keyword: this.searchKey, asssetProductType: this.cccproduct_type, isasset: isthisNotAssetRelated, accRecordType : this.accountRecordType,currentCCCId : this.currentCCCId, assetLOB : this.assetLOB })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    //this.strSource = result.strSource;
                    //this.strSource = JSON.parse(result.caseDetails).Source__c //JSON.parse(this.oldCaseDetails.caseDetails).Source__c;
                    this.strSource = JSON.parse(this.oldCaseDetails.caseDetails).Source__c;
                    this.boolShowNoData = false;
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        this.lstChannelValues = result.lstChannel;
                        //this.strDefaultChannel = this.lstChannelValues[0].label;
                       // this.strDefaultChannel =  JSON.parse(result.caseDetails).Channel__c//JSON.parse(this.oldCaseDetails.caseDetails).Channel__c;
                       if(JSON.parse(this.oldCaseDetails.caseDetails).Channel__c == undefined){
                            this.strDefaultChannel =  this.lstChannelValues[0].label;
                       }
                       else { 
                            this.strDefaultChannel =  JSON.parse(this.oldCaseDetails.caseDetails).Channel__c;
                       }
                        this.strChannelValue = this.strDefaultChannel; 
                        this.boolChannelVisible = true;
                    }
                    if(this.accounts.length == 0){
                        this.boolShowNoData = true;
                        this.strNoDataMessage = result.strErrorMessage;
                        this.loaded = true;
                        
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
                this.isNotSelected = true;
                this.loaded = true;
            });

    }

    getSelectedName(event) {
        this.createCaseWithAll = false;
        this.isNotSelected = false;
        this.isAllNature = false;
        this.isAllProduct = false;
        this.isAllSource = false;
        this.isRequestAndQuery = false;
        this.isRequestAndQuerySource = false;
        this.isOnlySource = false;
        this.productVal = '';
        this.natureVal = '';
        this.sourceVal = '';
        this.sourceValues = [];
        this.showIssueType = false;
        this.issueTypeVal = '';
     
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        /* if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
        }
        if ((selected) && (this.businessUnit === "ABFL")) {
            this.boolAllChannelVisible = false;
        } */
        if (selected) {
            /*if (selected && (selected[NATURE_FIELD.fieldApiName] == "All" || selected[SOURCE_FIELD.fieldApiName] == "All") && (!selected[NATURE_FIELD.fieldApiName].includes(',')) && (this.businessUnit != "ABFL")) {
                this.boolAllChannelVisible = true;
                this.boolAllSourceVisible = true;
            } */
            this.createCaseWithAll = true;
            this.isNotSelected = true;
            if (selected[NATURE_FIELD.fieldApiName] == "All") {
                this.isAllNature = true;
            }
            if (selected[SOURCE_FIELD.fieldApiName] == "All") {
                this.isAllSource = true;
            }
        }
        if (selected && (selected[NATURE_FIELD.fieldApiName].includes(','))) {
            const picklistValues = selected[SOURCE_FIELD.fieldApiName];
            const naturePicklistValues = selected[NATURE_FIELD.fieldApiName];
            if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                this.sourceValues = picklistValues.split(',').map((elem) => {
                    const sourceValues = {
                        label: elem,
                        value: elem
                    };
                    return sourceValues;
                });
            }

            else if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName] == "All")) {
                const optionVal = {
                    label: 'Branch',
                    value: 'Branch'
                };
                const optionVal1 = {
                    label: 'CEC',
                    value: 'CEC'
                };
                const emailVal = {
                    label: 'Email',
                    value: 'Email'
                };
                if (this.sourceValues.length == 0) {
                    this.sourceValues.push(optionVal, optionVal1, emailVal);
                }

                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
            }
            else if ((picklistValues) && (!selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                const optionVal = {
                    label: selected[SOURCE_FIELD.fieldApiName],
                    value: selected[SOURCE_FIELD.fieldApiName]
                };
                this.sourceValues.push(optionVal);
                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
                this.sourceVal = selected[SOURCE_FIELD.fieldApiName];
            }
            if (naturePicklistValues) {
                this.natureValues = naturePicklistValues.split(',').map((elem) => {
                    const natureValues = {
                        label: elem,
                        value: elem
                    };
                    return natureValues;
                });
            }

            this.createCaseWithAll = true;
            this.isNotSelected = true;
            this.isRequestAndQuery = true;
            if ((selected[SOURCE_FIELD.fieldApiName] != null) && (selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                this.isRequestAndQuerySource = true;
            }
            if ((selected[SOURCE_FIELD.fieldApiName] == 'All')) {
                this.isRequestAndQuerySource = true;
            }
            if (this.isAllSource == true) {
                this.isRequestAndQuerySource = false;
            }
        } else {
            if (selected) {
                this.isOnlySource = true;
                this.isAllSource = false;
                if (selected[NATURE_FIELD.fieldApiName] && selected[NATURE_FIELD.fieldApiName] != 'All') {
                    this.natureVal = selected[NATURE_FIELD.fieldApiName];
                }
                if (selected[SOURCE_FIELD.fieldApiName]) {

                    if (!selected[SOURCE_FIELD.fieldApiName].includes(',') && selected[SOURCE_FIELD.fieldApiName] != 'All') {
                        this.sourceVal = selected[SOURCE_FIELD.fieldApiName];
                    }
                    else if (selected[SOURCE_FIELD.fieldApiName].includes(',')) {
                        this.sourceValues = selected[SOURCE_FIELD.fieldApiName].split(',').map((elem) => {
                            const sourceValues = {
                                label: elem,
                                value: elem
                            };
                            return sourceValues;
                        });
                        this.isOnlySource = true;
                        this.createCaseWithAll = true;
                        this.isNotSelected = true; // Virendra : 8th March 2023 : To make Create Case button disable if field value is not selected.
                    }
                }
            }
        }
        if((selected) && selected.Allowed_Issue_Types__c && this.businessUnit === ABSLI_BU){
            
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
        //Making Disabled button false in case the Nature Field is not visible. 
        if (this.isAllNature == false && this.isRequestAndQuery == false) {
            this.isNotSelected = false;
        }
        else {
            this.isNotSelected = true;
        }
        if (selected && selected.hasOwnProperty("Complaint_Level__c")) {
            this.complaintSelected = selected['Complaint_Level__c']
            this.complaintLevelVisible = true;
            this.complaintValues = [];
            if (this.complaintSelected == 'L3') {
                this.caseComplaintLevel = 'L3';
            } else if (this.complaintSelected == 'L2') {
                this.caseComplaintLevel = 'L2';
            }
            this.fetchNatureMetadata(this.complaintSelected, selected[NATURE_FIELD.fieldApiName])
            this.isNotSelected = true;
        } else {
            this.complaintLevelVisible = false;
        }

    }
    validateApprovalEligibility(){
        let selectedCCC = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        let requestQueryList = ['Request','Query'];
        let validBUs = Recat_Approval_Required_BU_label.includes(',') ? Recat_Approval_Required_BU_label.split(',') : [Recat_Approval_Required_BU_label];
        console.log('validBUs--'+validBUs+'--'+selectedCCC.LOB__c+'--'+this.currentNature+'--current nature--'+selectedCCC.Nature__c);
        if(validBUs.includes(selectedCCC.LOB__c) && 
        ((requestQueryList.includes(this.currentNature) && !requestQueryList.includes(selectedCCC.Nature__c)) ||
        (!requestQueryList.includes(this.currentNature) && requestQueryList.includes(selectedCCC.Nature__c)))
        ){
            return true;
        }
        return false;
    }
    async handleUpdate(){
        if(this.validateApprovalEligibility()){
            if(!this.isInputValid()) {
                return;
            } 
            const rejectionReason = this.template.querySelector('[data-id="rejectReason"]');
            if(rejectionReason.value == undefined || rejectionReason.value == null || rejectionReason.value.trim() == ''){
                rejectionReason.reportValidity();
                return;
            }
            const botfeedback = this.template.querySelector('[data-id="botfeedback"]');
            if(this.showBotFeedbackDropdown === true && (botfeedback.value == undefined || botfeedback.value == null || botfeedback.value.trim() == '')){
                botfeedback.reportValidity();
                return;
            }
            this.selectedCCC = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
            
            if(!await this.validateNewCCC(this.selectedCCC.CCC_External_Id__c)){
                return;
            }
            this.newTypeSubType = this.selectedCCC.Type__c + ' - ' + this.selectedCCC.Sub_Type__c;
            this.recatReason = this.template.querySelector('[data-id="rejectReason"]').value;
            this.botFeedbackReason = this.botFeedbackVal;
            this.showApproval = true;
        }else{
            console.log('regular flow');
            this.updateCaseHandler();
        }
    }

    async updateCaseHandlerNew(event){
        console.log('inside new handler');
        //this.loaded = false;
        const fields = {};
        for(let fldToStamp in this.fieldToBeStampedOnCase) {
            fields[fldToStamp] = this.fieldToBeStampedOnCase[fldToStamp];
        }
        await this.getCaseRelatedObjName(this.selectedCCC.CCC_External_Id__c);
 
        if (this.caseRelObjName) {
            /*
            only if extension object is changing , then do this. 
            else does not matter.but on save, losing fields , winning fields should do
            */
            if(this.oldCaseDetails.currentExtensionName != this.caseRelObjName ){
                await this.createExtensionObj();
                fields[this.caseRelObjName] = this.caseExtensionRecordId;
            }
        }
        fields[CCC_FIELD.fieldApiName] = this.selectedCCC.CCC_External_Id__c;
        console.log('new Type__c--'+this.selectedCCC.Type__c+this.selectedCCC.Sub_Type__c);
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[CASE_BU_FIELD.fieldApiName] = this.businessUnit;
       // fields[SOURCE_FIELD.fieldApiName] = this.strSource;
       // fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        //jay
        fields[RECATEGORISATION_REASON_FIELD.fieldApiName] = this.recatReason;
        fields[BOT_FEEDBACK_FIELD.fieldApiName] = this.botFeedbackReason;
        if(this.issueTypeVal && this.issueTypeVal != null){
            fields[BSLI_ISSUE_TYPE.fieldApiName] = this.issueTypeVal;
        }
        let currentDateVal = new Date();
        let formattingOptions = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            timeZone: 'IST',
            hour12:true,
  			hour:'2-digit',
  			minute:'2-digit'
        };
        let currentDateLocale = currentDateVal.toLocaleString('en-IN', formattingOptions);
        var typeSubTypeText = this.selectedType + ' - ' + this.selectedSubType;
        console.log('typeSubTypeText--'+typeSubTypeText);
        let updatedOldCCCIdFields = this.oldCCCIdFields + '\n' + currentDateLocale + ' - ' + this.currentUserFullName + ' - ' + this.currentNature + ' - ' + typeSubTypeText;
        fields[OLDCCCIDFIELDS.fieldApiName] = updatedOldCCCIdFields;
        // VIRENDRA - ADDED BELOW CHECKS FOR REPARENTING - 
        //console.log('this.accountId --> '+this.accountId);
        //console.log('this.selectedCustomer --> '+this.selectedCustomer);
        if(this.accountId != '' && this.accountId != undefined && this.accountId != null){
            fields[CASE_ACCOUNT_ID.fieldApiName]=this.accountId;
            fields[CASE_ASSET_ID.fieldApiName]=this.assetId;
        }
        else if(this.leadId != '' && this.leadId != undefined && this.leadId != null){
            fields[CASE_LEAD_ID.fieldApiName]=this.leadId;
        }
        if(this.showBotFeedback && this.sendBotFeedback){
            fields['Is_send_Bot_Feedback'] = this.sendBotFeedback;
        }else{
            fields['Is_send_Bot_Feedback'] = false;
        }
        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields }; 
        console.log('json--'+JSON.stringify(fields));
        updateRequestedCCC({
            recId: this.recordId,
            newCaseJson : JSON.stringify(caseRecord),
            typeVal : this.selectedCCC.Type__c,
            subType : this.selectedCCC.Sub_Type__c,
            nature : this.selectedCCC.Nature__c
        })
        .then(result => {
            if(!result.startsWith('Error')){
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
                this.template.querySelector('c-asf_case-manual-approval').submitApproval(result,this.recordId);
            }else{
                this.loaded = true; 
                this.showError('error', 'Oops! Error occured', result);
            }
        })
        .catch(error => {
            console.log(error);
            this.showError('error', 'Oops! Error occured', error);
            this.loaded = true; 
        }); 

    }
    
    async updateCaseHandler() {

        const issueType = this.template.querySelector('[data-id="issueType"]');
        if(issueType){
            issueType.setCustomValidity("");
        } 
        if(!this.isInputValid()) {
            return;
        }
        const rejectionReason = this.template.querySelector('[data-id="rejectReason"]');
        if(rejectionReason.value == undefined || rejectionReason.value == null || rejectionReason.value.trim() == ''){
            rejectionReason.reportValidity();
            return;
        }
        const botfeedback = this.template.querySelector('[data-id="botfeedback"]');
        if(this.showBotFeedbackDropdown === true && (botfeedback.value == undefined || botfeedback.value == null || botfeedback.value.trim() == '')){
            botfeedback.reportValidity();
            return;
        }
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        
        if(!await this.validateNewCCC(selected.CCC_External_Id__c)){
            return;
        }
        if(issueType && selected && selected.CCC_External_Id__c === this.originalCCCValue && this.issueTypeVal === this.originalIssueType){
            issueType.setCustomValidity("Please select a different Issue Type");
            issueType.reportValidity();
            return;
        } 
        const fields = {};
        for(let fldToStamp in this.fieldToBeStampedOnCase) {
            fields[fldToStamp] = this.fieldToBeStampedOnCase[fldToStamp];
        }
        
        await this.getCaseRelatedObjName(selected.CCC_External_Id__c);
 
        if (this.caseRelObjName) {
            /*
            only if extension object is changing , then do this. 
            else does not matter.but on save, losing fields , winning fields should do
            */
            if(this.oldCaseDetails.currentExtensionName != this.caseRelObjName ){
                await this.createExtensionObj();
                fields[this.caseRelObjName] = this.caseExtensionRecordId;
            }
        }
       
        fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[CASE_BU_FIELD.fieldApiName] = this.businessUnit;
       // fields[SOURCE_FIELD.fieldApiName] = this.strSource;
       // fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        //jay
        fields[RECATEGORISATION_REASON_FIELD.fieldApiName] = this.template.querySelector('[data-id="rejectReason"]').value;
        fields[BOT_FEEDBACK_FIELD.fieldApiName] = this.botFeedbackVal;
        if(this.issueTypeVal && this.issueTypeVal != null){
            fields[BSLI_ISSUE_TYPE.fieldApiName] = this.issueTypeVal;
        }
        let currentDateVal = new Date();
        let formattingOptions = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            timeZone: 'IST',
            hour12:true,
  			hour:'2-digit',
  			minute:'2-digit'
        };
        let currentDateLocale = currentDateVal.toLocaleString('en-IN', formattingOptions);
        let typeSubTypeText = this.selectedType + ' - ' + this.selectedSubType;
        let updatedOldCCCIdFields = this.oldCCCIdFields + '\n' + currentDateLocale + ' - ' + this.currentUserFullName + ' - ' + this.currentNature + ' - ' + typeSubTypeText;
        if(this.businessUnit === ABSLI_BU && this.currentIssueType){
            updatedOldCCCIdFields = updatedOldCCCIdFields +' - '+this.currentIssueType;
        }
        if(this.businessUnit === 'ABHI' && this.overallSLA){
            const d = new Date(this.overallSLA); 
            const formatter = new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' });
            const formattedDate = formatter.format(d);
            updatedOldCCCIdFields = updatedOldCCCIdFields +' - '+formattedDate;
        }
        fields[OLDCCCIDFIELDS.fieldApiName] = updatedOldCCCIdFields;
        // VIRENDRA - ADDED BELOW CHECKS FOR REPARENTING - 
        //console.log('this.accountId --> '+this.accountId);
        //console.log('this.selectedCustomer --> '+this.selectedCustomer);
        
        if(this.accountId != '' && this.accountId != undefined && this.accountId != null){
            fields[CASE_ACCOUNT_ID.fieldApiName]=this.accountId;
            fields[CASE_ASSET_ID.fieldApiName]=this.assetId;
        }
        else if(this.leadId != '' && this.leadId != undefined && this.leadId != null){
            fields[CASE_LEAD_ID.fieldApiName]=this.leadId;
        }
        
        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
        this.loaded = false; 
        
        updateCaseRecord({ 
            recId: this.recordId,
            oldCCCId : JSON.parse(this.oldCaseDetails.caseDetails).CCC_External_Id__c,
            newCaseJson : JSON.stringify(caseRecord),
            typeSubTypeText : typeSubTypeText 
        })
        .then(result => {
            if(this.showBotFeedback && this.sendBotFeedback){
                this.notifyEbot();
            }
            this.dispatchEvent(new CloseActionScreenEvent());
            //console.log('Firing pubsub from Recategorize!!!!!!');
            let payload = {'source':'recat', 'recordId':this.recordId};
            fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);  
            let changeArray = [{recordId: this.recordId}];
            notifyRecordUpdateAvailable(changeArray);
            this.isNotSelected = true;
            this.createCaseWithAll = false; 
            //window.location.reload();
        })
        .catch(error => {
            console.log(error);
            this.showError('error', 'Oops! Error occured', error);
            this.loaded = true; 
        }); 
    }
    notifyEbot(){
        callEbotFeedbackApi({ caseId: this.recordId})
            .then(result => {
               console.log('ebot call success');
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
            });
    }
    handleIssueTypeChange(event){
        this.issueTypeVal = event.detail.value;
    }
    async validateNewCCC(newCCCExtId){
        let configuredCurrentCCC = await fetchCCCDetails({
            cccExtId : newCCCExtId
        })
        .catch(error => {
            console.log(error);
            this.showError('error', 'Oops! Error occured', error);
            this.loaded = true;
            return false; 
        });

        if(configuredCurrentCCC){
            let errorMsg;
            if(this.accountId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == true && configuredCurrentCCC.Is_Prospect_Related__c == false){
                errorMsg = 'Account is not there. But type sub type is selected which require Customer';
            } 
            else if(this.assetId == null && configuredCurrentCCC.is_FA_Mandatory__c == true && configuredCurrentCCC.Is_Prospect_Related__c == false){
                errorMsg = 'Asset is not there. But type sub type is selected which required Asset';
            }
            /* CHECK IF SELECTED CCC IS PROSPECT RELATED.
            /* Scenario 1 - CRN MANDATORY AS WELL AS IS PROSPECT RELATED IS TRUE. MEANING THE CTST IS ELIGIBLE FOR 
            /*              SELECTION AGAINST CUSTOMER AND LEAD BOTH. HENCE FIRST CHECK IF CUSTOMER PRESENT, IF NOT
            /*              CHECK IF LEAD PRESENT, IF BOTH OF THEM ARE NOT PRESENT SHOW ERROR MESSAGE.
            /* Scenario 2 - ASSET MANDATORY AS WELL AS IS PROSPECT RELATED IS TRUE. MEANING THE CTST IS ELIGIBLE FOR
            /*              SELECTION AGAINST ASSET AND LEAD BOTH. HENCE FIRST CHECK IF ASSET PRESENT, IF NOT CHECK
            /*              IF LEAD PRESENT, IF BOTH OF THEM ARE NOT PRESENT SHOW ERROR MESSAGE.
            /* Scenario 3 - ONLY IS PROSPECT RELATED IS TRUE THEN CHECK IF THE LEAD IS PRESENT, IF NOT THEN SHOW ERROR MESSAGE.
            /* Author - Virendra
            */
            if(configuredCurrentCCC.Is_Prospect_Related__c == true && configuredCurrentCCC.Only_CRN_Mandatory__c == true && this.accountId == null && this.leadId == null){
            errorMsg = 'Neither Account nor Prospect is there. But type sub type is selected which require Customer or Prospect.'
            }
            else if(configuredCurrentCCC.Is_Prospect_Related__c == true && configuredCurrentCCC.is_FA_Mandatory__c == true && this.assetId == null && this.leadId == null
                && !(configuredCurrentCCC.Only_CRN_Mandatory__c == true && this.accountId != null)){
            errorMsg = 'Neither Asset nor Prospect is there. but type sub type is selected which require Asset or Prospect.'
            }
            else if(configuredCurrentCCC.Is_Prospect_Related__c == true && this.leadId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == false && configuredCurrentCCC.is_FA_Mandatory__c == false){
            errorMsg = 'Prospect is not there. But type sub type is selected which require Prospect.'
            }
            /* PROSPECT RECATEGORISATION ENDS HERE */
              
            else if(configuredCurrentCCC.Priority__c != null && this.currentPriority != configuredCurrentCCC.Priority__c ){
                errorMsg = 'Case Category Configured priority and case priority is mismatch';
            } 
            else if(configuredCurrentCCC.Custom_Segment__c != null 
            && this.accountRecordType != configuredCurrentCCC.Custom_Segment__c ){
                errorMsg = 'Case Category Configured Customer segment and case customer segment is mismatch';
            }
            if(errorMsg){
                console.log('displaying error');
                this.showError('error', 'Oops! Invalid Selection', errorMsg);
                return false;
            } 
        }
        return true;
    }
    async createExtensionObj() {
        const fields = {};
        const caseRecord = { apiName: this.caseRelObjName, fields: fields };

        await createRecord(caseRecord)
            .then(result => {
                this.caseExtensionRecordId = result.id;
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
                this.loaded = true;
            })
    }

    handleNatureVal(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isAllSource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            } else if (this.isAllProduct) {
                if (this.productVal && this.productVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }
    closeAction(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleProductVal(event) {
        this.productVal = event.target.value;
        var btnActive = false;
        if (this.productVal && this.productVal != '') {
            btnActive = true;
            if (this.isAllNature) {
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            } else if (this.isAllSource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    // Method to handle the Channel Picklist
    handleChangeChannel(event) {
        this.strChannelValue = event.target.value;
        var btnActive = false;
        if (this.strChannelValue && this.strChannelValue != '') {
            btnActive = true;

        } else {
            btnActive = false;
        }
    }

    handleChangeNature(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isRequestAndQuerySource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
            if (this.complaintSelected != '') {
                this.fetchNatureMetadata(this.complaintSelected, this.natureVal)
                if (this.subsourceSelected)
                    btnActive = true;
                else
                    btnActive = false;
            }


        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    handleSource(event) {
        this.sourceVal = event.target.value;
        var btnActive = false;
        if (this.sourceVal && this.sourceVal != '') {
            btnActive = true;
            if (this.isRequestAndQuery) {
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    async getCaseRelatedObjName(cccExtId) {
        //tst Get the Case Extension Object Name
        await getCaseRelatedObjName({ cccId: cccExtId })
            .then(result => {
                this.caseRelObjName = result;
            })
            .catch(error => {
                console.log(error);
            });
    }

    async getCurrentCaseRecordDetails() {
       
        if(this.recordId != null && this.recordId != undefined){
            let result = await getCaseRecordDetails({ 
                recId: this.recordId 
            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured while loading the case', error);
            });
            
            this.oldCaseDetails = result;
            this.recategorizeEnabled = result.recategorizeEnabled;
            this.approvalPending = result.approvalPending;
            var caseparsedObject = JSON.parse(this.oldCaseDetails.caseDetails);
            this.accountId = caseparsedObject.AccountId;
            this.assetId = caseparsedObject.AssetId;
            if(this.assetId != '' && this.assetId != undefined && this.assetId != undefined){
                this.preselectedLoanAccountNumber = caseparsedObject.Asset.LAN__c;
            }
            if((this.businessUnit === ABSLI_BU || this.businessUnit === ABSLIG_BU) && this.assetId){
                this.preselectedLoanAccountNumber = caseparsedObject.Asset.Policy_No__c;
            }
            this.currentPriority = caseparsedObject.Priority;
            this.currentCCCId = caseparsedObject.CCC_External_Id__c;
            this.oldCCCIdFields = (caseparsedObject.oldCCCIdFields__c == undefined || caseparsedObject.oldCCCIdFields__c == null)?'':caseparsedObject.oldCCCIdFields__c;
            this.currentNature = (caseparsedObject.Nature__c == undefined || caseparsedObject.Nature__c == null)?'':caseparsedObject.Nature__c;
            this.selectedType = caseparsedObject.Type_Text__c;
            this.selectedSubType = caseparsedObject.Sub_Type_Text__c;
            this.currentUserFullName = this.oldCaseDetails.currentUserName;
            this.currentIssueType = caseparsedObject.Issue_Type__c;
            this.overallSLA = caseparsedObject.Overall_Case_Closure_SLA__c;
            if(caseparsedObject.Account != null && caseparsedObject.Account != undefined){
                if(caseparsedObject.Account.Client_Code__c != undefined && caseparsedObject.Account.Client_Code__c != null){
                    this.caseAccountClientCode = caseparsedObject.Account.Client_Code__c;
                }
            }
            
           
            /* CHECK IF THE CASE IS RETURNING ACCOUNT OR NOT. IN CASE OF PROSPECT RELATED CASES
            /* ACCOUNT IS COMING AS NULL.
            /* Author - Virendra
            */
            this.leadId = caseparsedObject.Lead__c;

            if(caseparsedObject.Account != null && caseparsedObject.Account != undefined){
                this.accountRecordType = caseparsedObject.Account.RecordType.Name;
                this.primaryLOBValue = caseparsedObject.Account.Business_Unit__c;
            }
            else if(caseparsedObject.Lead__c != null && caseparsedObject.Lead__c != undefined){
                this.leadRecordType = caseparsedObject.Lead__r.RecordType.Name;
                this.primaryLOBValue = caseparsedObject.Lead__r.Business_Unit__c;
            }
            
            
            //this is without asset parameter. default is false
            //this means , if case is not having asset , then
            //this will be true. 
            this.isasset = 'true';
            if (caseparsedObject.AssetId != undefined && caseparsedObject.AssetId != null){
                //this.assetId = caseparsedObject.AssetId;
                this.assetLOB = caseparsedObject.Asset.LOB__c; 
                //once case is associated to asset, reset this
                this.isasset = 'false';
            }
            else if(caseparsedObject.Lead__c != null && caseparsedObject.Lead__c != undefined){
                /* IN CASE OF SERVICE REQUEST CREATED WITH LEAD, FIRST CHECK IF IT IS FIRST ASSOCIATED WITH ASSET, IF YES
                *  EXECUTE FIRST IF BLOCK OTHERWISE, CHECK SET isasset FLAG TO PROSPECT
                *  THIS MEANS RETURN ONLY CTST's THOSE ARE SPECIFIC TO PROSPECT ONLY. THAT IS, ON ASF_CASE_CATEGORY_CONFIG WHERE Is_Prospect_Related__c IS TRUE.
                *  Author - VIRENDRA
                */
                this.isasset = 'Prospect';
            }
            this.loaded = true;
        }
    }

    resetBox() {
        this.dispatchEvent(new CustomEvent('resetbox', {
            detail: {
                message: 'true'
            }
        }));
    }
    
    handleSubSource(event) {
        this.subsourceSelected = event.target.value;
        if (this.subsourceSelected && this.complaintSelected && this.natureVal)
            this.isNotSelected = false;
        else
            this.isNotSelected = true;
    }
    //To get SR Category Reason:
    fetchNatureMetadata(level, nature) {
        fetchNatureMetadata({ level: level, nature: nature }).then(result => {
            this.selectedSRCategory = result;
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    async handleConfirmClick(msg) {
        const result = await LightningConfirm.open({
            message: msg,
            variant: 'headerless',
            label: 'Duplicate Found !',
            // setting theme would have no effect
        });
    }

    /* Virendra - REPARENTING USE CASE START HERE - */
    render() {
        return CUSTOMERPROSPECTSEARCH;
      }

    valChange(event) {
        getCurrentCustomer(event,this);
        
    }
    handleAccAction(event){
        this.showWhenCCCEligible = false;
        this.showWhenCCCNotEligible = false;
        setSelectedAccount(event,this);
    }
    handleAsstAction(event){
        setSelectedAsset(event,this);
        
    }
    async handleAccountAssetUpd(event){
        await updateAccountAndAssetOnCase(event,this);
        let changeArray = [{recordId: this.recordId}];
        notifyRecordUpdateAvailable(changeArray);

    }
    handleProceedToRecategorised(event){
        this.bProceedToRecategorisation = true;
        this.showCustomerSelection = false;
    }
    get showRecategorisationDiv(){
        if(this.recategorizeEnabled == true && this.approvalPending == false && this.bProceedToRecategorisation == true){
            //console.log(this.refs.myDiv);
            //console.log(this.template.querySelectorAll('[data-id="mydummydiv"]'));

            return true;
        }
        return false;
    }
    get initialOptions(){
        return getConstants.INITIAL_OPTIONS;
    }

    handleChangeAsset(event){
        this.isAssetChange = true;
        this.bProceedToRecategorisation = false;
    }
    handleChangeCTST(event){
        this.bProceedToRecategorisation = true;
        this.isAssetChange = false

    }
    get showRecategorisationOptions(){
        if(this.recategorizeEnabled && !this.approvalPending){
            if(!this.isAssetChange && !this.bProceedToRecategorisation){
                return true;
            }
        }
        return false;
        
    }

    getIsAssetValue(){
        if(this.assetId && this.assetId != null && this.assetId != undefined){
            return 'false';
        }
        else if(this.leadId && this.leadId != null && this.leadId != undefined){
            return 'Prospect';
        }
        return this.isasset;
    }
    getAssetLOB(){
        if(this.assetLOB != null && this.assetLOB != undefined && this.selectedLANLOB != null & this.selectedLANLOB !=undefined){
            if(this.assetLOB != this.selectedLANLOB){
                return this.selectedLANLOB;
            }
            else{
                return this.assetLOB;
            }
        }
        return this.assetLOB;
    }

    get currentCustomersAssets(){
        if(this.asstData != null && this.asstData != undefined && this.asstData.length >0){
            return this.asstData;
        }
        if(this.allCustomerRelatedAssets != null && this.allCustomerRelatedAssets != undefined && this.allCustomerRelatedAssets.length >0){
            return this.allCustomerRelatedAssets;
        }
    }
    
    get currentCustomerSelectedAsset(){

    }
    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();

        if (searchKey) {
            this.asstData = this.initialRecords;
            if (this.asstData) {

                let searchRecords = [];

                for (let record of this.asstData) {
                    let valuesArray = Object.values(record);

                    for (let val of valuesArray) {
                        let strVal = String(val);

                        if (strVal) {

                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.asstData = searchRecords;
            }
        } else {
            this.asstData = this.initialRecords;
        }
    }

}
