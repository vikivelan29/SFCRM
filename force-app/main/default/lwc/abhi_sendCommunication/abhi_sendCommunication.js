import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/ABHI_ClickPSSCommController.getMetadata';
import doComm from '@salesforce/apex/ABHI_ClickPSSCommController.doCommunication';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

export default class Abhi_sendCommunication extends LightningElement {

    @api currentSelRecord;
    @api objectApiName='';
    isLoading=false;
    @api recordId;
    @api assetLookupField;
    message = '';
    @track infoObject = {};
    @track commMetadata=[];
    returnedMetaData;
    showData=false;
    fields=[];
    @track fetchedRecord;
    toggleDisabled=false;
    checkedToggle=true;
    @track formData = {
        commType: '',
        template: '',
        alertCode: '0',
        phoneNumber: '',
        emailId: ''
    };
    @track showContact={
        showPhone: false,
        showEmail: false,
        showTemplate: false
    }
    @track recordDetails = {
        Phone: '',
        Email: ''
    };
    commOptions = [];
    displayMessage='';
    displayError = false;
    @track tempOptions = [];
    @track cols={
        emailField: '',
        phoneField: '',
    };
    assetReferenceField='';
    @track validation={
        validationMessage: '',
        validationTemplateMessage:'',
        showValidation:false,
        showTemplateValidation:false
    }

    connectedCallback(){
        this.isLoading=true;
    }

    @wire(getData, { objectName: '$objectApiName' })
    wiredMetadata({error, data}){
        if(data){
            console.log('data>>', data);
            console.log('dataLength>>', data.length);
            
            if(data.length <= 0 ){
                this.displayError = true;
                this.isLoading=false;
                this.displayMessage = "You don't have access to initiate this Communication. Please close this window." ;
                return;
            }
            console.log('Metadata>>>', data);
            this.cols.emailField = data[0].Email_Field__c;
            this.cols.phoneField = data[0].Phone_Field__c;
            this.fields = this.currentSelRecord?[this.objectApiName + "." + this.cols.emailField, this.objectApiName + "." + this.cols.phoneField, this.objectApiName + '.Name']:
            [this.objectApiName + "." + this.cols.emailField, this.objectApiName + "." + this.cols.phoneField, this.objectApiName + '.Name', this.objectApiName + '.Policy_No__c', this.objectApiName + '.SerialNumber',  this.objectApiName + '.Next_Premium_Date__c'];
            console.log('Fields>>>', JSON.stringify(this.fields));
            this.commMetadata=data;
            this.createFormData(data);
        }
        else if(error){
            this.displayError = true;
            this.displayMessage = error.body.message ;
            this.isLoading=false;
            console.error('Error in getCommMetadata>>>', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields'})
    wiredRecord({ error, data }) {
        if (error) {
            console.error('Error getting RecordData', error);    
        } else if (data) {
            console.log('Account Data>>', data);    
          this.fetchedRecord = data;
        }
      }

    handleClick(event){
        try {
            let buttonLabel = event.target.label;
            if(buttonLabel === 'Send'){
                if(this.formData.template != '' && this.validateData()){
                    this.formData.phoneNumber=this.checkedToggle?'':this.formData.phoneNumber;
                    this.formData.emailId=this.checkedToggle?'':this.formData.emailId;
                    console.log('lookupField>>', this.assetLookupField);
                    
                    let recordIdVar = (this.currentSelRecord && this.assetLookupField)?this.currentSelRecord[this.assetLookupField]:this.recordId;
                    doComm({"objectName" : this.objectApiName, "recordId": recordIdVar, "formData": JSON.stringify(this.formData)})
                    .then(result => {
                        console.log('Result>>>', result);
                        if(result.statusCode == 1000){
                            this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
                            this.showToast('Success', result.message, 'success');
                        }
                        else{
                            this.showToast('Error', result.message, 'error');
                        }
                        
                    })
                    .catch(error => {
                        console.log('Error in Comm:', JSON.stringify(error));
                        this.showToast('Error', error.body.message, 'error');
                    });
                }
                else if(this.formData.template == ''){
                    this.validation.showTemplateValidation=true;
                    this.validation.validationTemplateMessage='Please select a valid Template';
                    if(this.template.querySelector('.com_box') && !this.template.querySelector('.com_box').classList.contains('slds-has-error'))
                        this.template.querySelector('.com_box').classList.add('slds-has-error');
                }
            }
        } catch (error) {
            console.error('error in send>>>', JSON.stringify(error));
            
        }
        
    }

    validateData(){
        if(!this.checkedToggle && (this.showContact.showPhone && this.formData.phoneNumber == '') || (this.showContact.showEmail && this.formData.emailId == '')){
            if(this.showContact.showPhone){
                this.validation.validationMessage = 'Please enter a valid 10-digit Phone number';
                this.validation.showValidation=true;
                this.template.querySelector('.tel_inp').classList.add('slds-has-error');
            }
            
            return false;
        }
        else if(!this.checkedToggle && this.showContact.showPhone && this.formData.phoneNumber.length != 10){   
            this.validation.validationMessage = 'Please enter a valid 10-digit Phone number';
            this.validation.showValidation=true;
            this.template.querySelector('.tel_inp').classList.add('slds-has-error');
        }
        else return true;
    }

    createFormData(data){
       
        try {
            console.log('In createFormData>>>', data);
            this.returnedMetaData = data;
            let commArr=[];
            data.forEach(element => {
                if(commArr.length<=0 || !commArr.includes(element.CommunicationType__c)){
                    this.commOptions.push({
                        label: element.CommunicationType__c,
                        value: element.CommunicationType__c
                    });
                    commArr.push(element.CommunicationType__c);
                }
            });
            console.log('commOptions>>>', this.commOptions);
            this.showData=true;
            this.isLoading=false;
        } catch (error) {
            console.error('Error in createFormData>>>', JSON.stringify(error));
        }
        
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }

    handleChange(event){
        try {
            this.validation.showValidation = false;
            this.validation.showTemplateValidation=false;
            if(this.template.querySelector('.tel_inp') && this.template.querySelector('.tel_inp').classList.contains('slds-has-error'))
                this.template.querySelector('.tel_inp').classList.remove('slds-has-error');
            if(this.template.querySelector('.com_box') && this.template.querySelector('.com_box').classList.contains('slds-has-error'))
                this.template.querySelector('.com_box').classList.remove('slds-has-error');
            let selectedLabel = event.target.label;
            let selectedVal = event.detail.value;
            this.formData.template = '';
            
            if(selectedLabel == 'Communication Type'){
                this.formData.alertCode = '0';
                let tempOptionArr=[];
                this.returnedMetaData.forEach(element => {
                    console.log('element>>>', element);
                    
                    if(element.CommunicationType__c == selectedVal){
                        if(this.formData.alertCode == '0'){
                            this.formData.alertCode = element.Alert_Code__c;
                        }
                        tempOptionArr.push({
                            label: element.TemplateId__c+ ' - ' +element.TemplateName__c,
                            value: element.TemplateId__c
                        });
                    }
                });
                
                this.tempOptions = tempOptionArr;
                this.showContact.showTemplate = true;
                console.log('tempOptions>>>', this.tempOptions);
                
            }
            if(selectedLabel == 'Template'){
                this.formData.template = selectedVal;
            }
            let phoneField = this.cols.phoneField.includes('.')?this.fetchedRecord.fields[this.cols.phoneField.split('.')[0]].value.fields[this.cols.phoneField.split('.')[1]].value:this.fetchedRecord.fields[this.cols.phoneField].value;
            console.log('phoneField>>>', phoneField);
            
            let emailField = this.cols.emailField.includes('.')?this.fetchedRecord.fields[this.cols.emailField.split('.')[0]].value.fields[this.cols.emailField.split('.')[1]].value:this.fetchedRecord.fields[this.cols.emailField].value;
            if(selectedVal == 'SMS' || selectedVal == 'Whatsapp'){
                
                this.showContact.showPhone=true;
                this.showContact.showEmail=false;
                this.toggleDisabled = phoneField!=null?false:true;
                this.checkedToggle = phoneField!=null?true:false;
                this.recordDetails.Phone = phoneField!=null?phoneField:'';
            }
            else if(selectedVal == 'Email'){
                this.showContact.showEmail=true;
                this.showContact.showPhone=false;
                this.toggleDisabled = emailField!=null?false:true;
                this.checkedToggle = emailField!=null?true:false;
                this.recordDetails.Email = emailField!=null?emailField:'';
                
            }
        } catch (error) {
            console.error('Error in handleChange>>>', JSON.stringify(error));
            
        }
        
    }

    handleInputChange(event){
        let inputType = event.target.type;
        this.validation.showValidation=false;
        this.validation.showTemplateValidation=false;
        if(this.template.querySelector('.tel_inp') && this.template.querySelector('.tel_inp').classList.contains('slds-has-error'))
        this.template.querySelector('.tel_inp').classList.remove('slds-has-error');
        if(this.template.querySelector('.com_box') && this.template.querySelector('.com_box').classList.contains('slds-has-error'))
        this.template.querySelector('.com_box').classList.remove('slds-has-error');
        if(inputType == 'toggle'){
            this.checkedToggle = !this.checkedToggle;
        }
        if(inputType == 'tel'){
            let phoneNumber = event.detail.value;
            console.log('PhoneNumber>>', phoneNumber);
            this.formData.phoneNumber = phoneNumber;
        }
        if(inputType == 'email'){
            let emailId = event.detail.value;
            console.log('emailId>>', emailId);
            this.formData.emailId = emailId;
        }
     }

    handleCloseClick() {
        this.close('canceled');
      }
}