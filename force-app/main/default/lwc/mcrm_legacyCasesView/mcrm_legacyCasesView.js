import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import fetchAssets from '@salesforce/apex/MCRM_LegacyViewController.getRelatedContracts';
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
import getLegacyData from "@salesforce/apex/MCRM_LegacyViewController.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import searchMsg from '@salesforce/label/c.MCRM_Legacy_Search';
import noResults from '@salesforce/label/c.MCRM_Legacy_NoResults';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const fields = [CLIENT_CODE_FIELD, LOB_FIELD];

export default class mcrm_legacyCasesView extends LightningElement {
    @api recordId;
    @api apiName = 'MCRM_Legacy_Case';
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
    @track options = [];
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
    _isSearched=false;

    label={
        errorMessage,
        pageSize,
        searchMsg,
        noResults
    };
    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;

    connectedCallback() {
        getColumns({ configName: 'MCRM_LegacyCaseView' })
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

        this.fetchContracts();
    }

    fetchContracts() {
        fetchAssets({ accountId: this.recordId })
            .then(result => {
                let inarray=[];
                inarray.push({ label: 'Please Select', value: '' }); // Empty option
                inarray.push(...result);
                this.options = inarray;
            })
            .catch(error => {
                console.error('Error in fetching Contracts:' + error?.body?.message);
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
                    // debugger;
                    this.leagcyCaseData = result;
                    console.log('Result1 ==> ', result);
                    this.isLoading = false;
                    if (this.leagcyCaseData && this.leagcyCaseData.returnCode == '1' && this.leagcyCaseData.statusCode == 200) {
                        this.statusCode = this.leagcyCaseData.statusCode;
                        this.loaded = true;
                        this.displayTable = true;
                        this.data = this.leagcyCaseData.legacyCaseResponse;
                        console.log('***data ==> '+ JSON.stringify(this.data));
                        this.adjustDates(this.data);
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
                    else{
                        this.disabled = false;
                        this.showNotification("Error", this.label.errorMessage, 'error');
                    }
                    this._isSearched=true;
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
        /*if(this.selectedAsset != null && this.selectedAsset != undefined){
            this.startDateRequired = true;
            this.endDateRequired = true;
        }
        else{
            this.startDateRequired = false;
            this.endDateRequired = false;
        }*/
        console.log('this.v' + JSON.stringify(event.detail));
    }

    clearSelection(event){
        this.msdCaseNumber = '';
        this.selectedAsset = '';
        this.startDate='';
        this.endDate='';
        this.startDateRequired = false;
        this.endDateRequired = false;
        this._isSearched=false;
        this.displayTable = false;
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

    get isDisplayTable(){
        return (this.displayTable && this.data.length>0);
    }

    get noDataMessage(){
        return this._isSearched==true?this.label.noResults:this.label.searchMsg;
    }

    adjustDates(data){
        data.forEach(rec=>{
            if((rec['CaseResolvedOn']) && this.isValidDate(rec['CaseResolvedOn'])){
                rec['CaseResolvedOn'] = this.convertToIST(rec['CaseResolvedOn']);
            }
            if((rec['CaseCreatedOn']) && this.isValidDate(rec['CaseCreatedOn'])){
                rec['CaseCreatedOn'] = this.convertToIST(rec['CaseCreatedOn']);
            }
        });
    }

    isValidDate(value) {
        // Check if value is an instance of Date
        const date = new Date(value);
        // Check if the Date object is valid
        return !isNaN(date.getTime());
    }

    convertToIST(dateString) {
        // Parse the input date string as a Date object
        const date = new Date(dateString);
    
        // Convert the date to IST timezone by adding 5 hours and 30 minutes
        const IST_OFFSET = 5 * 60 + 30; // IST is GMT+5:30
        const gmtOffset = date.getTimezoneOffset(); // Timezone offset in minutes
        const istTime = new Date(date.getTime() + (IST_OFFSET - gmtOffset) * 60000);
    
        // Extract day, month, year, hours, minutes, and seconds
        const day = istTime.getDate().toString().padStart(2, '0');
        const month = (istTime.getMonth() + 1).toString().padStart(2, '0'); // Months are 0-indexed
        const year = istTime.getFullYear();
        const hours = istTime.getHours().toString().padStart(2, '0');
        const minutes = istTime.getMinutes().toString().padStart(2, '0');
        const seconds = istTime.getSeconds().toString().padStart(2, '0');
    
        // Return the formatted date and time as dd/mm/yyyy hh:mm:ss
        return `${day}-${month}-${year} ${hours}:${minutes}`;
    }

}