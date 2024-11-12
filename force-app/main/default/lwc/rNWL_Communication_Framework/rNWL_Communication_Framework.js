import { LightningElement, api, wire } from 'lwc';
import notifyUsers from '@salesforce/apex/RNWL_CommunicationFrameworkController.notifyUsers';
import getMetadata from '@salesforce/apex/RNWL_CommunicationFrameworkController.fetchCommunicationMDT';
import ACCOUNT_Phone from '@salesforce/schema/Opportunity.Account.Phone'; 
import ACCOUNT_Email from '@salesforce/schema/Opportunity.Account.PersonEmail'; 
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const fields = [ACCOUNT_Phone,ACCOUNT_Email];

export default class RNWL_Communication_Framework extends LightningElement {
    @api recordId;
    selectedChannelSource = '';
    errorMessage='Communication is not allowed for this channel due to unavailability, Please  contact your Administrator.';
    hasError = false;
    isSMS_Whatapp = false;
    isEmail = false;
    showUserDetails = false;
    notifyFlag = true;
    showSpinner = false;
    toEmailFlag = false;
    // property needs to be ind with data from controller:
    currentEmail;
    currentPhone;
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

    phoneNumInfo="i. ‘Enter the Number’ field will allow single additional mobile number.\nii. Mobile should be given in standard 10 digit format (without ‘0’ and ‘+91’)";
    emailInfo = "i. ‘Send To email’ allow to have single additional email address.\nii. ‘Send CC emails’ allow to have multiple additional email address, which  can  be semicolon separated (;)";
    
    ccEmailHelpText='Please use ";" separated valid emails';

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
            this.hasError = true;
        })
        .finally(()=>{
            this.showSpinner = false;
            this.notifyFlag = this.communicationMetadata.length == 0;
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

        if(!this.isEmailNeeded){
            this.inputEmail = '';
            this.inputCCEmail = '';

            this.notifyFlag = this.currentEmail == 'NA';
        }
    }

    phoneToggleChange(event){
        let toggleValue = event.detail.checked;
        this.isPhoneNeeded = toggleValue;

        if(!this.isPhoneNeeded){
            this.inputNumber = '';
            this.notifyFlag = this.currentPhone == 'NA';
        }
    }

    validatePhoneNumber(event){
        let phoneNumber = event.target.value;
        let phnCmp = this.template.querySelector(".inputPhone");
        
        if(phoneNumber && phoneNumber != '' && phoneNumber.length == 10){
            
            if (!this.validPhoneStart.includes(parseInt(phoneNumber[0]))) {
                phnCmp.setCustomValidity("Please enter valid phone number");
            } else {
                this.inputNumber = phoneNumber;
                phnCmp.setCustomValidity("");
            }
            
        }else{
            phnCmp.setCustomValidity("Please enter valid phone number");
        }

        phnCmp.reportValidity();

        this.notifyFlag = !phnCmp.checkValidity(); 
    }

    renderUserNames() {
        let flag = false;
        if(this.selectedChannelSource == 'SMS'){
            this.userList = this.communicationMetadata.filter((record) => record.SMS__c);
            flag = this.currentPhone == 'NA';
        }else if(this.selectedChannelSource == 'Whatsapp'){
            this.userList = this.communicationMetadata.filter((record) => record.WhatsApp__c);
            flag = this.currentPhone == 'NA';
        }else if(this.selectedChannelSource == 'Email'){
            this.userList = this.communicationMetadata.filter((record) => record.Email__c);
            flag = this.currentEmail == 'NA';
        }
        this.showUserDetails = this.userList && this.userList.length > 0;
        
        this.templateOptions = [];
        
        this.userList.forEach(rec=>{
            this.templateOptions.push({label: rec.User_Friendly_Name__c , value: rec.Metadata_Name__c});
        })

        this.selectedTemplate = this.userList[0]?.Metadata_Name__c;
        this.notifyFlag = this.selectedTemplate && !flag ? false : true ;
    }
    
    handleChange(event) {
        this.selectedTemplate = event.detail.value;
    }

    handleInputToChange(event){
        let emailAddress = event.detail.value;
        let email = this.template.querySelector(".toAddressCmp");

        if(!emailAddress || emailAddress == '' || !emailAddress.match(this.emailRegex)){
            email.setCustomValidity("Please enter valid email address");
        }else{
            email.setCustomValidity("");
            this.inputEmail = emailAddress;
        }
        email.reportValidity();

        this.toEmailFlag = !email.checkValidity();
        this.notifyFlag = this.toEmailFlag;

    }

    handleInputccChange(event) {
        let emailAddresses = event.detail.value;
        let email = this.template.querySelector(".ccAddressCmp");
        let isValidEmails = true;
        if(emailAddresses) {
            if(emailAddresses.includes(";")) {
                emailAddresses.split(";").forEach(element => {
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
        this.notifyFlag = this.toEmailFlag || !email.checkValidity() ? true : false;
        email.reportValidity();
    }

    notifyHandler() {
        let className;
        let methodName;
        for (let each in this.communicationMetadata) {
            if (this.communicationMetadata[each].Metadata_Name__c === this.selectedTemplate) {
                className = this.communicationMetadata[each].Class_Name__c;
                methodName = this.communicationMetadata[each].Method_Name__c;
            }
        }
        this.userList = this.communicationMetadata.filter((record) => record.SMS__c);
        let requestWrapper = {
            selectedTemplate : this.selectedTemplate,
            notificationMode : this.selectedChannelSource,
            alternateMobile : this.inputNumber,
            toAddresses : this.inputEmail,
            ccAddresses : this.inputCCEmail,
            opportunityId : this.recordId,
            className: className,
            methodName: methodName
        };
        let requestJSON = JSON.stringify(requestWrapper);
        notifyUsers({ requestJSON : requestJSON })
        .then(data => {
            if (data) {
                this.hasError = false;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: data,
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
        })
        .catch(error => {
            //this.hasError = true;
            console.log(JSON.stringify(error), '****');
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        })
    }
}