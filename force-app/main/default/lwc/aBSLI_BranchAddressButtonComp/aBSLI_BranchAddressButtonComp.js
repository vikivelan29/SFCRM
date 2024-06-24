import { LightningElement, api, track } from 'lwc';
import getTemplateBody from "@salesforce/apex/ABSLI_BranchAddressButtonController.getTemplateBody";
import getBranchDetail from "@salesforce/apex/ABSLI_BranchAddressButtonController.getBranchDetails";
import sendCommunication from "@salesforce/apex/ABSLI_BranchAddressButtonController.sendCommunication";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';

export default class ABSLI_BranchAddressButtonComp extends LightningElement {
    @track templateBody;
    @api recordId;
    @track sendToUnregistered = false;
    @track selectedBranchCity='';
    @track selectedBranchAddr='';
    @track selectedBranchPhone ='';
    @track selectedBranchState = '';
    @track selectedBranchPincode = '';
    @track selectedBranchId = '';
    @track showPreview = false;
    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['Address__c','Branch_Code__c','City__c','Phone__c'],
    };
    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: 'City__c' }],
    };
    

    async connectedCallback(){
        console.log('recordId in Child --> '+this.recordId);
        
    }

    @api
    sendCommunication(parentRecordId){

        console.log('Class Name --> '+parentRecordId);
        if(this.IsInputValid()){
            let unregistedPhoneNumber = null;
            if(this.refs.unregisterednumber){
                unregistedPhoneNumber = this.refs.unregisterednumber.value;
            }
            sendCommunication({accountId : parentRecordId, branchId : this.selectedBranchId, unregisteredNumber: unregistedPhoneNumber})
            .then((result)=>{
                this.invokeCloseModal();
                this.showSuccessMessage('success', 'SMS triggered successfully.', '');
    
            })
            .catch((error)=>{
                console.log('error');
                this.showError('error', 'Unable to send SMS.', error);
                debugger;
    
            })
        }
        
    }
    handleToggle(event){
        this.sendToUnregistered = !this.sendToUnregistered;
    }
    IsInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField=>{
            debugger;
            if(!inputField.checkValidity()){
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    invokeCloseModal(){
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    showSuccessMessage(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        });
        this.dispatchEvent(event);
    }
    handleBranchSelect(event){
        console.log(event.detail.recordId);
        let selectedRecordId = event.detail.recordId;
        this.selectedBranchId = '';

        if(selectedRecordId != null && selectedRecordId != undefined){
            getBranchDetail({branchId : selectedRecordId})
            .then((result)=>{
                console.log(result);
                this.selectedBranchCity = result.City__c;
                this.selectedBranchAddr = result.Address__c;
                this.selectedBranchPhone = result.Phone__c;
                this.selectedBranchState = result.State__c;
                this.selectedBranchPincode = result.Pincode__c;
                this.selectedBranchId = selectedRecordId;
            })
            .catch((error)=>{
                this.selectedBranchCity = '';
                this.selectedBranchAddr = '';
                this.selectedBranchPhone = '';
                this.selectedBranchState = '';
                this.selectedBranchPincode = '';

            })
        }else {
            // Reset field assignments if no record is selected
            this.selectedBranchCity = '';
            this.selectedBranchAddr = '';
            this.selectedBranchPhone = '';
            this.selectedBranchState = '';
            this.selectedBranchPincode = '';
            this.selectedBranchId = '';
        }
        
        debugger;
    }
    async handlePrevSend(event){
        console.log('This method is to preview the SMS Content before sneding it to user.');
        console.log('recordiId',this.recordId);
        console.log('branchId',this.selectedBranchId);
        await getTemplateBody({whatId : this.recordId, branchId : this.selectedBranchId})
        .then((result)=>{
            this.templateBody = result;
            this.showPreview = true;
            this.errorMsg = '';
        })
        .catch((error) => {
            console.log(error);
            this.showPreview = false;
        });

    }
    handleSend(event){
        this.sendCommunication(this.recordId);
    }
    handleBack(event){
        this.showPreview = false;
        this.selectedBranchCity = '';
        this.selectedBranchAddr = '';
        this.selectedBranchPhone = '';
        this.selectedBranchState = '';
        this.selectedBranchPincode = '';
        this.selectedBranchId = '';

    }

}