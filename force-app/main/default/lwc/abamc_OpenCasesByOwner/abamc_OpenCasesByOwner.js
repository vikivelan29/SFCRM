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
        if (openSections.length > 0) {
            this.activeSectionName = openSections[0];
        }
    }

    navigateToCase(event) {
        const caseId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view'
            }
        });
    }
}