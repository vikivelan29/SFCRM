import { LightningElement, track, api, wire } from 'lwc';
import getMatchingAccount from '@salesforce/apex/ASF_CaseUIController.getMatchingAccount';
import getMatchingContacts from '@salesforce/apex/ASF_CaseUIController.getMatchingContacts';
import updateCRN from '@salesforce/apex/ASF_CaseUIController.updateCRN';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import ACCOUNT_CRN_FIELD from '@salesforce/schema/Case.Client_Code__c';
import ASSET_FIELD from '@salesforce/schema/Case.AssetId';
import Case_SUPPLIEDEMAIL from '@salesforce/schema/Case.SuppliedEmail';
import noUpdate from '@salesforce/label/c.ASF_No_DML_Access';
import { reduceErrors } from 'c/asf_ldsUtils';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU';
import WellnessBU from '@salesforce/label/c.Wellness_BU';
import { lanLabels } from 'c/asf_ConstantUtility';

// VIRENDRA - BELOW IMPORTS ARE ADDED AS PART OF PROSPECT TAGGING REQUIREMENT PR970457-426
import CUSTOMERPROSPECTSEARCH from "./asf_CRNTagging.html";
import PROSPECTCREATION from "./asf_ProspectTagging.html";
import loggedInUserId from '@salesforce/user/Id';

import getForm from '@salesforce/apex/ASF_FieldSetController.getLOBSpecificForm';
import PROSPECT_BUSINESS_UNIT from '@salesforce/schema/Lead.Business_Unit__c';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import createProspectAndUpdCase from '@salesforce/apex/ASF_CaseUIController.CreateProspectAndUpdateOnCase';
// VIRENDRA - PROSPECT TAGGING IMPORTS ENDS HERE.

export default class Asf_CRNTagging extends LightningElement {
    @track accountOpts
    @track accountVal
    @track inpValue;
    selectedCustomer;
    selectedAsset;
    @api recordId;
    initialRecords;
    inpValueA;
    @track preSelectedRows = undefined;
    @track preSelectedAsset = undefined;
    prestdAcctId;
    noUpdate = noUpdate;
    @track showLANForCustomer = false;
    @track showProspectCreation = false;
    fields;
    error;
    @track loggedInUserBusinessUnit = '';
    @track dupeLead=[];
    @track showDupeList=false;
    @track selectedCustomerData;
    disableCreateBtn = false;
    isDisabledUpdateCaseButton = true;
    accountCrn;
    FAId;
    caseSuppliedEmail;
    productSearchPlaceholder;
    cardTitle;
    selectLan;
    asstCols;
    
    accCols;

    dupeLeadCols = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'MobilePhone', fieldName: 'MobilePhone', type: 'text' }
    ]
    asstData;
    accData;


    @wire(getRecord, { recordId: loggedInUserId, fields: [UserBusinessUnit ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
            this.cardTitle = lanLabels[this.loggedInUserBusinessUnit].CUSTOMER_TAGGING_CARD_TITLE != null? lanLabels[this.loggedInUserBusinessUnit].CUSTOMER_TAGGING_CARD_TITLE : lanLabels["DEFAULT"].CUSTOMER_TAGGING_CARD_TITLE;
            this.productSearchPlaceholder = lanLabels[this.loggedInUserBusinessUnit].PRODUCT_SEARCH_PLACEHOLDER != null? lanLabels[this.loggedInUserBusinessUnit].PRODUCT_SEARCH_PLACEHOLDER : lanLabels["DEFAULT"].PRODUCT_SEARCH_PLACEHOLDER;
            this.selectLan = lanLabels[this.loggedInUserBusinessUnit].SELECT_PRODUCT != null? lanLabels[this.loggedInUserBusinessUnit].SELECT_PRODUCT : lanLabels["DEFAULT"].SELECT_PRODUCT;
            this.asstCols = lanLabels[this.loggedInUserBusinessUnit].ASSET_COLUMNS != null? lanLabels[this.loggedInUserBusinessUnit].ASSET_COLUMNS : lanLabels["DEFAULT"].ASSET_COLUMNS;
            this.accCols = lanLabels[this.loggedInUserBusinessUnit].ACCOUNT_COLUMNS != null? lanLabels[this.loggedInUserBusinessUnit].ACCOUNT_COLUMNS : lanLabels["DEFAULT"].ACCOUNT_COLUMNS;
        } else if (error) {
            //this.error = error; 
        }
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ACCOUNT_CRN_FIELD, ASSET_FIELD, Case_SUPPLIEDEMAIL]
    })
    CaseData({error, data}){
        if(data){
            this.accountCrn = getFieldValue(data, ACCOUNT_CRN_FIELD);
            this.FAId = getFieldValue(data, ASSET_FIELD);
            this.caseSuppliedEmail = getFieldValue(data, Case_SUPPLIEDEMAIL);
            console.log('acc id--'+this.accountCrn);
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
                console.log('pre selected rows--'+this.preSelectedRows);
                this.showLANForCustomer = true;
                this.prestdAcctId = this.accData[0].recordId;
                this.selectedCustomer = this.prestdAcctId;
                //this.getAssetOnLoad(this.accData[0].recordId);
                console.log('acc data--'+JSON.stringify(this.accData));
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
            if(this.FAId) {
                my_ids1.push(this.FAId);
            }
            this.preSelectedAsset = my_ids1;
            console.log('con data--'+JSON.stringify(data));
        } else if (error) {
            this.error = error;
            console.log('error--'+JSON.stringify(error));
        }
    }

    valChange(event) {
        this.isDisabledUpdateCaseButton = true;
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
                console.log('adc data--'+JSON.stringify(this.accData));
            })
            .catch(error => {
            });
    }

    handleAccAction(event) {
        this.isDisabledUpdateCaseButton = false;
        const row = event.detail.selectedRows;
        this.selectedCustomerData = row[0];
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
                console.log('asset data--'+JSON.stringify(this.asstData));
            })
            .catch(error => {
            });
    }
    handleAsstAction(event){
        const row = event.detail.selectedRows;
        this.selectedAsset = row[0];
        console.log('sekectd asset--'+JSON.stringify(this.selectedAsset));
        
        if(this.selectedAsset) {
            this.isDisabledUpdateCaseButton = false;
        }
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
            if(this.loggedInUserBusinessUnit === ABSLI_BU || this.loggedInUserBusinessUnit === ABSLIG_BU){
                selectedFANum = this.selectedAsset.Policy_No__c;
            }else if(this.loggedInUserBusinessUnit === WellnessBU){
                selectedFANum = this.selectedAsset.ContractId__c;
            }else{
                selectedFANum = this.selectedAsset.LAN__c;
            }
        }
        
        if (this.selectedCustomer) {
            updateCRN({
                accountId: this.selectedCustomer,
                assetId: selectedAsstId,
                caseId: this.recordId,
                faNumber: selectedFANum,
                reqFromRecat: false
            })
                .then(result => {
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Case updated',
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
                    let getErrMsg = reduceErrors(error)[0]

                    if(getErrMsg) {
                        this.showError("error", "Error ", getErrMsg);
                    } else {
                        const event = new ShowToastEvent({
                            title: 'Error',
                            message: this.noUpdate,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);
                    }
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

    async handleProspectCreation(event){
        // THIS METHOD IS USED TO SHOW PROSPECT SCREEN.
        this.showProspectCreation = true;

        await getForm({ recordId: null, objectName: "Lead", fieldSetName: null,salesProspect:false })
            .then(result => {
                console.log('Data:' + JSON.stringify(result));
                if (result) {
                    this.fields = result.Fields;
                    this.error = undefined;
                    this.prePopulateEmailFieldOfLead();
                }
            }).catch(error => {
                console.log(error);
                this.error = error;
            });
    }

    prePopulateEmailFieldOfLead() {
        
        if(this.loggedInUserBusinessUnit === ABSLIG_BU) {

            for(let fld of this.fields) {
                if(fld.FieldName === "Email") {
                    fld.value = this.caseSuppliedEmail ?? "";
                }
            }
        }
    }

    /* ADDED BY - VIRENDRA
       REQUIREMENT - TO RENDER THE PROSPECT CREATION FORM WHEN USER CLICKS ON CREATE PROSPECT BUTTON.
    */
    render() {
        return this.showProspectCreation ? PROSPECTCREATION : CUSTOMERPROSPECTSEARCH;
      }
      /* ADDED BY - VIRENDRA
         REQUIREMENT - TO CREATE THE PROSPECT RECORD (LOB SPECIFIC) WHEN CLICKED ON CREATE PROSPECT BUTTON ON PROSPECT FORM.
      */
      async handleLeadSubmit(event){
        event.preventDefault();
        let leadFields = [...this.template.querySelectorAll('lightning-input-field')]
        let fieldsVar = leadFields.map((field)=>[field.fieldName,field.value]);
        if (!this.isInputValid()) {
            // Stay on same page if lightning-text field is required and is not populated with any value.
            return;
        }
        const fields = {};
        let leadRecord = Object.fromEntries([...fieldsVar, ['sobjectType', 'Lead']]);
        let caseRecord = {};
        leadRecord[PROSPECT_BUSINESS_UNIT.fieldApiName] = this.loggedInUserBusinessUnit;
        caseRecord["sobjectType"] = "Case";
        caseRecord["Id"] = this.recordId;

        if(this.loggedInUserBusinessUnit === "ABSLIG") {
            leadRecord["LastName"] = leadRecord?.Company ?? "default last name";
        }

        /* PASS CASERECORD WITH ID AND PROSPECTRECORD TO BE CREATED.
           IF THERE IS A DUPLICATE SERVICE PROSPECT ALREADY FOUND IN THE SYSTEM, IT WILL BE RETURNED
           AND SHOWN IN DATA-TABLE. USER CAN CLICK ON PROSPECT NAME HYPERLINK TO NAVIGATE TO EXISTING PROSPECT.
        */
        createProspectAndUpdCase({ caseToInsert: caseRecord, prospectRecord: leadRecord })
            .then(result =>{
                if(result.DuplicateLead != null && result.DuplicateLead != undefined){
                    this.dupeLead.push(JSON.parse(JSON.stringify(result.DuplicateLead)));
                    if(this.dupeLead != null && this.dupeLead != undefined && this.dupeLead.length > 0){
                        this.dupeLead[0].redirectLink =  '/' + this.dupeLead[0].Id;
                        this.showDupeList=true;
                        this.disableCreateBtn = true;
                        //this.loaded = true;
                        return;
                    }
                }
                this.caseRecordId = result.Case.Id;
                /*this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.caseRecordId,
                        actionName: 'view'
                    },
                    state: {
                        mode: 'edit'
                    }
                });*/
                this.dispatchEvent(new CloseActionScreenEvent());

                getRecordNotifyChange([{ recordId: this.recordId }]);

                    setTimeout(() => {
                        eval("$A.get('e.force:refreshView').fire();");
                    }, 1000);
            })
            .catch(error => {
                if(JSON.stringify(error).includes('INSUFFICIENT_ACCESS_OR_READONLY')){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: ' You dont have access to make changes as you are not the owner of the case.',
                            variant: 'error',
                        }),
                    );      
                }  
                else{
                    this.showError('error', 'Error occured', error);
                } 
                console.log('@@@ERRORJSON - '+JSON.stringify(error));

            });




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
    handleBack(event){
        this.showProspectCreation = false;
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

    // VIRENDRA - PROSPECT CREATION REQUIREMENT ENDS HERE.

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
