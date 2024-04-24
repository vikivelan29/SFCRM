import { refreshApex } from '@salesforce/apex';
import getAccountCaseComments from '@salesforce/apex/ABFL_AccRecentCaseCommController.getAccountCaseComments';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
export default class Abfl_AccRecentCaseComments extends NavigationMixin(LightningElement) {
    @api recordId;
    caseComments;
    displayCaseComments = false;
    @api rows;
    isLoaded = true;
    comments;

    @wire(getAccountCaseComments, { accountId: '$recordId', queryRows: '$rows' })
    wiredCaseComments(result) {
        console.log('The data received is '+JSON.stringify(result.data));
        this.comments = result;
        if (result.data && result.data.length > 0) {
            
            this.displayCaseComments = true;
            //console.log('Inside the CaseComments if loop');
            //console.log('this.displayCaseComments '+this.displayCaseComments);
            this.caseComments = result.data;    
            this.isLoaded = false;
        } else {
            this.displayCaseComments = false;
            this.caseComments = [];
            this.isLoaded = false;
        }
        if (result.error) {
            console.error('Error retrieving case comments:', result.error);
            this.isLoaded = false;
        }
    }
    
     refreshData(event){
            this.isLoaded = true;
            console.log('Inside REFRESH DATA');
           refreshApex(this.comments); 
           console.log('The Updated Data is '+JSON.stringify(this.caseComments));
           //setTimeout(() => { console.log('The Updated Data is '+JSON.stringify(this.caseComments)); }, 1000);         
           this.isLoaded = false;

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