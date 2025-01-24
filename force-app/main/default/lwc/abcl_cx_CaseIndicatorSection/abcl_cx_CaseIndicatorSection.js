import { LightningElement,api } from 'lwc';
import getCaseCounts from '@salesforce/apex/Asf_NpsIndicatiorController.getCaseCounts';

export default class Abcl_cx_CaseIndicatorSection extends LightningElement {
    showOpenCase = 0;
    showOpenComplaintCase=0;
    showEscalatedCases = 0;
    showSLABreachedCases=0;
    @api recordId;
    connectedCallback() {
        console.log('Inside connectedCallback');
        this.fetchCustomerCaseCount();
    }
 
    fetchCustomerCaseCount() {
        getCaseCounts({ accountId: this.recordId })
            .then((result) => {
                console.log('result---',JSON.stringify(result));
                if (result) {

                    this.showOpenCase = result.openCases;
                    this.showOpenComplaintCase = result.complaintCases;
                    this.showEscalatedCases = result.escalatedCases;
                    this.showSLABreachedCases =result.slaBreached;
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error retrieving customer data:', error);
            });
    }

    getIndicatorStyle(count) {
        return count > 0 ? 'red-text' : 'green-text';
    }

    //Custom CSS on numbers as per the count
    renderedCallback() {
        // Query all indicators
        const indicators = this.template.querySelectorAll('.indicator');
        console.log('Indicators found');
        indicators.forEach((indicator) => {
            const numberElement = indicator.querySelector('.indicator-number');
            if (parseInt(numberElement.textContent) > 0) {
                numberElement.classList.add('red-text');
                numberElement.classList.remove('green-text');
            } else {
                numberElement.classList.add('green-text');
                numberElement.classList.remove('red-text');
            }
        });
    }

    
}