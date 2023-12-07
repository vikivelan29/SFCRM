import { LightningElement, api} from 'lwc';
import updateCaseParent from '@salesforce/apex/ASF_RelateDuplicateCaseController.updateCaseParent';
import { CloseActionScreenEvent } from "lightning/actions";
//import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Asf_RelateDeduplicateCase extends LightningElement {
    @api recordId;
    @api objectApiName = 'Case';
    loaded = true;
   
    handleSuccess() {
        this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
    }

    handleError(event) {
        this.showToastMessage('Error!', event.detail.detail, 'error');
    }
    
    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    onSubmitHandler(event) {
        event.preventDefault();
        this.loaded = false;
        const fields = event.detail.fields;
        var isDuplicate = event.detail.fields['Is_Duplicate__c'];
        var parentCase = event.detail.fields['ParentId'];
        
        if(parentCase === ""){
            parentCase = null;
        } 
 
        updateCaseParent({ caseRecordId: this.recordId, parentId: parentCase, isDuplicate: isDuplicate})
            .then(result => {
                this.loaded = true;
                if(result === 'Success'){

                    this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    eval("$A.get('e.force:refreshView').fire();")
                    //refreshApex(this.wiredData);

                }else{
                    this.showToastMessage('Error!', result, 'error');
                }
                

            })
            .catch(error => {
                this.loaded = true;
                this.showToastMessage('Error!', error, 'error');
            }); 
    }
}