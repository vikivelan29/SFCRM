import { LightningElement,track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import WHATSAPPOPT_FIELD from '@salesforce/schema/Account.WhatsApp_Opt_in_status__c';
import ABCCONSENT_FIELD from '@salesforce/schema/Account.ABC_Consent__c';
import SOCIALMEDIAICONS from "@salesforce/resourceUrl/ABCL_SocailMediaIcons";
export default class Abcl_cx_CustomerConsentSection extends LightningElement {
    @api recordId;
    whatappOptIn = '-';
    serviceOptIn = '-';
    abcOptIn = '-';
    crossSellOptIn = '-';
    whatsappLogo = `${SOCIALMEDIAICONS}/ABCL_Whatsapp.png`;
    serviceappLogo = `${SOCIALMEDIAICONS}/ABCL_Serviceapp.png`;
    crossappLogo = `${SOCIALMEDIAICONS}/ABCL_Crossapp.png`;
    abcLogo = `${SOCIALMEDIAICONS}/ABCL_ABC.jpg`;
    @wire(getRecord, { recordId: '$recordId', fields: [WHATSAPPOPT_FIELD, ABCCONSENT_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            if (WHATSAPPOPT_FIELD.fieldApiName in data.fields) {
                if(data.fields.WhatsApp_Opt_in_status__c.value) {
                    this.whatappOptIn = data.fields.WhatsApp_Opt_in_status__c.value;
                }
            }
            if (ABCCONSENT_FIELD.fieldApiName in data.fields) {
                if(data.fields.ABC_Consent__c.value){
                    this.abcOptIn = data.fields.ABC_Consent__c.value;
                }
            }
        } else if (error) {
            console.error(error);
        }
    }
    
}