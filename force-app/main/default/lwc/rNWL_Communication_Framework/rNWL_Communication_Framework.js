
import { LightningElement, api } from 'lwc';
import notifyUsers from '@salesforce/apex/RNWL_CommunicationFrameworkController.notifyUsers';
import getMetadata from '@salesforce/apex/RNWL_CommunicationFrameworkController.fetchCommunicationMDT';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class RNWL_Communication_Framework extends LightningElement {
    @api recordId;
    selectedChannelSource = '';
    errorMessage='';
    hasError = false;
    isSMS_Whatapp = false;
    isEmail = false;
    showUserDetails = false;
    notifyFlag = true;
    showSpinner = false;
    // property needs to be ind with data from controller:
    currentEmail = 'test@test.com';
    currentPhone = '9876543210';
    isEmailNeeded = false;
    isPhoneNeeded = false;
    inputEmail;
    inputNumber;
    inputCCEmail;
    emailRegex=/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    validPhoneStart = [6,7,8,9];
    communicationMetadata = [];
    userList=[];
    selectedTemplate;
    templateOptions=[];

    communicationOptions = [
        { label: 'Email', value: 'Email' },
        { label: 'SMS', value: 'SMS' },
        { label: 'Whatsapp', value: 'Whatsapp' },
    ];

    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {
            this.currentPhone = getFieldValue(data, ACCOUNT_Phone) ? getFieldValue(data, ACCOUNT_Phone) : 'NA'; 
            this.currentEmail = getFieldValue(data, ACCOUNT_Email) ? getFieldValue(data, ACCOUNT_Email) : 'NA'; 
        }else if(error){
            console.log('error-', JSON.stringify(error));
        }
    }

    connectedCallback(){
        this.userList = [];
        this.showSpinner = true;

        getMetadata()
        .then(data => {
            if (data && data.length > 0) {
                this.communicationMetadata = data;
                this.hasError = false;
            }
        })
        .catch(error=>{
            this.errorMessage = error;
            this.hasError = true;
        })
        .finally(()=>{
            this.showSpinner = false;
        })
    }

    selecteOption(event){
        this.selectedChannelSource =  event.detail.value;
        this.isEmail = this.selectedChannelSource == 'Email';
        this.isSMS_Whatapp = !this.isEmail;
        this.isPhoneNeeded = this.isEmailNeeded = false;
        let cmp = this.template.querySelector('.phoneCmp');
        if(this.isSMS_Whatapp && cmp){
            this.template.querySelector('.phoneCmp').checked = false;
        }
        this.renderUserNames();
    }
    
    emailToggleChange(event){
        let toggleValue = event.detail.checked;
        this.isEmailNeeded = toggleValue;
    }

    phoneToggleChange(event){
        let toggleValue = event.detail.checked;
        this.isPhoneNeeded = toggleValue;
    }

    validatePhoneNumber(event){
        let phoneNumber = event.target.value;
        if(phoneNumber && phoneNumber.length == 10){
            let phnCmp = this.template.querySelector(".inputPhone");
            if (!this.validPhoneStart.includes(parseInt(phoneNumber[0]))) {
                phnCmp.setCustomValidity("Please enter valid phone number");
            } else {
                this.inputNumber = phoneNumber;
                phnCmp.setCustomValidity("");
            }
            phnCmp.reportValidity();
        }
    }

    renderUserNames() {
        if(this.selectedChannelSource == 'SMS'){
            this.userList = this.communicationMetadata.filter((record) => record.SMS__c);
        }else if(this.selectedChannelSource == 'Whatsapp'){
            this.userList = this.communicationMetadata.filter((record) => record.WhatsApp__c);
        }else if(this.selectedChannelSource == 'Email'){
            this.userList = this.communicationMetadata.filter((record) => record.Email__c);
        }
        this.showUserDetails = this.userList && this.userList.length > 0;
        
        this.templateOptions = [];
        
        this.userList.forEach(rec=>{
            this.templateOptions.push({label: rec.User_Friendly_Name__c , value: rec.Metadata_Name__c});
        })

        this.selectedTemplate = this.userList[0]?.Metadata_Name__c;
        this.notifyFlag = this.selectedTemplate ? false : true ;
    }
    
    handleChange(event) {
        this.selectedTemplate = event.detail.value;
        this.notifyFlag = this.selectedTemplate ? false : true ;
    }

    handleInputToChange(event){
        let emailAddress = event.detail.value;
        let email = this.template.querySelector(".toAddressCmp");

        if(!emailAddress.match(this.emailRegex)){
            email.setCustomValidity("Please enter valid email address");
        }else{
            email.setCustomValidity("");
            this.inputEmail = emailAddress;
        }
        email.reportValidity();
    }

    handleInputccChange(event) {
        let emailAddresses = event.detail.value;
        let email = this.template.querySelector(".ccAddressCmp");
        let isValidEmails = true;
        if(emailAddresses) {
            if(emailAddresses.includes(",")) {
                emailAddresses.split(",").forEach(element => {
                    if (!element.trim().match(this.emailRegex)) {
                        isValidEmails = false;
                    }
                });
            } else {
                if (!emailAddresses.match(this.emailRegex)) {
                    isValidEmails = false;
                }
            }
        } else {
            isValidEmails = false;
        }
        if (isValidEmails) {
            email.setCustomValidity("");
            this.inputCCEmail = emailAddresses;
        } else{
            email.setCustomValidity("Please enter valid email addresses");
        }
        email.reportValidity();
    }

    notifyHandler() {
        let requestWrapper = { 
            selectedTemplate : this.selectedTemplate,
            notificationMode : this.selectedChannelSource,
            alternateMobile : this.inputNumber,
            toAddresses : this.inputEmail,
            ccAddresses : this.inputCCEmail,
            opportunityId : this.recordId
        };
        let requestJSON = JSON.stringify(requestWrapper);
        notifyUsers({ requestJSON : requestJSON })
        .then(data => {
            if (data) {
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: data,
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error.message,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        })
    }
}
