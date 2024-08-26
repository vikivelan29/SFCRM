import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import fetchAssets from '@salesforce/apex/ABSLI_LegacyViewController.getRelatedPolicyNames';
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
import getLegacyData from "@salesforce/apex/ABSLI_LegacyViewController.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const fields = [CLIENT_CODE_FIELD, LOB_FIELD];

export default class Absli_legacyCasesView extends LightningElement {
    @api recordId;
    @api apiName = 'ABSLI_Legacy_Case';
    @api payloadInfo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    legacyCaseData;
    data;
    startDate;
    endDate;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    options = '';
    statusCode;
    columns;
    errorMessage;
    lob;
    customerId;
    msdCaseNumber = '';
    startDateRequired = false;
    endDateRequired = false;
    @track requiredDateSelection = false;
    @track initialErrorMsg = 'Please select either Case Number or Policy.'

    label={
        errorMessage,
        pageSize
    };
    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;

    connectedCallback() {
        getColumns({ configName: 'ABSLI_Legacy_Case_View_Columns' })
            .then(result => {
                this.columns = [
                    {
                        type: "button", label: 'View Case', fixedWidth: 100, typeAttributes: {
                            label: 'View',
                            name: 'View',
                            title: 'View',
                            disabled: false,
                            value: 'view',
                            variant: 'neutral',
                        }
                    },
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
            })
            .catch(error => {
                console.error('Error in fetching columns:' + error.body.message);
                this.showNotification('Error', 'Error fetching data', 'Error');
            });

        this.fetchPolicy();
    }

    fetchPolicy() {
        fetchAssets({ accountId: this.recordId })
            .then(result => {
                this.options = result;
            })
            .catch(error => {
                console.error('Error in fetching policy names:' + error.body.message);
            })
    }

    fetchLegacyCases() {
        this.displayTable = false;
        this.displayError = false;
        this.data = null;

        this.customerId = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        this.lob = getFieldValue(this.account.data, LOB_FIELD);
        
        //if(this.atleastOneParameterSelected()){
            if (this.checkFieldValidity()) {
                this.disabled = true;
                this.isLoading = true;
                debugger;
                getLegacyData({
                    customerId: this.customerId, lanNumber: this.selectedAsset, startDate: this.startDate,
                    endDate: this.endDate, lob: this.lob, msdCaseNumber : this.msdCaseNumber
                }).then(result => {
                    console.log('Result=>:'+JSON.stringify(result));
                    debugger;
                    this.leagcyCaseData = result;
                    console.log('Result1 ==> ', result);
                    this.isLoading = false;
                    if (this.leagcyCaseData && this.leagcyCaseData.returnCode == '1' && this.leagcyCaseData.statusCode == 200) {
                        this.statusCode = this.leagcyCaseData.statusCode;
                        this.loaded = true;
                        this.displayTable = true;
                        this.data = this.leagcyCaseData.legacyCaseResponse;
                        this.disabled = false;
                    }
                    else if (this.leagcyCaseData && this.leagcyCaseData.statusCode != 0 && (this.leagcyCaseData.returnCode == '2' || this.leagcyCaseData.returnMessage != null)) {
                        console.log('@@@Erro');
                        this.displayError = true;
                        this.loaded = true;
                        this.errorMessage = this.leagcyCaseData.returnMessage;
                        this.disabled = false;
                        //this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                    }
                    else if (this.leagcyCaseData && this.leagcyCaseData.statusCode == 0) {
                        this.disabled = false;
                        this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                    }
                }).catch(error => {
                    debugger;
                    console.log('error ==> ', error);
                    this.showNotification("Error", this.label.errorMessage, 'error');
                    this.isLoading = false;
                    this.loaded = true;
                    this.disabled = false;
                })
    
            }
        //}
        //else{
        //    this.showNotification("Error", this.initialErrorMsg, 'error');
        //}

        
    }

    atleastOneParameterSelected(){
        let bAssetSelected = this.selectedAsset != null && this.selectedAsset != undefined && this.selectedAsset != '' ? true : false;
        let bCaseNumberSelected = this.msdCaseNumber != null && this.msdCaseNumber != undefined && this.msdCaseNumber != '' ? true : false;

        if(bAssetSelected || bCaseNumberSelected){
            return true;
        }
        return false;
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleChange(event) {

        this.selectedAsset = event.detail.value;
        if(this.selectedAsset != null && this.selectedAsset != undefined){
            this.startDateRequired = true;
            this.endDateRequired = true;
        }
        else{
            this.startDateRequired = false;
            this.endDateRequired = false;
        }
        console.log('this.v' + JSON.stringify(event.detail));
    }
    callRowAction(event) {
        debugger;
        //this.showChildTable = false;
     //   console.log('Hi>1'+JSON.stringify(event.detail));
        // reset var
        this.showChildTable = true;
        this.payloadInfo = null;
        let result = {};
        
        this.selectedRow = JSON.stringify(event.detail);

        console.log('Hi>1'+ this.selectedRow +'2@@ '+this.statusCode);
        result.statusCode= this.statusCode;
        result.payload = this.selectedRow;
        this.payloadInfo = result;

        setTimeout(() => {             
            this.template.querySelector('c-abfl_base_view_screen').callFunction();
        }, 200);
    }
    startDateChange(event)
    {
        if(!this.selectedAsset){
            this.endDateRequired = false;
        }
        this.startDate = event.target.value;
        if(this.startDate){
            this.endDateRequired = true;
        }
        console.log('The startDate selected is '+this.startDate );
    }

    endDateChange(event)
    {
        if(!this.selectedAsset){
            this.startDateRequired = false;
        }
        this.endDate = event.target.value;
        if(this.endDate){
            this.startDateRequired = true;
        }
        console.log('The endDate selected is '+this.endDate );
    }
    checkFieldValidity(){
        this.isLoading = false;
        let checkAllFieldsValid = true;
        checkAllFieldsValid = [
            ...this.template.querySelectorAll('.inpFieldCheckValidity'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        console.log('checkAllFieldsValid'+checkAllFieldsValid);
        return checkAllFieldsValid;
    }
    handleCaseInput(event){
        this.msdCaseNumber = event.target.value;
        console.log('The msdCaseNumber selected is '+this.msdCaseNumber );
    }

}