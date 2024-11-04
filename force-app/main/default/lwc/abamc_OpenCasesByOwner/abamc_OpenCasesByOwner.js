import { LightningElement, wire, track,api } from 'lwc';
import getOpenCasesByOwner from '@salesforce/apex/ABSLAMC_MyOpenCasesController.getOpenCasesByOwner';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class Abamc_OpenCasesByOwner extends NavigationMixin(LightningElement) {
    @track casesByStage = [];
    userId = userId;
    @track activeSectionName = '';

    connectedCallback(){
        console.log('userid:',this.userId);
    }

    @wire(getOpenCasesByOwner, { userId: '$userId' })
    wiredCases({ error, data }) {
        if (data) {
            // Transform data into an array of objects with key and cases properties for easy iteration in HTML
            this.casesByStage = Object.keys(data).map(stage => ({
                stage,
                cases: data[stage]
            }));
        } else if (error) {
            console.error('Error retrieving cases:', error);
        }
    }


    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        // If a section is opened, set it as the active section
        if (openSections.length > 0) {
            this.activeSectionName = openSections[0];
        }
    }

    // Navigate to the case detail page when a case link is clicked
   /* navigateToCase(event) {
        const caseId = event.currentTarget.dataset.id;
        window.open(`/lightning/r/Case/${caseId}/view`, '_blank');
    }*/
    navigateToCase(event) {
        const caseId = event.currentTarget.dataset.id;
        
        // Navigate to the case record page in the same window
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view'
            }
        });
    }
}