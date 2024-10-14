import { LightningElement, track, api, wire } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getTypeSubTypeByCustomerDetails';
//import fetchNatureMetadata from '@salesforce/apex/ASF_CaseUIController.fetchNatureMetadata';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import ABSLI_CASE_DETAIL_OBJECT from '@salesforce/schema/ABSLI_Case_Detail__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getObjectInfos, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getCaseRelatedObjName from '@salesforce/apex/ASF_CaseUIController.getCaseRelatedObjName';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import AMIOwner from '@salesforce/schema/Case.AmIOwner__c';
import AccountId from '@salesforce/schema/Case.AccountId';
import ACOUNNTRECORDTYPE from '@salesforce/schema/Case.Account.RecordType.Name';
import NOAUTOCOMM_FIELD from '@salesforce/schema/Case.No_Auto_Communication__c';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU'; 
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU';
import ABHI_BU from '@salesforce/label/c.ABHI_BU';
import { lanLabels } from 'c/asf_ConstantUtility';
import { AUTO_COMM_BU_OPT } from 'c/asf_ConstantUtility'; // Rajendra Singh Nagar: PR1030924-209

//tst strt
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';

import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNTTYPE_FIELD from '@salesforce/schema/Asset.Account.IsPersonAccount';
//import ASSET_PRODUCT_FIELD from '@salesforce/schema/Case.Asset.Product_Name__c';
import CASE_ASSET from '@salesforce/schema/Case.AssetId';
import ACCOUNT_PRIMARY_LOB from '@salesforce/schema/Case.Account.Line_of_Business__c';
//import ACCOUNT_CLASSIFICATION from '@salesforce/schema/Case.Account.Classification__c';
import CASE_ASSET_LOB from '@salesforce/schema/Case.Asset.LOB__c';
import BUSINESS_UNIT from '@salesforce/schema/User.Business_Unit__c';
import BSLI_CATEGORY_TYPE from '@salesforce/schema/ABSLI_Case_Detail__c.Complaint_Category__c';

import FAmsg from '@salesforce/label/c.ASF_FA_Validation_Message';

import { asf_Utility } from 'c/asf_Utility';
import FA_Mandatory from '@salesforce/label/c.ASF_FA_Mandatory_preframework';
import Customer_Mandatory from '@salesforce/label/c.ASF_Customer_Mandatory';
import CRN_Basis_Case from '@salesforce/label/c.ASF_CRN_Basis_Case';
import WithoutFA from '@salesforce/label/c.ASF_CreateSRwithoutFA';
import WithFA from '@salesforce/label/c.ASF_CreateSRwithFA';
import getSrRejectReasons from '@salesforce/apex/ASF_GetCaseRelatedDetails.getRejectionReasons';

import getDuplicateCases from '@salesforce/apex/ABCL_CaseDeDupeCheckLWC.getDuplicateCases';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';
import LightningConfirm from 'lightning/confirm';
import USER_ID from '@salesforce/user/Id';


// VIRENDRA - Updating component for Prospect Requirement.
import CloseCaseWithoutCustomerLbl from '@salesforce/label/c.ASF_CloseCaseWithoutCustomer';
import CreateCaseWithProspectLbl from '@salesforce/label/c.ASF_CreateCaseWithProspect';
import CASE_PROSPECT_ID from '@salesforce/schema/Case.Lead__c';



//tst end

export default class ASF_createCaseWithType extends NavigationMixin(LightningElement) {
    searchKey;
    accounts;
    isNotSelected = true;
    isNotSelectedReject = true;
    @api recordId;
    loaded = true;
    caseRelObjName;
    caseExtensionRecordId;
    caseRecordId;
    closeCase;
    rejectCase;
    //tst strt
    doneTypingInterval = 300;
    typingTimer;
    createCaseWithAll = false;
    isAllNature = false;
    isAllProduct = false;
    isAllSource = false;
    isRequestAndQuery = false;
    isRequestAndQuerySource = false;
    natureVal;
    productVal;
    sourceVal = 'Email';
    showRejetedReason = false;
    selectedCaseStage;
    customerId;
    withoutAsset;
    originValue;
    @track noAutoCommOptions = [];
    noAutoCommValue = [];
    showAutoComm = false;
    isCloseCase = false;
    closeCaseWithoutCusButton = '';


    @api propertyValue;
    @api assetId;
    assetAccount;
    @track isShowModal = false;

    options;
    flag;
    assetProductName;
    value;
    contactName;
    contactSelected;
    caseRec;
    singleChoice;
    isNextButtonDisabled = true;
    sourceValues = [];
    natureValues = [];
    @track objectInfo;
    rejectedDetails = '';
    caseRecord;
    showSRModal = false;
    showFAmsg = true;
    faValidMsg;
    isFTRJourney = false;
    showSRDescription = false;
    caseDescriptionFTR;
    rejectBtnCalled = false;

    complaintLevelVisible = false;
    complaintValues = [];
    complaintSelected;
    subsourceSelected;
    withFALabel;
    withoutFALabel = WithoutFA;
    selectedSRCategory

    selectedReason = '';
    reasonLOV = [];
    sourceOnRecord = '';
    cccProductType;
    caseComplaintLevel;
    primaryLOBValue;
    isCloseWithoutCRNFlow = false;
    classificationValue;
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    // De-dupe for Payment - 
    isTransactionRelated = false;
    transactionNumber = '';
    accountRecordType = '';


    // VIRENDRA - PROSPECT CHANGES 
    closeWithoutCustomerLbl = CloseCaseWithoutCustomerLbl;
    caseWithProspectLbl = CreateCaseWithProspectLbl;
    prospectRecId;
    showOnCustomerTagging = false;
    showOnProspectTagging = false;

    accountLOB = '';
    lobAsset ='';
    businessUnit; 

    cols; 

    //BSLI
    showFtr = false;
    ftrValue = false;
    showIssueType = false;
    issueTypeVal;
    issueTypeOptions = [];
    showCategoryType = false;
    @track categoryTypeOptions = [];
    categoryTypeVal;
    @api defaultRecTypeId; // this field is used to fetch the picklist values
    @api picklistApiName = NOAUTOCOMM_FIELD;
    @api bsliRecTypeId;
    boolAllChannelVisible = false;
    strChannelValue = '';
    lstChannelValues = [];
    strDefaultChannel = '';
    currentObj = CASE_OBJECT.objectApiName;

    get stageOptions() {
        return [
            { label: 'Pending for Rejection', value: 'Pending for Rejection' },
            { label: 'Closed', value: 'Closed' }
        ];
    }
    get frameWorkrecordTypeId() {
        // Returns a map of record type Ids 
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Framework');
    }

    get saveBtnVisibility() {
        return (this.isNotSelectedReject || this.isNotSelected || this.isCloseWithoutCRNFlow);
    }

    get saveAndCloseBtnVisibility() {

        if (this.isCloseWithoutCRNFlow === true && this.isNotSelected === false) {
            return false;
        }
        else {
            return (this.isNotSelectedReject || this.isNotSelected || this.rejectBtnCalled || (!this.isFTRJourney));
        }

    }

    caseFields = [NATURE_FIELD, SOURCE_FIELD];

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
                this.adjustAutoCommunications(data);

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
    @wire(getRecord, { recordId: '$recordId', fields: [
        SOURCE_FIELD, 
        CASE_CONTACT_FIELD, 
        ACCOUNT_PRIMARY_LOB, 
        AMIOwner, 
        AccountId, 
        CASE_ASSET,
        ACOUNNTRECORDTYPE, 
        CASE_ASSET_LOB,
        CASE_PROSPECT_ID,
        NOAUTOCOMM_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Case',
                    message,
                    variant: 'error',
                }),
            );
        }
        else if (data) {
            this.caseRec = data;
            this.showOnCustomerTagging = false;
            this.showOnProspectTagging = false;
            this.isNotSelectedReject = true;

            this.flag = this.contactSelected = this.caseRec.fields.ContactId;
            
            if (this.caseRec.fields.AssetId.value) {
                this.showFAmsg = false;
                this.assetId = this.caseRec.fields.AssetId.value;
            }

            this.sourceOnRecord = this.caseRec.fields.Source__c.value;
            this.customerId = this.caseRec.fields.AccountId.value;

            // VIRENDRA - SHOW CUSTOMER AND LAN RELATED BUTTON IF CUSTOMER TAGGING DONE.
            if(this.customerId != null && this.customerId != undefined && this.customerId != ''){
                this.showOnCustomerTagging = true;
            }
            let noAutoCommValues = this.caseRec.fields.No_Auto_Communication__c.value;
            this.noAutoCommValue = noAutoCommValues != null?noAutoCommValues.split(';'):[];

            // VIRENDRA - ADDED FOR PROSPECT REQUIREMENT
            this.prospectRecId = this.caseRec.fields.Lead__c.value;
            if(this.prospectRecId != null && this.prospectRecId != undefined && this.prospectRecId != ''){
                this.showOnProspectTagging = true;
            }

            // Get the Account Record Type.
            if(this.caseRec.fields.Account.value != null){
                if(this.caseRec.fields.Account.value.fields.RecordType.value.fields.Name.value != null){
                    this.accountRecordType = this.caseRec.fields.Account.value.fields.RecordType.value.fields.Name.value;
                }
            }
        }
    }

    get displayRejectionReason(){
        return this.showRejetedReason && this.businessUnit != 'ABSLI';
    }


    get isPersonAccount() {
        return getFieldValue(this.caseRec.data, ACCOUNTTYPE_FIELD);

    }

    handleAutoCommChange(event){
        this.noAutoCommValue = event.detail.value;
    }

    @wire(getRecord, { recordId: USER_ID, fields: [BUSINESS_UNIT] })
    user({ error, data}) {
        if (data){
           this.businessUnit = getFieldValue(data, BUSINESS_UNIT);
           this.cols = lanLabels[this.businessUnit].CTST_COLS != null? lanLabels[this.businessUnit].CTST_COLS : lanLabels["DEFAULT"].CTST_COLS;
           this.faValidMsg = lanLabels[this.businessUnit].FA_VALIDATION_MESSAGE != null? lanLabels[this.businessUnit].FA_VALIDATION_MESSAGE : lanLabels["DEFAULT"].FA_VALIDATION_MESSAGE;
           this.withFALabel = lanLabels[this.businessUnit].CREATE_CASE_WITH_FA != null? lanLabels[this.businessUnit].CREATE_CASE_WITH_FA : lanLabels["DEFAULT"].CREATE_CASE_WITH_FA;

           // Rajendra Singh Nagar: PR1030924-209 - adjust auto communications options after BU is determined. 
           this.adjustAutoCommunications(undefined);
        } else if (error){
            console.log('error in get picklist--'+JSON.stringify(error));
        }
    }

    // Rajendra Singh Nagar: PR1030924-209 - Added function
    adjustAutoCommunications(data){
        if(AUTO_COMM_BU_OPT[this.businessUnit]?.OPTSLBLS){
            this.noAutoCommOptions = AUTO_COMM_BU_OPT[this.businessUnit].OPTSLBLS.map(item => ({
                label: item.label,
                value: item.value
            }));
        }else{
            if(data){
                this.noAutoCommOptions = data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            }
        }
    }

    //This Funcation will get the value from Text Input.
    handelSearchKey(event) {
        console.log('hete in yext chage')
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;
        console.log('searchKey' + this.searchKey)
        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.SearchAccountHandler();
            }
        }, this.doneTypingInterval);
    }

    //This funcation will fetch the Account Name on basis of searchkey
    SearchAccountHandler() {
        console.log('in search handler');
        this.accounts = null;
        this.createCaseWithAll = false;
        this.isNotSelected = true;
        this.showFtr = false;
        this.showIssueType = false;
        this.ftrValue = false;
        this.showCategoryType = false;
        this.boolAllChannelVisible = false;

        let customerId = this.caseRec.fields.AccountId.value;
        let assetId = this.caseRec.fields.Asset.value;
        let leadId = this.caseRec.fields.Lead__c.value;


        if(this.caseRec.fields.Asset.value != null && this.caseRec.fields.Asset.value != undefined){
                if(this.caseRec.fields.Asset.value.fields.LOB__c != null && this.caseRec.fields.Asset.value.fields.LOB__c != undefined){
                    this.lobAsset = this.caseRec.fields.Asset.value.fields.LOB__c.value;
                    console.log('lobAsset ',this.caseRec.fields.Asset.value.fields.LOB__c.value);
                }
        }
        if(this.caseRec.fields.Account.value != null && this.caseRec.fields.Account.value != undefined){
            if(this.caseRec.fields.Account.value.fields.Line_of_Business__c != null && this.caseRec.fields.Account.value.fields.Line_of_Business__c != undefined){
                this.accountLOB = this.caseRec.fields.Account.value.fields.Line_of_Business__c.value;
                console.log('lobAcc ',this.caseRec.fields.Account.value.fields.Line_of_Business__c.value);
            }
        
        }
    const inpArg = new Map();
    inpArg['accountLOB'] = this.accountLOB;
    inpArg['closeCaseWithoutCusButton'] = this.closeCaseWithoutCusButton;
    let strInpArg = JSON.stringify(inpArg);
        //call Apex method.
        if ((this.withoutAsset == 'false' && assetId != null)
            || (this.withoutAsset == 'true' && customerId != '') || (this.withoutAsset == 'closeCRN') || (this.withoutAsset == 'Prospect' && leadId !='')) {
            getAccountData({ keyword: this.searchKey, asssetProductType: this.cccProductType, isasset: this.withoutAsset, accRecordType: this.accountRecordType, assetLob :this.lobAsset, inpArg :strInpArg })
                .then(result => {
                    this.accounts = result.lstCCCrecords;
                    console.log('result---'+JSON.stringify(result));
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        this.lstChannelValues = result.lstChannel;
                        this.strDefaultChannel = this.lstChannelValues[0].label;
                        this.strChannelValue = this.strDefaultChannel;
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

    }

    getSelectedName(event) {
        this.createCaseWithAll = false;
        let leadId = this.caseRec.fields.Lead__c.value;
        if ((this.customerId != undefined && this.customerId != null) || (leadId != undefined && leadId != null && leadId != ''))
            this.isNotSelected = false;
        if (this.isCloseWithoutCRNFlow === true && this.isNotSelected === true) {
            this.isNotSelected = false;
        }

        this.isAllNature = false;
        this.isAllProduct = false;
        this.isAllSource = false;
        this.isRequestAndQuery = false;
        this.isRequestAndQuerySource = false;
        this.complaintLevelVisible = false;
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
        this.categoryTypeVal = '';
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        this.complaintSelected = '';

        // Reset isTransaction Related Every time selection changes. - Virendra
        this.isTransactionRelated = false;
        this.transactionNumber = '';
        if(selected){
            this.showSRDescription = this.isFTRJourney = selected.Is_FTR_Journey__c;
        }

        let cccExternalId = '';

        if (this.caseRec.fields.AmIOwner__c.value == true) {
            this.isNotSelectedReject = false;
        }

        if (selected && selected.hasOwnProperty("CCC_External_Id__c")) {
            cccExternalId = selected.CCC_External_Id__c;
            this.fetchRejectionReason(cccExternalId);
        }

        if(selected && !this.isCloseCase && (this.showOnCustomerTagging || this.showOnProspectTagging) && this.businessUnit != ABSLI_BU && this.businessUnit != ABSLIG_BU
        && this.businessUnit != ABHI_BU){
            this.showAutoComm = true;
        }
        if((selected) && this.businessUnit === ABSLI_BU && selected.Nature__c === 'Complaint'){
            this.showCategoryType = true;
        }
        if(selected && this.businessUnit === ABSLI_BU && !this.isCloseWithoutCRNFlow && selected.Show_FTR_Flag_on_Creation__c){
            this.showFtr = true;
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
        if((selected) && this.businessUnit === ABSLI_BU){
            this.boolAllChannelVisible = true;
        } 
        if (selected && (selected[NATURE_FIELD.fieldApiName] == "All") && (!selected[NATURE_FIELD.fieldApiName].includes(','))) {
            this.createCaseWithAll = true;
            this.isNotSelected = true;
            if (selected[NATURE_FIELD.fieldApiName] == "All") {
                this.isAllNature = true;
            }
            // else{
            //     this.isAllNature = true;
            //     this.natureVal = selected[NATURE_FIELD.fieldApiName];
            // }


        }
        if (selected && (selected[NATURE_FIELD.fieldApiName].includes(','))) {
            console.log('queryandreq' + JSON.stringify(selected));
            const naturePicklistValues = selected[NATURE_FIELD.fieldApiName];

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

        } else {
            if (selected) {
                if (selected[NATURE_FIELD.fieldApiName]) {
                    this.natureVal = selected[NATURE_FIELD.fieldApiName];
                }
            }
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
            //this.fetchNatureMetadata(this.complaintSelected, selected[NATURE_FIELD.fieldApiName])
            this.isNotSelected = true;
        } else {
            this.complaintLevelVisible = false;
        }


        if (selected && selected.hasOwnProperty("Is_Transaction_Related__c")) {
            this.isTransactionRelated = selected.Is_Transaction_Related__c;
            console.log('isTransactionRelated ---> ' + this.isTransactionRelated);
        }

    }
    async createCaseHandler() {
        this.loaded = false;

        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];

        var contact;
        if (!this.flag) {
            contact = this.value;
        }
        let source = 'Email';
        if (this.sourceOnRecord == 'Nodal' || this.sourceOnRecord == 'BO')
            source = this.sourceOnRecord;

        console.log('source********** ' + source);
        console.log('this.sourceOnRecord********** ' + this.sourceOnRecord);

        if (this.caseRec.fields.Account.value != null && this.caseRec.fields.Account.value != undefined) {
            if (this.caseRec.fields.Account.value.fields.Line_of_Business__c.value != null || this.caseRec.fields.Account.value.fields.Line_of_Business__c.value != undefined) {
                this.primaryLOBValue = this.caseRec.fields.Account.value.fields.Line_of_Business__c.value
            }
        }

        /*if (this.caseRec.fields.Account.value.fields.Classification__c.value != null || this.caseRec.fields.Account.value.fields.Classification__c.value != undefined) {
            this.classificationValue = this.caseRec.fields.Account.value.fields.Classification__c.value
        }*/

        new asf_Utility().createRelObjJS(selected, source, this.frameWorkrecordTypeId, this.rejectedDetails, contact, this);

    }

    navigateToRecordEditPage(id) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
                    attributes: {
                        recordId: id,
                        //objectApiName: 'Case', // objectApiName is optional
                        actionName: 'view'
                    },
                    state: {
                        mode: 'edit'
                    }
        });

        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        /* setTimeout(() => {
             window.location.reload();          
         }, 1000) */
    }

    handleNatureVal(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isAllSource) {
                if (this.sourceVal && this.sourceVal != '') {
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
        if (this.customerId != undefined && this.customerId != null)
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
                if (this.sourceVal && this.sourceVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }
        if (this.customerId != undefined && this.customerId != null)
            this.isNotSelected = !btnActive;
    }

    handleChangeNature(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isRequestAndQuerySource) {
                if (this.sourceVal && this.sourceVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
            console.log('here222' + this.complaintSelected)
            if (this.complaintSelected != '') {
                //this.fetchNatureMetadata(this.complaintSelected, this.natureVal)
                if (this.subsourceSelected)
                    btnActive = true;
                else
                    btnActive = false;
            }

            console.log('here333')
        } else {
            btnActive = false;
        }
        if (this.customerId != undefined && this.customerId != null)
            this.isNotSelected = !btnActive;
    }

    handleContactChange(event) {
        this.value = event.detail.value;
        if (this.value) {
            this.isNextButtonDisabled = false;
        }
        this.contactName = event.target.options.find(opt => opt.value === event.detail.value).label;
    }
    handleStageChange(event) {
        console.log('event.detail.value' + event.detail.value);
        this.selectedCaseStage = event.detail.value;
        //this.createCaseHandler();
    }
    handleFtr(event){
        this.ftrValue = event.target.checked;
    }
    handleIssueTypeChange(event){
        this.issueTypeVal = event.detail.value;
    }
    handleCatTypeChange(event){
        this.categoryTypeVal = event.detail.value;
    }
    gotoMainScreen() {
        this.contactSelected = true;
    }


    async handleSaveNext(event) {
        if (!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            return;
        }

        const allValid = [
            ...this.template.querySelectorAll('lightning-textarea'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {

            var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];

            var dupeResult = await this.checkDuplicateCase(selected);

            if (!dupeResult) {
                return;
            }

            this.createCaseHandler();
        }
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
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
    async checkDuplicateCase(selected) {
        // Virendra - To call de-dupe check call here.

        let listOfCases = [];


        let caseRecord = { 'sObjectType': 'Case' };
        caseRecord.CCC_External_Id__c = selected.CCC_External_Id__c
        if(this.customerId != null && this.customerId != undefined)
            caseRecord.AccountId = this.customerId;
        else
            caseRecord.AccountId = undefined;
        listOfCases.push(caseRecord);
        let bResult = true;
        var errMg = '';
        if (caseRecord.AccountId != undefined && caseRecord.AccountId != null) {
            await getDuplicateCases({ cases: listOfCases, transactionNo: this.transactionNumber, businessUnit: selected.Business_Unit__c })
                .then(result => {
                    console.log('result --> ' + result);
                    bResult = true;

                })
                .catch(error => {
                    console.log('error --> ' + error);
                    bResult = false;
                    errMg = error.body.message;
                })

            if (!bResult) {
                await this.handleConfirmClick(errMg);
            }
        }


        return bResult;


    }

    async handleCloseBtn(event) {

        if (!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            return;
        }

        const allValid = [
            ...this.template.querySelectorAll('lightning-textarea'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            this.closeCase = true;

            var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];

            var dupeResult = await this.checkDuplicateCase(selected);

            if (!dupeResult) {
                return;
            }

            this.createCaseHandler();
        }
    }

    async handleRejectBtn(event) {
        
        this.showRejetedReason = true;
        this.showSRDescription = false;
        this.rejectBtnCalled = true;

        // this.rejectCase = true;
        //this.createCaseHandler();
    }
    saveRejection(event) {
        console.log('this.rejectedDetails.length' + this.rejectedDetails.length);
        if (this.rejectedDetails.length == 0 && this.businessUnit != ABSLI_BU) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please update rejection details',
                    variant: 'Error',
                }),
            );
        } else if (this.selectedReason == '' && this.businessUnit != ABSLI_BU) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select rejection reason',
                    variant: 'Error',
                }),
            );
        } else {
            this.rejectCase = true;
            this.createCaseHandler();
        }

    }
    cancelReject() {
        console.log('caseRecord' + this.caseRecord);
        this.showRejetedReason = false;

        this.rejectBtnCalled = false;

        //Show SR Description if FTR Journey Case
        if (this.isFTRJourney) {
            this.showSRDescription = true;
        }
    }
    hideModalBox() {
        this.isShowModal = false;
    }
    setRejectedDetails(event) {
        this.rejectedDetails = event.target.value;
    }

    setSRDescription(event) {
        this.caseDescriptionFTR = event.target.value;
    }

    hideModal() {
        this.showSRModal = false;
        this.isNotSelected = true;
        this.searchKey = '';
        this.accounts = [];
        this.createCaseWithAll = false;
        this.showAutoComm = false;
        this.ftrValue = false;
        this.showFtr = false;
        this.showIssueType = false;
        this.issueTypeVal = '';
        this.categoryTypeVal = '';
        this.isNotSelectedReject = true;
        this.showCategoryType = false;
        this.closeCaseWithoutCusButton = '';
        this.boolAllChannelVisible = false;
        this.strChannelValue = '';
        this.cancelReject();
    }

    showModal(event) {

        this.showSRDescription = false;
        this.complaintLevelVisible = false;
        let assetId = this.caseRec.fields.Asset.value;
        this.isCloseCase = false;
        

        this.isTransactionRelated = false;
        this.transactionNumber = '';


        console.log('assetId' + assetId == null);
        if (assetId == '' || assetId == undefined || assetId == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: lanLabels[this.businessUnit].FA_MANDATORY_PREFRAMEWORK != null? lanLabels[this.businessUnit].FA_MANDATORY_PREFRAMEWORK : lanLabels["DEFAULT"].FA_MANDATORY_PREFRAMEWORK,
                    variant: 'Error',
                }),
            );

        }
        this.showSRModal = true;
        this.withoutAsset = 'false';
        this.complaintLevelVisible = false;
        this.isCloseWithoutCRNFlow = false;



    }
    showModalWitoutFA(event) {

        this.showSRDescription = false;
        this.complaintLevelVisible = false;
        let customerId = this.caseRec.fields.AccountId.value;
        let assetId = this.caseRec.fields.Asset.value;
        this.isCloseCase = false;

        this.isTransactionRelated = false;
        this.transactionNumber = '';

        if (customerId == '' || customerId == undefined || customerId == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: Customer_Mandatory,
                    variant: 'Error',
                }),
            );

        } else {
            if (customerId != null && assetId != null) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: CRN_Basis_Case,
                        variant: 'Warning',
                    }),
                );
            }

        }
        this.withoutAsset = 'true';
        this.showSRModal = true;
        this.complaintLevelVisible = false;
        this.isCloseWithoutCRNFlow = false;

    }
    handleComplaint(event) {
        this.complaintSelected = event.target.value;
        if (this.subsourceSelected && this.complaintSelected)
            this.isNotSelected = false;
        else
            this.isNotSelected = true;
    }
    handleSubSource(event) {
        this.subsourceSelected = event.target.value;
        if (this.subsourceSelected && this.complaintSelected && this.natureVal)
            this.isNotSelected = false;
        else
            this.isNotSelected = true;
    }
    // Method to handle the Channel Picklist
    handleChangeChannel(event) {
        this.strChannelValue = event.target.value;
    }


    //To get Rejection Reason:
    async fetchRejectionReason(cccExtId) {
        await getSrRejectReasons({ cccExternalId: cccExtId }).then(result => {
            this.reasonLOV = [];
            result.forEach(reason => {
                const optionVal = {
                    label: reason,
                    value: reason
                };
                this.reasonLOV.push(optionVal);
            });
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });
    }
    

    handleRejReasonChange(event) {
        this.selectedReason = event.target.value;
    }

    //To get SR Category Reason:
    /*fetchNatureMetadata(level, nature) {
        if (level && nature) {
            fetchNatureMetadata({ level: level, nature: nature }).then(result => {
                this.selectedSRCategory = result;
            }).catch(error => {
                console.log('Error: ' + JSON.stringify(error));
            });
        }
    }
    */




    showModalCloseWitoutCRN(event) {

        this.showSRDescription = false;
        this.complaintLevelVisible = false;
        this.isCloseCase = true;
        this.closeCaseWithoutCusButton= 'true';
        this.withoutAsset = 'closeCRN';
        this.showSRModal = true;
        this.complaintLevelVisible = false;
        this.isCloseWithoutCRNFlow = true;
        this.isTransactionRelated = false;
        this.transactionNumber = '';
    }

    categoriseCaseForProspect(event){
        this.showSRDescription = false;
        this.complaintLevelVisible = false;
        this.isNotSelected = true;
        this.closeCaseWithoutCusButton= 'true';
        this.isCloseCase = false;

        this.withoutAsset = 'Prospect';
        this.showSRModal = true;
        this.complaintLevelVisible = false;
        this.isCloseWithoutCRNFlow = false;
        this.isTransactionRelated = false;
        this.transactionNumber = '';
    }

    handleTransactionChange(event) {
        this.transactionNumber = event.target.value;
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
