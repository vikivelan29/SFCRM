import { LightningElement, track, api, wire } from 'lwc';
import getMatchingAccount from '@salesforce/apex/ASF_CaseUIController.getMatchingAccount';
import getMatchingContacts from '@salesforce/apex/ASF_CaseUIController.getMatchingContacts';
import updateCRN from '@salesforce/apex/ASF_CaseUIController.updateCRN';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import ACCOUNT_CRN_FIELD from '@salesforce/schema/Case.Client_Code__c';
import ASSET_FIELD from '@salesforce/schema/Case.AssetId';
import noUpdate from '@salesforce/label/c.ASF_No_DML_Access';


export default class Asf_CRNTagging extends LightningElement {
    @track accountOpts
    @track accountVal
    @track inpValue;
    selectedCustomer;
    selectedAsset;
    @api recordId;
    initialRecords;
    inpValueA;
    preSelectedRows = [];
    preSelectedAsset = [];
    prestdAcctId;
    noUpdate = noUpdate;
        accountCrn;
    FAId;

    asstCols = [{
        label: 'Id',
        fieldName: 'Id',
        type: 'text',
        fixedWidth: 1,
        hideLabel: true,
        hideDefaultActions: true
    },
    {
        label: 'Name',
        fieldName: 'Name',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Product Code',
        fieldName: 'Product_Code__c',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'LAN Number',
        fieldName: 'LAN__c',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Disbursal Amount',
        fieldName: 'Disbursed_Amount__c',
        type: 'currency',
        initialWidth: 180
    },
    {
        label: 'Loan Disbursement Status',
        fieldName: 'Loan_Disbursement_Status__c',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Loan Start Date',
        fieldName: 'Loan_Start_Date__c',
        type: 'date',
        initialWidth: 180
    },
    {
        label: 'Loan End Date',
        fieldName: 'Loan_End_Date__c',
        type: 'date',
        initialWidth: 180
    }
    ]

    accCols = [{
        label: 'Id',
        fieldName: 'recordId',
        type: 'text',
        fixedWidth: 1,
        hideLabel: true,
        hideDefaultActions: true
    },
    {
        label: 'Customer Name',
        fieldName: 'name',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Email ID',
        fieldName: 'emailId',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Mobile Number',
        fieldName: 'mobile',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Client Code',
        fieldName: 'clientCode',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'PAN Number',
        fieldName: 'pan',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Type',
        fieldName: 'objectType',
        type: 'text',
        initialWidth: 180
    }
    ]
    asstData;
    accData;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ACCOUNT_CRN_FIELD, ASSET_FIELD]
    })
    CaseData({error, data}){
        if(data){
            this.accountCrn = getFieldValue(data, ACCOUNT_CRN_FIELD);
            this.FAId = getFieldValue(data, ASSET_FIELD);
                    } else if(error){
            console.log(error);
        }
    };

    @wire(getMatchingAccount, {
        userInp: '$accountCrn',
        accPreSelected: true
    })
    wiredAccounts({
        error,
        data
    }) {
        if (data) {
            this.accData = data;
            if(data !=null){
                let my_ids = [];
                my_ids.push(this.accData[0].recordId);
                this.preSelectedRows = my_ids;
                this.showLANForCustomer = true;
                this.prestdAcctId = this.accData[0].recordId;
                this.selectedCustomer = this.prestdAcctId;
                //this.getAssetOnLoad(this.accData[0].recordId);
            }

        } else if (error) {
            this.error = error;
            console.log('error--'+JSON.stringify(error));
        }
    }

    @wire(getMatchingContacts, {
        accountId: '$prestdAcctId'
    })
    wiredAccounts1({
        error,
        data
    }) {
        if (data) {
                        this.asstData = data.asstList;
            this.initialRecords = data.asstList;
            this.selectedCustomer = this.prestdAcctId;

            let my_ids1 = [];
            my_ids1.push(this.FAId);
            this.preSelectedAsset = my_ids1;
        } else if (error) {
            this.error = error;
            console.log('error--'+JSON.stringify(error));
        }
    } 

    valChange(event) {
        this.inpValue = event.target.value;
        if (this.inpValue && this.inpValue.length >= 2) {
            this.preSelectedRows = [];
            this.prestdAcctId = '';
            this.asstData = [];
            this.SearchAccountHandler(event);
        } else if (this.inpValue.length == 0) {
            this.preSelectedRows = [];
            this.prestdAcctId = '';
            this.asstData = [];
            this.inpValue = this.accountCrn;
            this.SearchAccountHandler(event);
        }
    }

    SearchAccountHandler(event) {
        getMatchingAccount({
            userInp: this.inpValue,
            accPreSelected: false
        })
            .then(result => {
                this.accData = result;
                            })
            .catch(error => {
            });
    }

    handleAccAction(event) {
        const row = event.detail.selectedRows;
        this.selectedCustomer = row[0].recordId;
        this.showLANForCustomer = false;
        if(row[0].objectType == 'Customer'){
            // SHOW LAN ONLY WHEN OBJECTTYPE EQUALS CUSTOMER.
            this.showLANForCustomer = true;
        }

        getMatchingContacts({
            accountId: this.selectedCustomer
        })
            .then(result => {
                this.asstData = result.asstList;
                this.initialRecords = result.asstList;
                            })
            .catch(error => {
            });
    }
    handleAsstAction(event){
        const row = event.detail.selectedRows;
        this.selectedAsset = row[0];
    }

    handleclick(event) {
         /*let conTable = this.template.querySelector('[data-id="conTable"]');
        let asstTable = this.template.querySelector('[data-id="asstTable"]');
        let selectedAsst = undefined;
        if(asstTable != undefined && asstTable != null){
            if(asstTable.getSelectedRows()>0){
                selectedAsst = JSON.stringify(asstTable.getSelectedRows()).length > 2 ? asstTable.getSelectedRows() : undefined;
            }
            
        } */
        let selectedAsstId = null;
        let selectedFANum = 'NA';
        if (this.selectedAsset != undefined) {
            selectedAsstId = this.selectedAsset.Id;
            selectedFANum = this.selectedAsset.LAN__c;
        }

        if (this.selectedCustomer) {
            updateCRN({
                accountId: this.selectedCustomer,
                assetId: selectedAsstId,
                caseId: this.recordId,
                faNumber: selectedFANum
            })
                .then(result => {
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'SR updated',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.dispatchEvent(new CloseActionScreenEvent());

                    getRecordNotifyChange([{ recordId: this.recordId }]);

                    setTimeout(() => {
                        eval("$A.get('e.force:refreshView').fire();");
                    }, 1000);
                })
                .catch(error => {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: this.noUpdate,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                });
        } else {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please select an Customer',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }

    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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