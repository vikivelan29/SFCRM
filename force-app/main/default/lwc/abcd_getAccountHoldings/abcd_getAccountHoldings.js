import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getAccountHoldings from '@salesforce/apex/ABCD_GetAccountHoldingsController.getAccountHoldings';
import getClientCode from '@salesforce/apex/ABCD_GetAccountHoldingsController.getClientCode';
//import { RefreshEvent } from 'lightning/refresh'; 
//import { fireEvent, fireEventNoPageRef, registerListener } from 'c/asf_pubsub'; // Virendra - Instead of LMS moving to pubsub

export default class abcd_getAccuontHolding extends LightningElement {
    @api recordId;
    @track selectedFunction = '';
    @track functionsOptions = [
        {label : 'Health Insurance',value: 'HI'},
        {label : 'Life Insurance',value: 'LI'},
        {label : 'Motor Insurance',value: 'MI'},
        {label : 'Portfolio',value: 'PC'},
        {label : 'Credit Score',value: 'CS'},
        {label : 'Mutual Fund',value: 'MF'},
        {label : 'Digigold ',value: 'DG'},
        {label : 'Demat',value: 'DM'},
        {label : 'Deposit ',value: 'DS'},
        {label : 'Buisness Loan',value: 'BL'},
        {label : 'House Finance Loan',value: 'HFL'},
        {label : 'DHE ',value: 'DHE'}
    ];
    @track dontShowGetholdings = true;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track data;
    @track showFetchResponse = false;
    @api fieldNameToSearch = '';
    @track apifetchError = false;
    @track apiFetchErroText = 'External Service is not responding. Please proceed manully entering data.'
    @track showAcceptBtn = false;
    @track clientCode = '';
    @track accountData;
    @track columns = [
        { label: 'Holding Account #', fieldName: 'id', type: 'text' }, 
    ];
    @track selectedAccountHolding = '';
    @track disableInput = false;
    @track holdingNumber = '';
    

    @wire(CurrentPageReference) pageRef;

    showToast(e){
        this.dispatchEvent(new ShowToastEvent(e));        
    }

    handleDOBChange(event){
        this.clientDOB = event.detail.value;
    }

    connectedCallback(){
        this.fetchClientCode();
    }
    async fetchClientCode() {
        try {
            const result = await getClientCode({ caseId: this.recordId });
            this.clientCode = result;
        } catch (error) {
            console.error('Error fetching Client_Code__c:', error);
        }
    }
    closeParentPopup() {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }

    handleFetchDetails(event){
        event.preventDefault();
        this.invokegetAccountHoldingCallout();
    }

    handleInputChange(event) {
        this.holdingNumber = event.target.value;
        if(this.holdingNumber){
            this.showAcceptBtn = true;
        }
    }
    async invokegetAccountHoldingCallout() {
        debugger;
            await getAccountHoldings({ customerId: this.clientCode, lob: this.selectedFunction})
            .then((result) => {
                if (result.isSuccess) {
                    this.showToast({
                        title: "Success",
                        message: "Account Holdings Fetched Successfully",
                        variant: "success",
                    });
                    this.accountData = result.holdingIDs.map((id) => ({ id }));
                    this.disableInput = true;
                    this.apifetchError = false;
                }
                else{
                    this.apifetchError =true;
                    this.disableInput = false;
                    this.showToast({
                        title: "Error",
                        message: result.errorMessage,
                        variant: "error",
                    });
                }
            })
            .catch((error) => {
                console.log(error);
            })

        
    }
    
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows; 
        debugger
        console.log('Selected Rows:', JSON.stringify(selectedRows)); 
        console.log('First Selected Row:', JSON.stringify(selectedRows[0].id)); 
        if (selectedRows.length > 0) {
            this.selectedAccountHolding = selectedRows[0].id;
            this.showAcceptBtn = true; 
        } else {
            this.selectedAccountHolding = null; 
            this.showAcceptBtn = false;
        }
    }

    handleUpdateFromFieldPopUp(event){
        event.preventDefault();

        let arr_fieldDetails = [];
        let propConfirmedField = {};
        let selectedFunction = {};
        debugger
        if(this.selectedAccountHolding){
            propConfirmedField.FieldAPINAme = this.fieldNameToSearch;
            propConfirmedField.fieldValue = this.selectedAccountHolding;
            propConfirmedField.status = 'Success';
        }else{
            propConfirmedField.FieldAPINAme = this.fieldNameToSearch;
            propConfirmedField.fieldValue = this.holdingNumber;
            propConfirmedField.status = 'Success';
        }
        
        arr_fieldDetails.push(propConfirmedField);
        
        selectedFunction.FieldAPINAme = 'Function__c';
        selectedFunction.fieldValue = this.selectedFunction;
        selectedFunction.status = 'Success';
        arr_fieldDetails.push(selectedFunction);
        console.log('arr_fields',arr_fieldDetails);
        this.dispatchEvent(new CustomEvent("case360fieldextn",
            {
                detail: {
                    arr_fieldDetails
                }
            }
        ));
        this.cancelConfirmFieldPopup();

    }
    handleFunctionChange(event){
        this.selectedFunction = this.template.querySelector("lightning-combobox").value;
        if(this.selectedFunction != ''){
            this.dontShowGetholdings = false;
        } 
    }
    
    cancelConfirmFieldPopup(event) {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }
    
}