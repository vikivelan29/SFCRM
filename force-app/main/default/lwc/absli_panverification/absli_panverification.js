import { LightningElement,api,wire } from 'lwc';
import getPanDetails from '@salesforce/apex/ABSLI_NSDLPANVerification.getPanVerificationDetails';
import panVerification from '@salesforce/apex/ABSLI_NSDLPANVerification.verifyPAN';
import panUpdate from '@salesforce/apex/ABSLI_NSDLPANVerification.updatePAN';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Absli_panverification extends LightningElement {
    pan;
    name;
    dob;
    record;
    error;
    verificationCompleted;
    showSpinner;
    @api recordId;
    @api caseIntId;
    @api intExtId;
    nsdlResponse;

    handleFieldChange(event) {
        this.record = JSON.parse(JSON.stringify(this.record));
        const fieldName = event.target.name;
        this.record[fieldName] = event.target.value;
    }

    @wire (getPanDetails,{caseId: '$recordId'})
	wiredPanDetails({data, error}){
		if(data) {
			this.record =data;
            if(this.record.panValidationStatus){
                //this.verificationCompleted = true;
            }
			this.error = undefined;
		}else {
			this.record =undefined;
			this.error = error;
		}
	}

    verifyPAN(e){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            let currValidity = inputCmp.checkValidity();
            if(inputCmp.name == 'dob' && inputCmp.value){
                if(new Date(inputCmp.value) > new Date()){
                    currValidity = false;
                    inputCmp.setCustomValidity("Date of Birth can't be a future date");
                }else{
                    currValidity = true;
                    inputCmp.setCustomValidity("");
                }
                inputCmp.reportValidity();
            }
            return validSoFar && currValidity;
        }, true);
        if (allValid) {
            this.showSpinner = true;
            panVerification({ panInputWrapperStr : JSON.stringify(this.record), caseId: this.recordId, intExtId : this.intExtId })
            .then(result => {
                if(result.isSuccess){
                    this.verificationCompleted = true;
                    this.showToast({
                        title: "Success",
                        message: "PAN Validated Successfully",
                        variant: "success",
                    });
                    this.nsdlResponse = JSON.parse(result.responseStr).outputData[0];
                }else {
                    this.showToast({
                        title: "Error",
                        message: result.errorMessage,
                        variant: "error",
                    });
                }
                this.error = undefined;
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                this.showSpinner = false;
            })
        }
    } 

    updatePAN(e){
        this.showSpinner = true;
        panUpdate({ caseId: this.recordId })
        .then(result => {
            if(result.isSuccess){
                /*this.showToast({
                    title: "Success",
                    message: "PAN Update Initiated Successfully",
                    variant: "success",
                });*/
                this.closeModal();
            }else {
                this.showToast({
                    title: "Error",
                    message: result.errorMessage,
                    variant: "error",
                });
            }
            this.error = undefined;
            this.showSpinner = false;
        })
        .catch(error => {
            this.error = error;
            this.showSpinner = false;
        })
    }

    showToast(e){
        this.dispatchEvent(new ShowToastEvent(e));        
    }

    closeModal(){
        const closeEvent = new CustomEvent('closepopup',{});
        this.dispatchEvent(closeEvent);
    }

    rejectionHandler(e){
        this.closeModal();
    }
    
}