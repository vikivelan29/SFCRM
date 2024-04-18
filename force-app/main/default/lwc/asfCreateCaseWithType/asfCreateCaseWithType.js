import { LightningElement, track, api, wire } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountDataByCustomerType';
import getAccountRec from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountRec';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import { createRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import fetchRelatedContacts from '@salesforce/apex/ASF_GetCaseRelatedDetails.fetchRelatedContacts';

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
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import TECHNICAL_SOURCE_FIELD from '@salesforce/schema/Case.Technical_Source__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/Asset.AccountId';
import Business_Unit from '@salesforce/schema/Asset.LOB_Code__r.BusinessUnit__c';
import Business_Unit_LOB from '@salesforce/schema/Asset.LOB_Code__c';

import ACCOUNTTYPE_FIELD from '@salesforce/schema/Asset.Account.IsPersonAccount';
import ACCOUNT_RECORDTYPE from '@salesforce/schema/Asset.Account.RecordType.DeveloperName';

import REOPEN_DAYS from '@salesforce/schema/Case.Reopen_Days__c';
import IS_CLONEABLE from '@salesforce/schema/Case.ASF_Is_Cloneable__c'; //Functionality Clone SR - Santanu Oct27,2023

import getDuplicateCases from '@salesforce/apex/ABCL_CaseDeDupeCheckLWC.getDuplicateCases';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';
import LightningConfirm from 'lightning/confirm';


export default class AsfCreateCaseWithType extends NavigationMixin(LightningElement) {
    searchKey;
    accounts;
    isNotSelected = true;
    @api recordId;
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
    natureVal;
    productVal;
    sourceVal;

    @api propertyValue;
    @api assetId;
    @api isasset;
    @api accountId;
    assetAccount;

    @api accid;

    options;
    flag;
    businessUnitValue;
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
    lstChannelValues = [];
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

    // De-dupe for Payment - 
    isTransactionRelated = false;
    transactionNumber = '';
    accountRecordType = '';


    /* get natureValues() {
         return [
             { label: 'Request', value: 'Request' },
             { label: 'Query', value: 'Query' },
   
         ];
     } */
    /* get sourceValues() {
         return [
             { label: 'CEC', value: 'CEC' },
             { label: 'RL Branch ', value: 'RL Branch' },
   
         ];
     }  */

    //tst end

    //caseFields = [NATURE_FIELD,PRODUCT_FIELD,SOURCE_FIELD,CHANNEL_FIELD];
    caseFields = [NATURE_FIELD, SOURCE_FIELD, CHANNEL_FIELD];


    connectedCallback() {
        console.log('accId ---> ' + this.accountId);
        this.getAccountRecord();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD, Business_Unit, Business_Unit_LOB, ACCOUNTTYPE_FIELD,ACCOUNT_RECORDTYPE] })
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
            this.flag = this.contactSelected = this.asset.fields.Account.value.fields.IsPersonAccount.value;
            this.primaryLOBValue = this.asset.fields.Account.value.fields.Primary_LOB__c.value;
            if (this.asset.fields.LOB_Code__c.value) {
                this.businessUnitValue = this.asset.fields.LOB_Code__r.value.fields.BusinessUnit__c.value;
            }
            /*if(this.asset.fields.ccc_product_Type__c.value){
                this.cccproduct_type =this.asset.fields.ccc_product_Type__c.value;
            }*/
            this.classificationValue = this.asset.fields.Account.value.fields.Classification__c.value;
            if (!this.contactSelected) {
                fetchRelatedContacts({ accId: this.asset.fields.AccountId.value })
                    .then(result => {
                        let stages = [];
                        result.forEach((element) => {
                            stages.push({
                                label: element.Name,
                                value: element.Id
                            });
                        });
                        this.options = stages;
                    })
                    .catch(error => {
                        console.log(error);
                        this.error = error;
                    });
            }
        } else {
            this.getAccountRecord();

        }
    }




    // get assetAccount() {
    //     return getFieldValue(this.asset.data, ACCOUNT_FIELD);
    // }

    get isPersonAccount() {
        return getFieldValue(this.asset.data, ACCOUNTTYPE_FIELD);
    }

    //This Funcation will get the value from Text Input.
    handelSearchKey(event) {
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
        getAccountData({ keyword: this.searchKey, asssetProductType: this.cccproduct_type, isasset: this.isasset, accRecordType : this.accountRecordType })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    this.strSource = result.strSource;
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
        // Reset isTransaction Related Every time selection changes. - Virendra
        this.isTransactionRelated = false;
        this.transactionNumber = '';

        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
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
            if (selected && (selected[NATURE_FIELD.fieldApiName] == "All" || selected[SOURCE_FIELD.fieldApiName] == "All") && (!selected[NATURE_FIELD.fieldApiName].includes(','))) {
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
        fields[ASSETID_FIELD.fieldApiName] = this.recordId;
        fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[SOURCE_FIELD.fieldApiName] = this.strSource;
        fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;

        if (this.isasset == false) {
            fields[CASE_ACCOUNT_FIELD.fieldApiName] = this.asset.fields.AccountId.value;
            fields[LAN_NUMBER.fieldApiName] = this.asset.fields.ASF_Card_or_Account_Number__c.value;

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
        console.log('tst22557');
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
                this.disableCaseBtn = false;
            })
            .catch(error => {
                console.log('tst225572' + JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                this.loaded = true;
                this.isNotSelected = true;
                this.createCaseWithAll = false;
                this.disableCaseBtn = false;
            })
    }



    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        //{ label: 'Product', fieldName: 'Product__c', type: 'text' },
        //{ label: 'Source', fieldName: 'Source__c', type: 'text' },
        { label: 'LOB', fieldName: 'Business_Unit__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ]

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

    handleSourceVal(event) {
        this.sourceVal = event.target.value;
        var btnActive = false;
        if (this.sourceVal && this.sourceVal != '') {
            btnActive = true;
            if (this.isAllNature) {
                console.log('tst2245' + this.natureVal);
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    console.log('tst2255' + this.natureVal);
                    btnActive = false;
                }
            } else if (this.isAllProduct) {
                console.log('tst2245' + this.productVal);
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
        this.sourceVal = event.target.value;
        var btnActive = false;
        if (this.sourceVal && this.sourceVal != '') {
            btnActive = true;
            if (this.isRequestAndQuery) {
                //console.log('sassd'+this.natureVal);
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    //console.log('tst2255'+this.natureVal);
                    btnActive = false;
                }
            }
            //Changes as per PR970457-1419 to add Track id for Phone Outbound & Inbound Nodal desk
            if(this.sourceFldValue == 'Phone-Inbound' || this.sourceFldValue == 'Phone-Outbound' || this.sourceFldValue == 'Inbound Nodal Desk'){
                btnActive = false;
                this.isPhoneInbound = true;
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

    handleContactChange(event) {
        this.value = event.detail.value;
        if (this.value) {
            this.isNextButtonDisabled = false;
        }
        this.contactName = event.target.options.find(opt => opt.value === event.detail.value).label;
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
                console.log('result' + result);
            })
            .catch(error => {
                console.log(error);
            });
        //tst end
        }
        
    }

    gotoMainScreen() {
        this.contactSelected = true;
    }
    resetBox() {
        console.log('in reset box');
        this.dispatchEvent(new CustomEvent('resetbox', {
            detail: {
                message: 'true'
            }
        }));
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
        //fr

        var contact;
        if (!this.flag) {
            contact = this.value;
        }
        //fields[SUBJECT_FIELD.fieldApiName] = 'SR : '+selected.Type__c;
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[CASE_BUSINESSUNIT.fieldApiName] = this.primaryLOBValue;
        fields[SOURCE_FIELD.fieldApiName] = this.strSource;
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

    async handleConfirmClick(msg) {
        const result = await LightningConfirm.open({
            message: msg,
            variant: 'headerless',
            label: 'Duplicate Found !',
            // setting theme would have no effect
        });
    }



}