import { LightningElement, api } from 'lwc';
import getInteractionInfoAcc from '@salesforce/apex/ABCL_cx360Controller.getInteractionInfo';
import { NavigationMixin } from 'lightning/navigation';
export default class Abcl_cx_CommunicationsSection extends NavigationMixin(LightningElement) {

    @api recordId;
    recordsList = [];
    showInteractionData = false;
    showNoCommunicationsMessage = false;
    
    intColumns = [
        { label: 'Log Name', fieldName: 'Name', type: 'text' },
        { label: 'SMS Msg Body', fieldName: 'SMS_Msg_Body__c', type: 'text' },
        {
            label: 'Date', fieldName: 'CreatedDate', type: 'date',
            typeAttributes: { day: '2-digit', month: '2-digit', year: 'numeric' }
        },
        { label: 'Status', fieldName: 'Status__c', type: 'text' }
    ];

    connectedCallback() {
        this.fetchLatestInteraction();
    }

    fetchLatestInteraction() {
        getInteractionInfoAcc({ customerId: this.recordId })
            .then((result) => {
                this.recordsList = [...this.recordsList, ...result];
                this.recordsList.length > 0 ? this.showInteractionData = true : this.showNoCommunicationsMessage = true;                
            })
            .catch((error) => {
                this.error = error;
                console.error('Error while retrieving communications:', error);
            });
    }

    handleViewAll(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'force__dynamicRelatedListViewAll'
        },
        state: {
            force__recordId: this.recordId, // Parent record (e.g., Account ID)
            force__flexipageId: 'ABCL_4Col_Cx360', // Update with your actual FlexiPage ID
            force__cmpId: 'lst_dynamicRelatedList7'
        }
     });
    }

}