import { LightningElement, track, api, wire } from 'lwc';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import getLegacyData from "@salesforce/apex/ABCD_LegacyViewController.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class abcd_legacyCasesView extends LightningElement {
    @api apiName = 'ABCD_Legacy_Case';
    @api payloadInfo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    legacyCaseData;
    data;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    options = '';
    statusCode;
    columns;
    errorMessage;
    phone = '';
    email = '';
    @track requiredDateSelection = false;
    @track initialErrorMsg = 'Please select either Case Number or Policy.'
    @track showLegacy;
    @track selectedAccount;
    @track showSearchButton = false;
    startDate;
    endDate;
    startDateRequired = false;
    endDateRequired = false;

    
    label={
        errorMessage,
        pageSize
    };

    account;

    connectedCallback() {
        getColumns({ configName: 'ABCD_Legacy_Case_View_Columns' })
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

    }


    fetchLegacyCases() {
        this.displayTable = false;
        this.displayError = false;
        this.data = null;

        
        //if(this.atleastOneParameterSelected()){
            if (this.checkFieldValidity()) {
                this.disabled = true;
                this.isLoading = true;
                debugger;
                getLegacyData({
                    mobileNumber: this.phone, email: this.email, startDate: this.startDate,
                    endDate: this.endDate
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
                    else if(this.leagcyCaseData.statusCode != 200){
                        this.disabled = false;
                        this.showNotification("Error", 'Unexpected Error, please try again or contact your admin','error');
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
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    clearSelection(event){
        this.phone = '';
        this.email = '';
        this.showSearchButton = false;
        this.startDate='';
        this.endDate='';
        this.startDateRequired = false;
        this.endDateRequired = false;
        this.showChildTable = false;
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
            validateField(fieldType, fieldValue) {
                const inputElement = this.template.querySelector(`[data-id="${fieldType}Input"]`);
                inputElement.setCustomValidity('');
            
                let isValid = true;
                let errorMessage = '';
            
                if (fieldType === 'mobile') {
                    const regex = /^[0-9]{10}$/; // Matches exactly 10 digits
                    isValid = regex.test(fieldValue);
                    errorMessage = 'Invalid Mobile Number, 10 Digits are allowed';
                } else if (fieldType === 'email') {
                    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    isValid = regex.test(fieldValue);
                    errorMessage = 'Invalid Email Id';
                }
            
                if (fieldValue) {
                    if (!isValid) {
                        inputElement.setCustomValidity(errorMessage);
                    } else {
                        inputElement.setCustomValidity('');
                    }
                } else {
                    inputElement.setCustomValidity('');
                }
            
                inputElement.reportValidity();
                return isValid;
            }
            
            handleFieldChange(event) {
                const fieldType = event.target.dataset.id.replace('Input', '');
                const fieldValue = event.target.value;
            
                if (fieldType === 'mobile') {
                    this.phone = fieldValue;
                } else if (fieldType === 'email') {
                    this.email = fieldValue;
                }
            
                const isMobileValid = this.validateField('mobile', this.phone);
                const isEmailValid = this.validateField('email', this.email);
            
                this.showSearchButton = isMobileValid || isEmailValid;
            }

            get isSearchDisabled() {
                return !this.showSearchButton;
            }
}