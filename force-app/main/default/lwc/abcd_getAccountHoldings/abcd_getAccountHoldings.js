import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getAccountHoldings from '@salesforce/apex/ABCD_GetAccountHoldingsController.getAccountHoldings';
import getClientCode from '@salesforce/apex/ABCD_GetAccountHoldingsController.getClientCode';
import { FUNCTION_OPTIONS } from './functionOptions';
//import { RefreshEvent } from 'lightning/refresh'; 
//import { fireEvent, fireEventNoPageRef, registerListener } from 'c/asf_pubsub'; // Virendra - Instead of LMS moving to pubsub

export default class abcd_getAccuontHolding extends LightningElement {
    @api recordId;
    @track selectedFunction = '';
    @track functionsOptions = FUNCTION_OPTIONS;
    @track dontShowGetholdings = true;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track data;
    @track showFetchResponse = false;
    @api fieldNameToSearch = '';
    @track apifetchError = false;
    @track prospectError = false;
    @track apiFetchErroText = 'Please proceed manully entering data.'
    @track prospectErrorText = 'Cannot retrieve Account holdings for prospect. Select a Function to accept.'
    @track showAcceptBtn = false;
    @track clientCode = '';
    @track accountData;
    @track columns = [
        { label: 'Holding Account #', fieldName: 'id', type: 'text' }, 
    ];
    @track selectedAccountHolding = '';
    @track disableInput = false;
    @track holdingNumber = '';
    @track apiReturnedNone = false;
    @track disableAccountHolding = false;
    

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
            if(this.clientCode === '' || this.clientCode === null || this.clientCode === undefined){
                this.dontShowGetholdings = true;
                this.prospectError = true;
            }
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
                    if (result.holdingIDs.length === 0) {  
                        this.apiReturnedNone = true; 
                        this.disableInput = false;
                        this.showToast({
                            title: "No Holdings Found",
                            message: "No account holdings available for the selected function. Please proceed manually entering data.",
                            variant: "warning",
                        });
                    } else {
                        this.showToast({
                            title: "Success",
                            message: "Account Holdings Fetched Successfully",
                            variant: "success",
                        });
                        this.accountData = result.holdingIDs.map((id) => ({ id }));
                        this.disableInput = true;
                        this.apifetchError = false;
                    }
                }    
                else{
                    this.apiFetchErroText = 'Please proceed manully entering data.'
                    this.apifetchError =true;
                    this.apiFetchErroText = result.errorMessage + ' ' + this.apiFetchErroText;
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
        let selectedFunctionLabel = this.functionsOptions.find(option => option.value === this.selectedFunction)?.label || '';

        debugger
        if(this.selectedAccountHolding){
            propConfirmedField.FieldAPINAme = 'Account_Holding__c';
            propConfirmedField.fieldValue = this.selectedAccountHolding;
            propConfirmedField.status = 'Success';
        }else{
            propConfirmedField.FieldAPINAme = 'Account_Holding__c';
            propConfirmedField.fieldValue = this.holdingNumber;
            propConfirmedField.status = 'Success';
        }
        
        arr_fieldDetails.push(propConfirmedField);
        
        selectedFunction.FieldAPINAme = 'Function__c';
        selectedFunction.fieldValue = selectedFunctionLabel;
        selectedFunction.status = 'Success';
        arr_fieldDetails.push(selectedFunction);

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
        if(this.selectedFunction != '' && this.selectedFunction != 'EC' && this.selectedFunction != 'AP'){
           if(this.clientCode === '' || this.clientCode === null || this.clientCode === undefined){
                this.dontShowGetholdings = true;
                this.prospectError = true;
                this.showAcceptBtn = true;
            }else{
                this.dontShowGetholdings = false;
            }
        }else if(this.selectedFunction == 'EC' || this.selectedFunction == 'AP'){
                this.dontShowGetholdings = true;
                this.apiReturnedNone = true;
                this.showAcceptBtn = true;
                this.holdingNumber = this.clientCode;
                this.disableAccountHolding = true;
        }
    }
    
    cancelConfirmFieldPopup(event) {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }
    
    get showManualInput() {
        return this.apifetchError || this.apiReturnedNone;
    }
    
    
}