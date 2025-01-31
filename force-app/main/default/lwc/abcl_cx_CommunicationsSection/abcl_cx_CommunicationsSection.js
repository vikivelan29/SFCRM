import { LightningElement, api } from 'lwc';
import getInteractionInfoAcc from '@salesforce/apex/ABCL_cx360Controller.getInteractionInfo';
import { NavigationMixin } from 'lightning/navigation';
export default class Abcl_cx_CommunicationsSection extends NavigationMixin(LightningElement) {

    @api recordId;
    recordsList = [];
    showInteractionData = false;
    showNoCommunicationsMessage = false;
    
    intColumns = [
        { label: 'Name', fieldName: 'communication_channels__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Application Type', fieldName: 'Email_Subject__c', type: 'text' },
        {
            label: 'Created Date', fieldName: 'CreatedDate', type: 'date',
            typeAttributes: { day: '2-digit', month: '2-digit', year: 'numeric' }
        },
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
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'ASF_Communication_Log__c', // Replace with your object's API name
                actionName: 'list'
            },
            state: {
                filter: `Account__c = '${this.recordId}'` // Adjust field API name if different
            }
        });
    }

}