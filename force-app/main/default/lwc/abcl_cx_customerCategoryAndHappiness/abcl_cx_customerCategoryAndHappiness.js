import { LightningElement, track, api, wire } from 'lwc';
import SOCIALMEDIAICONS from "@salesforce/resourceUrl/ABCL_SocailMediaIcons";
import BUSINESS_UNIT from '@salesforce/schema/Account.Business_Unit__c';
import getNpsScore from '@salesforce/apex/Asf_NpsIndicatiorController.getNpsScore';
import getAccountInfoFields from '@salesforce/apex/ABCL_cx360Controller.getAccountInfoFields';
import getHandleWithCareField from '@salesforce/apex/ABCL_cx360Controller.getHNIorHWCField';
import { getRecord } from 'lightning/uiRecordApi';
import { lanLabels } from 'c/asf_ConstantUtility'; //sad
import { NavigationMixin} from 'lightning/navigation';
export default class Abcl_cx_customerCategoryAndHappiness extends NavigationMixin(LightningElement) {

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
    isAbml;
    isOther;
    showUndefinedNPS = false;
    showSadNPS = false;
    showNeutralNPS = false;
    showSatisfactoryNPS = false;
    @api recordId;
    employmenttype = '-';
    customerSince = '-';
    showHWC = false;
    //ABML properties
    accountOpeningDate='-';
    clientAccountStatus='-';
    fieldsToFetch;
    fields = [];
    @wire(getRecord, { recordId: '$recordId', fields: [BUSINESS_UNIT] })
    wiredRecord({ error, data }) {
        if (data) {
            //Business Unit
            if (BUSINESS_UNIT.fieldApiName in data.fields) {
                console.log('Business Unit 1>>',data.fields.Business_Unit__c.value);
                const businessUnitValue = data.fields.Business_Unit__c.value;
                this.businessUnit = data.fields.Business_Unit__c.value;
                this.isAbhfl = businessUnitValue === 'ABHFL';
                this.isWellness = businessUnitValue === 'Wellness';
                this.isAbml = businessUnitValue === 'ABML';
                console.log('this.isAbml>>',this.isAbml);
                this.isOther = (businessUnitValue !== 'ABHFL' && businessUnitValue !== 'Wellness');
                this.customerBU = businessUnitValue ?? '';
                this.getAccountInfoFields();
                this.getHandleWithCareField();
                this.loadNpsScore();
            }
            
        } else if (error) {
            console.error(error);
        }
    }

    getAccountInfoFields(){
        getAccountInfoFields({recordId: this.recordId, businessUnit: this.businessUnit, tileName:'Customer Happiness'})
            .then((fields) => {
                this.fields = fields; // Populate the fields array
            })
            .catch((error) => {
                console.error('Error fetching field set fields:', error);
                this.error = error;
            });
    }
    
    getHandleWithCareField(){
        getHandleWithCareField({recordId: this.recordId, businessUnit:this.businessUnit,scenario:'HWC' })
        .then(result => {
                    this.showHWC = result;
        })
        .catch(error => {
            console.error('error handle with care', error);
        });
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