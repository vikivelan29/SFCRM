import { LightningElement, track, api, wire } from 'lwc';
import SOCIALMEDIAICONS from "@salesforce/resourceUrl/ABCL_SocailMediaIcons";
import CUSTOMERSINCE_FIELD from '@salesforce/schema/Account.Customer_Since__c';
import HWC_FIELD from '@salesforce/schema/Account.Handle_With_Care_HWC__c';
import BUSINESS_UNIT from '@salesforce/schema/Account.Business_Unit__c';
import HNICUSTOMER from '@salesforce/schema/Account.HNI_Customer__c';
import getNpsScore from '@salesforce/apex/Asf_NpsIndicatiorController.getNpsScore';
import { getRecord } from 'lightning/uiRecordApi';
import { lanLabels } from 'c/asf_ConstantUtility';
import { NavigationMixin} from 'lightning/navigation';
export default class Abcl_cx_customerCategoryAndHappiness extends NavigationMixin(LightningElement) {
    //facebookLogo = `${SOCIALMEDIAICONS}/facebook.png`;
    //xLogo = `${SOCIALMEDIAICONS}/twitter.png`;
    //linkedInLogo = `${SOCIALMEDIAICONS}/linkedin.png`;
    //instagramLogo = `${SOCIALMEDIAICONS}/instagram.png`;
    facebookLogo = `${SOCIALMEDIAICONS}/facebook.jpg`;
    xLogo = `${SOCIALMEDIAICONS}/twitter.jpg`;
    linkedInLogo = `${SOCIALMEDIAICONS}/linkedin.jpg`;
    instagramLogo = `${SOCIALMEDIAICONS}/instagram.jpg`;
    hwcLogo= `${SOCIALMEDIAICONS}/HWC.png`;
    facebooklink = 'https://facebook.com';
    xlink = 'https://twitter.com';
    linkedinlink = 'https://www.linkedin.com';
    instagramlink = 'https://instagram.com';
    nps = undefined;
    showCustomerNPSbyNumber;
    customerBU = '';
    isAbhfl;
    isWellness;
    isOther;
    showUndefinedNPS = false;
    showSadNPS = false;
    showNeutralNPS = false;
    showSatisfactoryNPS = false;
    @api recordId;
    employmenttype = '-';
    customerSince = '-';
    showHWC = false;
    showHNI= false;

    @wire(getRecord, { recordId: '$recordId', fields: [CUSTOMERSINCE_FIELD, HWC_FIELD, BUSINESS_UNIT,HNICUSTOMER] })
    wiredRecord({ error, data }) {
        if (data) {
            //Customer since data
            if (CUSTOMERSINCE_FIELD.fieldApiName in data.fields) {
                this.customerSince = data.fields.Customer_Since__c.value;
                let dateObject = new Date(this.customerSince);
                this.customerSince = dateObject.toISOString().split('T')[0];;
            }
            //HWC data
            if (HWC_FIELD.fieldApiName in data.fields) {
                let hwcFieldVal = data.fields.Handle_With_Care_HWC__c.value;
                if (hwcFieldVal == 'Y' || hwcFieldVal == 'Yes') {
                    this.showHWC = true;
                }
            }

            //Business Unit
            if (BUSINESS_UNIT.fieldApiName in data.fields) {
                const businessUnitValue = data.fields.Business_Unit__c.value;
                this.isAbhfl = businessUnitValue === 'ABHFL';
                this.isWellness = businessUnitValue === 'Wellness';
                this.isOther = (businessUnitValue !== 'ABHFL' && businessUnitValue !== 'Wellness');
                this.customerBU = businessUnitValue ?? '';
                this.loadNpsScore();
            }
            if (HNICUSTOMER.fieldApiName in data.fields) {
                const hniCust = data.fields.HNI_Customer__c.value;
                if(hniCust==true){
                    this.showHNI=true;
                }
            }


        } else if (error) {
            console.error(error);
        }
    }


    loadNpsScore() {
        getNpsScore({ customerId: this.recordId })
            .then(result => {
                this.nps = result;
                console.log('NPS record', JSON.stringify(this.nps));
                this.claculateNPSRating();
            })
            .catch(error => {
                console.error('Error loading NPS record', error);
            });
    }

    claculateNPSRating() {
        this.showCustomerNPSbyNumber = undefined;

        if (JSON.stringify(this.nps) !== "{}") {
            this.businessUnit = Object.keys(this.nps)[0];
            this.showCustomerNPSbyNumber = this.nps[this.businessUnit];
        }
        else {
            this.businessUnit = this.customerBU;
        }

        if (this.businessUnit && (this.businessUnit !== lanLabels[this.businessUnit].ABHI_BUSINESS_UNIT)) {
            if (this.businessUnit == 'ABHFL') {
                if (this.showCustomerNPSbyNumber == undefined) {
                    this.showUndefinedNPS = true;
                    console.log('Undefined TRUE');
                }
                else if (this.showCustomerNPSbyNumber >= 0 && this.showCustomerNPSbyNumber <= 3) {
                    this.showSadNPS = true;
                    console.log('SAD TRUE');
                }
                else if (this.showCustomerNPSbyNumber > 3 && this.showCustomerNPSbyNumber <= 6) {
                    this.showNeutralNPS = true;
                    console.log('Neutral TRUE');
                }
                else if (this.showCustomerNPSbyNumber > 6 && this.showCustomerNPSbyNumber <= 10) {
                    this.showSatisfactoryNPS = true;
                    console.log('Satisfactory TRUE');
                }
                else {
                    this.showUndefinedNPS = true;
                    console.log('Undefined TRUE final');
                }
            } else {
                if (this.showCustomerNPSbyNumber == 0 || this.showCustomerNPSbyNumber == undefined) {
                    this.showUndefinedNPS = true;
                }
                else if (this.showCustomerNPSbyNumber > 0 && this.showCustomerNPSbyNumber <= 3) {
                    this.showSadNPS = true;
                }
                else if (this.showCustomerNPSbyNumber > 3 && this.showCustomerNPSbyNumber <= 6) {
                    this.showNeutralNPS = true;
                }
                else if (this.showCustomerNPSbyNumber > 6 && this.showCustomerNPSbyNumber <= 10) {
                    this.showSatisfactoryNPS = true;
                }
                else {
                    this.showUndefinedNPS = true;
                }
            }

        }
        else if (this.businessUnit && (this.businessUnit === lanLabels[this.businessUnit].ABHI_BUSINESS_UNIT)) {
            this.logicToShowEmoji();
        }
    }

    logicToShowEmoji() {
        if (this.showCustomerNPSbyNumber <= 6) {
            this.showSadNPS = true;
        }
        else if (this.showCustomerNPSbyNumber <= 8) {
            this.showNeutralNPS = true;
        }
        else if (this.showCustomerNPSbyNumber <= 10) {
            this.showSatisfactoryNPS = true;
        }
        else {
            this.showUndefinedNPS = true;
        }
    }

    //Navigation to Survey Response
    navigateTOSurveyResponse() {
        this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
        var strtabId;
        if(focusedTab.tabId){strtabId=focusedTab.tabId}
        if(focusedTab.parentTabId){strtabId=focusedTab.parentTabId}
        this.invokeWorkspaceAPI('openSubtab', {
            parentTabId: strtabId,
            pageReference: {
            type: "standard__component",
            attributes: {
                componentName: "c__abhfl_NavigationAura",
            },
            state: {
                c__accountId: this.recordId
            }
            },
            focus: true
        }).then(response => {
            this.invokeWorkspaceAPI('setTabLabel', {
            tabId: response,
            label: 'Survey Details'
            }),
            this.invokeWorkspaceAPI('setTabIcon', {
                tabId: response,
                icon: "utility:product_transfer",
                iconAlt: "apex_plugin"
            })
        });
        });
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
        const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
 
            detail: {
            category: "workspaceAPI",
            methodName: methodName,
            methodArgs: methodArgs,
            callback: (err, response) => {
                if (err) {
                return reject(err);
                } else {
                return resolve(response);
                }
            }
            }
        });
        window.dispatchEvent(apiEvent);
        });
    }
}