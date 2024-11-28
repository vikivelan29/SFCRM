import { LightningElement, api, track } from 'lwc';
import { countryCodeOptions } from './countryCodeOptions';

export default class absli_reconfirminput extends LightningElement {
    @api ccfield;
    @track originalTextValue = '';
    @track confirmTextValue = '';
    @track bConfirmationTextNotMatching = true;
    @track showConfirmationError = false;
    @api fieldNameToSearch = '';
    @track MICR_CODE = '000000000';
    @api recordId;
    @track IFSC_Code = '';
    @track countryCodeVisibilty = false;
    options = [];
    @track isMobileNumberError = false;
    @track selectedCountryCode;
    @track isInvalidMobileNumberError = false;
    @track confirmMobileNumberError = false;
    @track emailIDvalidation = false;
    @track isOriginalEmailInvalid = false;
    @track isConfirmEmailInvalid = false;
    @track bankAccNumbervalidation = false;
    @track hasValidationError = false;

    connectedCallback(){
        console.log('this in connectedcallback',JSON.stringify(this.recordId));
        if(this.fieldNameToSearch === 'Mobile_Number__c'){
           this.countryCodeVisibilty = true;
        }
        if(this.fieldNameToSearch === 'Email_Id__c'){
            this.emailIDvalidation = true;
         }
        if(this.fieldNameToSearch === 'Account_Number__c'){
            this.bankAccNumbervalidation = true;
        }
        this.options = countryCodeOptions;
    }
    validateMobileNumberCharacters(number) {
        const regex = /^[0-9]+$/;
        return regex.test(number);
    }
        mobileNumberValidation() {
            const originalInput = this.template.querySelector('[data-id="originalInput"]');
            const confirmInput = this.template.querySelector('[data-id="confirmInput"]');

                originalInput.setCustomValidity('');
                confirmInput.setCustomValidity('');

                const setValidity = (inputElement, condition, message) => {
                    if (inputElement.value) {
                        if (condition) {
                            inputElement.setCustomValidity(message);
                            this.hasValidationError = true;
                        } else {
                            inputElement.setCustomValidity('');
                            this.hasValidationError = false; 
                        }
                        inputElement.reportValidity(); 
                    } else {
                        inputElement.setCustomValidity(''); 
                        inputElement.reportValidity();
                    }
                };

                setValidity(originalInput, this.originalTextValue && !this.validateMobileNumberCharacters(this.originalTextValue), 'Invalid Mobile Number');

                setValidity(confirmInput, this.confirmTextValue && !this.validateMobileNumberCharacters(this.confirmTextValue), 'Invalid Mobile Number');
                
                if (this.selectedCountryCode === '91' && this.originalTextValue && this.originalTextValue.length != 10) {
                    this.isMobileNumberError = true;
                } else if(this.selectedCountryCode !== '91' && this.originalTextValue && this.originalTextValue.length > 15){
                        this.isMobileNumberError = true;
                }else {
                    this.isMobileNumberError = false;
                }
        }
    handleOriginalTextChange(event) {
        this.originalTextValue = event.target.value;
        const originalInput = this.template.querySelector('[data-id="originalInput"]');
        let isOriginalAccNumInvalid = false;
        
        if(this.countryCodeVisibilty){
            this.mobileNumberValidation();
            this.confirmationCheck(); 
        }
        if (this.originalTextValue === '') {
            this.isOriginalEmailInvalid = false;
            isOriginalAccNumInvalid = false;
            this.hasValidationError = false;
            originalInput.setCustomValidity('');
        } else if(this.emailIDvalidation){
            this.isOriginalEmailInvalid = !this.validateEmail(this.originalTextValue);
            this.isOriginalEmailInvalid?originalInput.setCustomValidity('Invalid Email ID.'):originalInput.setCustomValidity('');
            this.hasValidationError = this.isOriginalEmailInvalid;
            this.confirmationCheck(); 
        } else if(this.bankAccNumbervalidation){
            isOriginalAccNumInvalid = !this.validateBankAccountNumber(this.originalTextValue);
            isOriginalAccNumInvalid?originalInput.setCustomValidity('Invalid Account Number. Min-5 Max-34.'):originalInput.setCustomValidity('');
            this.hasValidationError = isOriginalAccNumInvalid;
            this.confirmationCheck(); 
        }
        originalInput.reportValidity();
    }
    handleConfirmTextChange(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        const confirmInput = this.template.querySelector('[data-id="confirmInput"]');
        let isConfirmAccNumInvalid = false;
        
        if(this.countryCodeVisibilty){
            this.mobileNumberValidation();
            this.confirmationCheck(); 
        }
        
        if (this.confirmTextValue === '') {
            this.isConfirmEmailInvalid = false;
            isConfirmAccNumInvalid = false;
            this.hasValidationError = false;
            confirmInput.setCustomValidity('');
        } else if(this.emailIDvalidation){
            this.isConfirmEmailInvalid = !this.validateEmail(this.confirmTextValue);
            this.isConfirmEmailInvalid?confirmInput.setCustomValidity('Invalid Email ID.'):confirmInput.setCustomValidity('');
            this.hasValidationError = this.isConfirmEmailInvalid;
            this.confirmationCheck(); 
        } else if(this.bankAccNumbervalidation){
            isConfirmAccNumInvalid = !this.validateBankAccountNumber(this.confirmTextValue);
            isConfirmAccNumInvalid?confirmInput.setCustomValidity('Invalid Account Number. Min-5 Max-34.'):confirmInput.setCustomValidity('');
            this.hasValidationError = isConfirmAccNumInvalid;
            this.confirmationCheck(); 
        }
        confirmInput.reportValidity();
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
            this.showConfirmationError = false;
            this.iconClass = 'successBtn';
        }else if ((this.originalTextValue == this.confirmTextValue)){
            this.bConfirmationTextNotMatching = false;
            this.showConfirmationError = false;
            this.iconClass = 'successBtn';
        }
        else {
            this.bConfirmationTextNotMatching = true;
            this.showConfirmationError = true;
        }
        
        if(this.countryCodeVisibilty && this.selectedCountryCode == null){
            this.bConfirmationTextNotMatching = true; 
        }
        if(this.hasValidationError){
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
    validateEmail(email) {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return regex.test(email);
    }
    validateBankAccountNumber(input) {
        const regex = /^[a-zA-Z0-9]{5,34}$/;
        return regex.test(input);
    }
}