import { LightningElement, track, api, wire } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CaseUIController.getAccountData';
//import fetchNatureMetadata from '@salesforce/apex/ASF_CaseUIController.fetchNatureMetadata';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getCaseRelatedObjName from '@salesforce/apex/ASF_CaseUIController.getCaseRelatedObjName';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import AMIOwner from '@salesforce/schema/Case.AmIOwner__c';
import AccountId from '@salesforce/schema/Case.AccountId';
import ACOUNNTRECORDTYPE from '@salesforce/schema/Case.Account.RecordType.Name';

//tst strt
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';

import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNTTYPE_FIELD from '@salesforce/schema/Asset.Account.IsPersonAccount';
import Business_Unit from '@salesforce/schema/Case.Asset.LOB_Code__r.BusinessUnit__c';
//import ASSET_PRODUCT_FIELD from '@salesforce/schema/Case.Asset.Product_Name__c';
import CASE_ASSET from '@salesforce/schema/Case.AssetId';
import ACCOUNT_PRIMARY_LOB from '@salesforce/schema/Case.Account.Line_of_Business__c';
//import ACCOUNT_CLASSIFICATION from '@salesforce/schema/Case.Account.Classification__c';


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


    @api propertyValue;
    @api assetId;
    assetAccount;
    @track isShowModal = false;

    options;
    flag;
    businessUnitValue;
    assetProductName;
    value;
    contactName;
    contactSelected;
    asset;
    singleChoice;
    isNextButtonDisabled = true;
    sourceValues = [];
    natureValues = [];
    @track objectInfo;
    rejectedDetails = '';
    caseRecord;
    showSRModal = false;
    showFAmsg = true;
    faValidMsg = FAmsg;
    isFTRJourney = false;
    showSRDescription = false;
    caseDescriptionFTR;
    rejectBtnCalled = false;

    complaintLevelVisible = false;
    complaintValues = [];
    complaintSelected;
    subsourceSelected;
    withFALabel = WithFA;
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

    @wire(getRecord, { recordId: '$recordId', fields: [SOURCE_FIELD, CASE_CONTACT_FIELD, ACCOUNT_PRIMARY_LOB, AMIOwner, AccountId, Business_Unit, CASE_ASSET,ACOUNNTRECORDTYPE] })
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
            this.asset = data;

            this.flag = this.contactSelected = this.asset.fields.ContactId;
            if (this.asset.fields.Asset.value && this.asset.fields.Asset.value.fields.LOB_Code__r.value) {
                this.businessUnitValue = this.asset.fields.Asset.value.fields.LOB_Code__r.value.fields.BusinessUnit__c.value;
            }
            if (this.asset.fields.AssetId.value) {
                this.showFAmsg = false;
            }

            this.sourceOnRecord = this.asset.fields.Source__c.value;

            if (this.asset.fields.AmIOwner__c.value == true) {
                this.isNotSelectedReject = false;
            } else {
                this.isNotSelectedReject = true;
            }
            this.customerId = this.asset.fields.AccountId.value;

            // Get the Account Record Type.
            if(this.asset.fields.Account.value != null){
                if(this.asset.fields.Account.value.fields.RecordType.value.fields.Name.value != null){
                    this.accountRecordType = this.asset.fields.Account.value.fields.RecordType.value.fields.Name.value;
                }
            }
        }
    }


    get isPersonAccount() {
        return getFieldValue(this.asset.data, ACCOUNTTYPE_FIELD);

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

        let customerId = this.asset.fields.AccountId.value;
        let assetId = this.asset.fields.Asset.value;
        //call Apex method.
        if ((this.withoutAsset == 'false' && assetId != null)
            || this.withoutAsset == 'true' && customerId != '' || this.withoutAsset == 'closeCRN') {

            getAccountData({ keyword: this.searchKey, assetProductType: this.cccProductType, withoutAsset: this.withoutAsset, accRecordType: this.accountRecordType })
                .then(result => {
                    this.accounts = result;
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
        if (this.customerId != undefined && this.customerId != null)
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
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        this.complaintSelected = '';

        // Reset isTransaction Related Every time selection changes. - Virendra
        this.isTransactionRelated = false;
        this.transactionNumber = '';

        this.showSRDescription = this.isFTRJourney = selected.Is_FTR_Journey__c;

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

        if (this.asset.fields.Account.value != null && this.asset.fields.Account.value != undefined) {
            if (this.asset.fields.Account.value.fields.Line_of_Business__c.value != null || this.asset.fields.Account.value.fields.Line_of_Business__c.value != undefined) {
                this.primaryLOBValue = this.asset.fields.Account.value.fields.Line_of_Business__c.value
            }
        }

        /*if (this.asset.fields.Account.value.fields.Classification__c.value != null || this.asset.fields.Account.value.fields.Classification__c.value != undefined) {
            this.classificationValue = this.asset.fields.Account.value.fields.Classification__c.value
        }*/

        new asf_Utility().createRelObjJS(selected, source, this.frameWorkrecordTypeId, this.rejectedDetails, contact, this);

    }

    navigateToRecordEditPage(id) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                objectApiName: 'Case',
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



    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'Product', fieldName: 'Product__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ]

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
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if(selected != null && selected != undefined){
            let cccExtId = selected.CCC_External_Id__c;
            if(cccExtId != null && cccExtId != undefined){
                await this.fetchRejectionReason(cccExtId);
            }
        }
        
        this.showRejetedReason = true;
        this.showSRDescription = false;
        this.rejectBtnCalled = true;

        // this.rejectCase = true;
        //this.createCaseHandler();
    }
    saveRejection(event) {
        console.log('this.rejectedDetails.length' + this.rejectedDetails.length);
        if (this.rejectedDetails.length == 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please update rejection details',
                    variant: 'Error',
                }),
            );
        } else if (this.selectedReason == '') {
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
    }

    showModal(event) {

        this.showSRDescription = false;
        this.complaintLevelVisible = false;
        let assetId = this.asset.fields.Asset.value;

        this.isTransactionRelated = false;
        this.transactionNumber = '';


        console.log('assetId' + assetId == null);
        if (assetId == '' || assetId == undefined || assetId == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: FA_Mandatory,
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
        let customerId = this.asset.fields.AccountId.value;
        let assetId = this.asset.fields.Asset.value;

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


    //To get Rejection Reason:
    async fetchRejectionReason(cccExtId) {
        await getSrRejectReasons({ cccExternalId: cccExtId }).then(result => {
            result.forEach(reason => {
                const optionVal = {
                    label: reason,
                    value: reason
                };
                this.reasonLOV.push(optionVal);
            });
            this.showRejetedReason = true;
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

        this.withoutAsset = 'closeCRN';
        this.showSRModal = true;
        this.complaintLevelVisible = false;
        this.isCloseWithoutCRNFlow = true;
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