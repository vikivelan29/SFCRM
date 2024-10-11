import { LightningElement, track, api, wire } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getTypeSubTypeByCustomerDetails';
import getAccountRec from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountRec';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import ABSLI_CASE_DETAIL_OBJECT from '@salesforce/schema/ABSLI_Case_Detail__c';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import fetchRelatedContacts from '@salesforce/apex/ASF_GetCaseRelatedDetails.fetchRelatedContacts';

import CASE_EXTENSION_ID_FIELD from "@salesforce/schema/ABHFL_Case_Detail__c.Id";
import COMPLAINT_TYPE_FIELD from "@salesforce/schema/ABHFL_Case_Detail__c.Complaint_Type__c";
import STAGE_FIELD from '@salesforce/schema/Case.Stage__c';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import ASSETID_FIELD from '@salesforce/schema/Case.AssetId';
import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import TYPETXT_FIELD from '@salesforce/schema/Case.Type_Text__c';
import SUBTYPETXT_FIELD from '@salesforce/schema/Case.Sub_Type_Text__c';
import CASE_BUSINESSUNIT from '@salesforce/schema/Case.Business_Unit__c';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CASE_ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import LAN_NUMBER from '@salesforce/schema/Case.LAN__c';
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import SUB_SOURCE_FIELD from '@salesforce/schema/Case.Sub_Source__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import FTR_FIELD from '@salesforce/schema/Case.FTR__c';
import NOAUTOCOMM_FIELD from '@salesforce/schema/Case.No_Auto_Communication__c';
import TRACK_ID from '@salesforce/schema/Case.Track_Id__c';
import { getObjectInfos, getPicklistValues } from 'lightning/uiObjectInfoApi';
import TECHNICAL_SOURCE_FIELD from '@salesforce/schema/Case.Technical_Source__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/Asset.AccountId';
import Business_Unit from '@salesforce/schema/Asset.LOB_Code__r.BusinessUnit__c';
import Business_Unit_LOB from '@salesforce/schema/Asset.LOB__c';

import ACCOUNTTYPE_FIELD from '@salesforce/schema/Asset.Account.IsPersonAccount';
import ACCOUNT_RECORDTYPE from '@salesforce/schema/Asset.Account.RecordType.DeveloperName';

import REOPEN_DAYS from '@salesforce/schema/Case.Reopen_Days__c';
import IS_CLONEABLE from '@salesforce/schema/Case.ASF_Is_Cloneable__c'; //Functionality Clone SR - Santanu Oct27,2023

import getDuplicateCases from '@salesforce/apex/ABCL_CaseDeDupeCheckLWC.getDuplicateCases';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';
import ANI_NUMBER from '@salesforce/schema/Case.ANI_Number__c';
import BSLI_ISSUE_TYPE from '@salesforce/schema/Case.Issue_Type__c';
import BSLI_CATEGORY_TYPE from '@salesforce/schema/ABSLI_Case_Detail__c.Complaint_Category__c';
import LightningConfirm from 'lightning/confirm';
import { reduceErrors } from 'c/asf_ldsUtils';
import USER_ID from '@salesforce/user/Id';
import BUSINESS_UNIT from '@salesforce/schema/User.Business_Unit__c';
import updateCaseExtension from '@salesforce/apex/ABHFL_CTSTHelper.updateCaseExtension'
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU'; 
import MCRM_BU from '@salesforce/label/c.Wellness_BU'; // PR970457-117 added MCRM_BU
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU'; 
import ABHI_BU from '@salesforce/label/c.ABHI_BU';
import ABSLI_Track_Sources from '@salesforce/label/c.ABSLI_Track_Sources';
import ABHI_Track_Sources from '@salesforce/label/c.ABHI_Track_Sources';
import { lanLabels } from 'c/asf_ConstantUtility';
import { AUTO_COMM_BU_OPT } from 'c/asf_ConstantUtility'; // Rajendra Singh Nagar: PR1030924-209
import * as validator from 'c/asf_CreateCaseValidations';

export default class AsfCreateCaseWithType extends NavigationMixin(LightningElement) {
    searchKey;
    accounts;
    isNotSelected = true;
    @api recordId;
    @api fieldToBeStampedOnCase;
    loaded = true;
    caseRelObjName;
    caseExtensionRecordId;
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
    isPhoneInbound = false;
    natureVal;
    productVal;
    sourceVal;

    @api propertyValue;
    @api assetId;
    @api isasset;
    @api accountId;
    assetAccount;

    @api accid;

    @track sourceVsSubSourceObj;

    options;
    flag;
    value;
    contactName;
    contactSelected;
    asset;
    singleChoice;
    isNextButtonDisabled = true;
    sourceValues = [];
    natureValues = [];
    originValue;
    primaryLOBValue;
    classificationValue;
    strSource = '';
    strChannelValue = '';
    @track noAutoCommOptions = [];
    noAutoCommValue = [];
    strDefaultChannel = '';
    boolChannelVisible = false;
    boolShowNoData = false;
    boolAllChannelVisible = false;
    boolAllSourceVisible = false;
    strNoDataMessage = '';
    complaintLevelVisible = false;
    complaintValues = [];
    complaintSelected;
    subsourceSelected;
    cccProductType;
    selectedSRCategory;
    caseComplaintLevel;
    boolShowDownloadCSV = false;
    cccproduct_type = '';
    sourceFldOptions;
    sourceFldValue;
    subSourceFldOptions = [];
    subSourceFldValue = '';
    trackId = '';
    complaintType;
    uniqueId;
    businessUnit;
    cols;

    // De-dupe for Payment - 
    isTransactionRelated = false;
    transactionNumber = '';
    accountRecordType = '';
    caseFields = [NATURE_FIELD, SOURCE_FIELD, CHANNEL_FIELD];

    accountLOB = '';
    //BSLI
    showAutoCommunication = true;
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
    currentObj = CASE_OBJECT.objectApiName;

    //ABHI
    abhiTrackSources = ABHI_Track_Sources.includes(',') ? ABHI_Track_Sources.split(',') : ABHI_Track_Sources;

    
    //utility method
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    @wire(getRecord, { recordId: USER_ID, fields: [BUSINESS_UNIT] })
    user({ error, data}) {
        if (data){
           this.businessUnit = getFieldValue(data, BUSINESS_UNIT);
           this.cols = lanLabels[this.businessUnit].CTST_COLS != null? lanLabels[this.businessUnit].CTST_COLS : lanLabels["DEFAULT"].CTST_COLS;

           // Rajendra Singh Nagar: PR1030924-209 - adjust auto communications options after BU is determined. 
           this.adjustAutoCommunications();
        } else if (error){
            console.log('error in get record--'+JSON.stringify(error));
        }
    }

    // Rajendra Singh Nagar: PR1030924-209 - Added function
    adjustAutoCommunications(){
        if(AUTO_COMM_BU_OPT[this.businessUnit]?.OPTSLBLS){
            this.noAutoCommOptions = AUTO_COMM_BU_OPT[this.businessUnit].OPTSLBLS.map(item => ({
                label: item.label,
                value: item.value
            }));
        }else{
            this.noAutoCommOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        }
    }
    
    connectedCallback() {
        console.log('accId ---> ' + this.accountId);
        console.log('assestid ---> ' + JSON.stringify(this.fieldToBeStampedOnCase));
        const unique = JSON.stringify(this.fieldToBeStampedOnCase);
        if(unique != null && unique != undefined){
            this.uniqueId = JSON.parse(unique).AssetId;
        }
        console.log('assestid ---> ' + this.uniqueId);
        this.getAccountRecord();
        console.log('business ---> ' + this.businessUnit);
    }
    @wire(getRecord, { recordId: '$uniqueId', fields: [Business_Unit_LOB] })
    asset;
    
    get lobAsset() {
        return getFieldValue(this.asset.data, Business_Unit_LOB);
    }
    renderedCallback() {

        this.makeReadOnly();
        
        if(this.businessUnit == 'ABHFL') {
            this.abhfRenderedCallbacklHandler();
        }
    }

    makeReadOnly() {
        let getSourceFldCombobox = this.template.querySelector("[data-id='Source Field']");
        if(getSourceFldCombobox && this.sourceFldOptions) {
            if(this.sourceFldOptions.length == 1) {
                getSourceFldCombobox.readOnly = true;
            }
            else if(this.sourceFldOptions.length > 1){
                getSourceFldCombobox.readOnly = false;
            }
        }
    }

    abhfRenderedCallbacklHandler() {
        if(this.boolAllSourceVisible) {
            let getSubSourceCombobox = this.template.querySelector("[data-id='Sub_Source__c']");
            if(getSubSourceCombobox) {
                getSubSourceCombobox.classList.remove('slds-hide');
            }
        }
    }
    
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
    //This Funcation will get the value from Text Input.
    handelSearchKey(event) {
        console.log('lob ---> ' + this.lobAsset);
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;

        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.SearchAccountHandler();
            }
        }, this.doneTypingInterval);
    }

    //This funcation will fetch the Account Name on basis of searchkey
    SearchAccountHandler() {
        this.accounts = null;
        this.createCaseWithAll = false;
        this.boolAllChannelVisible = false;
        this.boolAllSourceVisible = false;
        this.boolChannelVisible = false;
        this.isNotSelected = true;
        this.isPhoneInbound = false;
        this.showAniNumber = false;
        this.showCategoryType = false;
        this.showFtr = false;
        this.showIssueType = false;
        this.ftrValue = false;

        const inpArg = new Map();

        inpArg['accountLOB'] = this.accountLOB;

        let strInpArg = JSON.stringify(inpArg);

        getAccountData({ keyword: this.searchKey, asssetProductType: this.cccproduct_type, isasset: this.isasset, accRecordType : this.accountRecordType, assetLob :this.lobAsset,inpArg : strInpArg })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    console.log('result data table--'+JSON.stringify(result));
                    console.log('result data table--'+JSON.stringify(result.lstCCCrecords));
                    this.strSource = result.strSource;
                    this.complaintType = result.complaintType;
                    if(this.strSource) {
                        this.sourceVsSubSourceObj = result.mapOfSourceToSubsource;
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

    getSubSourceOptions(sourceVsSubSourceObj) {
        let subSourceOptions     = sourceVsSubSourceObj[this.sourceFldValue].split(',');
        let subSourceFldOptions  = subSourceOptions.map(subSourceValue => ({label : subSourceValue, value : subSourceValue}));
        return subSourceFldOptions
    }

    populateSubSourceFld() {
        let subSourceOptions     = this.getSubSourceOptions(this.sourceVsSubSourceObj);
        this.subSourceFldOptions = subSourceOptions;
        this.subSourceFldValue   = subSourceOptions[0].value; 
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
        this.ftrValue = false;
        this.showFtr = false;
        this.showIssueType = false;
        this.showCategoryType = false;
        this.issueTypeVal = '';
        this.aniNumber = '';
        this.trackId = '';
        // Reset isTransaction Related Every time selection changes. - Virendra
        this.isTransactionRelated = false;
        this.transactionNumber = '';
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;

            if(this.businessUnit === 'ABHFL'){
                if(this.sourceFldValue == 'Call Center'){
                    this.isNotSelected = false;
                    this.isPhoneInbound = true;
                }
                this.populateSubSourceFld();
            }
            if(this.businessUnit === ABSLI_BU || this.businessUnit === ABSLIG_BU || this.businessUnit === ABHI_BU){
                this.showAutoCommunication = false;
            }
            if(this.businessUnit === ABHI_BU && this.abhiTrackSources.includes(this.sourceFldValue.trim())){
                this.isPhoneInbound = true;
            }
        }
        if((selected) && this.businessUnit === ABSLI_BU && selected.Show_FTR_Flag_on_Creation__c){
            this.showFtr = true;
        }
        if((selected) && this.businessUnit === ABSLI_BU && selected.Nature__c === 'Complaint'){
            this.showCategoryType = true;
        }
        if ((selected) && ((this.businessUnit === 'ABFL')|| (this.businessUnit === 'ABWM')  || (this.businessUnit === ABSLIG_BU) || (this.businessUnit === MCRM_BU))) { // PR970457-117 added MCRM_BU
            this.boolAllChannelVisible = false;
            this.boolAllSourceVisible = true;
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
        if (selected && selected.hasOwnProperty("Is_Bulk_Creatable__c") && selected.Is_Bulk_Creatable__c == true && !this.isNotSelected) {
            getUserPermissionSet({})
                .then(result => {
                    if (result && result == true) {
                        this.boolShowDownloadCSV = true;
                    }
                    else {
                        this.boolShowDownloadCSV = false;
                    }
                })
                .catch(error => {
                    this.boolShowDownloadCSV = false;
                })
        }
        else {
            this.boolShowDownloadCSV = false;
        }
        if (selected) {
            if (selected && (selected[NATURE_FIELD.fieldApiName] == "All" || selected[SOURCE_FIELD.fieldApiName] == "All") && (!selected[NATURE_FIELD.fieldApiName].includes(','))&& (this.businessUnit != 'ABFL')) {
                console.log('tst2245' + JSON.stringify(selected));
                this.boolAllChannelVisible = true;
                this.boolAllSourceVisible = true;
            }
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
            //console.log('queryandreq'+JSON.stringify(selected));
            const picklistValues = selected[SOURCE_FIELD.fieldApiName];
            const naturePicklistValues = selected[NATURE_FIELD.fieldApiName];
            //console.log("picklistapis",picklistValues);
            if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                //if (picklistValues) {
                //console.log("testpicklist",selected[SOURCE_FIELD.fieldApiName]);
                this.sourceValues = picklistValues.split(',').map((elem) => {
                    const sourceValues = {
                        label: elem,
                        value: elem
                    };
                    return sourceValues;
                });
            }

            else if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName] == "All")) {
                // this.sourceValues = selected[SOURCE_FIELD.fieldApiName] ;
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

                // this.sourceValues.push(optionVal1);


                //console.log("testpicklistsrc",selected[SOURCE_FIELD.fieldApiName]);
                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
                //return sourceValues;
                //this.sourceVal = selected[SOURCE_FIELD.fieldApiName];    



            }
            else if ((picklistValues) && (!selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                // this.sourceValues = selected[SOURCE_FIELD.fieldApiName] ;
                const optionVal = {
                    label: selected[SOURCE_FIELD.fieldApiName],
                    value: selected[SOURCE_FIELD.fieldApiName]
                };
                this.sourceValues.push(optionVal);
                //console.log("testpicklistsrc",selected[SOURCE_FIELD.fieldApiName]);
                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
                //return sourceValues;
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
                //console.log('source',selected[SOURCE_FIELD.fieldApiName]);
                this.isRequestAndQuerySource = true;
            }
            if ((selected[SOURCE_FIELD.fieldApiName] == 'All')) {
                console.log('source', selected[SOURCE_FIELD.fieldApiName]);
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

        if (selected && selected.hasOwnProperty("Is_Transaction_Related__c")) {
            this.isTransactionRelated = selected.Is_Transaction_Related__c;
            console.log('isTransactionRelated ---> ' + this.isTransactionRelated);
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

    async createCaseHandler() {
        this.isNotSelected = true;
        if(!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            this.isNotSelected = false;
            return;
        }
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];

        var dupeResult = await this.checkDuplicateCase(selected);

        if(!dupeResult){
            this.isNotSelected = false;
            return;
        }

        //this.loaded = false;
        const fields = {};

        for(let fldToStamp in this.fieldToBeStampedOnCase) {
            fields[fldToStamp] = this.fieldToBeStampedOnCase[fldToStamp];
        }
        
        if (this.isasset == true) {
            await this.getAccountRecord();
        }
        //tst strt
        await this.getCaseRelatedObjName(selected.CCC_External_Id__c);
        //tst end

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
        fields[SUB_SOURCE_FIELD.fieldApiName] = this.subSourceFldValue;
        fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        fields[NOAUTOCOMM_FIELD.fieldApiName] = this.noAutoCommValue.join(';');
        fields[FTR_FIELD.fieldApiName] = this.ftrValue;
        console.log('ftr val--'+this.ftrValue);
        //Field Checks
        if(this.trackId != null && this.trackId != undefined && this.trackId != ""){
            fields[TRACK_ID.fieldApiName] = this.trackId;
        }
        if(this.aniNumber && this.aniNumber != null){
            fields[ANI_NUMBER.fieldApiName] = this.aniNumber;
        }
        if(this.issueTypeVal && this.issueTypeVal != null){
            fields[BSLI_ISSUE_TYPE.fieldApiName] = this.issueTypeVal;
        }
        if (this.isasset == false) {
            console.log('--asset--',this.asset);
            fields[CASE_ACCOUNT_FIELD.fieldApiName] = this.accountId;//this.asset.fields.AccountId.value;
            //fields[LAN_NUMBER.fieldApiName] = this.asset.fields.ASF_Card_or_Account_Number__c.value;

            //fields[PRODUCT_FIELD.fieldApiName] = this.asset.fields.Product_Name__c.value;
            //fields[CASE_BRANCH_FIELD.fieldApiName] = this.asset.fields.Account.value.fields.Home_Branch__c.value;
        } else {
            fields[CASE_ACCOUNT_FIELD.fieldApiName] = this.accountData.Id;
            fields[LAN_NUMBER.fieldApiName] = 'NA';
            //fields[CASE_BRANCH_FIELD.fieldApiName] = this.accountData.Home_Branch__c;
        }
        if(this.primaryLOBValue != null && this.primaryLOBValue != undefined){
            fields[CASE_BUSINESSUNIT.fieldApiName] = this.primaryLOBValue; 
        }
        
        if (!this.flag) {
            fields[CASE_CONTACT_FIELD.fieldApiName] = this.value;
        }
        
        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
        this.loaded = false;
        if(selected.Validation_method_during_creation__c){
            console.log('invoking validator');
            let methodName = selected.Validation_method_during_creation__c;
            let validationResult = await validator[methodName](caseRecord,'account');
            console.log('returned with dynamic method '+JSON.stringify(validationResult));
            if(validationResult.isSuccess == false){
                this.showError('error', 'Oops! Validation error occured', validationResult.errorMessageForUser);
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
                return;
            }
            console.log('ending validator');
        }

        this.loaded = false;
        console.log('tst22557');
        createRecord(caseRecord)
            .then(result => {
                this.caseRecordId = result.id;
                this.resetBox();
                this.loaded = true;
                if(this.caseExtensionRecordId) {
                    this.updateCaseExtensionRecord(this.caseExtensionRecordId);
                }
                //tst strt
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.caseRecordId,
                        //objectApiName: 'Case', // objectApiName is optional
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
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error creating record',
                //         message: error.body.message,
                //         variant: 'error',
                //     }),
                // );
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
            })
    }

    updateCaseExtensionRecord(caseExtensionRecId) {
        if(this.complaintType) {
            /*const fields = {};

            fields[CASE_EXTENSION_ID_FIELD.fieldApiName] = caseExtensionRecId;
            fields[COMPLAINT_TYPE_FIELD.fieldApiName] = this.complaintType;

            const recordInput = {
            fields: fields
            };

            updateRecord(recordInput).then((record) => {
                console.log('Record--> '+record);
            });*/
            updateCaseExtension({caseextensionId: caseExtensionRecId, complainttype : this.complaintType})
            .then((result) => {
                console.log(result);
            })
            .catch((error) => {
                console.log("Error inside updateCaseExtension "+JSON.stringify(error));
            });
  
        }
    }

    async createRelObj() {
        const fields = {};

        if(this.isTransactionRelated){
            fields[TRANSACTION_NUM.fieldApiName] = this.transactionNumber;
        }
        let categoryType = (this.template.querySelector("[data-id='Category_Type']") != undefined && this.template.querySelector("[data-id='Category_Type']") != null) ? this.template.querySelector("[data-id='Category_Type']").value : null;
        if(categoryType && categoryType != null) {
            fields[BSLI_CATEGORY_TYPE.fieldApiName] = categoryType;
        }
        console.log('rel object name--'+this.caseRelObjName+'BU--'+this.businessUnit);
        const caseRecord = { apiName: this.caseRelObjName, fields: fields };

        await createRecord(caseRecord)
            .then(result => {
                this.caseExtensionRecordId = result.id;
                console.log('tst22557' + this.caseExtensionRecordId);
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error creating record',
                //         message: error.body.message,
                //         variant: 'error',
                //     }),
                // );
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
        console.log("selectedvalue", this.natureVal);
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
        this.sourceFldValue = event.target.value;
        this.sourceVal = event.target.value;
        var btnActive = false;

        if (this.sourceVal && this.sourceVal != '') {
            btnActive = true;
            this.isPhoneInbound = false;
            this.showAniNumber = false;
            this.trackId = '';
            this.aniNumber = '';
            if (this.isRequestAndQuery) {
                //console.log('sassd'+this.natureVal);
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    //console.log('tst2255'+this.natureVal);
                    btnActive = false;
                }
            }
            let bsliSourceList = ABSLI_Track_Sources.includes(',') ? ABSLI_Track_Sources.split(',') : ABSLI_Track_Sources;
            //Changes as per PR970457-1419 to add Track id for Phone Outbound & Inbound Nodal desk
            if(this.sourceFldValue == 'Phone-Inbound' || this.sourceFldValue == 'Phone-Outbound' || this.sourceFldValue == 'Inbound Nodal Desk'){
                btnActive = false;
                this.isPhoneInbound = true;
            }
            if(this.businessUnit === ABSLI_BU && bsliSourceList.includes(this.sourceFldValue.trim())){
                btnActive = false;
                this.isPhoneInbound = true;
                this.showAniNumber = true;
            }
            if(this.businessUnit === ABHI_BU && this.abhiTrackSources.includes(this.sourceFldValue.trim())){
                btnActive = false;
                this.isPhoneInbound = true;
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    handleSubSourceFunc(event) {

        //this.isNotSelected = true;
        let dataSetId = event.target.dataset.id;
        let evtValue  = event.target.value;

        if(dataSetId == "Sub_Source__c") {
            this.subSourceFldValue = evtValue;
        }
    }

    handleAutoCommChange(event){
        this.noAutoCommValue = event.detail.value;
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

    async getAccountRecord() {
        console.log('accId' + this.accountId);
        if(this.accountId != null && this.accountId != undefined){
            await getAccountRec({ recId: this.accountId })
            .then(result => {
                this.accountData = result;
                this.primaryLOBValue = result.Business_Unit__c;
                this.classificationValue = result.Classification__c;
                this.accountRecordType = result.RecordType.Name;
                this.accountLOB = result.Line_of_Business__c; // THIS IS USED IN CASE OF ABFL TO CHECK IF THE LOB IS WEALTH.
                console.log('result' + result);
            })
            .catch(error => {
                console.log(error);
            });
        //tst end
        }
        
    }

    resetBox() {
        console.log('in reset box');
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

    // description : For Bulk Upload. Download Button
    async generateCSV() {

        this.loaded = true;
        var fields = {};

        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[SOURCE_FIELD.fieldApiName] = this.sourceFldValue;
        fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        fields[SUBTYPETXT_FIELD.fieldApiName] = selected.Sub_Type__c;

        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields, cccExtId: selected.CCC_External_Id__c };

        generateCreateBulkCSV({ strObjectJson: JSON.stringify(caseRecord) })
            .then(result => {

                this.dataCSV = result;
                this.downloadCSVFile();

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                this.loaded = true;
            })
    }

    /** Description -For Bulk. this method validates the dataCSV and creates the csv file to download Bulk**/
    downloadCSVFile() {
        let rowEnd = '\n';
        let csvString = '';
        // this set elminates the duplicates if have any duplicate keys
        let rowData = new Set();

        // getting keys from dataCSV
        this.dataCSV.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                rowData.add(key);
            });
        });

        rowData = Array.from(rowData);
        csvString += rowData.join(',');
        csvString += rowEnd;

        // main for loop to get the dataCSV based on key value
        for (let i = 0; i < this.dataCSV.length; i++) {
            let colValue = 0;

            // validating keys in dataCSV
            for (let key in rowData) {
                if (rowData.hasOwnProperty(key)) {
                    // Key value 
                    // Ex: Id, Name
                    let rowKey = rowData[key];
                    // add , after every value except the first.
                    if (colValue > 0) {
                        csvString += ',';
                    }
                    let value = this.dataCSV[i][rowKey] === undefined ? '' : this.dataCSV[i][rowKey];
                    csvString += '"' + value + '"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_blank';//'_self';
        downloadElement.download = 'Bulk Creation ' + '-' + Date.now() + '.csv';
        downloadElement.click();
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

    async checkDuplicateCase(selected){
        // Virendra - To call de-dupe check call here.

        let listOfCases = [];
        

        let caseRecord = {'sObjectType' : 'Case'};
        caseRecord.CCC_External_Id__c = selected.CCC_External_Id__c
        caseRecord.AccountId =  this.accountData.Id;
        listOfCases.push(caseRecord);
        let bResult = true;
        var errMg = '';

        await getDuplicateCases({ cases: listOfCases, transactionNo : this.transactionNumber, businessUnit : selected.Business_Unit__c })
            .then(result => {
                console.log('result --> '+result);
                bResult = true;

            })
            .catch(error => {
                console.log('error --> '+error);
                bResult = false;
                errMg = error.body.message;
            })

            if(!bResult){
                await this.handleConfirmClick(errMg);
            }

            return bResult;


    }
    handleTransactionChange(event){
        this.transactionNumber = event.target.value;
    }
    handleFtr(event){
        this.ftrValue = event.target.checked;
    }
    handleTrackId(event){
        this.trackId = event.target.value;
        if(this.businessUnit === ABSLI_BU && this.aniNumber != null && this.trackId != '' && this.trackId != null){
            this.isNotSelected = false;
        }
        else if(this.businessUnit != ABSLI_BU && this.trackId.length != 0){
            this.isNotSelected = false;
        }
        else {
            this.isNotSelected = true;
        }

    }
    handleAniNumber(event){
        this.aniNumber = event.target.value;
        if(this.businessUnit === ABSLI_BU && this.aniNumber != null && this.trackId != '' && this.trackId != null){
            this.isNotSelected = false;
        }
        else if(this.businessUnit != ABSLI_BU && this.aniNumber.length != 0){
            this.isNotSelected = false;
        }
        else {
            this.isNotSelected = true;
        }

    }
    handleIssueTypeChange(event){
        this.issueTypeVal = event.detail.value;
    }
    async handleConfirmClick(msg) {
        const result = await LightningConfirm.open({
            message: msg,
            variant: 'headerless',
            label: 'Duplicate Found !',
            // setting theme would have no effect
        });
    }
}
