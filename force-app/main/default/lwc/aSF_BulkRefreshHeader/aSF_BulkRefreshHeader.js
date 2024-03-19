import { LightningElement,wire } from 'lwc';
import refreshHeader from '@salesforce/apex/ASF_BulkCsvController.refreshHeader';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from "lightning/uiRecordApi";

export default class ASF_BulkRefreshHeader extends LightningElement {
    recordId;
    refreshMessage = '';
    showResult = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.fetchUpdate();
        }
    }

    fetchUpdate(){
        refreshHeader({bulkHeaderId: this.recordId})
            .then(result => {
                this.showResult = true;
                this.refreshMessage = result;  
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch(error => {
                console.error('Error calling refresh method:', error);    
            });
    }
    
}