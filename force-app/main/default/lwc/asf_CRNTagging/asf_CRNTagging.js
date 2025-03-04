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
import ABCD_BU from '@salesforce/label/c.ABCD_Business_Unit';
import ONEABC_BU from '@salesforce/label/c.ABCD_ONEABC_BU';
import ONEABC_Acc_Error_ABCD from '@salesforce/label/c.ONEABC_Acc_Error_ABCD_Customer';
import ONEABC_Acc_Error_Non_ABCD from '@salesforce/label/c.ONEABC_Acc_Error_Non_ABCD_Customer';
import ONEABC_Acc_Error_LOB from '@salesforce/label/c.ONEABC_Acc_Error_LOB_Customer';
import { lanLabels } from 'c/asf_ConstantUtility';


// VIRENDRA - BELOW IMPORTS ARE ADDED AS PART OF PROSPECT TAGGING REQUIREMENT PR970457-426
import CUSTOMERPROSPECTSEARCH from "./asf_CRNTagging.html";
import PROSPECTCREATION from "./asf_ProspectTagging.html";
import loggedInUserId from '@salesforce/user/Id';

import getForm from '@salesforce/apex/ASF_FieldSetController.getLOBSpecificForm';
import PROSPECT_BUSINESS_UNIT from '@salesforce/schema/Lead.Business_Unit__c';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import CASE_BUSINESS_UNIT from '@salesforce/schema/Case.Business_Unit__c';
import CASE_RECORDTYPE from '@salesforce/schema/Case.RecordType.Name';
import createProspectAndUpdCase from '@salesforce/apex/ASF_CaseUIController.CreateProspectAndUpdateOnCase';
import INSUFFICIENT_ACCESS_MSG from '@salesforce/label/c.Wellness_Insufficient_Access';//PR1030924-905
import CASE_ACCESS_ERROR from '@salesforce/label/c.Wellness_CaseComment_add_Err_Msg';//PR1030924-905
import ABML_BU from '@salesforce/label/c.ABML_BU'; //Added by EY
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
    label = {
        CASE_ACCESS_ERROR, //PR1030924-905
        INSUFFICIENT_ACCESS_MSG //PR1030924-905
    };
    caseBu;
    selectedRecBu = '';
    caseRecType = '';
    selectedCustomerType = '';

    @wire(getRecord, { recordId: loggedInUserId, fields: [UserBusinessUnit ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
            this.cardTitle = lanLabels[this.loggedInUserBusinessUnit]?.CUSTOMER_TAGGING_CARD_TITLE || lanLabels["DEFAULT"].CUSTOMER_TAGGING_CARD_TITLE;
            this.productSearchPlaceholder = lanLabels[this.loggedInUserBusinessUnit]?.PRODUCT_SEARCH_PLACEHOLDER || lanLabels["DEFAULT"].PRODUCT_SEARCH_PLACEHOLDER;
            this.selectLan = lanLabels[this.loggedInUserBusinessUnit]?.SELECT_PRODUCT || lanLabels["DEFAULT"].SELECT_PRODUCT;
            this.asstCols = lanLabels[this.loggedInUserBusinessUnit]?.ASSET_COLUMNS || lanLabels["DEFAULT"].ASSET_COLUMNS;
            this.accCols = lanLabels[this.loggedInUserBusinessUnit]?.ACCOUNT_COLUMNS || lanLabels["DEFAULT"].ACCOUNT_COLUMNS;
        } else if (error) {
            //this.error = error; 
        }
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ACCOUNT_CRN_FIELD, ASSET_FIELD, Case_SUPPLIEDEMAIL, CASE_BUSINESS_UNIT, CASE_RECORDTYPE]
    })
    CaseData({error, data}){
        if(data){
            this.caseBu = getFieldValue(data, CASE_BUSINESS_UNIT);
            this.accountCrn = getFieldValue(data, ACCOUNT_CRN_FIELD);
            this.FAId = getFieldValue(data, ASSET_FIELD);
            this.caseSuppliedEmail = getFieldValue(data, Case_SUPPLIEDEMAIL);
            this.caseRecType = getFieldValue(data, CASE_RECORDTYPE);
            console.log('acc id--'+this.caseRecType);
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
                this.selectedRecBu = this.accData[0].accBu;
                this.asstCols = lanLabels[this.selectedRecBu]?.ASSET_COLUMNS || lanLabels["DEFAULT"].ASSET_COLUMNS;
                this.selectedCustomerType = this.accData[0].objectType;
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
        const row = event.detail.selectedRows;
        this.selectedCustomer = row[0].recordId;
        this.selectedRecBu = row[0].accBu;
        this.asstCols = lanLabels[this.selectedRecBu]?.ASSET_COLUMNS || lanLabels["DEFAULT"].ASSET_COLUMNS;
        this.selectedCustomerType = row[0].objectType;
        this.showLANForCustomer = false;
        if(row[0].objectType == 'Customer' && this.loggedInUserBusinessUnit != ABML_BU){// Added by EY for ABML business unit
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
            }else{
                selectedFANum = this.selectedAsset.LAN__c;
            }
        }
        
        if (this.selectedCustomer) {

            const inpArg = new Map();
            // VIRENDRA - ADDED CHECK TO FIND OUT IF THE CASE IF ABCD CASE AND CUSTOMER TAGGING IS DONE FOR NON-ABCD CUSTOMER.
            /* SCENARIO 1 - WHEN AGE
            */
            if(this.loggedInUserBusinessUnit == ABCD_BU){
                if(this.caseRecType != 'Framework'){
                    if(this.caseBu == ABCD_BU && this.selectedRecBu != ABCD_BU){
                        inpArg['customerBu'] = ONEABC_BU;
                    }
                    else if(this.caseBu == ONEABC_BU && this.selectedRecBu == ABCD_BU){
                        inpArg['customerBu'] = ABCD_BU;
                    }
                }else if(this.caseRecType === 'Framework'){
                    if(this.caseBu == ABCD_BU && this.selectedRecBu != ABCD_BU){
                        this.showError('error', 'Error Occured', ONEABC_Acc_Error_ABCD);
                        return;
                    }
                    else if(this.caseBu == ONEABC_BU && (this.selectedRecBu == ABCD_BU && this.selectedCustomerType != 'Prospect')){
                        this.showError('error', 'Error Occured', ONEABC_Acc_Error_Non_ABCD);
                        return;
                    }
                }
                if(this.caseBu != ABCD_BU && this.caseBu != ONEABC_BU){
                    this.showError('error', 'Error Occured', ONEABC_Acc_Error_LOB);
                    return;
                }
                /*else if(this.caseBu != 'ABCD' && this.caseBu !='ONEABC' && this.caseBu != this.selectedRecBu){
                    inpArg['customerBu'] = this.selectedRecBu;
                }*/
            }
            //inpArg['customerBu'] = this.selectedRecBu;
            let strInpArg = JSON.stringify(inpArg);

            updateCRN({
                accountId: this.selectedCustomer,
                assetId: selectedAsstId,
                caseId: this.recordId,
                faNumber: selectedFANum,
                reqFromRecat: false,
                inpArg: strInpArg
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
                    let errorMessage = reduceErrors(error)[0];
                    if(errorMessage) {
                        if(errorMessage.indexOf(this.label.INSUFFICIENT_ACCESS_MSG) != -1){
                            errorMessage = this.label.CASE_ACCESS_ERROR; //PR1030924-905
                        }
                        this.showError("error", "Error ", errorMessage);
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
        this.dupeLead=[];
        this.showDupeList=false;
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
}