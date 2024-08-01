import { LightningElement, api, track } from 'lwc';
import { countryCodeOptions } from './countryCodeOptions';

export default class absli_reconfirminput extends LightningElement {
    @api ccfield;
    @track originalTextValue = '';
    @track confirmTextValue = '';
    @track bConfirmationTextNotMatching = true;
    @api fieldNameToSearch = '';
    @track MICR_CODE = '000000000';
    @api recordId;
    @track IFSC_Code = '';
    @track countryCodeVisibilty = false;
    options = [];
    @track isMobileNumberError = false;
    @track selectedCountryCode;
    @track isInvalidMobileNumberError = false;

    connectedCallback(){
        console.log('this in connectedcallback',JSON.stringify(this.recordId));
        if(this.fieldNameToSearch === 'Mobile_Number__c'){
           this.countryCodeVisibilty = true;
        }
        this.options = countryCodeOptions;
    }
    validateMobileNumberCharacters(number) {
        const regex = /^[0-9]+$/;
        return regex.test(number);
    }
    mobileNumberValidation(){
        if (this.originalTextValue && !this.validateMobileNumberCharacters(this.originalTextValue)) {
            this.isInvalidMobileNumberError = true;
        }else if (this.confirmTextValue && !this.validateMobileNumberCharacters(this.confirmTextValue)) {
            this.isInvalidMobileNumberError = true;
        }else{
            this.isInvalidMobileNumberError = false;
        }      
        if (this.selectedCountryCode === '91' && this.originalTextValue && this.originalTextValue.length != 10) {
            this.isMobileNumberError = true;
        } else if(this.selectedCountryCode !== '91' && this.originalTextValue && this.originalTextValue.length != 15){
                this.isMobileNumberError = true;
        }else {
            this.isMobileNumberError = false;
        }
    }
    handleOriginalTextChange(event) {
        this.originalTextValue = event.target.value;
        this.mobileNumberValidation();
    
        this.confirmationCheck();
    }
    handleConfirmTextChange(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        this.mobileNumberValidation();
        this.confirmationCheck();
    }
    varifyConfirmFieldPopup(event) {
        if (this.confirmTextValue == this.originalTextValue && !this.isMobileNumberError) {
            event.preventDefault();

            let arr_fieldDetails = [];
            let propConfirmedField = {};
            let countryCodeField = {};
            propConfirmedField.FieldAPINAme = this.fieldNameToSearch;
            propConfirmedField.fieldValue = this.confirmTextValue;
            propConfirmedField.status = 'Success';
            arr_fieldDetails.push(propConfirmedField);

            //updateParentCountryCode({ caseId: this.recordId, countryCode: this.selectedCountryCode });
            
            countryCodeField.FieldAPINAme = 'Country_Code__c';
            countryCodeField.fieldValue = this.selectedCountryCode;
            countryCodeField.status = 'Success';
            arr_fieldDetails.push(countryCodeField);
            this.dispatchEvent(new CustomEvent("case360fieldextn",
                {
                    detail: {
                        arr_fieldDetails
                    }
                }
            ));
            this.cancelConfirmFieldPopup();
        }
    }
    confirmationCheck() {
        if ((this.originalTextValue == this.confirmTextValue) && !this.isMobileNumberError && this.selectedCountryCode != null && !this.isInvalidMobileNumberError) {
            this.bConfirmationTextNotMatching = false;
            this.iconClass = 'successBtn';
        }
        else {
            this.bConfirmationTextNotMatching = true;
        }
    }
    cancelConfirmFieldPopup(event) {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }
    disconnectedCallback() {
        this.ccfield = undefined;
    }
    handleOriginalAndConfirmationText(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        this.originalTextValue = val;
    }
    handleCountryCodeOptionChange(event){
        let val = event.target.value;
        this.selectedCountryCode = val;
        this.confirmationCheck();
        this.mobileNumberValidation();
    }
}