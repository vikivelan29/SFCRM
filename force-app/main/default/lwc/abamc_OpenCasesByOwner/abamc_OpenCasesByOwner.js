import { LightningElement, wire, track,api } from 'lwc';
import getOpenCasesByOwner from '@salesforce/apex/ABSLAMC_MyOpenCasesController.getOpenCasesByOwner';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class Abamc_OpenCasesByOwner extends NavigationMixin(LightningElement) {
    @track casesByStage = [];
    userId = userId;
    @track activeSectionName = '';;
    wiredCasesResult;
    @track isLoading = false;

    connectedCallback(){
        console.log('userid:',this.userId);
    }

    @wire(getOpenCasesByOwner, { userId: '$userId' })
    wiredCases(result) {
        this.wiredCasesResult = result; // Store the result for refreshApex
        const { data, error } = result;
        if (data) {
            this.casesByStage = Object.keys(data).map(stage => ({
                stage,
                cases: data[stage]
            }));
        } else if (error) {
            console.error('Error retrieving cases:', error);
        }
        this.isLoading = false;
    }


    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        // If a section is opened, set it as the active section
        if (openSections.length > 0) {
            this.activeSectionName = openSections[0];
        }
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredCasesResult);
        this.isLoading = false;
    }

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