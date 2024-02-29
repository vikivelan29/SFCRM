import getAccountCaseComments from '@salesforce/apex/ABFL_AccRecentCaseCommController.getAccountCaseComments';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
export default class Abfl_AccRecentCaseComments extends NavigationMixin(LightningElement) {
    @api recordId;
    caseComments;
    displayCaseComments = false;
    @api rows;

    @wire(getAccountCaseComments, { accountId: '$recordId', queryRows: '$rows' })
    wiredCaseComments({ error, data }) {
        console.log('The data received is '+JSON.stringify(data));
        console.log('The data received is '+JSON.stringify(!data));
        if (data && data.length > 0) {
            this.displayCaseComments = true;
            console.log('Inside the CaseComments if loop');
            console.log('this.displayCaseComments '+this.displayCaseComments);
            this.caseComments = data;
        } else {
            this.displayCaseComments = false;
            this.caseComments = [];
        }
        if (error) {
            console.error('Error retrieving case comments:', error);
        }
    }
    handleCaseClick(event) {
        const caseId = event.target.dataset.caseid;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view'
            }
        });
    }
}