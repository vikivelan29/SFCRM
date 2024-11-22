import { LightningElement, api, wire } from 'lwc';
import getCasesForAccount from '@salesforce/apex/ABSLAMC_AccountIndicatorController.getCasesForAccount';
import getLatestNPSData from '@salesforce/apex/ABSLAMC_AccountIndicatorController.getLatestNPSData';
import { loadStyle } from 'lightning/platformResourceLoader';
import CUSTOM_ABAMC_Indicator_CSS from '@salesforce/resourceUrl/ABAMC_Indicator_CSS';

export default class Abamc_accountIndicator extends LightningElement {
    @api recordId;

    caseData = [];
    npsData = [];
    error;
    noCaseData = false;
    noNPSData = false;

    connectedCallback() {
        console.log('inside conne',CUSTOM_ABAMC_Indicator_CSS);
        loadStyle(this, CUSTOM_ABAMC_Indicator_CSS)
            .then(() => {
                console.log('inside conne',CUSTOM_ABAMC_Indicator_CSS);
                console.log('CSS loaded successfully');
            })
            .catch(error => {
                console.log('inside conne',CUSTOM_ABAMC_Indicator_CSS);
                console.error('Error loading CSS', error);
            });
    }

    @wire(getCasesForAccount, { accId: '$recordId' })
    wiredCases({ error, data }) {
        if (data) {
            this.caseData = this.processCaseData(data);
            this.error = undefined;
            console.log('inside case data');
            if(this.caseData.length === 0){
                this.noCaseData = true;
            }
        } else if (error) {
            console.log('inside case error');
            this.error = error;
            this.caseData = undefined;
            this.noCaseData = true;
        }
    }

    processCaseData(data) {
        let processedCaseData = [];
        for (let key in data) {
            if (data.hasOwnProperty(key)) {
                processedCaseData.push({
                    category: key, 
                    count: data[key].length 
                });
            }
        }
        return processedCaseData;
    }

    @wire(getLatestNPSData, { accId: '$recordId' })
    wiredNPS({ error, data }) {
        if (data) {
            this.npsData = this.processNPSData(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.npsData = undefined;
            this.nonpsData = true;
        }
    }

    processNPSData(data) {
        let processedNPSData = [];
        for (let key in data) {
            if (data.hasOwnProperty(key)) {
                let value = data[key];
                let cssClass = ''; 
                if (key === 'Score' && value) {
                    let score = parseInt(value, 10);
                    if (score >= 1 && score <= 6) {
                        value = `${score} - Detractor`;
                        cssClass = 'nps-detractor';
                    } else if (score === 7 || score === 8) {
                        value = `${score} - Passive`;
                        cssClass = 'nps-passive';
                    } else if (score === 9 || score === 10) {
                        value = `${score} - Promoter`;
                        cssClass = 'nps-promoter';
                    }
                }

                processedNPSData.push({ key, value, cssClass });
            }
        }
        console.log('processed NPS Data:',JSON.stringify(processedNPSData));
        return processedNPSData;
    }    
}